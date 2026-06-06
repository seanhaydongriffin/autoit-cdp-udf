#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "CDP.au3"

With test("Simple API GET test")

	$isbn = GetISBN()

	$step = teststep("Create an item with JSON data")
		$jPostData = _JsonC_Object().add("type", "blu-ray").add("isbn13", $isbn).add("price", 97.99).add("numberinstock", 0)
		$jHeaderData = _JsonC_Object().add("Content-Type", "application/json")
		$jResp = $api.post('https://apichallenges.eviltester.com/simpleapi/items', $jPostData, $jHeaderData)
		ExpectedResponse($step, $jResp, 201, "Created")
	$step = 0

	$firstId = LogItemSummary()
	DeleteItem($firstId)
	$isbn = GetISBN()

	$step = teststep("Create an item with String data")
		$jResp = $api.post('https://apichallenges.eviltester.com/simpleapi/items', _JsonC_Object('{ "type": "blu-ray", "isbn13": "' & $isbn & '", "price": 97.99, "numberinstock": 0 }'), _JsonC_Object('{ "Content-Type": "application/json" }'))
		ExpectedResponse($step, $jResp, 201, "Created")
	$step = 0

	$firstId = LogItemSummary()
	DeleteItem($firstId)

EndWith

Func ExpectedResponse($step, $jResp, $expectedStatus, $expectedStatusText)
	$step.expect($jResp.status.value(), "Status").toBe($expectedStatus, @ScriptLineNumber)
	$step.expect($jResp.statusText.value(), "Status Text").toBe($expectedStatusText, @ScriptLineNumber)
	$step.expect($jResp.headers.value(), "Headers").toContain("content-type: application/json", @ScriptLineNumber)
	if $jResp.body.type() = "string" Then ConsoleWrite("      > Body: " & $jResp.body.value() & @CRLF)
	if $jResp.body.type() = "object" Then ConsoleWrite("      > Body: " & $jResp.body.toString() & @CRLF)
	$step.expect($jResp.contentType.value(), "Content Type").toBe("application/json", @ScriptLineNumber)
EndFunc

Func LogItemSummary()
	$jResp = $api.get("https://apichallenges.eviltester.com/simpleapi/items")
	$items = $jResp.body.get("items")
	ConsoleWrite("  > Total number of items = " & $items.count() & @CRLF)
	Return $items.at(0).get("id").value()
EndFunc

Func GetISBN()
	$jResp = $api.get("https://apichallenges.eviltester.com/simpleapi/randomisbn")
	Return $jResp.body.value()
EndFunc

Func DeleteItem($id)
	$jResp = $api.delete("https://apichallenges.eviltester.com/simpleapi/items/" & $id)
	ConsoleWrite("  > Deleted item id = " & $id & @CRLF)
EndFunc
