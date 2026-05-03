;http://code.msdn.microsoft.com/windowsdesktop/WinHTTP-WebSocket-sample-50a140b5/sourcecode?fileId=51199&pathId=1032775223
#AutoIt3Wrapper_UseX64=y

#include "CDP.au3"

#cs

chrome.exe --remote-debugging-port=9222 --user-data-dir="C:\Temp\ChromeDebug" --no-first-run --no-default-browser-check


curl http://localhost:9222/json/version
"webSocketDebuggerUrl": "ws://localhost:9222/devtools/browser/<UUID>"

curl http://localhost:9222/json
{
  "id": "D93FB5EC35D60AE9E1B9373D3502EA7B",
  "title": "Example",
  "url": "https://example.com",
  "webSocketDebuggerUrl": "ws://localhost:9222/devtools/page/D93FB5EC35D60AE9E1B9373D3502EA7B"
}
#ce

Local $hTimer = TimerInit()

;Local $browser = _CDP_BrowserAttach("localhost", 9222, "/devtools/page/D93FB5EC35D60AE9E1B9373D3502EA7B")

;Local $browser = _CDP_BrowserOpen(9299, '--no-first-run --no-default-browser-check', @ScriptDir & '\ChromeDebug', True, 'C:\Users\SGriffin\AppData\Local\ms-playwright\chromium-1217\chrome-win64\chrome.exe')

Local $browser = $cdp.launchBrowser(9299, '--no-first-run --no-default-browser-check', @ScriptDir & '\ChromeDebug', True, 'C:\Users\SGriffin\AppData\Local\ms-playwright\chromium-1217\chrome-win64\chrome.exe')
Local $page    = $browser.page()

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

$browser.close()

Local $fDiff = TimerDiff($hTimer)
ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $fDiff = ' & $fDiff & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console


Exit


;$articleMetaText = $page.locator("css=header.article-meta").innerTextReplace(@LF, " ")

;Local $docTitle = $page.evaluate("document.title")
;ConsoleWrite("$docTitle = " & $docTitle & @CRLF)
;Exit





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


