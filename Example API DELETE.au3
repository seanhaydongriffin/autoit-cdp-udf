#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "CDP.au3"

With test("Simple API DELETE test")
	$firstId = LogItemSummary()

	$step = teststep("Delete the first item with id = " & $firstId)
		$jResp = $api.delete("https://apichallenges.eviltester.com/simpleapi/items/" & $firstId)
		ExpectedResponse($step, $jResp, 200, "OK")
	$step = 0
	
	LogItemSummary()
	PostItem()
	LogItemSummary()
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

Func PostItem()
	$isbn = GetISBN()
	$jResp = $api.post('https://apichallenges.eviltester.com/simpleapi/items', _JsonC_Object().add("type", "blu-ray").add("isbn13", $isbn).add("price", 97.99).add("numberinstock", 0), _JsonC_Object().add("Content-Type", "application/json"))
	if $jResp.body.type() = "string" Then ConsoleWrite("  > Added item: " & $jResp.body.value() & @CRLF)
	if $jResp.body.type() = "object" Then ConsoleWrite("  > Added item: " & $jResp.body.toString() & @CRLF)
EndFunc

Func GetISBN()
	$jResp = $api.get("https://apichallenges.eviltester.com/simpleapi/randomisbn")
	Return $jResp.body.value()
EndFunc

