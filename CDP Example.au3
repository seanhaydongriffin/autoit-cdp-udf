;http://code.msdn.microsoft.com/windowsdesktop/WinHTTP-WebSocket-sample-50a140b5/sourcecode?fileId=51199&pathId=1032775223
#AutoIt3Wrapper_UseX64=y

#include "CDP.au3"

Local $hTimer = TimerInit()

Local $browser = Browser_Launch("localhost", 9222, "/devtools/page/D93FB5EC35D60AE9E1B9373D3502EA7B")
Local $page    = $browser.NewPage()

$page.Goto("https://testpages.eviltester.com")
$page.locator("//head/title").expect.toHaveText("Software Testing Practice Pages, Apps, and Challenges")

$pages_link = $page.locator("xpath=//a[@href='/pages/']")
$pages_link.expect.toHaveText("Pages")

$pages_link.click(True)
$page.locator("//a[@href='/pages/basics/']/span").expect.toHaveText("Basics", @ScriptLineNumber)
$page.locator("//a[@href='/pages/basics/']").click(True)
$page.locator("//a[@href='/pages/basics/basic-web-page/']").click(True)

$page.locator("css=header.article-meta").expect.toContainText("Elements", @ScriptLineNumber)
$page.locator("//p[@id='para1']").expect.toHaveText("A paragraph of text")
$page.locator("//p[@id='para2']").expect.toHaveText("Another paragraph of text")

$page.locator("//button[@id='button1']").click()
$clickMessage = $page.locator("//p[@id='click-message']").expect.toHaveText("You clicked the button!")

Local $fDiff = TimerDiff($hTimer)
ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $fDiff = ' & $fDiff & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

Exit


;$articleMetaText = $page.locator("css=header.article-meta").innerTextReplace(@LF, " ")

;Local $docTitle = $page.evaluate("document.title")
;ConsoleWrite("$docTitle = " & $docTitle & @CRLF)
;Exit


#cs
Local $sHost = "localhost"
Local $iPort = 9222
;Local $sPath = "/devtools/browser/e3f32401-9f89-46a2-b1bc-6db7dd900185"
Local $sPath = "/devtools/page/D93FB5EC35D60AE9E1B9373D3502EA7B"

;Local $hTimer = TimerInit()
_CDP_Connect($sHost, $iPort, $sPath)
If @error Then Exit MsgBox(16, "Error", "Failed to connect")
ConsoleWrite("Connected to CDP" & @CRLF)
;Local $fDiff = TimerDiff($hTimer)
;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $fDiff = ' & $fDiff & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

AdlibRegister("_CDP_RecvLoop", 5)
_CDP_SendCommand("DOM.enable")
_CDP_SendCommand("Page.enable")


;_CDP_Navigate("https://testpages.eviltester.com")
_CDP_WaitForLoad()

_CDP_QuerySelectorXPath("//a[@href='/pages/']")

Exit

_CDP_ClickObjectId(_CDP_QuerySelectorXPath("//a[@href='/pages/']"))
_CDP_WaitForLoad()
_CDP_ClickObjectId(_CDP_QuerySelectorXPath("//a[@href='/pages/basics/']"))
_CDP_WaitForLoad()
_CDP_ClickObjectId(_CDP_QuerySelectorXPath("//a[@href='/pages/basics/basic-web-page/']"))
_CDP_WaitForLoad()

Exit



_CDP_SendCommand("DOM.enable")
_CDP_SendCommand("Page.enable")
;_CDP_Navigate("https://github.com/janison/ads/tree/13edef26b460c0c9356a23fe23cd5b5c97c2e5e5/Plugins/Janison.SpaApi/Data/Checklists")
_CDP_WaitForLoad()
$objectId = _CDP_QuerySelectorXPath("//table[@aria-labelledby='folders-and-files']/tbody/tr[2]/td[2]//a")
_CDP_ClickObjectId($objectId)

_CDP_WaitForLoad()
$objectId2 = _CDP_QuerySelectorXPath("//button[@data-testid='download-raw-button']")
ConsoleWrite("clicking" & @CRLF)
_CDP_ClickObjectId($objectId2)


AdlibUnRegister("_CDP_RecvLoop")

;$msgObj = $g_CDP_Pending(1)
;Local $msgIdObj = _JsonC_ObjectObjectGet($msgObj, "id")
;Local $msgId = _JsonC_ObjectGetValue($msgIdObj)
;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $msgId = ' & $msgId & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console


Exit

_CDP_SendCommand("Page.enable")

;Local $hTimer = TimerInit()
;_CDP_Navigate($hWS, "https://example.com")
;_CDP_Navigate($hWS, "https://www.google.com")
;_CDP_Navigate($hWS, "https://global.qa1.ads.janisoncloud.com")
;_CDP_Navigate($hWS, "https://www.untatme.com")
;_CDP_Navigate("https://github.com/janison/ads/tree/13edef26b460c0c9356a23fe23cd5b5c97c2e5e5/Plugins/Janison.SpaApi/Data/Checklists")

;Local $fDiff = TimerDiff($hTimer)
;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $fDiff = ' & $fDiff & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

_CDP_WaitForLoad()

$objectId = _CDP_QuerySelectorXPath("//table[@aria-labelledby='folders-and-files']/tbody/tr[2]/td[2]//a")
_CDP_ClickObjectId($objectId)

_CDP_WaitForLoad()
Sleep(5000) ; give React time to hydrate

$objectId2 = _CDP_QuerySelectorXPath("//button[@data-testid='download-raw-button']")
ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $objectId2 = ' & $objectId2 & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
_CDP_ClickObjectId($objectId2)

;Sleep(1000) ; give React time to hydrate

;Local $html = _CDP_Evaluate($hWS, "document.body.innerHTML")
;ConsoleWrite($html & @CRLF)

;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $objectId = ' & $objectId & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
;Exit

;$objectId = _CDP_QuerySelectorXPath("//button[contains(text(), 'Sign In')]")
;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $objectId = ' & $objectId & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console


Exit

Local $hTimer = TimerInit()
_CDP_Click($hWS, 'button.text-sm')
Local $fDiff = TimerDiff($hTimer)
ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $fDiff = ' & $fDiff & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console


;Sleep(500)
;_CDP_Evaluate($hWS, "document.title")
;_CDP_Click($hWS, '.button.login')
;_CDP_Click($hWS, 'button[class*="button"][class*="login"]')

#ce


#cs
	For $i = 0 To UBound($aSites) - 1
		ConsoleWrite("====================" & @crlf)
		; Create session, connection and request handles.

		$hOpen = _WinHttpOpen("WebSocket sample", $WINHTTP_ACCESS_TYPE_DEFAULT_PROXY)
		If $hOpen = 0 Then
			$iError = _WinAPI_GetLastError()
			ConsoleWrite("Open error" & @CRLF)
			Exit
		EndIf

		;$hConnect = _WinHttpConnect($hOpen, $aSites[$i][0], $INTERNET_DEFAULT_HTTP_PORT)
		$hConnect = _WinHttpConnect($hOpen, $sHost, $iPort)
		If $hConnect = 0 Then
			$iError = _WinAPI_GetLastError()
			ConsoleWrite("Connect error" & @CRLF)
			Exit
		EndIf

		;$hRequest = _WinHttpOpenRequest($hConnect, "GET", $aSites[$i][1], "")
		$hRequest = _WinHttpOpenRequest($hConnect, "GET", $sPath, "")
		If $hRequest = 0 Then
			$iError = _WinAPI_GetLastError()
			ConsoleWrite("OpenRequest error" & @CRLF)
			Exit
		EndIf

		; Request protocol upgrade from http to websocket.

		Local $fStatus = _WinHttpSetOptionNoParams($hRequest, $WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET)
		If Not $fStatus Then
			$iError = _WinAPI_GetLastError()
			ConsoleWrite("SetOption error" & @CRLF)
			Exit
		EndIf

		; Perform websocket handshake by sending a request and receiving server's response.
		; Application may specify additional headers if needed.

		$fStatus = _WinHttpSendRequest($hRequest)
		If Not $fStatus Then
			$iError = _WinAPI_GetLastError()
			ConsoleWrite("SendRequest error" & @CRLF)
			Exit
		EndIf

		$fStatus = _WinHttpReceiveResponse($hRequest)
		If Not $fStatus Then
			$iError = _WinAPI_GetLastError()
			ConsoleWrite("ReceiveResponse error" & @CRLF)
			Exit
		EndIf

		; Application should check what is the HTTP status code returned by the server and behave accordingly.
		; WinHttpWebSocketCompleteUpgrade will fail if the HTTP status code is different than 101.
		$iExtended = _WinHttpQueryHeaders($hRequest, $WINHTTP_QUERY_STATUS_CODE)

		If $iExtended <> 101 Then
			ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $iExtended = ' & $iExtended & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
			Exit
		EndIf

		$hWebSocket = _WinHttpWebSocketCompleteUpgrade($hRequest, 0)
		If $hWebSocket = 0 Then
			$iError = _WinAPI_GetLastError()
			ConsoleWrite("WebSocketCompleteUpgrade error" & @CRLF)
			Exit
		EndIf

		_WinHttpCloseHandle($hRequest)
		$hRequestHandle = 0

		ConsoleWrite("Succesfully upgraded to websocket protocol" & @CRLF)

		; Send and receive data on the websocket protocol.

		$iError = _WinHttpWebSocketSend($hWebSocket, _
				$WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE, _
				$aSites[$i][2])
		If @error Or $iError <> 0 Then
			ConsoleWrite("WebSocketSend error" & @CRLF)
			Exit
		EndIf

		ConsoleWrite("Sent message to the server: " & $aSites[$i][2] & @CRLF)

		Local $iBufferLen = 1024
		Local $tBuffer = 0, $bRecv = Binary("")

		Local $iBytesRead = 0, $iBufferType = 0
		Do
			If $iBufferLen = 0 Then
				$iError = $ERROR_NOT_ENOUGH_MEMORY
			Exit
			EndIf

			$tBuffer = DllStructCreate("byte[" & $iBufferLen & "]")

			$iError = _WinHttpWebSocketReceive($hWebSocket, _
					$tBuffer, _
					$iBytesRead, _
					$iBufferType)
			If @error Or $iError <> 0 Then
				ConsoleWrite("WebSocketReceive error" & @CRLF)
			Exit
			EndIf

			; If we receive just part of the message restart the receive operation.

			$bRecv &= BinaryMid(DllStructGetData($tBuffer, 1), 1, $iBytesRead)
			$tBuffer = 0

			$iBufferLen -= $iBytesRead
		Until $iBufferType <> $WINHTTP_WEB_SOCKET_UTF8_FRAGMENT_BUFFER_TYPE

		; We expected server just to echo single binary message.

		If $iBufferType <> $WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE Then
			ConsoleWrite("Unexpected buffer type" & @CRLF)
			$iError = $ERROR_INVALID_PARAMETER
			Exit
		EndIf

		ConsoleWrite("Received message from the server: '" & BinaryToString($bRecv) & "'" & @CRLF)

		; Gracefully close the connection.

		$iError = _WinHttpWebSocketClose($hWebSocket, _
				$WINHTTP_WEB_SOCKET_SUCCESS_CLOSE_STATUS)
		If @error Or $iError <> 0 Then
			ConsoleWrite("WebSocketClose error" & @CRLF)
			Exit
		EndIf

		; Check close status returned by the server.

		Local $iStatus = 0, $iReasonLengthConsumed = 0
		Local $tCloseReasonBuffer = DllStructCreate("byte[123]")

		$iError = _WinHttpWebSocketQueryCloseStatus($hWebSocket, _
				$iStatus, _
				$iReasonLengthConsumed, _
				$tCloseReasonBuffer)
		If @error Or $iError <> 0 Then
			ConsoleWrite("QueryCloseStatus error" & @CRLF)
			Exit
		EndIf

		ConsoleWrite("The server closed the connection with status code: '" & $iStatus & "' and reason: '" & _
				BinaryToString(BinaryMid(DllStructGetData($tCloseReasonBuffer, 1), 1, $iReasonLengthConsumed)) & "'" & @CRLF)
	Next
#ce

#cs
Func quit()
    If $hRequest <> 0 Then
        _WinHttpCloseHandle($hRequest)
        $hRequest = 0
    EndIf

    If $hWebSocket <> 0 Then
        _WinHttpCloseHandle($hWebSocket)
        $hWebSocket = 0
    EndIf

    If $hConnect <> 0 Then
        _WinHttpCloseHandle($hConnect)
        $hConnect = 0
    EndIf

    If $iError <> 0 Then
        ConsoleWrite("Application failed with error: " & $iError & @CRLF)
        Return -1
    EndIf

    Return 0
EndFunc
#ce



#cs
Func _CDP_Send($hWebSocket, $sJson)
    Local $iErr = _WinHttpWebSocketSend($hWebSocket, _
        $WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE, _
        $sJson)

    If @error Or $iErr <> 0 Then Return SetError(1, $iErr, False)
    Return True
EndFunc
#ce



#cs
Func _CDP_Receive($hWebSocket)
    Local $tBuffer = DllStructCreate("byte[4096]")
    Local $iBytes = 0, $iType = 0
	ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $iBytes = ' & $iBytes & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

    Local $iErr = _WinHttpWebSocketReceive($hWebSocket, $tBuffer, $iBytes, $iType)
	ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $iBytes = ' & $iBytes & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
	ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $iErr = ' & $iErr & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

    ; No data available yet
    If $iErr = 0 And $iBytes = 0 Then Return ""

    ; Error or close
    If @error Or $iErr <> 0 Then Return SetError(1, $iErr, "")

    Return BinaryToString(BinaryMid(DllStructGetData($tBuffer, 1), 1, $iBytes))
EndFunc
#ce

#cs
Func _CDP_Receive($hWebSocket)
    Local $tBuffer = DllStructCreate("byte[4096]")
    Local $iBytes = 0, $iType = 0

    Local $iErr = _WinHttpWebSocketReceive($hWebSocket, $tBuffer, $iBytes, $iType)
	ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $iBytes = ' & $iBytes & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
	ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $iErr = ' & $iErr & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

    ; Timeout → no data
    If $iErr = 12002 Then Return ""

    ; No data
    If $iErr = 0 And $iBytes = 0 Then Return ""

    ; Error
    If $iErr <> 0 Then Return SetError(1, $iErr, "")

    Return BinaryToString(BinaryMid(DllStructGetData($tBuffer, 1), 1, $iBytes))
EndFunc
#ce


#cs
Func _CDP_Navigate($sUrl)
    Local $oParams = ObjCreate("Scripting.Dictionary")
    $oParams.Add("url", $sUrl)

    Return _CDP_SendCommand("Page.navigate", $oParams)
EndFunc
#ce





#cs
Func _CDP_WaitForLoad($hWS, $iTimeoutMs = 5000)
    Local $tEnd = TimerInit()
    While TimerDiff($tEnd) < $iTimeoutMs
        Local $msg = _CDP_Receive($hWS)
		ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $msg = ' & $msg & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
        If $msg = "" Then ContinueLoop

        If StringInStr($msg, '"method":"Page.loadEventFired"') Then
            ConsoleWrite("Page loaded" & @CRLF)
            Return True
        EndIf
    WEnd
    Return False
EndFunc
#ce




#cs
Func _CDP_DOM_Enable($hWS)
    _CDP_SendCommand($hWS, "DOM.enable")
EndFunc
#ce

#cs
Func _CDP_GetDocument($hWS)
	ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : "DOM.getDocument" = ' & "DOM.getDocument" & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
    Local $iId = _CDP_SendCommand($hWS, "DOM.getDocument")

    Local $tEnd = TimerInit()
    While TimerDiff($tEnd) < 2000
        Local $msg = _CDP_Receive($hWS)
        If $msg = "" Then ContinueLoop

        If StringInStr($msg, '"id":' & $iId) Then
            Return $msg
        EndIf
    WEnd

    Return SetError(1, 0, "")
EndFunc
#ce

#cs
Func _CDP_QuerySelector($hWS, $iNodeId, $sSelector)
	ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $iNodeId = ' & $iNodeId & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
    Local $oParams = _CDP_NewParams()
    $oParams.Add("nodeId", $iNodeId)
    $oParams.Add("selector", $sSelector)

    Local $iId = _CDP_SendCommand("DOM.querySelector", $oParams)

    Local $tEnd = TimerInit()
    While TimerDiff($tEnd) < 2000
        Local $msg = _CDP_Receive($hWS)
        If $msg = "" Then ContinueLoop

        If StringInStr($msg, '"id":' & $iId) Then
            Return $msg
        EndIf
    WEnd

    Return SetError(1, 0, "")
EndFunc
#ce


Func _CDP_QuerySelectorXPath($xpath)

	; 1. Evaluate XPath
    Local $js = 'document.evaluate("' & $xpath & '", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue'
	;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $js = ' & $js & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
    Local $evalObj = _CDP_Evaluate($js)

    ; 2. Parse objectId
    Local $resultObj = _JsonC_ObjectObjectGet($evalObj, "result")
    Local $remoteObj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $objectIdObj = _JsonC_ObjectObjectGet($remoteObj, "objectId")
    Local $objectId = _JsonC_ObjectGetValue($objectIdObj)
	ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $objectId = ' & $objectId & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

    If $objectId = "" Then Return 0
	return $objectId

EndFunc


#cs
Func _CDP_DescribeNodeByObjectId($hWS, $objectId)
    ; Build params
    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $objectId)

    ; Send command
    Local $cmdId = _CDP_SendCommand("DOM.describeNode", $oParams)

    ; Wait for response
    Local $tEnd = TimerInit()
    While TimerDiff($tEnd) < 2000
        Local $msg = _CDP_Receive($hWS)
        If $msg = "" Then ContinueLoop

        ; Match the response by id
        If StringInStr($msg, '"id":' & $cmdId) Then
            Return $msg
        EndIf
    WEnd

    Return ""
EndFunc
#ce


#cs
Func _CDP_GetBoxModel($hWS, $iNodeId)
    Local $oParams = _CDP_NewParams()
    $oParams.Add("nodeId", $iNodeId)

    Local $iId = _CDP_SendCommand("DOM.getBoxModel", $oParams)

    Local $tEnd = TimerInit()
    While TimerDiff($tEnd) < 2000
        Local $msg = _CDP_Receive($hWS)
        If $msg = "" Then ContinueLoop

        If StringInStr($msg, '"id":' & $iId) Then
            Return $msg
        EndIf
    WEnd

    Return SetError(1, 0, "")
EndFunc
#ce

Func _CDP_DispatchMouseEvent($hWS, $sType, $x, $y)
    Local $oParams = _CDP_NewParams()
    $oParams.Add("type", $sType)
    $oParams.Add("x", $x)
    $oParams.Add("y", $y)
    $oParams.Add("button", "left")
    $oParams.Add("clickCount", 1)

    _CDP_SendCommand("Input.dispatchMouseEvent", $oParams)
EndFunc

#cs
Func _CDP_Click($hWS, $sSelector)

    ; 1. Get document root
    Local $doc = _CDP_GetDocument($hWS)

	$jobj = _JsonC_TokenerParse($doc)
	$result = _JsonC_ObjectObjectGet($jobj, "result")
	$root = _JsonC_ObjectObjectGet($result, "root")
	$children = _JsonC_ObjectObjectGet($root, "children")
	$children_array = _JsonC_ObjectArrayGetObjects($children)

	Local $rootId

	For $child in $children_array

		$nodeName = _JsonC_ObjectObjectGet($child, "nodeName")

		if _JsonC_ObjectGetValue($nodeName) == "HTML" Then
			$rootId = _JsonC_ObjectGetValue(_JsonC_ObjectObjectGet($child, "nodeId"))
			ExitLoop
		EndIf
	Next

	ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $rootId = ' & $rootId & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

;	Return

	If $rootId = "" Then
		ConsoleWrite("ERROR: Could not find <html> root node" & @CRLF)
		Return False
	EndIf


    ; 2. Query selector
    Local $sel = _CDP_QuerySelector($hWS, $rootId, $sSelector)

	$jobj = _JsonC_TokenerParse($sel)
	$result = _JsonC_ObjectObjectGet($jobj, "result")
	$nodeId = _JsonC_ObjectGetValue(_JsonC_ObjectObjectGet($result, "nodeId"))

    If $nodeId = "" Or $nodeId = "0" Then
        ConsoleWrite("Selector not found: " & $sSelector & @CRLF)
        Return False
    EndIf

	;ConsoleWrite(_CDP_DescribeNode($hWS, $nodeId) & @CRLF)

    ; 3. Get box model
    Local $box = _CDP_GetBoxModel($hWS, $nodeId)
    Local $coords = StringRegExp($box, '"content":\[(.*?)\]', 1)

    If Not IsArray($coords) Then Return False

    Local $a = StringSplit($coords[0], ",")
    Local $x1 = Number($a[1])
    Local $y1 = Number($a[2])
    Local $x2 = Number($a[3])
    Local $y2 = Number($a[4])

    ; 4. Compute center
    Local $cx = ($x1 + $x2) / 2
    Local $cy = ($y1 + $y2) / 2

    ; 5. Dispatch click
    _CDP_DispatchMouseEvent($hWS, "mouseMoved", $cx, $cy)
    _CDP_DispatchMouseEvent($hWS, "mousePressed", $cx, $cy)
    _CDP_DispatchMouseEvent($hWS, "mouseReleased", $cx, $cy)

    Return True
EndFunc
#ce

Func _CDP_ClickObjectId($objectId)
    Local $oParams = _CDP_NewParams()
    $oParams.Add("objectId", $objectId)
    $oParams.Add("functionDeclaration", "function() { this.click(); }")
    $oParams.Add("awaitPromise", False)

    _CDP_SendCommand("Runtime.callFunctionOn", $oParams)
EndFunc

#cs
Func _CDP_ClickNodeId($hWS, $nodeId)

    ; 3. Get box model
    Local $box = _CDP_GetBoxModel($hWS, $nodeId)
    Local $coords = StringRegExp($box, '"content":\[(.*?)\]', 1)

    If Not IsArray($coords) Then Return False

    Local $a = StringSplit($coords[0], ",")
    Local $x1 = Number($a[1])
    Local $y1 = Number($a[2])
    Local $x2 = Number($a[3])
    Local $y2 = Number($a[4])

    ; 4. Compute center
    Local $cx = ($x1 + $x2) / 2
    Local $cy = ($y1 + $y2) / 2

    ; 5. Dispatch click
    _CDP_DispatchMouseEvent($hWS, "mouseMoved", $cx, $cy)
    _CDP_DispatchMouseEvent($hWS, "mousePressed", $cx, $cy)
    _CDP_DispatchMouseEvent($hWS, "mouseReleased", $cx, $cy)

    Return True
EndFunc
#ce

#cs
Func _CDP_DescribeNode($hWS, $iNodeId)
    Local $oParams = _CDP_NewParams()
    $oParams.Add("nodeId", $iNodeId)

    Local $iId = _CDP_SendCommand("DOM.describeNode", $oParams)

    Local $tEnd = TimerInit()
    While TimerDiff($tEnd) < 2000
        Local $msg = _CDP_Receive($hWS)
        If $msg = "" Then ContinueLoop
        If StringInStr($msg, '"id":' & $iId) Then Return $msg
    WEnd

    Return ""
EndFunc
#ce




#cs
Func Page_LocatorXPath($oSelf)

	; 1. Evaluate XPath
    Local $xpath = $oSelf.arguments.values[0]
    Local $js = 'document.evaluate("' & $xpath & '", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue'
	Local $evalObj = _CDP_Evaluate($js)

    ; 2. Parse objectId
    Local $resultObj = _JsonC_ObjectObjectGet($evalObj, "result")
    Local $remoteObj = _JsonC_ObjectObjectGet($resultObj, "result")
    Local $objectIdObj = _JsonC_ObjectObjectGet($remoteObj, "objectId")
    Local $objectIdVal = _JsonC_ObjectGetValue($objectIdObj)

    ; Create Locator object

	Local $oLocator = IDispatch()
	$oLocator.objectId = $objectIdVal
	$oLocator.__defineGetter('Click',Locator_Click)
	$oLocator.__defineGetter('InnerText',Locator_InnerText)
    Return $oLocator

EndFunc
#ce







