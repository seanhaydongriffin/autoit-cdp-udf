#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "CDP.au3"

With test("Simple API GET test")

	$step = teststep("Get all items")
		$jResp = $api.get('https://apichallenges.eviltester.com/simpleapi/items')
		LogResponse($step, $jResp, 200, "OK")

		$items = $jResp.body.get("items")
		For $i = 0 to $items.count() - 1
			LogItem($items.at($i))
		Next
	$step = 0

	$firstId = LogItemSummary()

	$step = teststep("Delete the first item")
		$jResp = $api.delete("https://apichallenges.eviltester.com/simpleapi/items/" & $firstId)
		LogResponse($step, $jResp, 200, "OK")
	$step = 0

	$firstId = LogItemSummary()
	$isbn = GetISBN()

	$step = teststep("Create an item with JSON data")
		$jPostData = _JsonC_Object()
		$jPostData.add("type", "blu-ray")
		$jPostData.add("isbn13", $isbn)
		$jPostData.add("price", 97.99)
		$jPostData.add("numberinstock", 0)
		$jHeaderData = _JsonC_Object()
		$jHeaderData.add("Content-Type", "application/json")
		$jResp = $api.post('https://apichallenges.eviltester.com/simpleapi/items', $jPostData.handle, $jHeaderData.handle)
		LogResponse($step, $jResp, 201, "Created")
	$step = 0

	$firstId = LogItemSummary()
	DeleteItem($firstId)
	$isbn = GetISBN()

	$step = teststep("Create an item with String data")
		;$sOptions = '{ "username": "foo", "password": "bar", "proxy": "127.0.0.1:8888", "timeout": 30, "followRedirects": true, "cookieFile": "cookies.txt", "caInfo": "curl-ca-bundle.crt", "sslVerifyPeer": false }'
		$jResp = $api.post('https://apichallenges.eviltester.com/simpleapi/items', '{ "type": "blu-ray", "isbn13": "' & $isbn & '", "price": 97.99, "numberinstock": 0 }', '{ "Content-Type": "application/json" }')
		LogResponse($step, $jResp, 201, "Created")
	$step = 0

	LogItemSummary()

EndWith

Func LogResponse($step, $jResp, $expectedStatus, $expectedStatusText)
	$step.expect($jResp.status.value(), "Status").toBe($expectedStatus, @ScriptLineNumber)
	$step.expect($jResp.statusText.value(), "Status Text").toBe($expectedStatusText, @ScriptLineNumber)
	$step.expect($jResp.headers.value(), "Headers").toContain("content-type: application/json", @ScriptLineNumber)
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
