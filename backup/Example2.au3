#AutoIt3Wrapper_UseX64=y
#include "JsonCEx.au3"

_JsonC_Startup("json-c.dll")
_AutoItObject_Startup()




$jArrOfValues = JsonC_Array().add("Paula").add("Cindy").add("Dorothy")

$jArrOfObjects = JsonC_Array()
$jArrOfObjects.add(JsonC_Object().add("name", "Alice").add("age", 30).add("height", 175.8).add("isEmployed", True))
$jArrOfObjects.add(JsonC_Object().add("name", "Roger").add("age", 32).add("height", 165.3).add("isEmployed", False))

$jobj2 = JsonC_Object().add("person", $jArrOfValues).add("personDetails", $jArrOfObjects)

For $oObject In $jArrOfObjects
    ConsoleWrite("person name = " & $oObject.name.value() & @CRLF)
Next

For $oObject In $jobj2.personDetails
    ConsoleWrite("person name = " & $oObject.name.value() & @CRLF)
Next

$jstr = $jobj2.toString()
ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $jstr = ' & $jstr & @CRLF & '>Error code: ' & @error & @CRLF)


Exit

#cs
$jobj = JsonC_Object().add("name", "Alice").add("age", 30).add("height", 175.8).add("isEmployed", True).add("friends", $jarr)
$jstr = $jobj.toString()
;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $jstr = ' & $jstr & @CRLF & '>Error code: ' & @error & @CRLF)

ConsoleWrite("JSON type: " & $jobj.type() & ", string: " & $jobj.toString() & @CRLF)
ConsoleWrite("Name type: " & $jobj.name.type() & ", value: " & $jobj.name.value() & @CRLF)
ConsoleWrite("Age type: " & $jobj.age.type() & ", value: " & $jobj.age.value() & @CRLF)
ConsoleWrite("Height type: " & $jobj.height.type() & ", value: " & $jobj.height.value() & @CRLF)
ConsoleWrite("IsEmployed type: " & $jobj.isEmployed.type() & ", value: " & $jobj.isEmployed.value() & @CRLF)

Exit
#ce

$jobj = _JsonC_ObjectNewObject()
_JsonC_ObjectObjectAdd($jobj, "name", _JsonC_ObjectNewString("Alice"))
_JsonC_ObjectObjectAdd($jobj, "age", _JsonC_ObjectNewInt(30))
_JsonC_ObjectObjectAdd($jobj, "height", _JsonC_ObjectNewDouble(175.8))
_JsonC_ObjectObjectAdd($jobj, "isEmployed", _JsonC_ObjectNewBoolean(True))
$jarr = _JsonC_ObjectNewArray()
_JsonC_ObjectArrayAdd($jarr, _JsonC_ObjectNewString("Paula"))
_JsonC_ObjectArrayAdd($jarr, _JsonC_ObjectNewString("Cindy"))
_JsonC_ObjectArrayAdd($jarr, _JsonC_ObjectNewString("Dorothy"))
_JsonC_ObjectObjectAdd($jobj, "friends", $jarr)
$str = _JsonC_ObjectToJsonString($jobj)
ConsoleWrite("String: " & $str & @CRLF)

$jobj = _JsonC_TokenerParse($str)
ConsoleWrite("JSON type: " & _JsonC_TypeToName(_JsonC_ObjectGetType($jobj)) & ", string: " & _JsonC_ObjectToJsonString($jobj) & @CRLF)

$name = _JsonC_ObjectObjectGet($jobj, "name")
ConsoleWrite("Name type: " & _JsonC_TypeToName(_JsonC_ObjectGetType($name)) & ", value (using GetString): " & _JsonC_ObjectGetString($name) & ", value (using GetValue): " & _JsonC_ObjectGetValue($name) & @CRLF)

$age = _JsonC_ObjectObjectGet($jobj, "age")
ConsoleWrite("Age type: " & _JsonC_TypeToName(_JsonC_ObjectGetType($age)) & ", value (using GetInt): " & _JsonC_ObjectGetInt($age) & ", value (using GetValue): " & _JsonC_ObjectGetValue($age) & @CRLF)

$height = _JsonC_ObjectObjectGet($jobj, "height")
ConsoleWrite("Height type: " & _JsonC_TypeToName(_JsonC_ObjectGetType($height)) & ", value (using GetDouble): " & _JsonC_ObjectGetDouble($height) & ", value (using GetValue): " & _JsonC_ObjectGetValue($height) & @CRLF)

$is_employed = _JsonC_ObjectObjectGet($jobj, "isEmployed")
ConsoleWrite("IsEmployed type: " & _JsonC_TypeToName(_JsonC_ObjectGetType($is_employed)) & ", value (using GetBoolean): " & _JsonC_ObjectGetBoolean($is_employed) & ", value (using GetValue): " & _JsonC_ObjectGetValue($is_employed) & @CRLF)

$friends = _JsonC_ObjectObjectGet($jobj, "friends")
$friends_array_list = _JsonC_ObjectGetArray($friends)
ConsoleWrite("Number of friends (from array list): " & _JsonC_ArrayListLength($friends_array_list) & ", 2nd friend (from array list): " & _JsonC_ObjectGetValue(_JsonC_ArrayListGetIndex($friends_array_list, 1)) & @CRLF)


ConsoleWrite("Number of friends (from array object): " & _JsonC_ObjectArrayLength($friends) & ", 2nd friend (from array object): " & _JsonC_ObjectGetValue(_JsonC_ObjectArrayGetIndex($friends, 1)) & @CRLF)

$friends_array = _JsonC_ObjectArrayGetObjects($friends)
For $friend in $friends_array
	ConsoleWrite("Friend type: " & _JsonC_TypeToName(_JsonC_ObjectGetType($friend)) & ", value: " & _JsonC_ObjectGetValue($friend) & @CRLF)
Next

ConsoleWrite("Is age a type of string: " & _JsonC_ObjectIsType($age, $JSONC_TYPE_STRING) & @CRLF)
ConsoleWrite("Is age a type of int: " & _JsonC_ObjectIsType($age, $JSONC_TYPE_INT) & @CRLF)

_JsonC_ObjectObjectDel($jobj, "age")
ConsoleWrite("JSON string without age: " & _JsonC_ObjectToJsonString($jobj) & @CRLF)


$jobj = _JsonC_ObjectNewObject()
_JsonC_ObjectObjectAdd($jobj, "name", _JsonC_ObjectNewString("Alice"))
_JsonC_ObjectObjectAdd($jobj, "age", _JsonC_ObjectNewInt(30))

$str = _JsonC_ObjectToJsonString($jobj)
ConsoleWrite("String: " & $str & @CRLF)

Local $iter = _JsonC_ObjectIterInit($jobj)

Do

Local $key = _JsonC_ObjectIterGetName($iter)
ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $key = ' & $key & @CRLF & '>Error code: ' & @error & @CRLF)

Local $valueObj = _JsonC_ObjectIterGetValue($iter)
$value = _JsonC_ObjectGetValue($valueObj)
ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $value = ' & $value & @CRLF & '>Error code: ' & @error & @CRLF)

until _JsonC_ObjectIterNext($iter) = False








_JsonC_Shutdown()

