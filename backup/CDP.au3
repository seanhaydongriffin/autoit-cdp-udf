#AutoIt3Wrapper_UseX64=y
#include-once

; ======================================================================================================================
;   AutoIt CDP UDF
;   Direct Chrome DevTools Protocol automation for AutoIt
; ======================================================================================================================

#region --- Core Includes & Globals ---

#include "CurlEx.au3"
#include "JsonC.au3"
#include "AutoItObject.au3"

Global $hActiveBrowserWs
Global $hActivePageWs
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
Local $cdp = _AutoItObject_Create()
_AutoItObject_AddMethod($cdp, "launchBrowser", "_CDP_Browser_Launch")

#endregion

#region --- CDP Transport Layer (low-level) ---
; _CDP_Connect()
; _CDP_SendCommand()
; _CDP_SendSync()
; _CDP_RecvLoop()
; _CDP_NewParams()


#cs
Func _CDP_Connect($sHost, $iPort, $sPath)

    Local $url = "ws://" & $sHost & ":" & $iPort & $sPath

	$hCurl = Curl_Easy_Init()
	Curl_Easy_Setopt($hCurl, $CURLOPT_URL, $url)
	Curl_Setopt_Websocket($hCurl)
	Curl_Easy_Perform($hCurl)

EndFunc
#ce


Func _CDP_Connect($iUrl)

	Local $hCurl = Curl_Easy_Init()
	Curl_Easy_Setopt($hCurl, $CURLOPT_URL, $iUrl)
	Curl_Setopt_Websocket($hCurl)
	Curl_Easy_Perform($hCurl)
	Return $hCurl

EndFunc



#cs
Func __CDP_Send($sJson)
    Local $rc = Curl_Ws_Send($hCurl, $sJson)

    If @extended = 0 Or $rc <> 0 Then
        ; @extended = bytes sent
        ; rc = CURLcode
        Return SetError(1, $rc, False)
    EndIf

    Return True
EndFunc
#ce

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

	; 1. Send command → get ID
    Local $id = _CDP_SendCommand($method, $params)

    ; 2. Mark this ID as pending
    ;$g_CDP_Pending($id) = Null

    ; 3. Wait for response
    Local $t = TimerInit()
    While TimerDiff($t) < $timeout
		If $g_CDP_Pending.Exists($id) Then
            Local $resp = $g_CDP_Pending($id)
            ;$g_CDP_Pending.Remove($id)
            Return $resp
        EndIf
        Sleep(1)
    WEnd

    Return SetError(1, 0, Null)
EndFunc



Func _CDP_RecvLoop()


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
; Browser_Launch()
; _CDP_Browser_NewPage()
; Browser_Close()







Func _CDP_Browser_Launch($oSelf, $port = 9222, $startupSwitches = "--no-first-run --no-default-browser-check", $profile = @TempDir & "\ChromeDebug", $deleteSessions = True, $path = @ProgramFilesDir & "\Google\Chrome\Application\chrome.exe")

	if $deleteSessions = True Then DirRemove($profile & "\Default\Sessions", 1)

	Local $cmd = '"' & $path & '" --remote-debugging-port=' & $port & ' --user-data-dir="' & $profile & '" ' & $startupSwitches ; & ' chrome://newtab'
	ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $cmd = ' & $cmd & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
    Run($cmd)
    Sleep(500) ; give Chrome time to start

	; Get the browser level websocket

	Local $resp = Curl_Get("http://localhost:" & $port & "/json/version")
	Local $pattern = '(?s)"webSocketDebuggerUrl"\s*:\s*"([^"]+)"'
	Local $matches = StringRegExp($resp, $pattern, 1)

	If @error Then
		ConsoleWrite("No browser WebSocket found" & @CRLF)
		Return
	EndIf

	Local $browserWsUrl = $matches[0]
	ConsoleWrite("Browser WebSocket URL: " & $browserWsUrl & @CRLF)

	; Connect to the browser level websocket

	$hActiveBrowserWs = _CDP_Connect($browserWsUrl)


	#cs
    Local $wsObj = _JsonC_TokenerParse($resp)
    Local $arrayObj = _JsonC_ObjectObjectGet($wsObj, "array")
	$array = _JsonC_ObjectArrayGetObjects($arrayObj)

	For $each in $array
		$height = _JsonC_ObjectObjectGet($each, "type")
		ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $height = ' & $height & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
		ConsoleWrite("Friend type: " & _JsonC_TypeToName(_JsonC_ObjectGetType($each)) & @CRLF)
	Next

	$array_list = _JsonC_ObjectGetArray($arrayObj)

	$xx = _JsonC_ArrayListLength($array_list)

;For $friend in $friends_array
;	ConsoleWrite("Friend type: " & _JsonC_TypeToName(_JsonC_ObjectGetType($friend)) & ", value: " & _JsonC_ObjectGetValue($friend) & @CRLF)
;Next

    Local $pageObj = _JsonC_ObjectObjectGet($wsObj, "page")
    ;Local $msgMethodObj = _JsonC_ObjectObjectGet($msgObj, "method")
    Local $pageObjVal = _JsonC_ObjectGetValue($pageObj)
	ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $pageObjVal = ' & $pageObjVal & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

	Exit
	#ce




    ; 1. Connect to CDP
    ;_CDP_Connect($host, $port, $path)


    ; 4. Create Browser object

	; Create a real AutoItObject COM object

    Local $oBrowser = _AutoItObject_Create()

    ; Add methods

    _AutoItObject_AddMethod($oBrowser, "page", "_CDP_Browser_NewPage")
    _AutoItObject_AddMethod($oBrowser, "close", "_CDP_Browser_Close")

    ; Add properties

    _AutoItObject_AddProperty($oBrowser, "wsUrl", $ELSCOPE_PUBLIC, $browserWsUrl)
    _AutoItObject_AddProperty($oBrowser, "wsPort", $ELSCOPE_PUBLIC, $port)
    _AutoItObject_AddProperty($oBrowser, "wsHandle", $ELSCOPE_PUBLIC, $hActiveBrowserWs)

    Return $oBrowser
EndFunc


Func _CDP_Browser_Attach($host, $port, $path)
    ; 1. Connect to CDP
    ;_CDP_Connect($host, $port, $path)


    ; 2. Start the receive loop
    AdlibRegister("_CDP_RecvLoop", 5)
    ;AdlibRegister("_CDP_RecvLoop", 20)

    ; 3. Enable core domains
    _CDP_SendSync("DOM.enable")
    _CDP_SendSync("Page.enable")
    _CDP_SendSync("Runtime.enable")

    ; 4. Create Browser object

	; Create a real AutoItObject COM object

    Local $oBrowser = _AutoItObject_Create()

    ; Add methods

    _AutoItObject_AddMethod($oBrowser, "newPage", "Browser_NewPage")

    ; (Optional) store connection info as properties
    _AutoItObject_AddProperty($oBrowser, "host", $ELSCOPE_PUBLIC, $host)
    _AutoItObject_AddProperty($oBrowser, "port", $ELSCOPE_PUBLIC, $port)
    _AutoItObject_AddProperty($oBrowser, "path", $ELSCOPE_PUBLIC, $path)

    Return $oBrowser
EndFunc


Func _CDP_Browser_NewPage($oSelf)

	; Get the page level websocket

	Local $resp = Curl_Get("http://localhost:" & $oSelf.wsPort & "/json")
	Local $pattern = '(?s)"type"\s*:\s*"page".+?"webSocketDebuggerUrl"\s*:\s*"([^"]+)"'
	Local $matches = StringRegExp($resp, $pattern, 1)

	If @error Then
		ConsoleWrite("No page WebSocket found" & @CRLF)
		Return
	EndIf

	Local $pageWsUrl = $matches[0]
	ConsoleWrite("Page WebSocket URL: " & $pageWsUrl & @CRLF)

	; 1. Connect to the page level websocket

	$hActivePageWs = _CDP_Connect($pageWsUrl)

    ; 2. Start the receive loop

    AdlibRegister("_CDP_RecvLoop", 5)
    ;AdlibRegister("_CDP_RecvLoop", 20)

    ; 3. Enable core domains

    _CDP_SendSync("DOM.enable")
    _CDP_SendSync("Page.enable")
    _CDP_SendSync("Runtime.enable")

    ; Create Page object

    Local $oPage = _AutoItObject_Create()

    ; Add methods

    _AutoItObject_AddMethod($oPage, "goto",     "_CDP_Page_Goto")
    _AutoItObject_AddMethod($oPage, "evaluate", "_CDP_Page_Evaluate")
    _AutoItObject_AddMethod($oPage, "locator",  "_CDP_Page_Locator")

    ; Add properties

    _AutoItObject_AddProperty($oPage, "wsUrl", $ELSCOPE_PUBLIC, $pageWsUrl)
    _AutoItObject_AddProperty($oPage, "wsPort", $ELSCOPE_PUBLIC, $oSelf.wsPort)
    _AutoItObject_AddProperty($oPage, "wsHandle", $ELSCOPE_PUBLIC, $hActivePageWs)

    Return $oPage

EndFunc

Func _CDP_Browser_Close($oSelf)

    _CDP_SendCommand("Browser.close")
	;_CDP_WaitForLoad()

    Return $oSelf

EndFunc


#endregion

#region --- Page Class ---
; Page_Create()
; Page_Goto()
; Page_Evaluate()
; Page_Locator()
; Page_WaitForLoadState()






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




Func _CDP_Page_Locator($oSelf, $selector)

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
        ;$expr = "document.evaluate(`" & $selector & "`, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue"
		$expr = 'document.evaluate("' & $selector & '", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue'
    Else
        $expr = "document.querySelector(`" & $selector & "`)"
    EndIf

	$timeout = 10000

    ; 3. Wait for response
    Local $t = TimerInit()
    While TimerDiff($t) < $timeout

		Local $resp = _CDP_Evaluate($expr)

		;Local $params = _CDP_NewParams()
		;$params.Add("expression", $expr)
		;$params.Add("returnByValue", False)

		;Local $resp = _CDP_SendSync($hCurl, "Runtime.evaluate", $params)

		$json_str = _JsonC_ObjectToJsonString($resp)
		;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $json_str = ' & $json_str & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

		; 2. Parse objectId
		Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
		Local $remoteObj = _JsonC_ObjectObjectGet($resultObj, "result")
		Local $objectIdObj = _JsonC_ObjectObjectGet($remoteObj, "objectId")

		if @error = 0 Then

			Local $objectIdVal = _JsonC_ObjectGetValue($objectIdObj)
			;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $objectIdVal = ' & $objectIdVal & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console


			; Create the Locator object

			Local $oLocator = _AutoItObject_Create()
			Local $oExpect = _AutoItObject_Create()

			; Add methods

			_AutoItObject_AddMethod($oLocator, "click", "_CDP_Locator_Click")
			_AutoItObject_AddMethod($oLocator, "innerText", "_CDP_Locator_InnerText")
			_AutoItObject_AddMethod($oLocator, "innerTextCRStripped", "_CDP_Locator_InnerTextCRStripped")
			_AutoItObject_AddMethod($oLocator, "innerTextLFStripped", "_CDP_Locator_InnerTextLFStripped")
			_AutoItObject_AddMethod($oLocator, "innerTextReplace", "_CDP_Locator_InnerTextReplace")
			_AutoItObject_AddMethod($oExpect, "toHaveText", "_CDP_Expect_ToHaveText")
			_AutoItObject_AddMethod($oExpect, "toContainText", "_CDP_Expect_ToContainText")

			; Add properties

			_AutoItObject_AddProperty($oLocator, "objectId", $ELSCOPE_PUBLIC, $objectIdVal)
			_AutoItObject_AddProperty($oLocator, "expect", $ELSCOPE_PUBLIC, $oExpect)
			_AutoItObject_AddProperty($oLocator, "value", $ELSCOPE_PUBLIC, "")
			_AutoItObject_AddProperty($oExpect, "target", $ELSCOPE_PUBLIC, $oLocator)




			Return $oLocator
		EndIf

		;ConsoleWrite("Retrying locator." & @CRLF)

        Sleep(1)
    WEnd

	ConsoleWrite("Timed out." & @CRLF)
	Exit

EndFunc



#endregion

#region --- Locator Class ---
; Locator_Create()
; Locator_Resolve()
; Locator_Click()
; Locator_InnerText()
; Locator_InnerTextReplace()
; Locator_GetAttribute()
; Locator_IsVisible()




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

    Return $valueVal
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

Locator‑level assertions

    toBeVisible()

    toBeHidden()

    toBeEnabled()

    toBeDisabled()

    toBeChecked()

    toHaveText()

    toContainText()

    toHaveAttribute()

    toHaveValue()

    toHaveCount()

Value assertions

    toBe()

    toEqual()

    toContain()

    toBeTruthy()

    toBeFalsy()

#ce


#cs
Func expect($target)

	; Create Expect object

	Local $oExpect = _AutoItObject_Create()

	; Add methods
	_AutoItObject_AddMethod($oExpect, "toHaveText", "Expect_ToHaveText")

	; Add properties
	_AutoItObject_AddProperty($oExpect, "targetObject", $ELSCOPE_PUBLIC, $target)
	_AutoItObject_AddProperty($oExpect, "value", $ELSCOPE_PUBLIC, "")

	Return $oExpect

EndFunc
#ce



Func _CDP_Expect_ToHaveText($oSelf, $expected, $scriptLineNumber = "?")

	$actual = $oSelf.target.innerText()

	If $actual = $expected Then
		ConsoleWrite('+ Pass (line ' & $scriptLineNumber & ') : expected [' & $expected & '] and got [' & $actual & ']' & @CRLF)
        Return True
    EndIf

	ConsoleWrite('! Fail (line ' & $scriptLineNumber & ') : expected [' & $expected & '] but got [' & $actual & ']' & @CRLF)
    Return False

EndFunc


Func _CDP_Expect_ToContainText($oSelf, $expected, $scriptLineNumber = "?")

	$actual = $oSelf.target.innerText()

	If StringInStr($actual, $expected) > 0 Then
		ConsoleWrite('+ Pass (line ' & $scriptLineNumber & ') : actual text contains [' & $expected & ']' & @CRLF)
        Return True
    EndIf

	ConsoleWrite('! Fail (line ' & $scriptLineNumber & ') : expected actual text to contain [' & $expected & '] but got [' & $actual & ']' & @CRLF)
    Return False

EndFunc



#endregion

#region --- Utilities ---
; String helpers
; JSON helpers
; Debug helpers



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


Func ErrFunc($oError)
	ConsoleWrite("!>COM Error !"&@CRLF&"!>"&@TAB&"Number: "&Hex($oError.Number,8)&@CRLF&"!>"&@TAB&"Windescription: "&StringRegExpReplace($oError.windescription,"\R$","")&@CRLF&"!>"&@TAB&"Source: "&$oError.source&@CRLF&"!>"&@TAB&"Description: "&$oError.description&@CRLF&"!>"&@TAB&"Helpfile: "&$oError.helpfile&@CRLF&"!>"&@TAB&"Helpcontext: "&$oError.helpcontext&@CRLF&"!>"&@TAB&"Lastdllerror: "&$oError.lastdllerror&@CRLF&"!>"&@TAB&"Scriptline: "&$oError.scriptline&@CRLF)
EndFunc   ;==>ErrFunc


#endregion


