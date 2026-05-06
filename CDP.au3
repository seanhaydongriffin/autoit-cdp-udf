#AutoIt3Wrapper_UseX64=y
FileInstall(".\json-c.dll", ".\")
FileInstall(".\libcurl-x64.dll", ".\")
FileInstall(".\selenium-manager.exe", ".\")

; ======================================================================================================================
;   AutoIt CDP UDF
;   Direct Chrome DevTools Protocol automation for AutoIt
; ======================================================================================================================

#region --- Core Includes & Globals ---

#include-once
#include <AutoItConstants.au3>
#include <StringConstants.au3>
#include <Array.au3>
#include "CurlEx.au3"
#include "JsonC.au3"
#include "AutoItObject.au3"

Global $hActiveBrowserWs = Null
Global $hActivePageWs = Null
Global $hActiveSessionId = Null
Global $g_iCDP_NextId = 1

Global Const $WINHTTP_WEB_SOCKET_RECEIVE_FLAG_PEEK = 1

Global $g_CDP_Pending = ObjCreate("Scripting.Dictionary")
Global $g_CDP_Events  = ObjCreate("Scripting.Dictionary")
Global $g_PageLoaded = False
$g_CDP_Events("Page.loadEventFired") = "_OnPageLoad"

$AutoItError = ObjEvent("AutoIt.Error", "ErrFunc") ; Install a custom error handler

#endregion

#region --- Initialization ---

_JsonC_Startup("json-c.dll")
_AutoItObject_Startup()

Global $cdpConfig = _AutoItObject_Create()
_AutoItObject_AddProperty($cdpConfig, "timeout", $ELSCOPE_PUBLIC, 5000)
_AutoItObject_AddProperty($cdpConfig, "infoPopups", $ELSCOPE_PUBLIC, False)
_AutoItObject_AddProperty($cdpConfig, "errorPopups", $ELSCOPE_PUBLIC, False)

Global $cdpBrowser = _AutoItObject_Create()
_AutoItObject_AddMethod($cdpBrowser, "launch", "_CDP_Browser_Launch")
_AutoItObject_AddMethod($cdpBrowser, "attach", "_CDP_Browser_Attach")

Global $cdp = _AutoItObject_Create()
_AutoItObject_AddProperty($cdp, "config", $ELSCOPE_PUBLIC, $cdpConfig)
_AutoItObject_AddProperty($cdp, "browser", $ELSCOPE_PUBLIC, $cdpBrowser)

AdlibRegister("_CDP_RecvLoop", 5)

#endregion

#region --- CDP Transport Layer (low-level) ---

Func _CDP_Connect($iUrl)

	Local $hCurl = Curl_Easy_Init()
	Curl_Easy_Setopt($hCurl, $CURLOPT_URL, $iUrl)
	Curl_Setopt_Websocket($hCurl)
	Curl_Easy_Perform($hCurl)
	Return $hCurl

EndFunc

Func __CDP_Send($sJson)
    Local $rc = Curl_Ws_Send($hActivePageWs, $sJson)
    ;Local $rc = Curl_Ws_Send($sJson)
    Local $sent = @extended

    ; rc = CURLcode, sent = bytes sent
    If $rc <> 0 Or $sent = 0 Then
        ConsoleWrite("CDP SEND: failed rc=" & $rc & " sent=" & $sent & @CRLF)
        Return SetError(1, $rc, False)
    EndIf

    Return True
EndFunc

Func _CDP_SendCommand($sMethod, $oParams = Null)
    Local $iId = $g_iCDP_NextId
    $g_iCDP_NextId += 1

    Local $sJson = '{"id":' & $iId & ',"method":"' & $sMethod & '"'

	If $hActiveSessionId <> Null Then $sJson &= ',"sessionId":"' & $hActiveSessionId & '"'

    If Not IsObj($oParams) Then
        $sJson &= '}'
    Else
        Local $sParams = __CDP_ParamsToJson($oParams)
        $sJson &= ',"params":' & $sParams & '}'
    EndIf

    ;ConsoleWrite("SEND: " & $sJson & @CRLF)

    __CDP_Send($sJson)
    Return $iId
EndFunc

Func _CDP_SendSync($method, $params = Null, $timeout = 2000)

	; Send command → get ID
    Local $id = _CDP_SendCommand($method, $params)

    ; Wait for response
    Local $t = TimerInit()
    While TimerDiff($t) < $timeout
		If $g_CDP_Pending.Exists($id) Then
            Local $resp = $g_CDP_Pending($id)
            $g_CDP_Pending.Remove($id)
            Return $resp
        EndIf
        Sleep(1)
    WEnd

    Return SetError(1, 0, Null)
EndFunc

Func _CDP_RecvLoop()

	if $hActivePageWs = Null Then Return

    Local $msg = Curl_Ws_Recv($hActivePageWs)
    Local $rc  = @extended

    ; rc = 81 (CURLE_AGAIN) means no data yet — totally normal
    If $rc = 81 Then
		Return
	EndIf

    ; rc = 56 (CURLE_RECV_ERROR) means connection closed
    If $rc = 56 Then
        ConsoleWrite("CDP RECV LOOP: connection closed (rc=56)" & @CRLF)
        AdlibUnRegister("_CDP_RecvLoop")
        Return
    EndIf

    ; Any other non-zero rc is a real error
    If $rc <> 0 Then
        ConsoleWrite("CDP RECV LOOP: fatal error rc=" & $rc & @CRLF)
        AdlibUnRegister("_CDP_RecvLoop")
        Return
    EndIf

    ; No message (empty string) but rc=0 → nothing to do
    If $msg = "" Then
		Return
	EndIf

    ; Normal message handling
    ;ConsoleWrite("RECV: " & $msg & @CRLF)

    Local $msgObj = _JsonC_TokenerParse($msg)
    If $msgObj = 0 Then
		Return
	EndIf

    Local $msgIdObj = _JsonC_ObjectObjectGet($msgObj, "id")
    Local $msgMethodObj = _JsonC_ObjectObjectGet($msgObj, "method")

    Local $msgId = ""
    Local $msgMethod = ""

    If $msgIdObj <> 0 Then $msgId = _JsonC_ObjectGetValue($msgIdObj)
    If $msgMethodObj <> 0 Then $msgMethod = _JsonC_ObjectGetValue($msgMethodObj)

    ; -------------------------
    ; 1. RESPONSE (has "id")
    ; -------------------------
    If $msgId <> "" Then
        $g_CDP_Pending($msgId) = $msgObj
        Return
    EndIf

    ; -------------------------
    ; 2. EVENT (has "method")
    ; -------------------------
    If $msgMethod <> "" Then
        If $g_CDP_Events.Exists($msgMethod) Then
            ; Call the event handler
            Call($g_CDP_Events($msgMethod), $msgObj)
		EndIf
        Return
    EndIf

EndFunc

Func _CDP_NewParams()
    Return ObjCreate("Scripting.Dictionary")
EndFunc

Func _CDP_WaitForLoad($timeout = 5000)
    Global $g_PageLoaded = False

    Local $t = TimerInit()
    While Not $g_PageLoaded
        If TimerDiff($t) > $timeout Then Return False
        Sleep(10)
    WEnd

    Return True
EndFunc

Func _CDP_Evaluate($sExpression)
    Local $oParams = _CDP_NewParams()
    $oParams.Add("expression", $sExpression)
    ;$oParams.Add("returnByValue", True)

    Return _CDP_SendSync("Runtime.evaluate", $oParams)
EndFunc

Func _OnPageLoad($params)
    ;ConsoleWrite("Page loaded event fired" & @CRLF)
    $g_PageLoaded = True
EndFunc

#endregion

#region --- Browser Class ---

Func _CDP_Browser_Launch($oSelf, $browser = Default, $port = Default, $startupSwitches = Default, $profile = Default, $windowSize = Default)

	if $cdp.config.infoPopups = True Then SplashTextOn("AutoIt CDP", "Preparing browser ...", 420, 120)

	if $browser = Default Then $browser = @ProgramFilesDir & "\Google\Chrome\Application\chrome.exe"
	if $port = Default Then $port = 9222
	if $startupSwitches = Default Then $startupSwitches = "--no-first-run --no-default-browser-check --disable-gpu --disable-dev-shm-usage --disable-extensions --disable-background-networking --disable-renderer-backgrounding --disable-sync --metrics-recording-only --mute-audio --hide-crash-restore-bubble --noerrdialogs --disable-infobars --disable-popup-blocking"
	if $profile = Default Then $profile = @ScriptDir & "\chromeprofile"
	if $windowSize <> Default Then $startupSwitches = $startupSwitches & ' --window-size=' & $windowSize

    If IsString($browser) And StringInStr($browser, "@") > 0 Then
		; it's a browser specifier
		$browserSpecifier = $browser
		$browser = __CDP_ResolveBrowserSpecifier($browserSpecifier)
		if @error > 0 Then
			ConsoleWrite('Browser specifier ' & $browserSpecifier & ' not found. Exiting.' & @CRLF)
			Exit
		EndIf
	ElseIf Not FileExists($browser) Then
        ConsoleWrite('Browser path ' & $browser & ' not found. Exiting.' & @CRLF)
        Exit
	EndIf

	; always delete previous sessions in the user profile
	;	to simplify detection of the correct websocket
	DirRemove($profile & "\Default\Sessions", 1)

	ConsoleWrite('> Info : Running ' & $browser & @CRLF)
	if $cdp.config.infoPopups = True Then ControlSetText("AutoIt CDP", "", "Static1", 'Launching browser ... ')
	Local $cmd = '"' & $browser & '" --remote-debugging-port=' & $port & ' --user-data-dir="' & $profile & '" ' & $startupSwitches ; & ' chrome://newtab'
    Run($cmd)

	if $cdp.config.infoPopups = True Then SplashOff()

    Sleep(500) ; give Chrome time to start

	$hActiveBrowserWs = __CDP_Browser_Connect($port)
	ConsoleWrite('> Info : Browser WebSocket Handle: ' & $hActiveBrowserWs & @CRLF)


    ; Create Browser object

    Local $oBrowser = _AutoItObject_Create()

    ; Add methods

    _AutoItObject_AddMethod($oBrowser, "page", "_CDP_Browser_NewPage")
    _AutoItObject_AddMethod($oBrowser, "headlessShell", "_CDP_Browser_NewHeadlessShell")
    _AutoItObject_AddMethod($oBrowser, "close", "_CDP_Browser_Close")

    ; Add properties

    ;_AutoItObject_AddProperty($oBrowser, "wsUrl", $ELSCOPE_PUBLIC, $browserWsUrl)
    _AutoItObject_AddProperty($oBrowser, "wsPort", $ELSCOPE_PUBLIC, $port)
    _AutoItObject_AddProperty($oBrowser, "wsHandle", $ELSCOPE_PUBLIC, $hActiveBrowserWs)

    Return $oBrowser
EndFunc

Func _CDP_Browser_Attach($oSelf, $port = 9222)

	; Connect to CDP

	$hActiveBrowserWs = __CDP_Browser_Connect($port)

    ; Create Browser object

    Local $oBrowser = _AutoItObject_Create()

    ; Add methods

    _AutoItObject_AddMethod($oBrowser, "page", "_CDP_Browser_NewPage")
    _AutoItObject_AddMethod($oBrowser, "close", "_CDP_Browser_Close")

    ; Add properties

    ;_AutoItObject_AddProperty($oBrowser, "wsUrl", $ELSCOPE_PUBLIC, $browserWsUrl)
    _AutoItObject_AddProperty($oBrowser, "wsPort", $ELSCOPE_PUBLIC, $port)
    _AutoItObject_AddProperty($oBrowser, "wsHandle", $ELSCOPE_PUBLIC, $hActiveBrowserWs)

    Return $oBrowser
EndFunc

Func __CDP_Browser_Connect($port)

	; Get the browser level websocket

	Local $resp = Curl_Get("http://localhost:" & $port & "/json/version")
	Local $pattern = '(?s)"webSocketDebuggerUrl"\s*:\s*"([^"]+)"'
	Local $matches = StringRegExp($resp, $pattern, 1)

	If @error Then
		ConsoleWrite("No browser WebSocket found" & @CRLF)
		Return
	EndIf

	Local $browserWsUrl = $matches[0]
	ConsoleWrite('> Info : Browser WebSocket Url: ' & $browserWsUrl & @CRLF)

	; Connect to the browser level websocket

	return _CDP_Connect($browserWsUrl)

EndFunc


Func _CDP_Browser_NewPage($oSelf)

	; Get the page level websocket

	Local $resp = Curl_Get("http://localhost:" & $oSelf.wsPort & "/json")
	Local $pattern = '(?s)"title"\s*:\s*"New Tab".+?"webSocketDebuggerUrl"\s*:\s*"([^"]+)"'
	Local $matches = StringRegExp($resp, $pattern, 1)

	If @error Then
		ConsoleWrite("No page WebSocket found" & @CRLF)
		Return
	EndIf

	Local $pageWsUrl = $matches[0]
	ConsoleWrite('> Info : Page WebSocket Url: ' & $pageWsUrl & @CRLF)

	; 1. Connect to the page level websocket

	$hActivePageWs = _CDP_Connect($pageWsUrl)
	ConsoleWrite('> Info : Page WebSocket Handle: ' & $hActivePageWs & @CRLF)

    ; 3. Enable core domains

    _CDP_SendSync("DOM.enable")
    _CDP_SendSync("Page.enable")
    _CDP_SendSync("Runtime.enable")

    ; Create Page object

    Local $oPage = _AutoItObject_Create()

    ; Add methods

    _AutoItObject_AddMethod($oPage, "goto",      "_CDP_Page_Goto")
    _AutoItObject_AddMethod($oPage, "evaluate",  "_CDP_Page_Evaluate")
    _AutoItObject_AddMethod($oPage, "locate",    "_CDP_Page_Locate")
    _AutoItObject_AddMethod($oPage, "locateNow", "_CDP_Page_LocateNow")

    ; Add properties

    ;_AutoItObject_AddProperty($oPage, "wsUrl", $ELSCOPE_PUBLIC, $pageWsUrl)
    _AutoItObject_AddProperty($oPage, "wsPort", $ELSCOPE_PUBLIC, $oSelf.wsPort)
    _AutoItObject_AddProperty($oPage, "wsHandle", $ELSCOPE_PUBLIC, $hActivePageWs)

    Return $oPage

EndFunc

Func _CDP_Browser_NewHeadlessShell($oSelf)

	; connect the page level websocket to the browser level websocket

	$hActivePageWs = $oSelf.wsHandle
	ConsoleWrite("Page WebSocket Handle: " & $hActivePageWs & @CRLF)

	; create a target

    Local $oParams = _CDP_NewParams()
    $oParams.Add("url", "about:blank")
    Local $resp = _CDP_SendSync("Target.createTarget", $oParams)

    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $targetIdObj = _JsonC_ObjectObjectGet($resultObj, "targetId")
    Local $targetIdVal = _JsonC_ObjectGetValue($targetIdObj)

	; get the targets

    ;$resp = _CDP_SendSync("Target.getTargets")
	;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $resp = ' & $resp & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

	; attach to the target

    Local $oParams = _CDP_NewParams()
    $oParams.Add("targetId", $targetIdVal)
    $oParams.Add("flatten", True)
    Local $resp = _CDP_SendSync("Target.attachToTarget", $oParams)

    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $sessionIdObj = _JsonC_ObjectObjectGet($resultObj, "sessionId")
    Local $sessionIdVal = _JsonC_ObjectGetValue($sessionIdObj)

	; Set the active session Id to that of the headless-shell

	$hActiveSessionId = $sessionIdVal
	ConsoleWrite("Page Session Id: " & $hActiveSessionId & @CRLF)

    ; Enable core domains

    _CDP_SendSync("DOM.enable")
    _CDP_SendSync("Page.enable")
    _CDP_SendSync("Runtime.enable")

    ; Create Page object

    Local $oPage = _AutoItObject_Create()

    ; Add methods

    _AutoItObject_AddMethod($oPage, "goto",      "_CDP_Page_Goto")
    _AutoItObject_AddMethod($oPage, "evaluate",  "_CDP_Page_Evaluate")
    _AutoItObject_AddMethod($oPage, "locate",    "_CDP_Page_Locate")
    _AutoItObject_AddMethod($oPage, "locateNow", "_CDP_Page_LocateNow")

    ; Add properties

    ;_AutoItObject_AddProperty($oPage, "wsUrl", $ELSCOPE_PUBLIC, $pageWsUrl)
    _AutoItObject_AddProperty($oPage, "wsPort", $ELSCOPE_PUBLIC, $oSelf.wsPort)
    _AutoItObject_AddProperty($oPage, "wsHandle", $ELSCOPE_PUBLIC, $hActivePageWs)

    Return $oPage

EndFunc

Func _CDP_Browser_Close($oSelf)

    AdlibUnRegister("_CDP_RecvLoop")
	Sleep(20)

    _CDP_SendCommand("Browser.close")
	Sleep(500)

	$hActiveBrowserWs = Null
	$hActivePageWs = Null
	$hActiveSessionId = Null
	$g_iCDP_NextId = 1

	$g_CDP_Pending.RemoveAll()
	$g_PageLoaded = False

	AdlibRegister("_CDP_RecvLoop", 5)
	Sleep(20)

    Return $oSelf

EndFunc

#endregion

#region --- Page Class ---

Func _CDP_Page_Goto($oSelf, $url)

;	_CDP_Navigate($url)

    Local $oParams = ObjCreate("Scripting.Dictionary")
    $oParams.Add("url", $url)

    _CDP_SendCommand("Page.navigate", $oParams)
	_CDP_WaitForLoad()

    Return $oSelf
EndFunc

Func _CDP_Page_Evaluate($oSelf, $expression)

	Local $evalObj = _CDP_Evaluate($expression)
	;_CDP_WaitForLoad()

    ; 2. Parse objectId
    Local $resultObj = _JsonC_ObjectObjectGet($evalObj, "result")
    Local $remoteObj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($remoteObj, "value")
    Local $valueObjVal = _JsonC_ObjectGetValue($valueObj)

    If $valueObjVal = "" Then Return 0
	return $valueObjVal

EndFunc

Func __CDP_Perform_Search($selector)

	for $i = 1 to 2

		Local $oParams = _CDP_NewParams()
		$oParams.Add("query", $selector)
		Local $resp = _CDP_SendSync("DOM.performSearch", $oParams)

		Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
		Local $searchIdObj = _JsonC_ObjectObjectGet($resultObj, "searchId")
		Local $searchIdVal = _JsonC_ObjectGetValue($searchIdObj)
		ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $searchIdVal = ' & $searchIdVal & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

		Local $oParams = _CDP_NewParams()
		$oParams.Add("searchId", $searchIdVal)
		$oParams.Add("fromIndex", 0)
		$oParams.Add("toIndex", 1)
		Local $resp = _CDP_SendSync("DOM.getSearchResults", $oParams)

		Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
		Local $nodeIdsObj = _JsonC_ObjectObjectGet($resultObj, "nodeIds")
		$nodeIds = _JsonC_ObjectArrayGetObjects($nodeIdsObj)

		For $nodeId in $nodeIds
			$nodeIdVal = _JsonC_ObjectGetValue($nodeId)
			if $nodeIdVal = 0 Then ExitLoop
			return $nodeIdVal
		Next

		Local $oParams = _CDP_NewParams()
		$oParams.Add("depth", -1)
		Local $resp = _CDP_SendSync("DOM.getDocument", $oParams)

	Next

	Return Null

EndFunc


Func __CDP_Object_To_Node($objectId)

	for $i = 1 to 2

		Local $oParams = _CDP_NewParams()
		$oParams.Add("objectId", $objectId)
		Local $resp = _CDP_SendSync("DOM.requestNode", $oParams)

		Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
		Local $nodeIdObj = _JsonC_ObjectObjectGet($resultObj, "nodeId")
		Local $nodeIdVal = _JsonC_ObjectGetValue($nodeIdObj)

		if $nodeIdVal <> 0 Then Return $nodeIdVal

		Local $oParams = _CDP_NewParams()
		$oParams.Add("depth", -1)
		_CDP_SendSync("DOM.getDocument", $oParams)

	Next
EndFunc


Func _CDP_Page_Locate($oSelf, $selector)

    Local $type = ""
	Local $nodeIdVal = Null

    ; Explicit prefixes
    If StringLeft($selector, 6) = "xpath=" Then
        $type = "xpath"
        $selector = StringTrimLeft($selector, 6)

    ElseIf StringLeft($selector, 4) = "css=" Then
        $type = "css"
        $selector = StringTrimLeft($selector, 4)

    ; Auto-detect XPath
    ElseIf StringLeft($selector, 2) = "//" Then
        $type = "xpath"

    ; Auto-detect CSS
    Else
        $type = "css"
    EndIf

    Local $expr = ""

    If $type = "xpath" Then
		$expr = 'document.evaluate("' & $selector & '", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue'
    Else
        $expr = "document.querySelector(`" & $selector & "`)"
    EndIf

	$timeout = 10000

    ; Wait for response
    Local $t = TimerInit()
    While TimerDiff($t) < $timeout

		Local $resp = _CDP_Evaluate($expr)

		;$json_str = _JsonC_ObjectToJsonString($resp)
		;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $json_str = ' & $json_str & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

		; Parse objectId
		Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
		Local $remoteObj = _JsonC_ObjectObjectGet($resultObj, "result")
		Local $objectIdObj = _JsonC_ObjectObjectGet($remoteObj, "objectId")

		if @error = 0 Then

			Local $objectIdVal = _JsonC_ObjectGetValue($objectIdObj)

			; Create the Locator object

			Local $oLocator = _AutoItObject_Create()
			Local $oExpect = _AutoItObject_Create()

			; Add methods

			_AutoItObject_AddMethod($oLocator, "click", "_CDP_Locator_Click")
			_AutoItObject_AddMethod($oLocator, "textContent", "_CDP_Locator_TextContent")
			_AutoItObject_AddMethod($oLocator, "innerText", "_CDP_Locator_InnerText")
			_AutoItObject_AddMethod($oLocator, "innerTextCRStripped", "_CDP_Locator_InnerTextCRStripped")
			_AutoItObject_AddMethod($oLocator, "innerTextLFStripped", "_CDP_Locator_InnerTextLFStripped")
			_AutoItObject_AddMethod($oLocator, "innerTextReplace", "_CDP_Locator_InnerTextReplace")
			_AutoItObject_AddMethod($oLocator, "innerHTML", "_CDP_Locator_InnerHTML")
			_AutoItObject_AddMethod($oLocator, "inputValue", "_CDP_Locator_InputValue")
			_AutoItObject_AddMethod($oLocator, "getAttribute", "_CDP_Locator_GetAttribute")
			_AutoItObject_AddMethod($oLocator, "isVisible", "_CDP_Locator_IsVisible")
			_AutoItObject_AddMethod($oLocator, "isHidden", "_CDP_Locator_IsHidden")
			_AutoItObject_AddMethod($oLocator, "setValue", "_CDP_Locator_SetValue")

			_AutoItObject_AddMethod($oExpect, "toBeVisible", "_CDP_Expect_Locator_ToBeVisible")
			_AutoItObject_AddMethod($oExpect, "toBeHidden", "_CDP_Expect_Locator_ToBeHidden")
			_AutoItObject_AddMethod($oExpect, "toBeEnabled", "_CDP_Expect_Locator_ToBeEnabled")
			_AutoItObject_AddMethod($oExpect, "toBeDisabled", "_CDP_Expect_Locator_ToBeDisabled")
			_AutoItObject_AddMethod($oExpect, "toBeChecked", "_CDP_Expect_Locator_ToBeChecked")
			_AutoItObject_AddMethod($oExpect, "toHaveText", "_CDP_Expect_Locator_ToHaveText")
			_AutoItObject_AddMethod($oExpect, "toContainText", "_CDP_Expect_Locator_ToContainText")
			_AutoItObject_AddMethod($oExpect, "toHaveAttribute", "_CDP_Expect_Locator_ToHaveAttribute")
			_AutoItObject_AddMethod($oExpect, "toHaveValue", "_CDP_Expect_Locator_ToHaveValue")
			_AutoItObject_AddMethod($oExpect, "toHaveCount", "_CDP_Expect_Locator_ToHaveCount")

			; Add properties

			_AutoItObject_AddProperty($oLocator, "objectId", $ELSCOPE_PUBLIC, $objectIdVal)
			_AutoItObject_AddProperty($oLocator, "nodeId", $ELSCOPE_PUBLIC, Null)
			_AutoItObject_AddProperty($oLocator, "expect", $ELSCOPE_PUBLIC, $oExpect)
			_AutoItObject_AddProperty($oLocator, "value", $ELSCOPE_PUBLIC, "")

			_AutoItObject_AddProperty($oExpect, "parent", $ELSCOPE_PUBLIC, $oLocator)

			Return $oLocator
		EndIf

		;ConsoleWrite("Retrying locator." & @CRLF)
        Sleep(1)
    WEnd

	ConsoleWrite("Timed out." & @CRLF)
	Exit

EndFunc

Func _CDP_Page_LocateNow($oSelf, $selector)

    Local $type = ""

    ; Explicit prefixes
    If StringLeft($selector, 6) = "xpath=" Then
        $type = "xpath"
        $selector = StringTrimLeft($selector, 6)

    ElseIf StringLeft($selector, 4) = "css=" Then
        $type = "css"
        $selector = StringTrimLeft($selector, 4)

    ; Auto-detect XPath
    ElseIf StringLeft($selector, 2) = "//" Then
        $type = "xpath"

    ; Auto-detect CSS
    Else
        $type = "css"
    EndIf

    Local $expr = ""

    If $type = "xpath" Then
		$expr = 'document.evaluate("' & $selector & '", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue'
    Else
        $expr = "document.querySelector(`" & $selector & "`)"
    EndIf

	Local $resp = _CDP_Evaluate($expr)

	;$json_str = _JsonC_ObjectToJsonString($resp)
	;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $json_str = ' & $json_str & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

	; Parse objectId
	Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
	Local $remoteObj = _JsonC_ObjectObjectGet($resultObj, "result")
	Local $objectIdObj = _JsonC_ObjectObjectGet($remoteObj, "objectId")

	if @error <> 0 Then Return Null

	Local $objectIdVal = _JsonC_ObjectGetValue($objectIdObj)

	; Create the Locator object

	Local $oLocator = _AutoItObject_Create()
	Local $oExpect = _AutoItObject_Create()

	; Add methods

	_AutoItObject_AddMethod($oLocator, "click", "_CDP_Locator_Click")
	_AutoItObject_AddMethod($oLocator, "innerText", "_CDP_Locator_InnerText")
	_AutoItObject_AddMethod($oLocator, "innerTextCRStripped", "_CDP_Locator_InnerTextCRStripped")
	_AutoItObject_AddMethod($oLocator, "innerTextLFStripped", "_CDP_Locator_InnerTextLFStripped")
	_AutoItObject_AddMethod($oLocator, "innerTextReplace", "_CDP_Locator_InnerTextReplace")

	; Add properties

	_AutoItObject_AddProperty($oLocator, "objectId", $ELSCOPE_PUBLIC, $objectIdVal)
	_AutoItObject_AddProperty($oLocator, "expect", $ELSCOPE_PUBLIC, $oExpect)
	_AutoItObject_AddProperty($oLocator, "value", $ELSCOPE_PUBLIC, "")
	;_AutoItObject_AddProperty($oExpect, "target", $ELSCOPE_PUBLIC, $oLocator)

	Return $oLocator

EndFunc

#endregion

#region --- Locator Class ---

; Locator_Create()
; Locator_Resolve()
; Locator_GetAttribute()
; Locator_IsVisible()


Func ValueObj($value)

	; string object
    Local $o = _AutoItObject_Create()
    _AutoItObject_AddProperty($o, "value", $ELSCOPE_PUBLIC, $value)
    _AutoItObject_AddProperty($o, "__default__", $ELSCOPE_PUBLIC, $value)

    ; expect object
    Local $expect = _AutoItObject_Create()
    _AutoItObject_AddMethod($expect, "toBe", "_CDP_Expect_Value_ToBe")
    ;_AutoItObject_AddMethod($expect, "toHaveText", "_CDP_Expect_ToHaveText")
    ;_AutoItObject_AddMethod($expect, "toContainText", "_CDP_Expect_ToContainText")
    _AutoItObject_AddMethod($expect, "toEqual", "_CDP_Expect_Value_ToEqual")
    _AutoItObject_AddMethod($expect, "toContain", "_CDP_Expect_Value_ToContain")
    _AutoItObject_AddMethod($expect, "toBeTruthy", "_CDP_Expect_Value_ToBeTruthy")
    _AutoItObject_AddMethod($expect, "toBeFalsy", "_CDP_Expect_Value_ToBeFalsy")

	_AutoItObject_AddProperty($expect, "parent", $ELSCOPE_PUBLIC, $o)
	_AutoItObject_AddProperty($o, "expect", $ELSCOPE_PUBLIC, $expect)

    Return $o
EndFunc


Func _CDP_Locator_TextContent($oSelf)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $oSelf.objectId)
    $oParams.Add("functionDeclaration", "function() { return this.textContent; }")
    $oParams.Add("returnByValue", True)

    Local $resp = _CDP_SendSync("Runtime.callFunctionOn", $oParams)

    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $result2Obj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($result2Obj, "value")
    Local $valueVal = _JsonC_ObjectGetValue($valueObj)

    Return ValueObj($valueVal)

EndFunc

Func _CDP_Locator_Click($oSelf, $waitForLoad = False)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $oSelf.objectId)
    $oParams.Add("functionDeclaration", "function() { this.click(); }")
    $oParams.Add("awaitPromise", False)

    _CDP_SendCommand("Runtime.callFunctionOn", $oParams)

	if $waitForLoad = True Then _CDP_WaitForLoad()

EndFunc

Func _CDP_Locator_InnerText($oSelf)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $oSelf.objectId)
    $oParams.Add("functionDeclaration", "function() { return this.innerText; }")
    $oParams.Add("returnByValue", True)

    Local $resp = _CDP_SendSync("Runtime.callFunctionOn", $oParams)

	;$json_str = _JsonC_ObjectToJsonString($resp)
	;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $json_str = ' & $json_str & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

    ; Extract the "result.value"
    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $result2Obj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($result2Obj, "value")
    Local $valueVal = _JsonC_ObjectGetValue($valueObj)

	$oSelf.value = $valueVal

    Return ValueObj($valueVal)
EndFunc

Func _CDP_Locator_InnerTextCRStripped($oSelf)
	$text = _CDP_Locator_InnerText($oSelf)
	Return StringStripCR($text)
EndFunc

Func _CDP_Locator_InnerTextLFStripped($oSelf)
	$text = _CDP_Locator_InnerText($oSelf)
	Return StringReplace($text, @LF, "")
EndFunc

Func _CDP_Locator_InnerTextReplace($oSelf, $searchString, $replaceString)
	$text = _CDP_Locator_InnerText($oSelf)
	Return StringReplace($text, $searchString, $replaceString)
EndFunc

Func _CDP_Locator_InnerHTML($oSelf)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $oSelf.objectId)
    $oParams.Add("functionDeclaration", "function() { return this.innerHTML; }")
    $oParams.Add("returnByValue", True)

    Local $resp = _CDP_SendSync("Runtime.callFunctionOn", $oParams)

    ; Extract the "result.value"
    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $result2Obj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($result2Obj, "value")
    Local $valueVal = _JsonC_ObjectGetValue($valueObj)

	;$oSelf.value = $valueVal

    Return ValueObj($valueVal)
EndFunc

Func _CDP_Locator_InputValue($oSelf)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $oSelf.objectId)
    $oParams.Add("functionDeclaration", "function() { return this.value; }")
    $oParams.Add("returnByValue", True)

    Local $resp = _CDP_SendSync("Runtime.callFunctionOn", $oParams)

    ; Extract the "result.value"
    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $result2Obj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($result2Obj, "value")
    Local $valueVal = _JsonC_ObjectGetValue($valueObj)

	;$oSelf.value = $valueVal

    Return ValueObj($valueVal)
EndFunc

Func _CDP_Locator_GetAttribute($oSelf, $name)

    Local $oParams = _CDP_NewParams()
	$oSelf.nodeId = __CDP_Object_To_Node($oSelf.objectId)
    $oParams.Add("nodeId", $oSelf.nodeId)

    Local $resp = _CDP_SendSync("DOM.getAttributes", $oParams)
    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $attributesObj = _JsonC_ObjectObjectGet($resultObj, "attributes")

	Local $getNextAttribute = False
	$attributes = _JsonC_ObjectArrayGetObjects($attributesObj)
	For $attribute in $attributes
		$attributeVal = _JsonC_ObjectGetValue($attribute)
		if $getNextAttribute = True Then Return ValueObj($attributeVal)
		if $attributeVal = $name Then $getNextAttribute = True
	Next

	Return Null
EndFunc

Func __CDP_Locator_IsVisibleValue($objectId)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $objectId)
    $oParams.Add("functionDeclaration", "function() { const r = this.getBoundingClientRect(); return !!(r.width && r.height); }")
    $oParams.Add("returnByValue", True)

    Local $resp = _CDP_SendSync("Runtime.callFunctionOn", $oParams)

    ; Extract the "result.value"
    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $result2Obj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($result2Obj, "value")
    Return _JsonC_ObjectGetValue($valueObj)

EndFunc

Func _CDP_Locator_IsVisible($oSelf)

	$val = __CDP_Locator_IsVisibleValue($oSelf.objectId) <> 0
    Return ValueObj($val)
EndFunc

Func _CDP_Locator_IsHidden($oSelf)

	$val = Not ( __CDP_Locator_IsVisibleValue($oSelf.objectId) <> 0 )
    Return ValueObj($val)
EndFunc

Func _CDP_Locator_SetValue($oSelf, $value)

	Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $oSelf.objectId)
    $oParams.Add("functionDeclaration", "function(value) { this.value = value; this.dispatchEvent(new Event('input', { bubbles: true })); this.dispatchEvent(new Event('change', { bubbles: true })); }")
    $oParams.Add("arguments", '[{"value":"' & $value & '"}]')

    Local $resp = _CDP_SendSync("Runtime.callFunctionOn", $oParams)

    ; Extract the "result.value"
    ;Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    ;Local $result2Obj = _JsonC_ObjectObjectGet($resultObj, "result")
    ;Local $valueObj = _JsonC_ObjectObjectGet($result2Obj, "value")
    ;Return _JsonC_ObjectGetValue($valueObj)

EndFunc

#endregion

#region --- Expect / Assertions ---

; Expect()
; Expect_ToHaveText()
; Expect_ToBeVisible()
; Expect_ToEqual()
; Expect_ToContain()


;Expect($page).ToHaveTitle("Test Pages")
;expect(page).toHaveURL()

;Expect($locator).ToHaveText("Hello") - innertext
;Expect($locator).ToBeVisible()
;expect(locator).toHaveAttribute()

;Expect($value).ToBe("Expected")
;expect(value).toEqual()
;expect(value).toContain()

#cs
Page‑level assertions

    toHaveTitle()

    toHaveURL()


#ce


Func _CDP_Expect_Locator_ToBeVisible($self, $scriptLineNumber = "?")

	if _CDP_Locator_IsVisible($self.parent).value Then

        ConsoleWrite("+ Pass (line " & $scriptLineNumber & ") : object [" & $self.parent.objectId & "] is visible" & @CRLF)
		Return True
    EndIf

    ConsoleWrite("! FAIL (line " & $scriptLineNumber & ") : object [" & $self.parent.objectId & "] is not visible" & @CRLF)
    Return False

EndFunc

Func _CDP_Expect_Locator_ToBeHidden($self, $scriptLineNumber = "?")

	if _CDP_Locator_IsHidden($self.parent).value Then

        ConsoleWrite("+ Pass (line " & $scriptLineNumber & ") : object [" & $self.parent.objectId & "] is hidden" & @CRLF)
		Return True
    EndIf

    ConsoleWrite("! FAIL (line " & $scriptLineNumber & ") : object [" & $self.parent.objectId & "] is not hidden" & @CRLF)
    Return False

EndFunc

Func _CDP_Expect_Locator_ToBeEnabled($self, $expected, $scriptLineNumber = "?")

EndFunc

Func _CDP_Expect_Locator_ToBeDisabled($self, $expected, $scriptLineNumber = "?")

EndFunc

Func _CDP_Expect_Locator_ToBeChecked($self, $expected, $scriptLineNumber = "?")

EndFunc

Func _CDP_Expect_Locator_ToHaveText($self, $expected, $scriptLineNumber = "?")

	Local $actual = _CDP_Locator_TextContent($self.parent).value

	If $actual = $expected Then
        ConsoleWrite("+ Pass (line " & $scriptLineNumber & ") : expected [" & $expected & "] and got [" & $actual & "]" & @CRLF)
		Return True
    EndIf

    ConsoleWrite("! FAIL (line " & $scriptLineNumber & ") : expected [" & $expected & "] but got [" & $actual & "]" & @CRLF)
    Return False
EndFunc

Func _CDP_Expect_Locator_ToContainText($self, $expected, $scriptLineNumber = "?")

	Local $actual = _CDP_Locator_TextContent($self.parent).value

	If StringInStr($actual, $expected) > 0 Then
		ConsoleWrite('+ Pass (line ' & $scriptLineNumber & ') : actual text contains [' & $expected & ']' & @CRLF)
        Return True
    EndIf

	ConsoleWrite('! Fail (line ' & $scriptLineNumber & ') : expected actual text to contain [' & $expected & '] but got [' & $actual & ']' & @CRLF)
    Return False
EndFunc

Func _CDP_Expect_Locator_ToHaveAttribute($self, $expected, $scriptLineNumber = "?")

EndFunc

Func _CDP_Expect_Locator_ToHaveValue($self, $expected, $scriptLineNumber = "?")

EndFunc

Func _CDP_Expect_Locator_ToHaveCount($self, $expected, $scriptLineNumber = "?")

EndFunc

Func _CDP_Expect_Value_ToBe($self, $expected, $scriptLineNumber = "?")
    Local $actual = $self.parent.value
    If $actual = $expected Then
        ConsoleWrite("+ Pass (line " & $scriptLineNumber & ") : expected [" & $expected & "] and got [" & $actual & "]" & @CRLF)
		Return True
    EndIf

    ConsoleWrite("! FAIL (line " & $scriptLineNumber & ") : expected [" & $expected & "] but got [" & $actual & "]" & @CRLF)
    Return False

EndFunc

Func _CDP_Expect_Value_ToEqual($self, $expected, $scriptLineNumber = "?")

EndFunc

Func _CDP_Expect_Value_ToContain($self, $expected, $scriptLineNumber = "?")

    Local $actual = $self.parent.value

	If StringInStr($actual, $expected) > 0 Then
		ConsoleWrite('+ Pass (line ' & $scriptLineNumber & ') : actual text contains [' & $expected & ']' & @CRLF)
        Return True
    EndIf

	ConsoleWrite('! Fail (line ' & $scriptLineNumber & ') : expected actual text to contain [' & $expected & '] but got [' & $actual & ']' & @CRLF)
    Return False

EndFunc

Func _CDP_Expect_Value_ToBeTruthy($self, $expected, $scriptLineNumber = "?")

EndFunc

Func _CDP_Expect_Value_ToBeFalsy($self, $expected, $scriptLineNumber = "?")

EndFunc


#endregion

#region --- Utilities ---

; String helpers
; JSON helpers
; Debug helpers

Func _CDP_Downloads_DeleteFile($fileMask)
	FileDelete(@UserProfileDir & "\Downloads\" & $fileMask)
EndFunc

Func _CDP_Downloads_WaitForFile($filename, $timeoutMs = 10000)
    Local $end = TimerInit()
    While Not FileExists(@UserProfileDir & "\Downloads\" & $filename)
        Sleep(50)
        If TimerDiff($end) > $timeoutMs Then Return False
    WEnd
    Return True
EndFunc

Func WaitForFile($path, $timeoutMs = 5000)
    Local $end = TimerInit()
    While Not FileExists($path)
        Sleep(50)
        If TimerDiff($end) > $timeoutMs Then Return False
    WEnd
    Return True
EndFunc


Func __CDP_ParamsToJson($o)
    Local $s = "{", $k

    For $k In $o
        Local $v = $o.Item($k)
        $s &= '"' & $k & '":'

        ; Handle AutoIt booleans explicitly
        If IsBool($v) Then
            $s &= ($v ? "true" : "false") & ","
            ContinueLoop
        EndIf

		If StringLeft($v, 1) = "[" And StringRight($v, 1) = "]" Then
			; it's wrapped in square brackets
			$s &= $v
            ContinueLoop
		EndIf

        Switch VarGetType($v)
            Case "String"
                $s &= '"' & StringReplace($v, '"', '\"') & '"'
            Case "Int32","Int64","Double"
                $s &= $v
            Case Else
                ; fallback: treat as string
                $s &= '"' & $v & '"'
        EndSwitch

        $s &= ","
    Next

    If StringRight($s, 1) = "," Then $s = StringTrimRight($s, 1)
    $s &= "}"
    Return $s
EndFunc


Func __CDP_ResolveBrowserSpecifier($browser)

    ; Split "chrome@119" into ["chrome", "119"]
    Local $arr = StringSplit($browser, "@", $STR_NOCOUNT)
    If @error Or UBound($arr) < 2 Then
        Return SetError(1, 0, $browser)
    EndIf

    Local $browserType = $arr[0]
    Local $browserVersion = $arr[1]

    ; Build Selenium Manager command
    Local $cmd = 'selenium-manager.exe --browser ' & $browserType & ' --browser-version ' & $browserVersion & ' --cache-path .'

    ; Run Selenium Manager and capture output
	ConsoleWrite('> Info : Locating ' & $browserType & ' version ' & $browserVersion & ' (this may take a moment if it needs to download)' & @CRLF)
    if $cdp.config.infoPopups = True Then ControlSetText("AutoIt CDP", "", "Static1", 'Locating ' & $browserType & ' version ' & $browserVersion & ' ...' & @CRLF & '(this may take a moment if it needs to download)')
	Local $output = __CDP_RunCmdCapture($cmd)
    If @error Then Return SetError(2, 0, "")

    ; Extract the "Browser path:" line
    Local $browserPath = __CDP_ExtractBrowserPath($output)
    If @error Then Return SetError(3, 0, "")

    Return $browserPath
EndFunc


; Helper: run a command and capture stdout
Func __CDP_RunCmdCapture($cmd)
    Local $pid = Run(@ComSpec & " /c " & $cmd, "", @SW_HIDE, $RUN_CREATE_NEW_CONSOLE + $STDERR_MERGED + $STDOUT_CHILD)
    If $pid = 0 Then Return SetError(1, 0, "")
	ProcessWaitClose($pid)
	Return StdoutRead($pid)
EndFunc


; Helper: extract the browser path from Selenium Manager output
Func __CDP_ExtractBrowserPath($text)
    Local $lines = StringSplit($text, @LF, $STR_ENTIRESPLIT)
    For $i = 1 To $lines[0]
        If StringInStr($lines[$i], "Browser path:") Then
            ; Extract everything after the colon
            Local $path = StringStripWS(StringTrimLeft($lines[$i], StringInStr($lines[$i], ":") ), $STR_STRIPALL)
            Return $path
        EndIf
    Next

    Return SetError(1, 0, "")
EndFunc





Func ErrFunc($oError)
	ConsoleWrite("!>COM Error !"&@CRLF&"!>"&@TAB&"Number: "&Hex($oError.Number,8)&@CRLF&"!>"&@TAB&"Windescription: "&StringRegExpReplace($oError.windescription,"\R$","")&@CRLF&"!>"&@TAB&"Source: "&$oError.source&@CRLF&"!>"&@TAB&"Description: "&$oError.description&@CRLF&"!>"&@TAB&"Helpfile: "&$oError.helpfile&@CRLF&"!>"&@TAB&"Helpcontext: "&$oError.helpcontext&@CRLF&"!>"&@TAB&"Lastdllerror: "&$oError.lastdllerror&@CRLF&"!>"&@TAB&"Scriptline: "&$oError.scriptline&@CRLF)
EndFunc   ;==>ErrFunc

#endregion

