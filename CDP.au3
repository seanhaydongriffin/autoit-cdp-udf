#AutoIt3Wrapper_UseX64=y
FileInstall(".\json-c.dll", ".\")
FileInstall(".\libcurl-x64.dll", ".\")
FileInstall(".\selenium-manager.exe", ".\")

; ======================================================================================================================
;   AutoIt CDP UDF
;   Direct Chrome DevTools Protocol automation for AutoIt
;
;	NOTE - Add the following line to your SciTEUser.properties for UTF8 / Unicode console support:
;
;	output.code.page=65001
;
; ======================================================================================================================

#region --- Core Includes & Globals ---

#include-once
#include <AutoItConstants.au3>
#include <StringConstants.au3>
#include <Array.au3>
#include <String.au3>
#include "CurlEx.au3"
#include "JsonC.au3"
#include "AutoItObject.au3"

Global Const $WINHTTP_WEB_SOCKET_RECEIVE_FLAG_PEEK = 1
Global $CDP_DISABLE_ALIASES
Global Enum $CDP_BROWSER, $CDP_PAGE

; Global CDP registry: wsHandle → state object
Global $g_CDP_Browsers = ObjCreate("Scripting.Dictionary")


$AutoItError = ObjEvent("AutoIt.Error", "ErrFunc") ; Install a custom error handler

#endregion

#region --- Initialization ---

_JsonC_Startup("json-c.dll")
_AutoItObject_Startup()

Local $cdpState = _AutoItObject_Create()
_AutoItObject_AddProperty($cdpState, "indentLevel",     	$ELSCOPE_PUBLIC, 0)
_AutoItObject_AddProperty($cdpState, "events",  			$ELSCOPE_PUBLIC, ObjCreate("Scripting.Dictionary"))

Global $cdpConfig = _AutoItObject_Create()
_AutoItObject_AddProperty($cdpConfig, "timeout", 			$ELSCOPE_PUBLIC, 5000)
_AutoItObject_AddProperty($cdpConfig, "debug", 				$ELSCOPE_PUBLIC, False)
_AutoItObject_AddProperty($cdpConfig, "infoPopups", 		$ELSCOPE_PUBLIC, False)
_AutoItObject_AddProperty($cdpConfig, "errorPopups", 		$ELSCOPE_PUBLIC, False)

Global $cdpBrowser = _AutoItObject_Create()
_AutoItObject_AddMethod($cdpBrowser, "launch", 				"_CDP_Browser_Launch")
_AutoItObject_AddMethod($cdpBrowser, "attach", 				"_CDP_Browser_Attach")

Global $cdp = _AutoItObject_Create()
_AutoItObject_AddProperty($cdp, "state", 					$ELSCOPE_PUBLIC, $cdpState)
_AutoItObject_AddProperty($cdp, "config", 					$ELSCOPE_PUBLIC, $cdpConfig)
_AutoItObject_AddProperty($cdp, "browser", 					$ELSCOPE_PUBLIC, $cdpBrowser)

If Not IsDeclared("CDP_DISABLE_ALIASES") Or Not $CDP_DISABLE_ALIASES Then
    Global $browser = $cdp.browser
    Global $config  = $cdp.config
EndIf

$cdp.state.events.Item("Page.loadEventFired") = "_OnPageLoad"

; UTF8 / Unicode support
DllCall("kernel32.dll", "bool", "SetConsoleOutputCP", "uint", 65001)
DllCall("kernel32.dll", "bool", "SetConsoleCP", "uint", 65001)

#endregion

#region --- CDP Transport Layer (low-level) ---

Func _CDP_Connect($iUrl)

	Local $hCurl = Curl_Easy_Init()
	Curl_Easy_Setopt($hCurl, $CURLOPT_URL, $iUrl)
	Curl_Setopt_Websocket($hCurl)
	Curl_Easy_Perform($hCurl)
	Return $hCurl

EndFunc

Func __CDP_Send($wsHandle, $sJson)
    Local $rc = Curl_Ws_Send($wsHandle, $sJson)
    Local $sent = @extended

    ; rc = CURLcode, sent = bytes sent
    If $rc <> 0 Or $sent = 0 Then
        if $cdp.config.debug = True Then ConsoleWrite("CDP SEND: failed rc=" & $rc & " sent=" & $sent & @CRLF)
        Return SetError(1, $rc, False)
    EndIf

    Return True
EndFunc

Func _CDP_SendCommand($oContext, $sMethod, $oParams = Null)

	If Not $g_CDP_Browsers.Exists(String($oContext.wsHandle)) Then Return SetError(2, 0, 0)
	Local $oState = $g_CDP_Browsers.Item(String($oContext.wsHandle))

	; Allocate id
    Local $iId = $oState.Item("nextId")
    $oState.Item("nextId") = $iId + 1

    Local $sJson = '{"id":' & $iId & ',"method":"' & $sMethod & '"'
	If $oContext.type = $CDP_PAGE Then $sJson &= ',"sessionId":"' & $oContext.sessionId & '"'

    If Not IsObj($oParams) Then
        $sJson &= '}'
    Else
        Local $sParams = __CDP_ParamsToJson($oParams)
        $sJson &= ',"params":' & $sParams & '}'
    EndIf

    if $cdp.config.debug = True Then ConsoleWrite("SEND: " & $sJson & @CRLF)

    __CDP_Send($oContext.wsHandle, $sJson)
    Return $iId
EndFunc

Func _CDP_SendSync($oContext, $method, $params = Null, $timeout = 2000)

	; 1. Resolve wsHandle key (string)
    Local $wsKey = String($oContext.wsHandle)

    If Not $g_CDP_Browsers.Exists($wsKey) Then
        Return SetError(2, 0, Null)
    EndIf

    ; 2. Get per‑browser CDP state
    Local $oState = $g_CDP_Browsers.Item($wsKey)

	; Send command → get ID
    Local $id = _CDP_SendCommand($oContext, $method, $params)

    ; Wait for response
    Local $t = TimerInit()
	Local $pending = $oState.Item("pending")

    While TimerDiff($t) < $timeout
		If $pending.Exists($id) Then
            Local $resp = $pending.Item($id)
            $pending.Remove($id)
            Return $resp
        EndIf
        Sleep(1)
    WEnd

    Return SetError(1, 0, Null)
EndFunc

Func _CDP_RecvLoop()

	; Iterate all browser wsHandles
    Local $keys = $g_CDP_Browsers.Keys

	For $i = 0 To UBound($keys) - 1

		Local $wsHandle = $keys[$i]
        Local $oState   = $g_CDP_Browsers.Item($wsHandle)
		Local $msg = Curl_Ws_Recv($wsHandle)
		Local $rc  = @extended

		; rc = 81 (CURLE_AGAIN) means no data yet — totally normal
		If $rc = 81 Then ContinueLoop

		; rc = 56 (CURLE_RECV_ERROR) means connection closed
		If $rc = 56 Then
			if $cdp.config.debug = True Then ConsoleWrite("CDP RECV LOOP: connection closed (rc=56)" & @CRLF)
			__CDP_RemoveBrowserState($wsHandle)
			ContinueLoop
		EndIf

		; Any other non-zero rc is a real error
		If $rc <> 0 Then
			if $cdp.config.debug = True Then ConsoleWrite("CDP RECV LOOP: fatal error rc=" & $rc & @CRLF)
			__CDP_RemoveBrowserState($wsHandle)
			ContinueLoop
		EndIf

		; No message (empty string) but rc=0 → nothing to do
		If $msg = "" Then ContinueLoop

		; Normal message handling
		if $cdp.config.debug = True then ConsoleWrite("RECV: " & $msg & @CRLF)

		Local $msgObj = _JsonC_TokenerParse($msg)
		If $msgObj = 0 Then ContinueLoop

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
			$oState.Item("pending").Item($msgId) = $msgObj
			ContinueLoop
		EndIf

		; -------------------------
		; 2. EVENT (has "method")
		; -------------------------
		If $msgMethod <> "" Then
			If $cdp.state.events.Exists($msgMethod) Then
				; Call the event handler
				Call($cdp.state.events.Item($msgMethod), $wsHandle, $msgObj)
			EndIf

			If $msgMethod = "Inspector.detached" Then
				__CDP_RemoveBrowserState($wsHandle)
			EndIf
			ContinueLoop
		EndIf
	Next
EndFunc

Func __CDP_RemoveBrowserState($wsKey)
    ; Remove this browser's CDP state
    If $g_CDP_Browsers.Exists($wsKey) Then
        $g_CDP_Browsers.Remove($wsKey)
		if $cdp.config.debug = True Then ConsoleWrite("DEBUG: Browser closed. Browsers remaining = " & $g_CDP_Browsers.Count & @CRLF)
    EndIf

    ; If no browsers remain, stop the recv loop
    If $g_CDP_Browsers.Count = 0 Then
        AdlibUnRegister("_CDP_RecvLoop")
		if $cdp.config.debug = True Then ConsoleWrite("DEBUG: _CDP_RecvLoop unregistered" & @CRLF)
    EndIf
EndFunc


Func _CDP_NewParams()
    Return ObjCreate("Scripting.Dictionary")
EndFunc

Func _CDP_WaitForLoad($oContext, $timeout = 5000)

    ; Resolve wsKey from browser or page
    Local $wsKey = String($oContext.wsHandle)
    If Not $g_CDP_Browsers.Exists($wsKey) Then Return False

    Local $oState = $g_CDP_Browsers.Item($wsKey)

    ; Reset load flag
    $oState.Item("pageLoaded") = False

    ; Wait for load event
    Local $t = TimerInit()
    While Not $oState.Item("pageLoaded")
        If TimerDiff($t) > $timeout Then Return False
        Sleep(10)
    WEnd

    Return True
EndFunc

Func _CDP_Evaluate($oContext, $sExpression)
    Local $oParams = _CDP_NewParams()
    $oParams.Add("expression", $sExpression)
    ;$oParams.Add("returnByValue", True)

    Return _CDP_SendSync($oContext, "Runtime.evaluate", $oParams)
EndFunc

Func _OnPageLoad($wsKey, $msgObj)
	If Not $g_CDP_Browsers.Exists($wsKey) Then Return
    Local $oState = $g_CDP_Browsers.Item($wsKey)
    ; Mark this browser as having fired a load event
    $oState.Item("pageLoaded") = True
EndFunc


#endregion



#region --- Browser Class ---

Func _CDP_Browser_Launch($oSelf, $browser = Default, $port = Default, $startupSwitches = Default, $profile = Default, $windowSize = Default)

	if $cdp.config.infoPopups = True Then SplashTextOn("AutoIt CDP", "Preparing browser ...", 420, 120)

	if $browser = Default Then $browser = @ProgramFilesDir & "\Google\Chrome\Application\chrome.exe"
	if $port = Default Then $port = 9222
	if $startupSwitches = Default Then $startupSwitches = "--no-first-run --no-default-browser-check --disable-gpu --disable-dev-shm-usage --disable-extensions --disable-background-networking --disable-renderer-backgrounding --disable-sync --metrics-recording-only --mute-audio --hide-crash-restore-bubble --noerrdialogs --disable-infobars --disable-popup-blocking --enable-automation --silent-launch"
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

	if $cdp.config.infoPopups = True Then ControlSetText("AutoIt CDP", "", "Static1", 'Launching browser ... ')
	Local $cmd = '"' & $browser & '" --remote-debugging-port=' & $port & ' --user-data-dir="' & $profile & '" ' & $startupSwitches ; & ' chrome://newtab'
	ConsoleWrite('> Info : Running ' & $cmd & @CRLF)
    Run($cmd)

	if $cdp.config.infoPopups = True Then SplashOff()

    Sleep(500) ; give Chrome time to start

	if $g_CDP_Browsers.Count = 0 Then
		AdlibRegister("_CDP_RecvLoop", 5)
		if $cdp.config.debug = True Then ConsoleWrite("DEBUG: _CDP_RecvLoop registered" & @CRLF)
	EndIf

	Local $wsHandle = Number(__CDP_Browser_Connect($port))

    Local $oState = ObjCreate("Scripting.Dictionary")
    $oState.Add("pending", ObjCreate("Scripting.Dictionary"))
    $oState.Add("nextId",  1)
    $oState.Add("pageLoaded", False)

	$g_CDP_Browsers.Add(String($wsHandle), $oState)

    ; Create Browser object

    Local $oBrowser = _AutoItObject_Create()

    ; Add methods

    _AutoItObject_AddMethod($oBrowser, "newPage", "_CDP_Browser_NewPage")
    ;_AutoItObject_AddMethod($oBrowser, "headlessShell", "_CDP_Browser_NewHeadlessShell")
    _AutoItObject_AddMethod($oBrowser, "close", "_CDP_Browser_Close")

    ; Add properties

    _AutoItObject_AddProperty($oBrowser, "type", $ELSCOPE_READONLY, $CDP_BROWSER)
    ;_AutoItObject_AddProperty($oBrowser, "wsUrl", $ELSCOPE_PUBLIC, $browserWsUrl)
    _AutoItObject_AddProperty($oBrowser, "wsPort", $ELSCOPE_PUBLIC, $port)
    _AutoItObject_AddProperty($oBrowser, "wsHandle", $ELSCOPE_PUBLIC, $wsHandle)

	; Remove the default "New Tab"

	Local $defaultTargetId = _CDP_Browser_GetDefaultTabTargetId($oBrowser)

	If $defaultTargetId <> Null Then
		Local $oParams = _CDP_NewParams()
		$oParams.Add("targetId", $defaultTargetId)
		_CDP_SendSync($oBrowser, "Target.closeTarget", $oParams)
	EndIf

    Return $oBrowser
EndFunc


Func _CDP_Browser_GetDefaultTabTargetId($oSelf)
    Local $resp = _CDP_SendSync($oSelf, "Target.getTargets")
    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $targetInfosObj = _JsonC_ObjectObjectGet($resultObj, "targetInfos")
	Local $targetInfos = _JsonC_ObjectArrayGetObjects($targetInfosObj)

	For $targetInfo in $targetInfos
		Local $typeObj = _JsonC_ObjectObjectGet($targetInfo, "type")
		Local $typeVal = _JsonC_ObjectGetValue($typeObj)
        If $typeVal = "page" Then
			Local $urlObj = _JsonC_ObjectObjectGet($targetInfo, "url")
			Local $urlVal = _JsonC_ObjectGetValue($urlObj)
			If $urlVal = "chrome://newtab/" Or $urlVal = "about:blank" Then
				Local $targetIdObj = _JsonC_ObjectObjectGet($targetInfo, "targetId")
				Local $targetIdVal = _JsonC_ObjectGetValue($targetIdObj)
				Return $targetIdVal
			EndIf
		EndIf
	Next

    Return Null
EndFunc

#cs
Func _CDP_Browser_Attach($oSelf, $port = 9222)

	; Connect to CDP

	$cdp.state.activeBrowserWs = __CDP_Browser_Connect($port)

    ; Create Browser object

    Local $oBrowser = _AutoItObject_Create()

    ; Add methods

    _AutoItObject_AddMethod($oBrowser, "page", "_CDP_Browser_NewPage")
    _AutoItObject_AddMethod($oBrowser, "close", "_CDP_Browser_Close")

    ; Add properties

    ;_AutoItObject_AddProperty($oBrowser, "wsUrl", $ELSCOPE_PUBLIC, $browserWsUrl)
    _AutoItObject_AddProperty($oBrowser, "wsPort", $ELSCOPE_PUBLIC, $port)
    _AutoItObject_AddProperty($oBrowser, "wsHandle", $ELSCOPE_PUBLIC, $cdp.state.activeBrowserWs)

    Return $oBrowser
EndFunc
#ce

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

	; create a target

    Local $oParams = _CDP_NewParams()
    $oParams.Add("url", "about:blank")
    Local $resp = _CDP_SendSync($oSelf, "Target.createTarget", $oParams)

    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $targetIdObj = _JsonC_ObjectObjectGet($resultObj, "targetId")
    Local $targetIdVal = _JsonC_ObjectGetValue($targetIdObj)

	; attach to the target

    Local $oParams = _CDP_NewParams()
    $oParams.Add("targetId", $targetIdVal)
    $oParams.Add("flatten", True)
    Local $resp = _CDP_SendSync($oSelf, "Target.attachToTarget", $oParams)

    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $sessionIdObj = _JsonC_ObjectObjectGet($resultObj, "sessionId")
    Local $sessionIdVal = _JsonC_ObjectGetValue($sessionIdObj)

    ; Create Page object

    Local $oPage = _AutoItObject_Create()

    ; Add action methods

    _AutoItObject_AddMethod($oPage, "goto",      	"_CDP_Page_Goto")
    _AutoItObject_AddMethod($oPage, "locator",    	"_CDP_Page_Locator")
    _AutoItObject_AddMethod($oPage, "locatorNow", 	"_CDP_Page_LocatorNow")
    _AutoItObject_AddMethod($oPage, "evaluate",  	"_CDP_Page_Evaluate")

	; Add getter methods

	_AutoItObject_AddMethod($oPage, "url",      	"_CDP_Page_Url")
    _AutoItObject_AddMethod($oPage, "title",      	"_CDP_Page_Title")
    _AutoItObject_AddMethod($oPage, "content",     	"_CDP_Page_Content")
    _AutoItObject_AddMethod($oPage, "viewportSize",	"_CDP_Page_ViewportSize")

    ; Add properties

    _AutoItObject_AddProperty($oPage, "type", $ELSCOPE_READONLY, $CDP_PAGE)
    ;_AutoItObject_AddProperty($oPage, "wsUrl", $ELSCOPE_PUBLIC, $pageWsUrl)
    _AutoItObject_AddProperty($oPage, "wsPort", $ELSCOPE_PUBLIC, $oSelf.wsPort)
    _AutoItObject_AddProperty($oPage, "wsHandle", $ELSCOPE_PUBLIC, $oSelf.wsHandle)
    _AutoItObject_AddProperty($oPage, "sessionId", $ELSCOPE_PUBLIC, $sessionIdVal)

    ; Enable core domains

    _CDP_SendSync($oPage, "DOM.enable")
    _CDP_SendSync($oPage, "Page.enable")
    _CDP_SendSync($oPage, "Runtime.enable")

    Return $oPage
EndFunc

#cs
Func _CDP_Browser_NewHeadlessShell($oSelf)

	; connect the page level websocket to the browser level websocket

	$cdp.state.activePageWs = $oSelf.wsHandle
	ConsoleWrite("Page WebSocket Handle: " & $cdp.state.activePageWs & @CRLF)

	; create a target

    Local $oParams = _CDP_NewParams()
    $oParams.Add("url", "about:blank")
    Local $resp = _CDP_SendSync("Target.createTarget", $oParams)

    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $targetIdObj = _JsonC_ObjectObjectGet($resultObj, "targetId")
    Local $targetIdVal = _JsonC_ObjectGetValue($targetIdObj)

	; attach to the target

    Local $oParams = _CDP_NewParams()
    $oParams.Add("targetId", $targetIdVal)
    $oParams.Add("flatten", True)
    Local $resp = _CDP_SendSync("Target.attachToTarget", $oParams)

    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $sessionIdObj = _JsonC_ObjectObjectGet($resultObj, "sessionId")
    Local $sessionIdVal = _JsonC_ObjectGetValue($sessionIdObj)

	; Set the active session Id to that of the headless-shell

	$cdp.state.activeSessionId = $sessionIdVal
	ConsoleWrite("Page Session Id: " & $cdp.state.activeSessionId & @CRLF)

    ; Enable core domains

    _CDP_SendSync($oSelf, "DOM.enable")
    _CDP_SendSync($oSelf, "Page.enable")
    _CDP_SendSync($oSelf, "Runtime.enable")

    ; Create Page object

    Local $oPage = _AutoItObject_Create()

    ; Add action methods

    _AutoItObject_AddMethod($oPage, "goto",      	"_CDP_Page_Goto")
    _AutoItObject_AddMethod($oPage, "locator",    	"_CDP_Page_Locator")
    _AutoItObject_AddMethod($oPage, "locatorNow", 	"_CDP_Page_LocatorNow")
    _AutoItObject_AddMethod($oPage, "evaluate",  	"_CDP_Page_Evaluate")

	; Add getter methods

	_AutoItObject_AddMethod($oPage, "url",      	"_CDP_Page_Url")
    _AutoItObject_AddMethod($oPage, "title",      	"_CDP_Page_Title")
    _AutoItObject_AddMethod($oPage, "content",     	"_CDP_Page_Content")
    _AutoItObject_AddMethod($oPage, "viewportSize",	"_CDP_Page_ViewportSize")

    ; Add properties

    ;_AutoItObject_AddProperty($oPage, "wsUrl", $ELSCOPE_PUBLIC, $pageWsUrl)
    _AutoItObject_AddProperty($oPage, "wsPort", $ELSCOPE_PUBLIC, $oSelf.wsPort)
    _AutoItObject_AddProperty($oPage, "wsHandle", $ELSCOPE_PUBLIC, $cdp.state.activePageWs)

    Return $oPage

EndFunc
#ce

Func _CDP_Browser_Close($oSelf)

    _CDP_SendCommand($oSelf, "Browser.close")
	Sleep(500)
	__CDP_RemoveBrowserState(String($oSelf.wsHandle))

    Return $oSelf

EndFunc

#cs
Func __CDP_Internal_Reset()
    $cdp.state.activeBrowserWs = Null
    $cdp.state.activePageWs = Null
    $cdp.state.activeSessionId = Null
    $cdp.state.nextId = 1

    $cdp.state.pending.RemoveAll()
    $cdp.state.pageLoaded = False
EndFunc
#ce

#endregion

#region --- Page Class ---

Func _CDP_Page_Goto($oSelf, $url)

    Local $oParams = ObjCreate("Scripting.Dictionary")
    $oParams.Add("url", $url)

    _CDP_SendCommand($oSelf, "Page.navigate", $oParams)
	_CDP_WaitForLoad($oSelf)

    Return $oSelf
EndFunc

Func _CDP_Page_Evaluate($oSelf, $expression)

	Local $evalObj = _CDP_Evaluate($oSelf, $expression)
	;_CDP_WaitForLoad()

    ; 2. Parse objectId
    Local $resultObj = _JsonC_ObjectObjectGet($evalObj, "result")
    Local $remoteObj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($remoteObj, "value")
    Local $valueObjVal = _JsonC_ObjectGetValue($valueObj)

    If $valueObjVal = "" Then Return 0
	return $valueObjVal

EndFunc

Func _CDP_Page_Url($oSelf)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("expression", "window.location.href")
    $oParams.Add("returnByValue", True)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.evaluate", $oParams)

    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $result2Obj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($result2Obj, "value")
    Local $valueVal = _JsonC_ObjectGetString($valueObj)

    Return $valueVal

EndFunc

Func _CDP_Page_Title($oSelf)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("expression", "document.title")
    $oParams.Add("returnByValue", True)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.evaluate", $oParams)

    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $result2Obj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($result2Obj, "value")
    Local $valueVal = _JsonC_ObjectGetString($valueObj)

    Return $valueVal

EndFunc

Func _CDP_Page_Content($self)
	; todo
EndFunc

Func _CDP_Page_ViewportSize($oSelf)

    Local $oParams = _CDP_NewParams()

    Local $resp = _CDP_SendSync($oSelf, "Page.getLayoutMetrics", $oParams)

    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $layoutViewportObj = _JsonC_ObjectObjectGet($resultObj, "layoutViewport")
    Local $clientWidthObj = _JsonC_ObjectObjectGet($layoutViewportObj, "clientWidth")
    Local $clientWidthVal = _JsonC_ObjectGetString($clientWidthObj)
    Local $clientHeightObj = _JsonC_ObjectObjectGet($layoutViewportObj, "clientHeight")
    Local $clientHeightVal = _JsonC_ObjectGetString($clientHeightObj)

    Local $a[2]
    $a[0] = $clientWidthVal
    $a[1] = $clientHeightVal
    Return $a

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


Func __CDP_Object_To_Node($oSelf)

	for $i = 1 to 2

		Local $oParams = _CDP_NewParams()
		$oParams.Add("objectId", $oSelf.objectId)
		Local $resp = _CDP_SendSync($oSelf, "DOM.requestNode", $oParams)

		Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
		Local $nodeIdObj = _JsonC_ObjectObjectGet($resultObj, "nodeId")
		Local $nodeIdVal = _JsonC_ObjectGetValue($nodeIdObj)

		if $nodeIdVal <> 0 Then Return $nodeIdVal

		Local $oParams = _CDP_NewParams()
		$oParams.Add("depth", -1)
		_CDP_SendSync($oSelf, "DOM.getDocument", $oParams)

	Next
EndFunc


Func _CDP_Page_Locator($oSelf, $selector)

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

		Local $resp = _CDP_Evaluate($oSelf, $expr)

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

			; Add action methods

			_AutoItObject_AddMethod($oLocator, "click", "_CDP_Locator_Click")										; partially done - Reqs CDP Commands DOM.getBoxModel, Input.dispatchMouseEvent, Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "dblClick", "_CDP_Locator_DoubleClick")								; todo - Reqs CDP Commands same as click (twice)
			_AutoItObject_AddMethod($oLocator, "hover", "_CDP_Locator_Hover")										; todo - Reqs CDP Commands DOM.getBoxModel, Input.dispatchMouseEvent
			_AutoItObject_AddMethod($oLocator, "tap", "_CDP_Locator_Tap")											; todo - Reqs CDP Commands Input.dispatchTouchEvent
			_AutoItObject_AddMethod($oLocator, "fill", "_CDP_Locator_Fill")											; done - Reqs CDP Commands DOM.focus, Input.insertText, Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "type", "_CDP_Locator_Type")											; todo - Reqs CDP Commands Input.dispatchKeyEvent
			_AutoItObject_AddMethod($oLocator, "press", "_CDP_Locator_Press")										; todo - Reqs CDP Commands Input.dispatchKeyEvent
			_AutoItObject_AddMethod($oLocator, "check", "_CDP_Locator_Check")										; todo - Reqs CDP Commands Runtime.callFunctionOn, Input.dispatchMouseEvent
			_AutoItObject_AddMethod($oLocator, "uncheck", "_CDP_Locator_Uncheck")									; todo - Reqs CDP Commands Runtime.callFunctionOn, Input.dispatchMouseEvent
			_AutoItObject_AddMethod($oLocator, "setChecked", "_CDP_Locator_SetChecked")								; todo - Reqs CDP Commands ?
			_AutoItObject_AddMethod($oLocator, "selectOption", "_CDP_Locator_SelectOption")							; todo - Reqs CDP Commands Runtime.callFunctionOn, DOM.dispatchEvent
			_AutoItObject_AddMethod($oLocator, "focus", "_CDP_Locator_Focus")										; todo - Reqs CDP Commands DOM.focus
			_AutoItObject_AddMethod($oLocator, "blur", "_CDP_Locator_Blur")											; todo - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "clear", "_CDP_Locator_Clear")										; todo - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "dragTo", "_CDP_Locator_DragTo")										; todo - Reqs CDP Commands DOM.getBoxModel, Input.dispatchMouseEvent
			_AutoItObject_AddMethod($oLocator, "setInputFiles", "_CDP_Locator_SetInputFiles")						; todo - Reqs CDP Commands DOM.setFileInputFiles
			_AutoItObject_AddMethod($oLocator, "dispatchEvent", "_CDP_Locator_DispatchEvent")						; todo - Reqs CDP Commands DOM.dispatchEvent
			_AutoItObject_AddMethod($oLocator, "scrollIntoViewIfNeeded", "_CDP_Locator_ScrollIntoViewIfNeeded")		; todo - Reqs CDP Commands DOM.scrollIntoViewIfNeeded, Runtime.callFunctionOn

			; Add getter methods

			_AutoItObject_AddMethod($oLocator, "textContent", "_CDP_Locator_TextContent")							; done - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "innerText", "_CDP_Locator_InnerText")								; done - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "innerTextCRStripped", "_CDP_Locator_InnerTextCRStripped")			; done - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "innerTextLFStripped", "_CDP_Locator_InnerTextLFStripped")			; done - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "innerTextReplace", "_CDP_Locator_InnerTextReplace")					; done - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "innerHTML", "_CDP_Locator_InnerHTML")								; done - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "inputValue", "_CDP_Locator_InputValue")								; done - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "getAttribute", "_CDP_Locator_GetAttribute")							; done - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "boundingBox", "_CDP_Locator_BoundingBox")							; todo - Reqs CDP Commands DOM.getBoxModel
			_AutoItObject_AddMethod($oLocator, "screenshot", "_CDP_Locator_Screenshot")								; todo - Reqs CDP Commands DOM.getBoxModel, Page.captureScreenshot
			_AutoItObject_AddMethod($oLocator, "evaluate", "_CDP_Locator_Evaluate")									; todo - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "evaluateAll", "_CDP_Locator_EvaluateAll")							; todo - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "elementHandle", "_CDP_Locator_ElementHandle")						; todo - Reqs CDP Commands DOM.resolveNode
			_AutoItObject_AddMethod($oLocator, "allInnerTexts", "_CDP_Locator_AllInnerTexts")						; todo - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "allTextContents", "_CDP_Locator_AllTextContents")					; todo - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "count", "_CDP_Locator_Count")										; todo - Reqs CDP Commands DOM.querySelectorAll

			; Add state methods

			_AutoItObject_AddMethod($oLocator, "isVisible", "_CDP_Locator_IsVisible")								; done - Reqs CDP Commands Runtime.callFunctionOn, DOM.getBoxModel
			_AutoItObject_AddMethod($oLocator, "isHidden", "_CDP_Locator_IsHidden")									; done - Reqs CDP Commands same as isVisible
			_AutoItObject_AddMethod($oLocator, "isEnabled", "_CDP_Locator_IsEnabled")								; done - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "isDisabled", "_CDP_Locator_IsDisabled")								; done - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "isEditable", "_CDP_Locator_IsEditable")								; done - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "isChecked", "_CDP_Locator_IsChecked")								; done - Reqs CDP Commands Runtime.callFunctionOn

			; Add waiting methods

			_AutoItObject_AddMethod($oLocator, "waitFor", "_CDP_Locator_WaitFor")									; todo - Reqs CDP Commands DOM.querySelector, Runtime.callFunctionOn, DOM.getBoxModel
			_AutoItObject_AddMethod($oLocator, "waitForElementState", "_CDP_Locator_WaitForElementState")			; todo - Reqs CDP Commands Runtime.callFunctionOn, DOM.getBoxModel
			_AutoItObject_AddMethod($oLocator, "waitForSelector", "_CDP_Locator_WaitForSelector")					; todo - Reqs CDP Commands DOM.querySelector, DOM.querySelectorAll

			; Add locator-creation methods

			_AutoItObject_AddMethod($oLocator, "locator", "_CDP_Locator_Locator")									; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "filter", "_CDP_Locator_Filter")										; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "nth", "_CDP_Locator_Nth")											; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "first", "_CDP_Locator_First")										; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "last", "_CDP_Locator_Last")											; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "getByRole", "_CDP_Locator_GetByRole")								; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "getByText", "_CDP_Locator_GetByText")								; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "getByLabel", "_CDP_Locator_GetByLabel")								; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "getByPlaceholder", "_CDP_Locator_GetByPlaceholder")					; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "getByAltText", "_CDP_Locator_GetByAltText")							; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "getByTitle", "_CDP_Locator_GetByTitle")								; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "getByTestId", "_CDP_Locator_GetByTestId")							; todo - Reqs CDP Commands No CDP — internal selector logic

			; Add properties

			_AutoItObject_AddProperty($oLocator, "type", $ELSCOPE_READONLY, $CDP_PAGE)
			_AutoItObject_AddProperty($oLocator, "objectId", $ELSCOPE_PUBLIC, $objectIdVal)
			_AutoItObject_AddProperty($oLocator, "nodeId", $ELSCOPE_PUBLIC, Null)
			_AutoItObject_AddProperty($oLocator, "value", $ELSCOPE_PUBLIC, "")
			_AutoItObject_AddProperty($oLocator, "wsHandle", $ELSCOPE_PUBLIC, $oSelf.wsHandle)
			_AutoItObject_AddProperty($oLocator, "sessionId", $ELSCOPE_PUBLIC, $oSelf.sessionId)

			Return $oLocator
		EndIf

		;ConsoleWrite("Retrying locator." & @CRLF)
        Sleep(1)
    WEnd

	ConsoleWrite("Timed out." & @CRLF)
	Exit

EndFunc

Func _CDP_Page_LocatorNow($oSelf, $selector)

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

	Local $resp = _CDP_Evaluate($oSelf, $expr)

	; Parse objectId
	Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
	Local $remoteObj = _JsonC_ObjectObjectGet($resultObj, "result")
	Local $objectIdObj = _JsonC_ObjectObjectGet($remoteObj, "objectId")

	if @error <> 0 Then Return Null

	Local $objectIdVal = _JsonC_ObjectGetValue($objectIdObj)

	; Create the Locator object

	Local $oLocator = _AutoItObject_Create()
	Local $oExpect = _AutoItObject_Create()

	; Add action methods

	_AutoItObject_AddMethod($oLocator, "click", "_CDP_Locator_Click")
	_AutoItObject_AddMethod($oLocator, "dblClick", "_CDP_Locator_DoubleClick")
	_AutoItObject_AddMethod($oLocator, "hover", "_CDP_Locator_Hover")
	_AutoItObject_AddMethod($oLocator, "tap", "_CDP_Locator_Tap")
	_AutoItObject_AddMethod($oLocator, "fill", "_CDP_Locator_Fill")
	_AutoItObject_AddMethod($oLocator, "type", "_CDP_Locator_Type")
	_AutoItObject_AddMethod($oLocator, "press", "_CDP_Locator_Press")
	_AutoItObject_AddMethod($oLocator, "check", "_CDP_Locator_Check")
	_AutoItObject_AddMethod($oLocator, "uncheck", "_CDP_Locator_Uncheck")
	_AutoItObject_AddMethod($oLocator, "setChecked", "_CDP_Locator_SetChecked")
	_AutoItObject_AddMethod($oLocator, "selectOption", "_CDP_Locator_SelectOption")
	_AutoItObject_AddMethod($oLocator, "focus", "_CDP_Locator_Focus")
	_AutoItObject_AddMethod($oLocator, "blur", "_CDP_Locator_Blur")
	_AutoItObject_AddMethod($oLocator, "clear", "_CDP_Locator_Clear")
	_AutoItObject_AddMethod($oLocator, "dragTo", "_CDP_Locator_DragTo")
	_AutoItObject_AddMethod($oLocator, "setInputFiles", "_CDP_Locator_SetInputFiles")
	_AutoItObject_AddMethod($oLocator, "dispatchEvent", "_CDP_Locator_DispatchEvent")
	_AutoItObject_AddMethod($oLocator, "scrollIntoViewIfNeeded", "_CDP_Locator_ScrollIntoViewIfNeeded")

	; Add getter methods

	_AutoItObject_AddMethod($oLocator, "textContent", "_CDP_Locator_TextContent")
	_AutoItObject_AddMethod($oLocator, "innerText", "_CDP_Locator_InnerText")
	_AutoItObject_AddMethod($oLocator, "innerTextCRStripped", "_CDP_Locator_InnerTextCRStripped")
	_AutoItObject_AddMethod($oLocator, "innerTextLFStripped", "_CDP_Locator_InnerTextLFStripped")
	_AutoItObject_AddMethod($oLocator, "innerTextReplace", "_CDP_Locator_InnerTextReplace")
	_AutoItObject_AddMethod($oLocator, "innerHTML", "_CDP_Locator_InnerHTML")
	_AutoItObject_AddMethod($oLocator, "inputValue", "_CDP_Locator_InputValue")
	_AutoItObject_AddMethod($oLocator, "getAttribute", "_CDP_Locator_GetAttribute")
	_AutoItObject_AddMethod($oLocator, "boundingBox", "_CDP_Locator_BoundingBox")
	_AutoItObject_AddMethod($oLocator, "screenshot", "_CDP_Locator_Screenshot")
	_AutoItObject_AddMethod($oLocator, "evaluate", "_CDP_Locator_Evaluate")
	_AutoItObject_AddMethod($oLocator, "evaluateAll", "_CDP_Locator_EvaluateAll")
	_AutoItObject_AddMethod($oLocator, "elementHandle", "_CDP_Locator_ElementHandle")
	_AutoItObject_AddMethod($oLocator, "allInnerTexts", "_CDP_Locator_AllInnerTexts")
	_AutoItObject_AddMethod($oLocator, "allTextContents", "_CDP_Locator_AllTextContents")
	_AutoItObject_AddMethod($oLocator, "count", "_CDP_Locator_Count")

	; Add state methods

	_AutoItObject_AddMethod($oLocator, "isVisible", "_CDP_Locator_IsVisible")
	_AutoItObject_AddMethod($oLocator, "isHidden", "_CDP_Locator_IsHidden")
	_AutoItObject_AddMethod($oLocator, "isEnabled", "_CDP_Locator_IsEnabled")
	_AutoItObject_AddMethod($oLocator, "isDisabled", "_CDP_Locator_IsDisabled")
	_AutoItObject_AddMethod($oLocator, "isEditable", "_CDP_Locator_IsEditable")
	_AutoItObject_AddMethod($oLocator, "isChecked", "_CDP_Locator_IsChecked")

	; Add waiting methods

	_AutoItObject_AddMethod($oLocator, "waitFor", "_CDP_Locator_WaitFor")
	_AutoItObject_AddMethod($oLocator, "waitForElementState", "_CDP_Locator_WaitForElementState")
	_AutoItObject_AddMethod($oLocator, "waitForSelector", "_CDP_Locator_WaitForSelector")

	; Add locator-creation methods

	_AutoItObject_AddMethod($oLocator, "locator", "_CDP_Locator_Locator")
	_AutoItObject_AddMethod($oLocator, "filter", "_CDP_Locator_Filter")
	_AutoItObject_AddMethod($oLocator, "nth", "_CDP_Locator_Nth")
	_AutoItObject_AddMethod($oLocator, "first", "_CDP_Locator_First")
	_AutoItObject_AddMethod($oLocator, "last", "_CDP_Locator_Last")
	_AutoItObject_AddMethod($oLocator, "getByRole", "_CDP_Locator_GetByRole")
	_AutoItObject_AddMethod($oLocator, "getByText", "_CDP_Locator_GetByText")
	_AutoItObject_AddMethod($oLocator, "getByLabel", "_CDP_Locator_GetByLabel")
	_AutoItObject_AddMethod($oLocator, "getByPlaceholder", "_CDP_Locator_GetByPlaceholder")
	_AutoItObject_AddMethod($oLocator, "getByAltText", "_CDP_Locator_GetByAltText")
	_AutoItObject_AddMethod($oLocator, "getByTitle", "_CDP_Locator_GetByTitle")
	_AutoItObject_AddMethod($oLocator, "getByTestId", "_CDP_Locator_GetByTestId")

	; Add properties

	_AutoItObject_AddProperty($oLocator, "objectId", $ELSCOPE_PUBLIC, $objectIdVal)
	_AutoItObject_AddProperty($oLocator, "value", $ELSCOPE_PUBLIC, "")

	Return $oLocator

EndFunc

#endregion

#region --- Locator Class ---

Func _CDP_Locator_Click($oSelf, $waitForLoad = False)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $oSelf.objectId)
    $oParams.Add("functionDeclaration", "function() { this.click(); }")
    $oParams.Add("awaitPromise", False)

    _CDP_SendCommand($oSelf, "Runtime.callFunctionOn", $oParams)

	if $waitForLoad = True Then _CDP_WaitForLoad($oSelf)

EndFunc

Func _CDP_Locator_DoubleClick($self, $waitForLoad = False)
	; Todo
EndFunc

Func _CDP_Locator_Hover($self)
	; Todo
EndFunc

Func _CDP_Locator_Tap($self)
	; Todo
EndFunc

Func _CDP_Locator_Fill($oSelf, $value)

	Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $oSelf.objectId)
    $oParams.Add("functionDeclaration", "function(value) { this.value = value; this.dispatchEvent(new Event('input', { bubbles: true })); this.dispatchEvent(new Event('change', { bubbles: true })); }")
    $oParams.Add("arguments", '[{"value":"' & $value & '"}]')

    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", $oParams)

EndFunc

Func _CDP_Locator_Type($self)
	; Todo
EndFunc

Func _CDP_Locator_Press($self)
	; Todo
EndFunc

Func _CDP_Locator_Check($self)
	; Todo
EndFunc

Func _CDP_Locator_Uncheck($self)
	; Todo
EndFunc

Func _CDP_Locator_SetChecked($self)
	; Todo
EndFunc

Func _CDP_Locator_SelectOption($self)
	; Todo
EndFunc

Func _CDP_Locator_Focus($self)
	; Todo
EndFunc

Func _CDP_Locator_Blur($self)
	; Todo
EndFunc

Func _CDP_Locator_Clear($self)
	; Todo
EndFunc

Func _CDP_Locator_DragTo($self)
	; Todo
EndFunc

Func _CDP_Locator_SetInputFiles($self)
	; Todo
EndFunc

Func _CDP_Locator_DispatchEvent($self)
	; Todo
EndFunc

Func _CDP_Locator_ScrollIntoViewIfNeeded($self)
	; Todo
EndFunc

Func _CDP_Locator_TextContent($oSelf)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $oSelf.objectId)
    $oParams.Add("functionDeclaration", "function() { return this.textContent; }")
    $oParams.Add("returnByValue", True)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", $oParams)

    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $result2Obj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($result2Obj, "value")
    Local $valueVal = _JsonC_ObjectGetString($valueObj)

    Return $valueVal

EndFunc


Func _CDP_Locator_InnerText($oSelf)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $oSelf.objectId)
    $oParams.Add("functionDeclaration", "function() { return this.innerText; }")
    $oParams.Add("returnByValue", True)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", $oParams)

    ; Extract the "result.value"
    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $result2Obj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($result2Obj, "value")
    Local $valueVal = _JsonC_ObjectGetValue($valueObj)

	$oSelf.value = $valueVal

	Return $valueVal
EndFunc

Func _CDP_Locator_InnerTextCRStripped($self)
	$text = _CDP_Locator_InnerText($self)
	Return StringStripCR($text)
EndFunc

Func _CDP_Locator_InnerTextLFStripped($self)
	$text = _CDP_Locator_InnerText($self)
	Return StringReplace($text, @LF, "")
EndFunc

Func _CDP_Locator_InnerTextReplace($self, $searchString, $replaceString)
	$text = _CDP_Locator_InnerText($self)
	Return StringReplace($text, $searchString, $replaceString)
EndFunc

Func _CDP_Locator_InnerHTML($oSelf)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $oSelf.objectId)
    $oParams.Add("functionDeclaration", "function() { return this.innerHTML; }")
    $oParams.Add("returnByValue", True)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", $oParams)

    ; Extract the "result.value"
    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $result2Obj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($result2Obj, "value")
    Local $valueVal = _JsonC_ObjectGetValue($valueObj)

	Return $valueVal

EndFunc

Func _CDP_Locator_InputValue($oSelf)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $oSelf.objectId)
    $oParams.Add("functionDeclaration", "function() { return this.value; }")
    $oParams.Add("returnByValue", True)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", $oParams)

    ; Extract the "result.value"
    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $result2Obj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($result2Obj, "value")
    Local $valueVal = _JsonC_ObjectGetValue($valueObj)

	Return $valueVal
EndFunc

Func _CDP_Locator_GetAttribute($oSelf, $name)

    Local $oParams = _CDP_NewParams()
	$oSelf.nodeId = __CDP_Object_To_Node($oSelf)
    $oParams.Add("nodeId", $oSelf.nodeId)

    Local $resp = _CDP_SendSync($oSelf, "DOM.getAttributes", $oParams)
    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $attributesObj = _JsonC_ObjectObjectGet($resultObj, "attributes")

	Local $getNextAttribute = False
	$attributes = _JsonC_ObjectArrayGetObjects($attributesObj)
	For $attribute in $attributes
		$attributeVal = _JsonC_ObjectGetValue($attribute)
		;if $getNextAttribute = True Then Return ValueObj($attributeVal)
		if $getNextAttribute = True Then Return $attributeVal
		if $attributeVal = $name Then $getNextAttribute = True
	Next

	Return Null
EndFunc

Func _CDP_Locator_BoundingBox($self)
	; Todo
EndFunc

Func _CDP_Locator_Screenshot($self)
	; Todo
EndFunc

Func _CDP_Locator_Evaluate($self)
	; Todo
EndFunc

Func _CDP_Locator_EvaluateAll($self)
	; Todo
EndFunc

Func _CDP_Locator_ElementHandle($self)
	; Todo
EndFunc

Func _CDP_Locator_AllInnerTexts($self)
	; Todo
EndFunc

Func _CDP_Locator_AllTextContents($self)
	; Todo
EndFunc

Func _CDP_Locator_Count($self)
	; Todo
EndFunc

Func __CDP_Locator_IsVisibleValue($oSelf)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $oSelf.objectId)
    $oParams.Add("functionDeclaration", "function() { const r = this.getBoundingClientRect(); return !!(r.width && r.height); }")
    $oParams.Add("returnByValue", True)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", $oParams)

    ; Extract the "result.value"
    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $result2Obj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($result2Obj, "value")
    Return _JsonC_ObjectGetValue($valueObj)

EndFunc

Func _CDP_Locator_IsVisible($oSelf)
	$val = __CDP_Locator_IsVisibleValue($oSelf) <> 0
	Return $val
EndFunc

Func _CDP_Locator_IsHidden($oSelf)
	$val = Not ( __CDP_Locator_IsVisibleValue($oSelf) <> 0 )
	Return $val
EndFunc

Func __CDP_Locator_IsDisabledValue($oSelf)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $oSelf.objectId)
    $oParams.Add("functionDeclaration", "function() { return this.disabled; }")
    $oParams.Add("returnByValue", True)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", $oParams)

    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $result2Obj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($result2Obj, "value")

	; Convert numeric 0/1 → AutoIt boolean
    Return (_JsonC_ObjectGetBoolean($valueObj) <> 0)

EndFunc

Func _CDP_Locator_IsEnabled($oSelf)
	Return Not __CDP_Locator_IsDisabledValue($oSelf)
EndFunc

Func _CDP_Locator_IsDisabled($oSelf)
	Return __CDP_Locator_IsDisabledValue($oSelf)
EndFunc

Func _CDP_Locator_IsEditable($oSelf)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $oSelf.objectId)

    ; Playwright-equivalent logic:
    ; editable = !disabled && !readOnly
    $oParams.Add("functionDeclaration", "function() { return !this.disabled && !this.readOnly; }")
    $oParams.Add("returnByValue", True)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", $oParams)

    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $result2Obj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($result2Obj, "value")

    ; Convert numeric 0/1 → AutoIt boolean
    Return (_JsonC_ObjectGetBoolean($valueObj) <> 0)

EndFunc

Func _CDP_Locator_IsChecked($oSelf)

    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $oSelf.objectId)
    $oParams.Add("functionDeclaration", "function() { return this.checked; }")
    $oParams.Add("returnByValue", True)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", $oParams)

    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $result2Obj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $valueObj = _JsonC_ObjectObjectGet($result2Obj, "value")

	; Convert numeric 0/1 → AutoIt boolean
    Return (_JsonC_ObjectGetBoolean($valueObj) <> 0)

EndFunc

Func _CDP_Locator_WaitFor($self)
	; Todo
EndFunc

Func _CDP_Locator_WaitForElementState($self)
	; Todo
EndFunc

Func _CDP_Locator_WaitForSelector($self)
	; Todo
EndFunc

Func _CDP_Locator_Locator($self)
	; Todo
EndFunc

Func _CDP_Locator_Filter($self)
	; Todo
EndFunc

Func _CDP_Locator_Nth($self)
	; Todo
EndFunc

Func _CDP_Locator_First($self)
	; Todo
EndFunc

Func _CDP_Locator_Last($self)
	; Todo
EndFunc

Func _CDP_Locator_GetByRole($self)
	; Todo
EndFunc

Func _CDP_Locator_GetByText($self)
	; Todo
EndFunc

Func _CDP_Locator_GetByLabel($self)
	; Todo
EndFunc

Func _CDP_Locator_GetByPlaceholder($self)
	; Todo
EndFunc

Func _CDP_Locator_GetByAltText($self)
	; Todo
EndFunc

Func _CDP_Locator_GetByTitle($self)
	; Todo
EndFunc

Func _CDP_Locator_GetByTestId($self)
	; Todo
EndFunc


#endregion


#region --- Test Class ---

Func _CDP_Test($self, $text)
    __CDP_ConsoleWriteUTF8("▶ Test: " & $text & @CRLF)
	$cdp.state.indentLevel = $cdp.state.indentLevel + 1
	Return $self
EndFunc

Func test($text)

    __CDP_ConsoleWriteUTF8("▶ Test: " & $text & @CRLF)
	$cdp.state.indentLevel = $cdp.state.indentLevel + 1

	Local $test = _AutoItObject_Create()
	;_AutoItObject_AddProperty($test, "text", $ELSCOPE_READONLY, $text)
	_AutoItObject_AddDestructor($test, "_CDP_Test_End")
	Return $test

EndFunc

Func teststep($text)

	__CDP_ConsoleWriteUTF8(_StringRepeat("  ", $cdp.state.indentLevel) & "▶ Step: " & $text & @CRLF)
	$cdp.state.indentLevel = $cdp.state.indentLevel + 1

	Local $teststep = _AutoItObject_Create()
	;_AutoItObject_AddProperty($teststep, "text", $ELSCOPE_READONLY, $text)
	_AutoItObject_AddMethod($teststep, "expect", "_CDP_Test_Step_Expect")
	_AutoItObject_AddDestructor($teststep, "_CDP_Test_Step_End")
	Return $teststep

EndFunc

Func _CDP_Test_Step_End($self)
	$cdp.state.indentLevel = $cdp.state.indentLevel - 1
EndFunc

Func _CDP_Test_End($self)
	$cdp.state.indentLevel = $cdp.state.indentLevel - 1
EndFunc

Func _CDP_Test_Step_Expect($self, $subject)
    Local $obj = _AutoItObject_Create()
    _AutoItObject_AddProperty($obj, "parent", $ELSCOPE_PUBLIC, $self)
    _AutoItObject_AddProperty($obj, "subject", $ELSCOPE_PUBLIC, $subject)

	; Add locator-based expect methods

    _AutoItObject_AddMethod($obj, "toBeVisible", "_CDP_Expect_Locator_ToBeVisible")							; done - Uses isVisible()
    _AutoItObject_AddMethod($obj, "toBeHidden", "_CDP_Expect_Locator_ToBeHidden")							; done - Uses isHidden()
    _AutoItObject_AddMethod($obj, "toBeEnabled", "_CDP_Expect_Locator_ToBeEnabled")							; done - Uses isEnabled()
    _AutoItObject_AddMethod($obj, "toBeDisabled", "_CDP_Expect_Locator_ToBeDisabled")						; done - Uses isDisabled()
    _AutoItObject_AddMethod($obj, "toBeChecked", "_CDP_Expect_Locator_ToBeChecked")							; done - Uses isChecked()
    _AutoItObject_AddMethod($obj, "toHaveText", "_CDP_Expect_Locator_ToHaveText")							; done - Uses textContent()
    _AutoItObject_AddMethod($obj, "toContainText", "_CDP_Expect_Locator_ToContainText")						; done - Uses textContent()
    _AutoItObject_AddMethod($obj, "toHaveAttribute", "_CDP_Expect_Locator_ToHaveAttribute")					; done - Uses getAttribute()
    _AutoItObject_AddMethod($obj, "toHaveClass", "_CDP_Expect_Locator_ToHaveClass")							; todo
    _AutoItObject_AddMethod($obj, "toHaveCount", "_CDP_Expect_Locator_ToHaveCount")							; todo - Uses DOM.querySelectorAll
    _AutoItObject_AddMethod($obj, "toHaveValue", "_CDP_Expect_Locator_ToHaveValue")							; todo
    _AutoItObject_AddMethod($obj, "toHaveJSProperty", "_CDP_Expect_Locator_ToHaveJSProperty")				; todo

	; Add value-based expect methods

	_AutoItObject_AddMethod($obj, "toBe", "_CDP_Expect_Value_ToBe")											; done
	_AutoItObject_AddMethod($obj, "toEqual", "_CDP_Expect_Value_ToEqual")									; todo
	_AutoItObject_AddMethod($obj, "toStrictEqual", "_CDP_Expect_Value_ToStrictEqual")						; todo
	_AutoItObject_AddMethod($obj, "toBeGreaterThan", "_CDP_Expect_Value_ToBeGreaterThan")					; done
	_AutoItObject_AddMethod($obj, "toBeGreaterThanOrEqual", "_CDP_Expect_Value_ToBeGreaterThanOrEqual")		; done
	_AutoItObject_AddMethod($obj, "toBeLessThan", "_CDP_Expect_Value_ToBeLessThan")							; done
	_AutoItObject_AddMethod($obj, "toBeLessThanOrEqual", "_CDP_Expect_Value_ToBeLessThanOrEqual")			; done
	_AutoItObject_AddMethod($obj, "toBeCloseTo", "_CDP_Expect_Value_ToBeCloseTo")							; done - untested
    _AutoItObject_AddMethod($obj, "toContain", "_CDP_Expect_Value_ToContain")								; done
	_AutoItObject_AddMethod($obj, "toMatch", "_CDP_Expect_Value_ToMatch")									; done
	_AutoItObject_AddMethod($obj, "toBeTruthy", "_CDP_Expect_Value_ToBeTruthy")								; done
	_AutoItObject_AddMethod($obj, "toBeFalsy", "_CDP_Expect_Value_ToBeFalsy")								; done
	_AutoItObject_AddMethod($obj, "toBeNull", "_CDP_Expect_Value_ToBeNull")									; done
	_AutoItObject_AddMethod($obj, "toBeDefined", "_CDP_Expect_Value_ToBeDefined")							; done
	_AutoItObject_AddMethod($obj, "toBeUndefined", "_CDP_Expect_Value_ToBeUndefined")						; done - untested
	_AutoItObject_AddMethod($obj, "toContainEqual", "_CDP_Expect_Value_ToContainEqual")						; todo
	_AutoItObject_AddMethod($obj, "toHaveLength", "_CDP_Expect_Value_ToHaveLength")							; done
	_AutoItObject_AddMethod($obj, "toThrow", "_CDP_Expect_Value_ToThrow")									; todo

    ; add more assertion methods here
    Return $obj
EndFunc


Func _CDP_Test_Step_Expect_Msg($indent, $pass, $text, $lineNumber = "")
	$result = "✓"
	if $pass = False Then $result = "✗"
	if $lineNumber <> "" Then $lineNumber = " (line " & $lineNumber & ")"

    __CDP_ConsoleWriteUTF8($indent & $result & " Expect: " & $text & $lineNumber & @CRLF)
EndFunc


Func _CDP_Expect_Locator_ToBeVisible($self, $scriptLineNumber = "")

	if _CDP_Locator_IsVisible($self.subject) = True Then
		_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), True, "object [" & $self.subject.objectId & "] is visible", $scriptLineNumber)
		Return True
    EndIf

	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), False, "object [" & $self.subject.objectId & "] is not visible", $scriptLineNumber)
    Return False

EndFunc

Func _CDP_Expect_Locator_ToBeHidden($self, $scriptLineNumber = "")

	if _CDP_Locator_IsHidden($self.subject) = True Then
		_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), True, "object [" & $self.subject.objectId & "] is hidden", $scriptLineNumber)
		Return True
    EndIf

	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), False, "object [" & $self.subject.objectId & "] is not hidden", $scriptLineNumber)
    Return False

EndFunc

Func _CDP_Expect_Locator_ToBeEnabled($self, $scriptLineNumber = "")

	if _CDP_Locator_IsEnabled($self.subject) = True Then
		_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), True, "object [" & $self.subject.objectId & "] is enabled", $scriptLineNumber)
		Return True
    EndIf

	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), False, "object [" & $self.subject.objectId & "] is not enabled", $scriptLineNumber)
    Return False

EndFunc

Func _CDP_Expect_Locator_ToBeDisabled($self, $scriptLineNumber = "")

	if _CDP_Locator_IsDisabled($self.subject) = True Then
		_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), True, "object [" & $self.subject.objectId & "] is disabled", $scriptLineNumber)
		Return True
    EndIf

	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), False, "object [" & $self.subject.objectId & "] is not disabled", $scriptLineNumber)
    Return False

EndFunc

Func _CDP_Expect_Locator_ToBeChecked($self, $scriptLineNumber = "")

	if _CDP_Locator_IsChecked($self.subject) = True Then
		_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), True, "object [" & $self.subject.objectId & "] is checked", $scriptLineNumber)
		Return True
    EndIf

	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), False, "object [" & $self.subject.objectId & "] is not checked", $scriptLineNumber)
    Return False

EndFunc

Func _CDP_Expect_Locator_ToHaveText($self, $expected, $scriptLineNumber = "")

	Local $actual = _CDP_Locator_TextContent($self.subject)

	If $actual = $expected Then
		_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), True, "expected [" & $expected & "] and got [" & $actual & "]", $scriptLineNumber)
		Return True
    EndIf

	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), False, "expected [" & $expected & "] but got [" & $actual & "]", $scriptLineNumber)
    Return False
EndFunc

Func _CDP_Expect_Locator_ToContainText($self, $expected, $scriptLineNumber = "")

	Local $actual = _CDP_Locator_TextContent($self.subject)

	If StringInStr($actual, $expected) > 0 Then
		_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), True, "actual text contains [" & $expected & "]", $scriptLineNumber)
        Return True
    EndIf

	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), False, "expected actual text to contain [" & $expected & "] but got [" & $actual & "]", $scriptLineNumber)
    Return False
EndFunc

Func _CDP_Expect_Locator_ToHaveAttribute($self, $name, $expectedValue, $scriptLineNumber = "")

	Local $actualValue = _CDP_Locator_GetAttribute($self.subject, $name)

	If $actualValue = $expectedValue Then
		_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), True, "actual object contains attribute [" & $name & "] with value [" & $expectedValue & "]", $scriptLineNumber)
        Return True
    EndIf

	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), False, "actual object does not contain attribute [" & $name & "] with value [" & $expectedValue & "]", $scriptLineNumber)
    Return False
EndFunc

Func _CDP_Expect_Locator_ToHaveValue($self, $expected, $scriptLineNumber = "")
	; todo
EndFunc

Func _CDP_Expect_Locator_ToHaveCount($self, $expected, $scriptLineNumber = "")
	; todo
EndFunc

Func _CDP_Expect_Value_ToBe($self, $expected, $line = "")
    Local $actual = $self.subject
    Local $pass = ($actual = $expected)
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), $pass, "expected [" & $expected & "] and got [" & $actual & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToEqual($self, $expected, $scriptLineNumber = "")

	; todo

	;	AutoIt has no deep‑equal, so we should serialize to JSON. for example ...
	;Local $actual = $self.subject
    ;Local $a = Json_Encode($actual)
    ;Local $b = Json_Encode($expected)
    ;Local $pass = ($a = $b)
EndFunc

Func _CDP_Expect_Value_ToStrictEqual($self, $expected, $scriptLineNumber = "")
	; todo - same as _CDP_Expect_Value_ToEqual above
EndFunc

Func _CDP_Expect_Value_ToBeGreaterThan($self, $expected, $line = "")
    Local $actual = $self.subject
    Local $pass = (Number($actual) > Number($expected))
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), $pass, "expected [" & $actual & "] to be greater than [" & $expected & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeGreaterThanOrEqual($self, $expected, $line = "")
    Local $actual = $self.subject
    Local $pass = (Number($actual) >= Number($expected))
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), $pass, "expected [" & $actual & "] to be greater than or equal to [" & $expected & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeLessThan($self, $expected, $line = "")
    Local $actual = $self.subject
    Local $pass = (Number($actual) < Number($expected))
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), $pass, "expected [" & $actual & "] to be less than [" & $expected & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeLessThanOrEqual($self, $expected, $line = "")
    Local $actual = $self.subject
    Local $pass = (Number($actual) <= Number($expected))
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), $pass, "expected [" & $actual & "] to be less than or equal to [" & $expected & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeCloseTo($self, $expected, $precision = 2, $line = "")
    Local $actual = $self.subject
    Local $delta = Abs($actual - $expected)
    Local $pass = ($delta <= (10 ^ -$precision))
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), $pass, "expected close to [" & $expected & "] but got [" & $actual & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToContain($self, $expected, $line = "")
    Local $actual = $self.subject
    Local $pass = False

    If IsString($actual) Then
        $pass = StringInStr($actual, $expected) > 0
    ElseIf IsArray($actual) Then
        For $i = 0 To UBound($actual) - 1
            If $actual[$i] = $expected Then
                $pass = True
                ExitLoop
            EndIf
        Next
    EndIf

    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), $pass, "expected [" & $actual & "] to contain [" & $expected & "]", $line)

    Return $pass
EndFunc

Func _CDP_Expect_Value_ToMatch($self, $pattern, $line = "")
    Local $actual = $self.subject
    Local $pass = StringRegExp($actual, $pattern)
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), $pass, "expected [" & $actual & "] to match regex [" & $pattern & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeTruthy($self, $line = "")
    Local $actual = $self.subject
    ; AutoIt truthiness: anything non-zero is True
    Local $pass = ($actual <> 0)
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), $pass, "expected truthy and got [" & $actual & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeFalsy($self, $line = "")
    Local $actual = $self.subject
    ; AutoIt falsiness: only 0 is False
    Local $pass = ($actual = 0)
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), $pass, "expected falsy and got [" & $actual & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeNull($self, $line = "")
    Local $actual = $self.subject
    Local $pass = ($actual = Null)
	if $actual = Null then $actual = "Null"
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), $pass, "expected Null and got [" & $actual & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeDefined($self, $line = "?")
    Local $actual = $self.subject
    Local $pass = Not ($actual = Default)
	$actual = "defined"
	if $pass = False then $actual = "undefined"
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), $pass, "expected defined value and got [" & $actual & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeUndefined($self, $line = "?")
    Local $actual = $self.subject
    Local $pass = ($actual = Default)
	$actual = "undefined"
	if $pass = False then $actual = "defined"
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), $pass, "expected undefined value and got [" & $actual & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToContainEqual($self, $expected, $scriptLineNumber = "")

	; todo
	#cs
    Local $actual = $self.subject
    Local $pass = False

    If IsArray($actual) Then
        Local $expectedJson = Json_Encode($expected)
        For $i = 0 To UBound($actual) - 1
            If Json_Encode($actual[$i]) = $expectedJson Then
                $pass = True
                ExitLoop
            EndIf
        Next
    EndIf

    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), $pass, "expected array to contain deep-equal [" & Json_Encode($expected) & "]", $line)

    Return $pass
	#ce
EndFunc

Func _CDP_Expect_Value_ToHaveLength($self, $expected, $line = "")
    Local $actual = $self.subject
    Local $len = 0

    If IsString($actual) Then
        $len = StringLen($actual)
    ElseIf IsArray($actual) Then
        $len = UBound($actual)
    EndIf

    Local $pass = ($len = $expected)
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), $pass, "expected length [" & $expected & "] and got [" & $len & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToThrow($self, $expected, $scriptLineNumber = "")

	; todo

	#cs
    Local $fn = $self.subject
    Local $pass = False

    If IsFunc($fn) Then
        Local $err = 0
        Local $result = ""
        $result = Execute("TryReturn(" & $fn & "())")
        $err = @error
        $pass = ($err <> 0)
    EndIf

    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel + 1), $pass, _
        "expected function to throw", $line)

    Return $pass
	#ce

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

Func __CDP_ConsoleWriteUTF8($sText)
	; ChrW(0x200B) enforces unicode fallback fonts in windows console
    ConsoleWrite(BinaryToString(StringToBinary(ChrW(0x200B) & $sText, 4), 1))
EndFunc

Func ErrFunc($oError)
	ConsoleWrite("!>COM Error !"&@CRLF&"!>"&@TAB&"Number: "&Hex($oError.Number,8)&@CRLF&"!>"&@TAB&"Windescription: "&StringRegExpReplace($oError.windescription,"\R$","")&@CRLF&"!>"&@TAB&"Source: "&$oError.source&@CRLF&"!>"&@TAB&"Description: "&$oError.description&@CRLF&"!>"&@TAB&"Helpfile: "&$oError.helpfile&@CRLF&"!>"&@TAB&"Helpcontext: "&$oError.helpcontext&@CRLF&"!>"&@TAB&"Lastdllerror: "&$oError.lastdllerror&@CRLF&"!>"&@TAB&"Scriptline: "&$oError.scriptline&@CRLF)
EndFunc   ;==>ErrFunc

#endregion

