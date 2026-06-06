#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "CDP.au3"

With test("Simple API GET test")

	$step = teststep("Get all items as json")
		$jHeaderData = _JsonC_Object().add("Accept", "application/json")
		$jResp = $api.get('https://apichallenges.eviltester.com/simpleapi/items', $jHeaderData)
		ExpectedResponse($step, $jResp, 200, "OK", "content-type: application/json")

		$items = $jResp.body.get("items")
		For $i = 0 to $items.count() - 1
			LogItem($items.at($i))
		Next
	$step = 0

	$step = teststep("Get all items as xml with default options")
		$jHeaderData = _JsonC_Object().add("Accept", "application/xml")
		$jOptions = _JsonC_Object().add("username", "").add("password", "").add("proxy", "").add("timeout", 30).add("followRedirects", True).add("cookieFile", "cookies.txt").add("caInfo", "curl-ca-bundle.crt").add("sslVerifyPeer", False)
		$jResp = $api.get('https://apichallenges.eviltester.com/simpleapi/items', $jHeaderData, $jOptions)
		ExpectedResponse($step, $jResp, 200, "OK", "content-type: application/xml")
	$step = 0

	$step = teststep("Get items of type 'cd'")
		$jResp = $api.get('https://apichallenges.eviltester.com/simpleapi/items?type=cd')
		if $jResp.body.type() = "string" Then ConsoleWrite("      > Body: " & $jResp.body.value() & @CRLF)
		if $jResp.body.type() = "object" Then ConsoleWrite("      > Body: " & $jResp.body.toString() & @CRLF)
	$step = 0

	$step = teststep("Get items of type 'blu-ray'")
		$jResp = $api.get('https://apichallenges.eviltester.com/simpleapi/items?type=blu-ray')
		if $jResp.body.type() = "string" Then ConsoleWrite("      > Body: " & $jResp.body.value() & @CRLF)
		if $jResp.body.type() = "object" Then ConsoleWrite("      > Body: " & $jResp.body.toString() & @CRLF)
	$step = 0


EndWith

Func ExpectedResponse($step, $jResp, $expectedStatus, $expectedStatusText, $headerText)
	$step.expect($jResp.status.value(), "Status").toBe($expectedStatus, @ScriptLineNumber)
	$step.expect($jResp.statusText.value(), "Status Text").toBe($expectedStatusText, @ScriptLineNumber)
	$step.expect($jResp.headers.value(), "Headers").toContain($headerText, @ScriptLineNumber)
	if $jResp.body.type() = "string" Then ConsoleWrite("      > Body: " & $jResp.body.value() & @CRLF)
	if $jResp.body.type() = "object" Then ConsoleWrite("      > Body: " & $jResp.body.toString() & @CRLF)
	$step.expect($jResp.contentType.value(), "Content Type").toBe("application/json", @ScriptLineNumber)
EndFunc

Func LogItem($item)
	ConsoleWrite("      > Item: id = " & $item.get("id").value() & _
		", type = " & $item.get("type").value() & _
		", isbn13 = " & $item.get("isbn13").value() & _
		", price = " & $item.get("price").value() & _
		", numberinstock = " & $item.get("numberinstock").value() & @CRLF)
EndFunc

Func LogItemSummary()
	$jResp = $api.get("https://apichallenges.eviltester.com/simpleapi/items")
	$items = $jResp.body.get("items")
	ConsoleWrite("  > Total number of items = " & $items.count() & @CRLF)
	Local $firstIdVal = $items.at(0).get("id").value()
	ConsoleWrite("  > ID of the first item = " & $firstIdVal & @CRLF)
	Return $firstIdVal
EndFunc

Func GetISBN()
	$jResp = $api.get("https://apichallenges.eviltester.com/simpleapi/randomisbn", Null, False)
	Local $isbn = $jResp.body.value()
	ConsoleWrite("  > Unique ISBN = " & $isbn & @CRLF)
	Return $isbn
EndFunc

Func DeleteItem($id)
	$api.delete("https://apichallenges.eviltester.com/simpleapi/items/" & $id)
EndFunc
