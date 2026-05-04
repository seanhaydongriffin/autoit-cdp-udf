#AutoIt3Wrapper_UseX64=y
#include-once

; #INDEX# =======================================================================================================================
; Title .........: JsonC
; AutoIt Version : 3.3.16.0
; Language ......: English
; Description ...: Functions for constructing JSON objects using JSON-C (https://github.com/json-c/json-c).
; Author(s) .....: Sean Griffin
; Dll ...........: json-c.dll (based on v0.18-20240915)
; ===============================================================================================================================

; #VARIABLES# ===================================================================================================================
Global $__g_hDll_JsonC = 0
Global $PtrSize = @AutoItX64 ? 8 : 4
; ===============================================================================================================================

; #CONSTANTS# ===================================================================================================================
Global Enum _
		$JSONC_TYPE_NULL, _
		$JSONC_TYPE_BOOLEAN, _
		$JSONC_TYPE_DOUBLE, _
		$JSONC_TYPE_INT, _
		$JSONC_TYPE_OBJECT, _
		$JSONC_TYPE_ARRAY, _
		$JSONC_TYPE_STRING

Global Const $tagJSONC_OBJECT = _
	"struct;"              		& _
    "int   o_type;"        		& _
	"uint  _ref_count;"    		& _
	"ptr   _to_json_string;"  	& _
	"ptr   _pb;"        		& _
	"ptr   _user_delete;" 		& _
	"ptr   _userdata;"      	& _
	"endstruct;"
; ===============================================================================================================================

; #CURRENT# =====================================================================================================================
; _JsonC_Startup
; _JsonC_Shutdown

; _JsonC_ObjectNewObject
; _JsonC_ObjectNewBoolean
; _JsonC_ObjectNewInt
; _JsonC_ObjectNewInt64
; _JsonC_ObjectNewDouble
; _JsonC_ObjectNewString
; _JsonC_ObjectNewArray
; _JsonC_ObjectArrayAdd

; _JsonC_ObjectObjectAdd
; _JsonC_ObjectObjectDel
; _JsonC_ObjectObjectGet

; _JsonC_TokenerParse
; _JsonC_ObjectToJsonString

; _JsonC_ObjectIsType
; _JsonC_ObjectGetType
; _JsonC_ObjectGetString
; _JsonC_ObjectGetBoolean
; _JsonC_ObjectGetDouble
; _JsonC_ObjectGetInteger
; _JsonC_ObjectGetObject
; _JsonC_ObjectGetValue

; _JsonC_ObjectGetArray
; _JsonC_ArrayListLength
; _JsonC_ArrayListGetIndex
; _JsonC_ObjectArrayLength
; _JsonC_ObjectArrayGetIndex
; _JsonC_ObjectArrayGetObjects
; ===============================================================================================================================

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_Startup
; Description ...: Loads json-c.dll
; Syntax ........: _JsonC_Startup($sDll_Filename = "")
; Parameters ....: $s_String      - a string formatted as JSON
;                  [$i_Os]        - search position where to start (normally don't touch!)
; Return values .: Success - Return a nested structure of AutoIt-datatypes
;                       @extended = next string offset
;                  Failure - Return "" and set @error to:
;                       @error = 1 - part is not json-syntax
;                              = 2 - key name in object part is not json-syntax
;                              = 3 - value in object is not correct json
;                              = 4 - delimiter or object end expected but not gained
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_Startup($sDll_Filename = "")
	If $sDll_Filename = Default Or $sDll_Filename = -1 Then $sDll_Filename = ""
	If $sDll_Filename = "" Then $sDll_Filename = "json-c.dll"
	Local $iExtended = 0
	Local $hDll = DllOpen($sDll_Filename)
	If $hDll = -1 Then
		$__g_hDll_JsonC = 0
		Return SetError(1, $iExtended, "")
	Else
		$__g_hDll_JsonC = $hDll
		Return SetExtended($iExtended, $sDll_Filename)
	EndIf
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_Tokener_Parse
; Description ...: Parse a string and return a json object
; Syntax ........: _JsonC_Tokener_Parse($sString)
; Parameters ....: $sString     - a string formatted as JSON
; Return values .: Success 		- return a non-NULL json_object if a valid JSON value is found
;                  Failure 		- Return a "" (NULL) and set @error to:
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_TokenerParse($sString)
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_tokener_parse", "str", $sString)
	If @error Then Return SetError(1, @error, 0) ; DllCall error
	If $avRval[0] = "" Then
		Return SetError(-1, $avRval[0], 0)
	EndIf
	Local $tJsonObject = DllStructCreate($tagJSONC_OBJECT, $avRval[0])
	If @error Then Return SetError(1, @error, 0) ; DllCall error
	Return $tJsonObject
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectToJsonString
; Description ...: Stringify object to json format.
; Syntax ........: _JsonC_ObjectToJsonString($pObject)
; Parameters ....: $pObject     - the json object instance
; Return values .: Success 		- return the string equivalent of the json object
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectToJsonString($pObject)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	Local $avRval = DllCall($__g_hDll_JsonC, "str", "json_object_to_json_string", "ptr", $pObject)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $avRval[0]
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectGetType
; Description ...: Get the type of the json object
; Syntax ........: _JsonC_ObjectGetType($pObject)
; Parameters ....: $pObject     - the json object instance
; Return values .: Success 		- return type being one of:
;									$JSONC_TYPE_NULL
;									$JSONC_TYPE_BOOLEAN
;									$JSONC_TYPE_DOUBLE
;									$JSONC_TYPE_INT
;									$JSONC_TYPE_OBJECT
;									$JSONC_TYPE_ARRAY
;									$JSONC_TYPE_STRING
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Remarks .......: See also _JsonC_TypeToName to turn this into a string suitable, for instance, for logging.
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectGetType($pObject)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	Local $avRval = DllCall($__g_hDll_JsonC, "int", "json_object_get_type", "ptr", $pObject)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $avRval[0]
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectIsType
; Description ...: Checks if the json object is of a given type
; Syntax ........: _JsonC_ObjectIsType($pObject, $iType)
; Parameters ....: $pObject     - the json object instance
;				   $iType		- one of:
;									$JSONC_TYPE_NULL
;									$JSONC_TYPE_BOOLEAN
;									$JSONC_TYPE_DOUBLE
;									$JSONC_TYPE_INT
;									$JSONC_TYPE_OBJECT
;									$JSONC_TYPE_ARRAY
;									$JSONC_TYPE_STRING
; Return values .: Success 		- return a True or False depending on whether object is the type
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectIsType($pObject, $iType)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	Local $avRval = DllCall($__g_hDll_JsonC, "int", "json_object_is_type", "ptr", $pObject, "int", $iType)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $avRval[0]
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_TypeToName
; Description ...: Return a string describing the type of the object. e.g. "int", or "object", etc...
; Syntax ........: _JsonC_TypeToName($iType)
; Parameters ....: $iType      - one of:
;									$JSONC_TYPE_NULL
;									$JSONC_TYPE_BOOLEAN
;									$JSONC_TYPE_DOUBLE
;									$JSONC_TYPE_INT
;									$JSONC_TYPE_OBJECT
;									$JSONC_TYPE_ARRAY
;									$JSONC_TYPE_STRING
; Return values .: Success 		- return the string name of the type
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_TypeToName($iType)
	Local $avRval = DllCall($__g_hDll_JsonC, "str", "json_type_to_name", "int", $iType)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $avRval[0]
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectObjectAdd
; Description ...: Add an object field to a json object of type $JSONC_TYPE_OBJECT
; Syntax ........: _JsonC_ObjectObjectAdd($pObject, $sKey, $pObjectToAdd)
; Parameters ....: $pObject     - the json object instance
;				   $sKey		- the object field name
;				   $pObjectToAdd- the json object to add
; Return values .: Success 		- the given json object field is added
;                  Failure 		- set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectObjectAdd($pObject, $sKey, $pObjectToAdd)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	if IsPtr($pObjectToAdd) = False Then $pObjectToAdd = DllStructGetPtr($pObjectToAdd)
	DllCall($__g_hDll_JsonC, "none", "json_object_object_add", "ptr", $pObject, "str", $sKey, "ptr", $pObjectToAdd)
	If @error Then Return SetError(1, @error, 0) ; DllCall error
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectObjectDel
; Description ...: Delete the given json object field
; Syntax ........: _JsonC_ObjectObjectDel($pObject, $sKey)
; Parameters ....: $pObject     - the json object instance
;				   $sKey		- the object field name
; Return values .: Success 		- the given json object field is deleted
;                  Failure 		- set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectObjectDel($pObject, $sKey)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	DllCall($__g_hDll_JsonC, "none", "json_object_object_del", "ptr", $pObject, "str", $sKey)
	If @error Then Return SetError(1, @error, 0) ; DllCall error
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectObjectGet
; Description ...: Get the json object associated with a given object field
; Syntax ........: _JsonC_ObjectObjectGet($pObject, $sKey)
; Parameters ....: $pObject     - the json object instance
;				   $sKey		- the object field name
; Return values .: Success 		- return the json object associated with the given field name
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectObjectGet($pObject, $sKey)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_object_get", "ptr", $pObject, "str", $sKey)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Local $tJsonObject = DllStructCreate($tagJSONC_OBJECT, $avRval[0])
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $tJsonObject
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectGetBoolean
; Description ...: Get the $JSONC_TYPE_BOOLEAN value of a json object
; Syntax ........: _JsonC_ObjectGetBoolean($pObject)
; Parameters ....: $pObject     - the json object instance
; Return values .: Success 		- a boolean
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectGetBoolean($pObject)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	Local $avRval = DllCall($__g_hDll_JsonC, "boolean", "json_object_get_boolean", "ptr", $pObject)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $avRval[0]
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectGetDouble
; Description ...: Get the $JSONC_TYPE_DOUBLE value of a json object
; Syntax ........: _JsonC_ObjectGetDouble($pObject)
; Parameters ....: $pObject     - the json object instance
; Return values .: Success 		- return a double floating point number
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectGetDouble($pObject)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	Local $avRval = DllCall($__g_hDll_JsonC, "double", "json_object_get_double", "ptr", $pObject)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $avRval[0]
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectGetInt
; Description ...: Get the $JSONC_TYPE_INT value of a json object
; Syntax ........: _JsonC_ObjectGetInt($pObject)
; Parameters ....: $pObject     - the json object instance
; Return values .: Success 		- return an int
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectGetInt($pObject)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	Local $avRval = DllCall($__g_hDll_JsonC, "int", "json_object_get_int", "ptr", $pObject)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $avRval[0]
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectGetObject
; Description ...: Get the hashtable of a json object of type json type object
; Syntax ........: _JsonC_ObjectGetObject($pObject)
; Parameters ....: $pObject     - the json object instance
; Return values .: Success 		- return a linkhash
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectGetObject($pObject)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_get_object", "ptr", $pObject)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $avRval[0]
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectGetArray
; Description ...: Get the arraylist of a json object of type json type array
; Syntax ........: _JsonC_ObjectGetArray($pObject)
; Parameters ....: $pObject     - the json object instance
; Return values .: Success 		- return an arraylist
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectGetArray($pObject)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_get_array", "ptr", $pObject)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $avRval[0]
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ArrayListLength
; Description ...: Get the length of an arraylist
; Syntax ........: _JsonC_ArrayListLength($tArrayList)
; Parameters ....: $tArrayList  - the arraylist (from _JsonC_ObjectGetArray)
; Return values .: Success 		- return the length of the arraylist
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ArrayListLength($tArrayList)
	Local $avRval = DllCall($__g_hDll_JsonC, "int", "array_list_length", "ptr", $tArrayList)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $avRval[0]
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ArrayListGetIndex
; Description ...: Get the json object for an item in the arraylist
; Syntax ........: _JsonC_ArrayListGetIndex($tArrayList, $iIndex)
; Parameters ....: $tArrayList  - the arraylist (from _JsonC_ObjectGetArray)
; Return values .: Success 		- return the json object
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ArrayListGetIndex($tArrayList, $iIndex)
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "array_list_get_idx", "ptr", $tArrayList, "int", $iIndex)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $avRval[0]
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectGetString
; Description ...: Get the string value of a json object
; Syntax ........: _JsonC_ObjectGetString($pObject)
; Parameters ....: $pObject     - the json object instance
; Return values .: Success 		- return a string
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectGetString($pObject)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	Local $avRval = DllCall($__g_hDll_JsonC, "str", "json_object_get_string", "ptr", $pObject)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $avRval[0]
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectGetValue
; Description ...: Get the value of a json object of any type
; Syntax ........: _JsonC_ObjectGetValue($pObject)
; Parameters ....: $pObject     - the json object instance
; Return values .: Success 		- return the value of the object
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectGetValue($pObject)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	Local $iType, $iLength
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_get_value", "ptr", $pObject, "int*", $iType, "int*", $iLength)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	$iType = $avRval[2]
	$iLength = $avRval[3]
	Switch $iType
		Case $JSONC_TYPE_NULL
			Return ""
		Case $JSONC_TYPE_BOOLEAN
			Return DllStructGetData(DllStructCreate("BOOLEAN", $avRval[0]), 1)
		Case $JSONC_TYPE_DOUBLE
			Return DllStructGetData(DllStructCreate("DOUBLE", $avRval[0]), 1)
		Case $JSONC_TYPE_INT
			Return DllStructGetData(DllStructCreate("INT", $avRval[0]), 1)
		Case $JSONC_TYPE_OBJECT
			Return DllStructGetData(DllStructCreate("PTR", $avRval[0]), 1)
		Case $JSONC_TYPE_ARRAY
			Return DllStructGetData(DllStructCreate("PTR", $avRval[0]), 1)
		Case $JSONC_TYPE_STRING
			Return DllStructGetData(DllStructCreate("CHAR[" & $iLength & "]", $avRval[0]), 1)
	EndSwitch
	Return SetError(1, @error, "")
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectGetFieldValue
; Description ...: Get the value of a field in a json object
; Syntax ........: _JsonC_ObjectGetFieldValue($pObject, $sKey)
; Parameters ....: $pObject     - the json object instance
;				   $sKey		- the object field name
; Return values .: Success 		- return the value of the field
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectGetFieldValue($pObject, $sKey)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	Local $iType, $iLength
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_get_field_value", "ptr", $pObject, "str", $sKey, "int*", $iType, "int*", $iLength)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	$iType = $avRval[3]
	$iLength = $avRval[4]
	Switch $iType
		Case $JSONC_TYPE_NULL
			Return ""
		Case $JSONC_TYPE_BOOLEAN
			Return DllStructGetData(DllStructCreate("BOOLEAN", $avRval[0]), 1)
		Case $JSONC_TYPE_DOUBLE
			Return DllStructGetData(DllStructCreate("DOUBLE", $avRval[0]), 1)
		Case $JSONC_TYPE_INT
			Return DllStructGetData(DllStructCreate("INT", $avRval[0]), 1)
		Case $JSONC_TYPE_OBJECT
			Return DllStructGetData(DllStructCreate("PTR", $avRval[0]), 1)
		Case $JSONC_TYPE_ARRAY
			Return DllStructGetData(DllStructCreate("PTR", $avRval[0]), 1)
		Case $JSONC_TYPE_STRING
			return DllStructGetData(DllStructCreate("CHAR[" & $iLength & "]", $avRval[0]), 1)
	EndSwitch
	Return SetError(1, @error, "")
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectNewObject
; Description ...: Create a new empty json object of type $JSONC_TYPE_OBJECT
; Syntax ........: _JsonC_ObjectNewObject()
; Parameters ....:
; Return values .: Success 		- return a json object of type $JSONC_TYPE_OBJECT
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectNewObject()
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_new_object")
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Local $tJsonObject = DllStructCreate($tagJSONC_OBJECT, $avRval[0])
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $tJsonObject
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectNewArray
; Description ...: Create a new empty json object of type $JSONC_TYPE_ARRAY
; Syntax ........: _JsonC_ObjectNewArray()
; Parameters ....:
; Return values .: Success 		- return a json object of type $JSONC_TYPE_ARRAY
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectNewArray()
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_new_array")
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Local $tJsonObject = DllStructCreate($tagJSONC_OBJECT, $avRval[0])
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $tJsonObject
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectArrayAdd
; Description ...: Add an element to the end of a json object of type $JSONC_TYPE_ARRAY
; Syntax ........: _JsonC_ObjectArrayAdd($pObject, $pObjectToAdd)
; Parameters ....: $pObject     - the json object instance of type $JSONC_TYPE_ARRAY
;				   $pObjectToAdd- the json object to add
; Return values .: Success 		- return an int
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectArrayAdd($pObject, $pObjectToAdd)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	if IsPtr($pObjectToAdd) = False Then $pObjectToAdd = DllStructGetPtr($pObjectToAdd)
	Local $avRval = DllCall($__g_hDll_JsonC, "int", "json_object_array_add", "ptr", $pObject, "ptr", $pObjectToAdd)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $avRval[0]
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectNewBoolean
; Description ...: Create a new empty json object of type $JSONC_TYPE_BOOLEAN
; Syntax ........: _JsonC_ObjectNewBoolean($bBoolean)
; Parameters ....: $bBoolean   	- a Boolean TRUE or FALSE (0 or 1)
; Return values .: Success 		- return a json_object of type $JSONC_TYPE_BOOLEAN
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectNewBoolean($bBoolean)
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_new_boolean", "boolean", $bBoolean)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Local $tJsonObject = DllStructCreate($tagJSONC_OBJECT, $avRval[0])
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $tJsonObject
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectNewInt
; Description ...: Create a new empty json object of type $JSONC_TYPE_INT
; Syntax ........: _JsonC_ObjectNewInt($iInteger)
; Parameters ....: $iInteger    - the integer
; Return values .: Success 		- return a json_object of type $JSONC_TYPE_INT
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectNewInt($iInteger)
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_new_int", "int", $iInteger)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Local $tJsonObject = DllStructCreate($tagJSONC_OBJECT, $avRval[0])
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $tJsonObject
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectNewInt64
; Description ...: Create a new empty json object of type $JSONC_TYPE_INT
; Syntax ........: _JsonC_ObjectNewInt64($iInteger)
; Parameters ....: $iInteger    - the integer
; Return values .: Success 		- return a json_object of type $JSONC_TYPE_INT
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectNewInt64($iInteger)
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_new_int64", "int64", $iInteger)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Local $tJsonObject = DllStructCreate($tagJSONC_OBJECT, $avRval[0])
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $tJsonObject
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectNewDouble
; Description ...: Create a new empty json object of type $JSONC_TYPE_DOUBLE
; Syntax ........: _JsonC_ObjectNewDouble($fDouble)
; Parameters ....: $fDouble     - the double
; Return values .: Success 		- return a json_object of type $JSONC_TYPE_DOUBLE
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectNewDouble($fDouble)
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_new_double", "double", $fDouble)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Local $tJsonObject = DllStructCreate($tagJSONC_OBJECT, $avRval[0])
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $tJsonObject
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectNewString
; Description ...: Create a new empty json object of type $JSONC_TYPE_STRING
; Syntax ........: _JsonC_ObjectNewString($sString)
; Parameters ....: $sString     - the string
; Return values .: Success 		- return a json_object of type $JSONC_TYPE_STRING
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectNewString($sString)
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_new_string", "str", $sString)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Local $tJsonObject = DllStructCreate($tagJSONC_OBJECT, $avRval[0])
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $tJsonObject
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectArrayLength
; Description ...: Get the length of a json object of type $JSONC_TYPE_ARRAY
; Syntax ........: _JsonC_ObjectArrayLength($pObject)
; Parameters ....: $pObject     - the json object instance
; Return values .: Success 		- return an int
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectArrayLength($pObject)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	Local $avRval = DllCall($__g_hDll_JsonC, "int64", "json_object_array_length", "ptr", $pObject)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $avRval[0]
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectArrayGetIndex
; Description ...: Get the element at specificed index of the array
; Syntax ........: _JsonC_ObjectArrayGetIndex($pObject, $iIndex)
; Parameters ....: $pObject     - a json object of type json_type_array
;				   $iIndex		- the index to get the element at
; Return values .: Success 		- return the json object at the specified index
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectArrayGetIndex($pObject, $iIndex)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_array_get_idx", "ptr", $pObject, "int", $iIndex)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Local $tJsonObject = DllStructCreate($tagJSONC_OBJECT, $avRval[0])
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $tJsonObject
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_ObjectArrayGetObjects
; Description ...: Get all the json objects from an array
; Syntax ........: _JsonC_ObjectArrayGetObjects($pObject)
; Parameters ....: $pObject     - a json object of type json_type_array
; Return values .: Success 		- return an AutoIt array of json objects
;                  Failure 		- Return a "" (NULL) and set @error to 1
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_ObjectArrayGetObjects($pObject)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_array_get_objects", "ptr", $pObject)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	$ArrayLength = _JsonC_ObjectArrayLength($pObject)
	Local $pObjects[$ArrayLength]
	For $i = 0 To $ArrayLength - 1
		Local $ptrObject = DllStructGetData(DllStructCreate("ptr", $avRval[0] + ($i * $PtrSize)), 1)
		$pObjects[$i] = $ptrObject
	Next
	Return $pObjects
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_Shutdown
; Description ...: Unloads json-c.dll
; Syntax ........: _JsonC_Shutdown()
; Parameters ....: $s_String      - a string formatted as JSON
;                  [$i_Os]        - search position where to start (normally don't touch!)
; Return values .: Success - Return a nested structure of AutoIt-datatypes
;                       @extended = next string offset
;                  Failure - Return "" and set @error to:
;                       @error = 1 - part is not json-syntax
;                              = 2 - key name in object part is not json-syntax
;                              = 3 - value in object is not correct json
;                              = 4 - delimiter or object end expected but not gained
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_Shutdown()
	If $__g_hDll_JsonC > 0 Then DllClose($__g_hDll_JsonC)
	$__g_hDll_JsonC = 0
EndFunc
