#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "CDP.au3"

With test("Simple API GET test")

	With teststep("Get all items")

		$jResp = $api.get('https://apichallenges.eviltester.com/simpleapi/items')
		LogResponse($jResp)

		Local $items = _JsonC_ObjectArrayGetObjects(_JsonC_ObjectObjectGet(_JsonC_ObjectObjectGet($jResp, "body"), "items"))
		For $item in $items
			LogItem($item)
		Next

	EndWith

	$firstId = LogItemSummary()

	With teststep("Delete the first item")

		$jResp = $api.delete("https://apichallenges.eviltester.com/simpleapi/items/" & $firstId)

	EndWith

	$firstId = LogItemSummary()
	$isbn = GetISBN()

	With teststep("Create an item with JSON data")

		;$jResp = $api.post('https://apichallenges.eviltester.com/simpleapi/items', Null, '{ "type": "blu-ray", "isbn13": "123-4-56-789012-3", "price": 97.99, "numberinstock": 0 }')

		;$sOptions = '{ "headerData": { ... }, "postData": "raw post data" }'
		;$sOptions = '{ "headerData": { "Content-Type": "application/json" }, "postData": { "type": "blu-ray", "isbn13": "' & $isbn & '", "price": 97.99, "numberinstock": 0 } }'
		;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $sOptions = ' & $sOptions & @CRLF & '>Error code: ' & @error & @CRLF)
		;$jOptions = _JsonC_TokenerParse($sOptions)

		$jPostData = _JsonC_ObjectNewObject()
		_JsonC_ObjectObjectAdd($jPostData, "type", _JsonC_ObjectNewString("blu-ray"))
		_JsonC_ObjectObjectAdd($jPostData, "isbn13", _JsonC_ObjectNewString($isbn))
		_JsonC_ObjectObjectAdd($jPostData, "price", _JsonC_ObjectNewDouble(97.99))
		_JsonC_ObjectObjectAdd($jPostData, "numberinstock", _JsonC_ObjectNewInt(0))

		$jHeaderData = _JsonC_ObjectNewObject()
		_JsonC_ObjectObjectAdd($jHeaderData, "Content-Type", _JsonC_ObjectNewString("application/json"))

		$jResp = $api.post('https://apichallenges.eviltester.com/simpleapi/items', $jPostData, $jHeaderData)
		LogResponse($jResp)

	EndWith

	$firstId = LogItemSummary()
	DeleteItem($firstId)
	$isbn = GetISBN()

	With teststep("Create an item with String data")

		;$sOptions = '{ "username": "foo", "password": "bar", "proxy": "127.0.0.1:8888", "timeout": 30, "followRedirects": true, "cookieFile": "cookies.txt", "caInfo": "curl-ca-bundle.crt", "sslVerifyPeer": false }'

		$jResp = $api.post('https://apichallenges.eviltester.com/simpleapi/items', '{ "type": "blu-ray", "isbn13": "' & $isbn & '", "price": 97.99, "numberinstock": 0 }', '{ "Content-Type": "application/json" }')
		LogResponse($jResp)

	EndWith

	LogItemSummary()

EndWith

Exit

Func LogResponse($jResp)
	ConsoleWrite("Status: " & _JsonC_ObjectGetValue(_JsonC_ObjectObjectGet($jResp, "status")) & @CRLF)
	ConsoleWrite("Status Text: " & _JsonC_ObjectGetValue(_JsonC_ObjectObjectGet($jResp, "statusText")) & @CRLF)
	ConsoleWrite("Headers: " & _JsonC_ObjectGetValue(_JsonC_ObjectObjectGet($jResp, "headers")) & @CRLF)
	ConsoleWrite("Body: " & _JsonC_ObjectToJsonString(_JsonC_ObjectObjectGet($jResp, "body")) & @CRLF)
	ConsoleWrite("Content Type: " & _JsonC_ObjectGetValue(_JsonC_ObjectObjectGet($jResp, "contentType")) & @CRLF)
EndFunc

Func LogItem($item)
	ConsoleWrite("Item: id = " & _JsonC_ObjectGetValue(_JsonC_ObjectObjectGet($item, "id")) & _
		", type = " & _JsonC_ObjectGetValue(_JsonC_ObjectObjectGet($item, "type")) & _
		", isbn13 = " & _JsonC_ObjectGetValue(_JsonC_ObjectObjectGet($item, "isbn13")) & _
		", price = " & _JsonC_ObjectGetValue(_JsonC_ObjectObjectGet($item, "price")) & _
		", numberinstock = " & _JsonC_ObjectGetValue(_JsonC_ObjectObjectGet($item, "numberinstock")) & @CRLF)
EndFunc

Func LogItemSummary()
	$jResp = $api.get("https://apichallenges.eviltester.com/simpleapi/items")
	Local $itemsObj = _JsonC_ObjectObjectGet(_JsonC_ObjectObjectGet($jResp, "body"), "items")
	ConsoleWrite("Total number of items = " & _JsonC_ObjectArrayLength($itemsObj) & @CRLF)
	Local $firstIdVal = _JsonC_ObjectGetValue(_JsonC_ObjectObjectGet(_JsonC_ObjectArrayGetIndex($itemsObj, 0), "id"))
	ConsoleWrite("ID of the first item = " & $firstIdVal & @CRLF)
	Return $firstIdVal
EndFunc

Func GetISBN()
	$jResp = $api.get("https://apichallenges.eviltester.com/simpleapi/randomisbn", Null, False)
	Local $isbn = _JsonC_ObjectGetValue(_JsonC_ObjectObjectGet($jResp, "body"))
	ConsoleWrite("Unique ISBN = " & $isbn & @CRLF)
	Return $isbn
EndFunc

Func DeleteItem($id)
	$api.delete("https://apichallenges.eviltester.com/simpleapi/items/" & $id)
EndFunc
