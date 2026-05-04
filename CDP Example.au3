#AutoIt3Wrapper_UseX64=y

#include "CDP.au3"

;BasicWebPageWithStandardBrowser()
;BasicWebPageWithStandardHeadlessBrowser()

ElementAttributes()

;BasicWebPageWithPlaywrightBrowser()
;BasicWebPageWithPlaywrightHeadlessBrowser()


Exit


Func ElementAttributes()

	Local $hTimer = TimerInit()

	Local $browser = LaunchStandardBrowser()
	Local $page    = $browser.page()

	$page.Goto("https://testpages.eviltester.com")

	$page.locate("//a[@href='/pages/']").click(True)
	$page.locate("//a[@href='/pages/basics/']").click(True)
	$page.locate("//a[@href='/pages/basics/element-attribute-examples/']").click(True)

	$page.locate("//p[@id='domattributes']").textContent().expect.toBe("This paragraph has attributes")
	$page.locate("//p[@id='jsattributes']").textContent().expect.toBe("This paragraph has dynamic attributes")
	$page.locate("//p[@id='jsattributes']").getAttribute("nextid").expect.toBe(1)
	$page.locate("//button[@id='add-attribute-button']").click()
	$page.locate("//p[@id='jsattributes']").getAttribute("nextid").expect.toBe(2)

	Local $fDiff = TimerDiff($hTimer)
	ConsoleWrite(@CRLF & "> ElementAttributes() took " & $fDiff & " ms." & @CRLF & @CRLF)

EndFunc

Func BasicWebPageWithStandardBrowser()

	Local $hTimer = TimerInit()

	Local $browser = LaunchStandardBrowser()
	Local $page    = $browser.page()
	BasicWebPage($browser, $page)

	Local $fDiff = TimerDiff($hTimer)
	ConsoleWrite(@CRLF & "> BasicWebPageWithStandardBrowser() took " & $fDiff & " ms." & @CRLF & @CRLF)

EndFunc

Func BasicWebPageWithStandardHeadlessBrowser()

	Local $hTimer = TimerInit()

	Local $browser = LaunchStandardHeadlessBrowser()
	Local $page    = $browser.page()
	BasicWebPage($browser, $page)

	Local $fDiff = TimerDiff($hTimer)
	ConsoleWrite(@CRLF & "> BasicWebPageWithStandardHeadlessBrowser() took " & $fDiff & " ms." & @CRLF & @CRLF)

EndFunc

Func BasicWebPageWithPlaywrightBrowser()

	Local $hTimer = TimerInit()

	Local $browser = LaunchPlaywrightBrowser()
	Local $page    = $browser.page()
	BasicWebPage($browser, $page)

	Local $fDiff = TimerDiff($hTimer)
	ConsoleWrite(@CRLF & "> BasicWebPageWithPlaywrightBrowser() took " & $fDiff & " ms." & @CRLF & @CRLF)

EndFunc

Func BasicWebPageWithPlaywrightHeadlessBrowser()

	Local $hTimer = TimerInit()

	Local $browser = LaunchPlaywrightHeadlessBrowser()
	Local $page    = $browser.headlessShell()
	BasicWebPage($browser, $page)

	Local $fDiff = TimerDiff($hTimer)
	ConsoleWrite(@CRLF & "> BasicWebPageWithPlaywrightHeadlessBrowser() took " & $fDiff & " ms." & @CRLF & @CRLF)

EndFunc

Func BasicWebPage($browser, $page)

	$page.Goto("https://testpages.eviltester.com")
	$page.locate("//head/title").expect.toHaveText("Software Testing Practice Pages, Apps, and Challenges", @ScriptLineNumber)
	$page.locate("//head/title").innerText().expect.toBe("Software Testing Practice Pages, Apps, and Challenges", @ScriptLineNumber)
	$page.locate("//head/title").expect.toBeHidden(@ScriptLineNumber)
	$page.locate("//head/title").isVisible().expect.toBe(False, @ScriptLineNumber)
	$page.locate("//head/title").isHidden().expect.toBe(True, @ScriptLineNumber)

	$pages_link = $page.locate("xpath=//a[@href='/pages/']")
	$pages_link.textContent().expect.toBe("Pages", @ScriptLineNumber)
	$pages_link.expect.toBeVisible(@ScriptLineNumber)
	$pages_link.isVisible().expect.toBe(True, @ScriptLineNumber)
	$pages_link.isHidden().expect.toBe(False, @ScriptLineNumber)
	$pages_link.click(True)

	$page.locate("//a[@href='/pages/basics/']/span").innerHTML().expect.toBe("Basics", @ScriptLineNumber)
	$page.locate("//a[@href='/pages/basics/']").click(True)
	$page.locate("//a[@href='/pages/basics/basic-web-page/']").click(True)

	$page.locate("css=header.article-meta").expect.toContainText("Elements", @ScriptLineNumber)
	$page.locate("css=header.article-meta").innerText().expect.toContain("Elements", @ScriptLineNumber)
	$page.locate("//p[@id='para1']").innerText().expect.toBe("A paragraph of text", @ScriptLineNumber)
	$page.locate("//p[@id='para2']").innerText().expect.toBe("Another paragraph of text", @ScriptLineNumber)

	$page.locate("//button[@id='button1']").click()
	$clickMessage = $page.locate("//p[@id='click-message']").innerText().expect.toBe("You clicked the button!", @ScriptLineNumber)

	$browser.close()

EndFunc


Func LaunchStandardBrowser()
	Return $cdp.browserLaunch(Default, 9299, Default, Default, "1280,800")
EndFunc

Func LaunchStandardHeadlessBrowser()
	Return $cdp.browserLaunch(Default, 9299, "--headless=new")
EndFunc

Func LaunchPlaywrightBrowser()
	Return $cdp.browserLaunch(@LocalAppDataDir & '\ms-playwright\chromium-1217\chrome-win64\chrome.exe', 9299, Default, Default, "1280,800")
EndFunc

Func LaunchPlaywrightHeadlessBrowser()
	Return $cdp.browserLaunch(@LocalAppDataDir & '\ms-playwright\chromium_headless_shell-1217\chrome-headless-shell-win64\chrome-headless-shell.exe', 9299)
EndFunc




;$articleMetaText = $page.locate("css=header.article-meta").innerTextReplace(@LF, " ")

;Local $docTitle = $page.evaluate("document.title")
;ConsoleWrite("$docTitle = " & $docTitle & @CRLF)
;Exit


;Local $browser2 = $cdp.browserAttach(9299)
;Local $page2    = $browser2.page()
;$page2.locator("//head/title").expect.toBe("Software Testing Practice Pages, Apps, and Challenges")
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


