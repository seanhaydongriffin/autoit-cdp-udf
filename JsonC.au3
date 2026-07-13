#AutoIt3Wrapper_UseX64=y
#include-once
#include <WinAPI.au3>
#include <Memory.au3>

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
; _JsonC_Version

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

; _JsonC_ObjectArrayLength
; _JsonC_ObjectArrayGetIndex
; _JsonC_ObjectArrayGetObjects
;
; _JsonC_ObjectIterInit
; _JsonC_ObjectIterNext
; _JsonC_ObjectIterGetName
; _JsonC_ObjectIterGetValue
;
; ===============================================================================================================================

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_Version
; Description ...: Returns the version of json-c
; Syntax ........: _JsonC_Version()
; Parameters ....:
; Return values .: the version of json-c
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_Version()
	Local $a = DllCall($__g_hDll_JsonC, "str", "json_c_version")
	If @error Then Return SetError(1, @error, Null) ; DllCall error
	Return $a[0]
EndFunc

; #FUNCTION# ======================================================================================
; Name ..........: _JsonC_Startup
; Description ...: Loads json-c embedded dll
; Syntax ........: _JsonC_Startup()
; Parameters ....: none
; Return values .: Success - dll loaded
;                  Failure - Return "" and set @error to:
;                       @error = 1 - dll not loaded
; Author ........: SeanGriffin
; =================================================================================================
Func _JsonC_Startup()
	Local $bBinaryImage
	If @AutoItX64 Then
		$bBinaryImage = __JsonC_Dll_X64()
	Else
		$bBinaryImage = __JsonC_Dll()
	EndIf
	$__g_hDll_JsonC = __JsonC_LoadBinaryDll($bBinaryImage, "explorer.exe")
	If @error Then
		$__g_hDll_JsonC = 0
		Return SetError(1, 0, "")
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
	If @error Then Return SetError(1, @error, Null) ; DllCall error
	If $avRval[0] = "" Then
		Return SetError(-1, $avRval[0], Null)
	EndIf
	Local $tJsonObject = DllStructCreate($tagJSONC_OBJECT, $avRval[0])
	If @error Then Return SetError(1, @error, Null) ; DllCall error
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
	If @error Then Return SetError(1, @error, Null) ; DllCall error
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
	If @error Then Return SetError(1, @error, Null) ; DllCall error
	Local $tJsonObject = DllStructCreate($tagJSONC_OBJECT, $avRval[0])
	If @error Then Return SetError(1, @error, Null) ; DllCall error
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
	If @error Then Return SetError(1, @error, Null) ; DllCall error
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
	If @error Then Return SetError(1, @error, Null) ; DllCall error
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
	If @error Then Return SetError(1, @error, Null) ; DllCall error
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
	if IsPtr($pObject) = False Then Return SetError(1, 0, Null)
	Local $iType = _JsonC_ObjectGetType($pObject)
	Switch $iType
		Case $JSONC_TYPE_STRING
			Return _JsonC_ObjectGetString($pObject)
		Case $JSONC_TYPE_INT
			Return _JsonC_ObjectGetInt($pObject)
		Case $JSONC_TYPE_DOUBLE
			Return _JsonC_ObjectGetDouble($pObject)
		Case $JSONC_TYPE_BOOLEAN
			Return _JsonC_ObjectGetBoolean($pObject)
		Case $JSONC_TYPE_OBJECT
			Return $pObject
		Case $JSONC_TYPE_ARRAY
			Return $pObject
		Case $JSONC_TYPE_NULL
			Return ""
	EndSwitch
	Return SetError(1, @error, Null)

#cs




	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	if IsPtr($pObject) = False Then Return SetError(1, 0, Null)
	Local $iType, $iLength
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_get_value", "ptr", $pObject, "int*", $iType, "int*", $iLength)
	If @error Then Return SetError(1, @error, Null) ; DllCall error
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
			;Return DllStructGetData(DllStructCreate("CHAR[" & $iLength & "]", $avRval[0]), 1)
			; the line above can incorrectly return 0 for an empty string, the following is a fix for that
			Return _JsonC_ObjectGetString($pObject)
	EndSwitch
	Return SetError(1, @error, Null)
	#ce
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
	If @error Then Return SetError(1, @error, Null) ; DllCall error
	Local $tJsonObject = DllStructCreate($tagJSONC_OBJECT, $avRval[0])
	If @error Then Return SetError(1, @error, Null) ; DllCall error
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
Func _JsonC_ObjectArrayGetObjects($pArray)
    If IsPtr($pArray) = False Then $pArray = DllStructGetPtr($pArray)

    ; length
    Local $aLen = DllCall($__g_hDll_JsonC, "int", "json_object_array_length", "ptr", $pArray)
    If @error Then Return SetError(1, @error, "")
    Local $iLen = $aLen[0]

    Local $pObjects[$iLen]

    ; loop through elements
    For $i = 0 To $iLen - 1
        Local $aElem = DllCall($__g_hDll_JsonC, "ptr", "json_object_array_get_idx", "ptr", $pArray, "int", $i)
        If @error Then Return SetError(2, @error, "")
        $pObjects[$i] = $aElem[0]
    Next

    Return $pObjects
EndFunc





#cs
Func _JsonC_ObjectIterInit($pObject)
	if IsPtr($pObject) = False Then $pObject = DllStructGetPtr($pObject)
	Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_iter_begin", "ptr", $pObject)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Return $avRval[0]
EndFunc
#ce

Func _JsonC_ObjectIterInit($pObject)
    If Not IsPtr($pObject) Then $pObject = DllStructGetPtr($pObject)

    ; Get the struct-by-value as a 64-bit value (opaque_ field)
    Local $avRval = DllCall($__g_hDll_JsonC, "int64", "json_object_iter_begin", "ptr", $pObject)
    If @error Then Return SetError(1, @error, 0)

    ; Create an AutoIt struct that matches: struct { void* opaque_; }
    Local $tIter = DllStructCreate("ptr")
    DllStructSetData($tIter, 1, $avRval[0])

    ; Return the struct, not the raw value
    Return $tIter
EndFunc


Func _JsonC_ObjectIterGetName($tIter)
    ; $tIter is a DllStruct from _JsonC_ObjectIterInit
    If IsPtr($tIter) Then
        ; if someone passes a ptr by mistake, still handle it
        Local $pIter = $tIter
    Else
        Local $pIter = DllStructGetPtr($tIter)
    EndIf

    Local $avRval = DllCall($__g_hDll_JsonC, "str", "json_object_iter_peek_name", "ptr", $pIter)
    If @error Then Return SetError(1, @error, "")

    Return $avRval[0]
EndFunc


Func _JsonC_ObjectIterGetValue($tIter)
    Local $pIter = DllStructGetPtr($tIter)

    Local $avRval = DllCall($__g_hDll_JsonC, "ptr", "json_object_iter_peek_value", "ptr", $pIter)
    If @error Then Return SetError(1, @error, 0)

    Return $avRval[0] ; this is a json_object*
EndFunc

Func _JsonC_ObjectIterNext($tIter)
    Local $pIter = DllStructGetPtr($tIter)

    DllCall($__g_hDll_JsonC, "none", "json_object_iter_next", "ptr", $pIter)
;	$a="yo"
;	ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $a = ' & $a & @CRLF & '>Error code: ' & @error & @CRLF)
    If @error Then Return SetError(1, @error, 0)

	if DllStructGetData($tIter, 1) = 0 Then Return False

	Return True
EndFunc




#cs
Func _JsonC_ObjectIterGetName($pIterator)
	if IsPtr($pIterator) = False Then $pIterator = DllStructGetPtr($pIterator)
	Local $avRval = DllCall($__g_hDll_JsonC, "str", "json_object_iter_peek_name", "ptr", $pIterator)
	If @error Then Return SetError(1, @error, "") ; DllCall error
	Local $pChar = $avRval[0]
	;### Debug CONSOLE ???
	ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $pChar = ' & $pChar & @CRLF & '>Error code: ' & @error & @CRLF)
	Exit
    If $pChar = 0 Then Return ""


	;Local $avRval = DllCall($__g_hDll_JsonC, "str", "json_object_to_json_string", "ptr", $pChar)
;### Debug CONSOLE ???
;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : @error = ' & @error & @CRLF & '>Error code: ' & @error & @CRLF)
;Exit

    ; Convert char* ? AutoIt string
    Local $t = DllStructCreate("char[4096]", $pChar)
    ;### Debug CONSOLE ???
    ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $t = ' & $t & @CRLF & '>Error code: ' & @error & @CRLF)
	Local $fred = DllStructGetData($t, 1)
	;### Debug CONSOLE ???
	ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $fred = ' & $fred & @CRLF & '>Error code: ' & @error & @CRLF)
    Return DllStructGetData($t, 1)
EndFunc
#ce







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

;--------------------------------------------------------------------------------------------------------------------------------------
#Region Embedded DLL

; Standalone PE-in-memory loader based on trancexx's Subrogation technique.

; Entry point: load a DLL from a Binary() image using a subrogor module.
Func __JsonC_LoadBinaryDll($bBinaryImage, $sSubrogor = "explorer.exe")
    ; Make structure out of binary data that was passed
    Local $tBinary = DllStructCreate("byte[" & BinaryLen($bBinaryImage) & "]")
    DllStructSetData($tBinary, 1, $bBinaryImage)
    ; Get pointer to it
    Local $pPointer = DllStructGetPtr($tBinary)

    ; IMAGE_DOS_HEADER
    Local $tIMAGE_DOS_HEADER = DllStructCreate("char Magic[2];" & _
            "word BytesOnLastPage;" & _
            "word Pages;" & _
            "word Relocations;" & _
            "word SizeofHeader;" & _
            "word MinimumExtra;" & _
            "word MaximumExtra;" & _
            "word SS;" & _
            "word SP;" & _
            "word Checksum;" & _
            "word IP;" & _
            "word CS;" & _
            "word Relocation;" & _
            "word Overlay;" & _
            "char Reserved[8];" & _
            "word OEMIdentifier;" & _
            "word OEMInformation;" & _
            "char Reserved2[20];" & _
            "dword AddressOfNewExeHeader", _
            $pPointer)

    ; Move to PE header
    $pPointer += DllStructGetData($tIMAGE_DOS_HEADER, "AddressOfNewExeHeader")
    Local $sMagic = DllStructGetData($tIMAGE_DOS_HEADER, "Magic")
    If Not ($sMagic == "MZ") Then
        Return SetError(1, 0, 0)
    EndIf

    ; IMAGE_NT_SIGNATURE
    Local $tIMAGE_NT_SIGNATURE = DllStructCreate("dword Signature", $pPointer)
    $pPointer += 4
    If DllStructGetData($tIMAGE_NT_SIGNATURE, "Signature") <> 17744 Then
        Return SetError(2, 0, 0)
    EndIf

    ; IMAGE_FILE_HEADER
    Local $tIMAGE_FILE_HEADER = DllStructCreate("word Machine;" & _
            "word NumberOfSections;" & _
            "dword TimeDateStamp;" & _
            "dword PointerToSymbolTable;" & _
            "dword NumberOfSymbols;" & _
            "word SizeOfOptionalHeader;" & _
            "word Characteristics", _
            $pPointer)

    Local $iNumberOfSections = DllStructGetData($tIMAGE_FILE_HEADER, "NumberOfSections")
    $pPointer += 20

    ; Determine type (x86/x64)
    Local $tMagic = DllStructCreate("word Magic;", $pPointer)
    Local $iMagic = DllStructGetData($tMagic, 1)
    Local $tIMAGE_OPTIONAL_HEADER

    If $iMagic = 267 Then
        If @AutoItX64 Then Return SetError(3, 0, 0)
        $tIMAGE_OPTIONAL_HEADER = DllStructCreate("word Magic;" & _
                "byte MajorLinkerVersion;" & _
                "byte MinorLinkerVersion;" & _
                "dword SizeOfCode;" & _
                "dword SizeOfInitializedData;" & _
                "dword SizeOfUninitializedData;" & _
                "dword AddressOfEntryPoint;" & _
                "dword BaseOfCode;" & _
                "dword BaseOfData;" & _
                "dword ImageBase;" & _
                "dword SectionAlignment;" & _
                "dword FileAlignment;" & _
                "word MajorOperatingSystemVersion;" & _
                "word MinorOperatingSystemVersion;" & _
                "word MajorImageVersion;" & _
                "word MinorImageVersion;" & _
                "word MajorSubsystemVersion;" & _
                "word MinorSubsystemVersion;" & _
                "dword Win32VersionValue;" & _
                "dword SizeOfImage;" & _
                "dword SizeOfHeaders;" & _
                "dword CheckSum;" & _
                "word Subsystem;" & _
                "word DllCharacteristics;" & _
                "dword SizeOfStackReserve;" & _
                "dword SizeOfStackCommit;" & _
                "dword SizeOfHeapReserve;" & _
                "dword SizeOfHeapCommit;" & _
                "dword LoaderFlags;" & _
                "dword NumberOfRvaAndSizes", _
                $pPointer)
        $pPointer += 96
    ElseIf $iMagic = 523 Then
        If Not @AutoItX64 Then Return SetError(3, 0, 0)
        $tIMAGE_OPTIONAL_HEADER = DllStructCreate("word Magic;" & _
                "byte MajorLinkerVersion;" & _
                "byte MinorLinkerVersion;" & _
                "dword SizeOfCode;" & _
                "dword SizeOfInitializedData;" & _
                "dword SizeOfUninitializedData;" & _
                "dword AddressOfEntryPoint;" & _
                "dword BaseOfCode;" & _
                "uint64 ImageBase;" & _
                "dword SectionAlignment;" & _
                "dword FileAlignment;" & _
                "word MajorOperatingSystemVersion;" & _
                "word MinorOperatingSystemVersion;" & _
                "word MajorImageVersion;" & _
                "word MinorImageVersion;" & _
                "word MajorSubsystemVersion;" & _
                "word MinorSubsystemVersion;" & _
                "dword Win32VersionValue;" & _
                "dword SizeOfImage;" & _
                "dword SizeOfHeaders;" & _
                "dword CheckSum;" & _
                "word Subsystem;" & _
                "word DllCharacteristics;" & _
                "uint64 SizeOfStackReserve;" & _
                "uint64 SizeOfStackCommit;" & _
                "uint64 SizeOfHeapReserve;" & _
                "uint64 SizeOfHeapCommit;" & _
                "dword LoaderFlags;" & _
                "dword NumberOfRvaAndSizes", _
                $pPointer)
        $pPointer += 112
    Else
        Return SetError(3, 0, 0)
    EndIf

    ; Extract key fields
    Local $iSizeOfImage = DllStructGetData($tIMAGE_OPTIONAL_HEADER, "SizeOfImage")
    Local $iEntryPoint = DllStructGetData($tIMAGE_OPTIONAL_HEADER, "AddressOfEntryPoint")
    Local $pOptionalHeaderImageBase = DllStructGetData($tIMAGE_OPTIONAL_HEADER, "ImageBase")

    ; Data directories
    $pPointer += 8 ; skip export
    Local $tIMAGE_DIRECTORY_ENTRY_IMPORT = DllStructCreate("dword VirtualAddress; dword Size", $pPointer)
    Local $pAddressImport = DllStructGetData($tIMAGE_DIRECTORY_ENTRY_IMPORT, "VirtualAddress")
    Local $iSizeImport = DllStructGetData($tIMAGE_DIRECTORY_ENTRY_IMPORT, "Size")
    $pPointer += 8
    $pPointer += 24 ; skip resource/exception/security

    Local $tIMAGE_DIRECTORY_ENTRY_BASERELOC = DllStructCreate("dword VirtualAddress; dword Size", $pPointer)
    Local $pAddressNewBaseReloc = DllStructGetData($tIMAGE_DIRECTORY_ENTRY_BASERELOC, "VirtualAddress")
    Local $iSizeBaseReloc = DllStructGetData($tIMAGE_DIRECTORY_ENTRY_BASERELOC, "Size")
    $pPointer += 8
    $pPointer += 40 ; debug/copyright/globalptr/tls/load_config
    $pPointer += 40 ; five more unused

    ; Load subrogor
    Local $pBaseAddress_OR = _WinAPI_LoadLibraryEx($sSubrogor, 1)
    Local $pBaseAddress = $pBaseAddress_OR
    If @error Then Return SetError(4, 0, 0)

    Local $bCleanLoad = __JsonC_UnmapViewOfSection($pBaseAddress)
    If $bCleanLoad Then
        $pBaseAddress = _MemVirtualAlloc($pBaseAddress, $iSizeOfImage, $MEM_RESERVE + $MEM_COMMIT, $PAGE_READWRITE)
    EndIf
    If @error Or $pBaseAddress = 0 Then
        $pBaseAddress = $pBaseAddress_OR
        $bCleanLoad = False
    EndIf

    Local $pHeadersNew = DllStructGetPtr($tIMAGE_DOS_HEADER)
    Local $iOptionalHeaderSizeOfHeaders = DllStructGetData($tIMAGE_OPTIONAL_HEADER, "SizeOfHeaders")

    ; Write headers
    __JsonC_VirtualProtect($pBaseAddress, $iOptionalHeaderSizeOfHeaders, $PAGE_READWRITE)
    If @error Then
        _WinAPI_FreeLibrary($pBaseAddress)
        Return SetError(6, 0, 0)
    EndIf

    DllStructSetData(DllStructCreate("byte[" & $iOptionalHeaderSizeOfHeaders & "]", $pBaseAddress), 1, _
        DllStructGetData(DllStructCreate("byte[" & $iOptionalHeaderSizeOfHeaders & "]", $pHeadersNew), 1))

    ; Sections
    Local $tIMAGE_SECTION_HEADER
    Local $iSizeOfRawData, $pPointerToRawData
    Local $iVirtualSize, $iVirtualAddress
    Local $tImpRaw, $tRelocRaw

    For $i = 1 To $iNumberOfSections
        $tIMAGE_SECTION_HEADER = DllStructCreate("char Name[8];" & _
                "dword VirtualSize;" & _
                "dword VirtualAddress;" & _
                "dword SizeOfRawData;" & _
                "dword PointerToRawData;" & _
                "dword PointerToRelocations;" & _
                "dword PointerToLinenumbers;" & _
                "word NumberOfRelocations;" & _
                "word NumberOfLinenumbers;" & _
                "dword Characteristics", _
                $pPointer)

        $iSizeOfRawData = DllStructGetData($tIMAGE_SECTION_HEADER, "SizeOfRawData")
        $pPointerToRawData = $pHeadersNew + DllStructGetData($tIMAGE_SECTION_HEADER, "PointerToRawData")
        $iVirtualAddress = DllStructGetData($tIMAGE_SECTION_HEADER, "VirtualAddress")
        $iVirtualSize = DllStructGetData($tIMAGE_SECTION_HEADER, "VirtualSize")
        If $iVirtualSize And $iVirtualSize < $iSizeOfRawData Then $iSizeOfRawData = $iVirtualSize

        __JsonC_VirtualProtect($pBaseAddress + $iVirtualAddress, $iVirtualSize, $PAGE_EXECUTE_READWRITE)
        If @error Then
            $pPointer += 40
            ContinueLoop
        EndIf

        DllStructSetData(DllStructCreate("byte[" & $iVirtualSize & "]", $pBaseAddress + $iVirtualAddress), 1, _
            DllStructGetData(DllStructCreate("byte[" & $iVirtualSize & "]"), 1))

        If $iSizeOfRawData Then
            DllStructSetData(DllStructCreate("byte[" & $iSizeOfRawData & "]", $pBaseAddress + $iVirtualAddress), 1, _
                DllStructGetData(DllStructCreate("byte[" & $iSizeOfRawData & "]", $pPointerToRawData), 1))
        EndIf

        If $iVirtualAddress <= $pAddressImport And $iVirtualAddress + $iSizeOfRawData > $pAddressImport Then
            $tImpRaw = DllStructCreate("byte[" & $iSizeImport & "]", $pPointerToRawData + ($pAddressImport - $iVirtualAddress))
            __JsonC_FixImports($tImpRaw, $pBaseAddress)
        EndIf

        If $iVirtualAddress <= $pAddressNewBaseReloc And $iVirtualAddress + $iSizeOfRawData > $pAddressNewBaseReloc Then
            $tRelocRaw = DllStructCreate("byte[" & $iSizeBaseReloc & "]", $pPointerToRawData + ($pAddressNewBaseReloc - $iVirtualAddress))
        EndIf

        $pPointer += 40
    Next

    ; Relocations
    If $pAddressNewBaseReloc And $iSizeBaseReloc Then
        __JsonC_FixReloc($tRelocRaw, $pBaseAddress, $pOptionalHeaderImageBase, $iMagic = 523)
    EndIf

    ; Entry point
    Local $pEntryFunc = $pBaseAddress + $iEntryPoint
    If $iEntryPoint Then
        DllCallAddress("bool", $pEntryFunc, "ptr", $pBaseAddress, "dword", 1, "ptr", 0)
    EndIf

    ; Pseudo handle
    Local $hPseudo = DllOpen($sSubrogor)
    If $bCleanLoad Then _WinAPI_FreeLibrary($pBaseAddress)
    __JsonC_DeattachSubrogor($sSubrogor)
    Return $hPseudo
EndFunc


Func __JsonC_FixReloc($tData, $pAddressNew, $pAddressOld, $fImageX64)
    Local $iDelta = $pAddressNew - $pAddressOld
    Local $iSize = DllStructGetSize($tData)
    Local $pData = DllStructGetPtr($tData)
    Local $tIMAGE_BASE_RELOCATION, $iRelativeMove
    Local $iVirtualAddress, $iSizeofBlock, $iNumberOfEntries
    Local $tEnries, $iData, $tAddress
    Local $iFlag = 3 + 7 * $fImageX64

    While $iRelativeMove < $iSize
        $tIMAGE_BASE_RELOCATION = DllStructCreate("dword VirtualAddress; dword SizeOfBlock", $pData + $iRelativeMove)
        $iVirtualAddress = DllStructGetData($tIMAGE_BASE_RELOCATION, "VirtualAddress")
        $iSizeofBlock = DllStructGetData($tIMAGE_BASE_RELOCATION, "SizeOfBlock")
        $iNumberOfEntries = ($iSizeofBlock - 8) / 2
        $tEnries = DllStructCreate("word[" & $iNumberOfEntries & "]", DllStructGetPtr($tIMAGE_BASE_RELOCATION) + 8)

        For $i = 1 To $iNumberOfEntries
            $iData = DllStructGetData($tEnries, 1, $i)
            If BitShift($iData, 12) = $iFlag Then
                $tAddress = DllStructCreate("ptr", $pAddressNew + $iVirtualAddress + BitAND($iData, 0xFFF))
                DllStructSetData($tAddress, 1, DllStructGetData($tAddress, 1) + $iDelta)
            EndIf
        Next

        $iRelativeMove += $iSizeofBlock
    WEnd
    Return 1
EndFunc


Func __JsonC_FixImports($tData, $hInstance)
    Local $pImportDirectory = DllStructGetPtr($tData)
    Local $hModule, $pFuncName, $tFuncName, $sFuncName, $pFuncAddress
    Local $tIMAGE_IMPORT_MODULE_DIRECTORY, $pModuleName, $tModuleName
    Local $tBufferOffset2, $iBufferOffset2
    Local $iInitialOffset, $iInitialOffset2, $iOffset
    Local Const $iPtrSize = DllStructGetSize(DllStructCreate("ptr"))

    While 1
        $tIMAGE_IMPORT_MODULE_DIRECTORY = DllStructCreate("dword RVAOriginalFirstThunk;" & _
                "dword TimeDateStamp;" & _
                "dword ForwarderChain;" & _
                "dword RVAModuleName;" & _
                "dword RVAFirstThunk", _
                $pImportDirectory)

        If Not DllStructGetData($tIMAGE_IMPORT_MODULE_DIRECTORY, "RVAFirstThunk") Then ExitLoop

        $pModuleName = $hInstance + DllStructGetData($tIMAGE_IMPORT_MODULE_DIRECTORY, "RVAModuleName")
        $tModuleName = DllStructCreate("char Name[" & _WinAPI_StringLenA($pModuleName) & "]", _
                $hInstance + DllStructGetData($tIMAGE_IMPORT_MODULE_DIRECTORY, "RVAModuleName"))
        $hModule = _WinAPI_LoadLibrary(DllStructGetData($tModuleName, "Name"))

        $iInitialOffset = $hInstance + DllStructGetData($tIMAGE_IMPORT_MODULE_DIRECTORY, "RVAFirstThunk")
        $iInitialOffset2 = $hInstance + DllStructGetData($tIMAGE_IMPORT_MODULE_DIRECTORY, "RVAOriginalFirstThunk")
        If $iInitialOffset2 = $hInstance Then $iInitialOffset2 = $iInitialOffset
        $iOffset = 0

        While 1
            $tBufferOffset2 = DllStructCreate("ptr", $iInitialOffset2 + $iOffset)
            $iBufferOffset2 = DllStructGetData($tBufferOffset2, 1)
            If Not $iBufferOffset2 Then ExitLoop

            If BitShift(BinaryMid($iBufferOffset2, $iPtrSize, 1), 7) Then
                $pFuncAddress = __JsonC_GetProcAddress($hModule, BitAND($iBufferOffset2, 0xFFFF))
            Else
                $pFuncName = $hInstance + $iBufferOffset2 + 2
                $tFuncName = DllStructCreate("word Ordinal; char Name[" & _WinAPI_StringLenA($pFuncName) & "]", _
                        $hInstance + $iBufferOffset2)
                $sFuncName = DllStructGetData($tFuncName, "Name")
                $pFuncAddress = __JsonC_GetProcAddress($hModule, $sFuncName)
            EndIf

            DllStructSetData(DllStructCreate("ptr", $iInitialOffset + $iOffset), 1, $pFuncAddress)
            $iOffset += $iPtrSize
        WEnd

        $pImportDirectory += 20
    WEnd
    Return 1
EndFunc


Func __JsonC_UnmapViewOfSection($pAddress)
    Local $aCall = DllCall("ntdll.dll", "int", "NtUnmapViewOfSection", _
            "handle", _WinAPI_GetCurrentProcess(), _
            "ptr", $pAddress)
    If @error Or $aCall[0] Then Return SetError(1, 0, False)
    Return True
EndFunc


Func __JsonC_VirtualProtect($pAddress, $iSize, $iProtection)
    Local $aCall = DllCall("kernel32.dll", "bool", "VirtualProtect", "ptr", $pAddress, "dword_ptr", $iSize, "dword", $iProtection, "dword*", 0)
    If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
    Return 1
EndFunc


Func __JsonC_GetProcAddress($hModule, $vName)
    Local $sType = "str"
    If IsNumber($vName) Then $sType = "word"
    Local $aCall = DllCall("kernel32.dll", "ptr", "GetProcAddress", "handle", $hModule, $sType, $vName)
    If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
    Return $aCall[0]
EndFunc


Func __JsonC_DeattachSubrogor($sSubrogor, $sNewName = Default)
    If $sNewName = Default Then $sNewName = "~L" & Random(100, 999, 1) & ".img"

    Local $tPROCESS_BASIC_INFORMATION = DllStructCreate("dword_ptr ExitStatus;" & _
            "ptr PebBaseAddress;" & _
            "dword_ptr AffinityMask;" & _
            "dword_ptr BasePriority;" & _
            "dword_ptr UniqueProcessId;" & _
            "dword_ptr InheritedFromUniqueProcessId")

    Local $aCall = DllCall("ntdll.dll", "long", "NtQueryInformationProcess", _
            "handle", _WinAPI_GetCurrentProcess(), _
            "dword", 0, _
            "ptr", DllStructGetPtr($tPROCESS_BASIC_INFORMATION), _
            "dword", DllStructGetSize($tPROCESS_BASIC_INFORMATION), _
            "dword*", 0)
    If @error Then Return SetError(1, 0, 0)

    Local $pPEB = DllStructGetData($tPROCESS_BASIC_INFORMATION, "PebBaseAddress")

    Local $tPEB_Small = DllStructCreate("byte InheritedAddressSpace;" & _
            "byte ReadImageFileExecOptions;" & _
            "byte BeingDebugged;" & _
            "byte Spare;" & _
            "ptr Mutant;" & _
            "ptr ImageBaseAddress;" & _
            "ptr LoaderData;", _
            $pPEB)

    Local $pPEB_LDR_DATA = DllStructGetData($tPEB_Small, "LoaderData")

    Local $tPEB_LDR_DATA = DllStructCreate("byte Reserved1[8];" & _
            "ptr Reserved2;" & _
            "ptr InLoadOrderModuleList[2];" & _
            "ptr InMemoryOrderModuleList[2];" & _
            "ptr InInitializationOrderModuleList[2];", _
            $pPEB_LDR_DATA)

    Local $pPointer = DllStructGetData($tPEB_LDR_DATA, "InMemoryOrderModuleList", 2)
    Local $pEnd = $pPointer
    Local $tLDR_DATA_TABLE_ENTRY, $sModule

    While 1
        $tLDR_DATA_TABLE_ENTRY = DllStructCreate("ptr InMemoryOrderModuleList[2];" & _
                "ptr InInitializationOrderModuleList[2];" & _
                "ptr DllBase;" & _
                "ptr EntryPoint;" & _
                "ptr Reserved3;" & _
                "word LengthFullDllName;" & _
                "word LengtMaxFullDllName;" & _
                "ptr FullDllName;" & _
                "word LengthBaseDllName;" & _
                "word LengtMaxBaseDllName;" & _
                "ptr BaseDllName;", _
                $pPointer)

        $pPointer = DllStructGetData($tLDR_DATA_TABLE_ENTRY, "InMemoryOrderModuleList", 2)
        If $pPointer = $pEnd Then ExitLoop

        $sModule = DllStructGetData(DllStructCreate("wchar[" & DllStructGetData($tLDR_DATA_TABLE_ENTRY, "LengthBaseDllName") / 2 & "]", _
                DllStructGetData($tLDR_DATA_TABLE_ENTRY, "BaseDllName")), 1)

        If $sModule = $sSubrogor Then
            DllStructSetData(DllStructCreate("wchar[" & DllStructGetData($tLDR_DATA_TABLE_ENTRY, "LengthBaseDllName") / 2 & "]", _
                    DllStructGetData($tLDR_DATA_TABLE_ENTRY, "BaseDllName")), 1, $sNewName)
            Return 1
        EndIf
    WEnd

    Return SetError(2, 0, 0)
EndFunc


Func __JsonC_Dll()
    Return Binary("0x" & _
        "4D5A90000300000004000000FFFF0000B800000000000000400000000000000000000000000000000000000000000000000000000000000000000000080100000E1FBA0E00B409CD21B8014CCD21546869732070726F6772616D2063616E6E6F74206265" & _
		"2072756E20696E20444F53206D6F64652E0D0D0A2400000000000000779C2A8B33FD44D833FD44D833FD44D83A85D7D827FD44D8B47445D931FD44D8B474B9D837FD44D8B47447D930FD44D8B47440D939FD44D8B47441D93FFD44D84A7C45D936FD44D8" & _
		"33FD45D877FD44D8A87440D93DFD44D8A87444D932FD44D8A874BBD832FD44D8A87446D932FD44D85269636833FD44D800000000000000000000000000000000504500004C010500FFF8276A0000000000000000E00002210B010E2C00820000003E0000" & _
		"00000000888700000010000000A00000000000100010000000020000060000000500040006000000000000000000010000040000000000000200400100001000001000000000100000100000000000001000000090B40000240E0000B4C2000018010000" & _
		"00E00000E00100000000000000000000000000000000000000F00000D806000060B0000054000000000000000000000000000000000000000000000000000000A0AF000040000000000000000000000000A0000020010000000000000000000000000000" & _
		"0000000000000000000000002E746578740000008D810000001000000082000000040000000000000000000000000000200000602E72646174610000322A000000A00000002C000000860000000000000000000000000000400000402E64617461000000" & _
		"3407000000D000000004000000B20000000000000000000000000000400000C02E72737263000000E001000000E000000002000000B60000000000000000000000000000400000402E72656C6F630000D806000000F000000008000000B8000000000000" & _
		"00000000000000004000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000053568B74240C578B5E0483FBFE77508B46088D7B013BF872343DFFFFFF7F730903C03BC70F42C78BF881FFFFFFFF3F772E8D04BD0000000050FF36FF1594A0001083C40885C074178906897E" & _
		"088B0E8B4424145F890499FF460433C05E5BC35F5E83C8FF5BC3CCCCCCCCCCCCCCCCCCCCFF74240C8B44240C6A04FF7004FF30FF742414FF1514A1001083C414C3CCCCCC8B4C240C8BC153558B6C2410F7D0573BE8775D8B7C24108D1C298B47043BE873" & _
		"4F3BD8774B568BF53BEB731B0F1F40008B078B04B085C07409508B470CFFD083C404463BF372E98B47048B0F2BC3C1E002508D0499508D04A950E8B87F00008B44242883C40C29470433C05E5F5D5BC35F5D83C8FF5BC3CCCCCCCCCCCCCCCCCC568B7424" & _
		"0C578B7C240C8B47083BF072343DFFFFFF7F730903C03BC60F42C68BF081FEFFFFFF3F77218D04B50000000050FF37FF1594A0001083C40885C0740A89078977085F33C05EC35F83C8FF5EC356578B7C240C33F6397704761B0F1F008B078B04B085C074" & _
		"09508B470CFFD083C404463B770472E8FF378B3590A00010FFD657FFD683C4085F5EC3CCCCCCCCCC8B4424048B4C24083B4804720333C0C38B008B0488C3CCCCCCCCCCCCCCCCCCCC568B742408578B7C24108B46043BF80F82A200000083FFFE0F87D900" & _
		"0000538B5E08558D6F013BEB723781FBFFFFFF7F72048BDDEB0703DB3BDD0F42DD81FBFFFFFF3F776A8D049D0000000050FF36FF1594A0001083C40885C074538906895E083B7E0473128B068B04B885C07409508B460CFFD083C4048B0E8B44241C8904" & _
		"B98B4E043BF976188BC72BC1C1E002508B066A008D048850E8507E000083C40C397E047703896E045D5B5F33C05EC35D5B5F83C8FF5EC383F8FF743B405056E88CFEFFFF83C40885C0752C8B068D0CB88B46042BC7C1E00250518D410450E8047E00008B" & _
		"0E83C40C8B4424148904B9FF460433C05F5EC35F83C8FF5EC3CCCCCC8B4424048B4004C3CCCCCCCCCCCCCCCC56578B7C241085FF784B81FFFFFFFF3F73436A10FF158CA000108BF083C40485F674328B4C240C894E0C8D0CBD0000000051897E08C74604" & _
		"00000000FF158CA0001083C404890685C0750F56FF1590A0001083C4045F33C05EC35F8BC65EC3CC535556578B7C241883FFFE0F87930000008B7424148D6F018B5E083BEB723781FBFFFFFF7F72048BDDEB0703DB3BDD0F42DD81FBFFFFFF3F776A8D04" & _
		"9D0000000050FF36FF1594A0001083C40885C074538906895E083B7E0473128B068B04B885C07409508B460CFFD083C4048B0E8B44241C8904B98B4E043BF976188BC72BC1C1E002508B066A008D048850E8EB7C000083C40C397E047703896E045F5E5D" & _
		"33C05BC35F5E5D83C8FF5BC3CCCCCCCC8B542408B8FFFFFF3F568B742408578B4E042BC13BD073428D3C113B7E087435760D5756E807FDFFFF83C4085F5EC3B80100000085FF0F44F88D04BD0000000050FF36FF1594A0001083C40885C0740A8906897E" & _
		"085F33C05EC35F83C8FF5EC3FF7424088B4424086A04FF7004FF30FF1518A1001083C410C3CCCCCCCCCCCCCCB828D70010C3CCCCCCCCCCCCCCCCCCCC833DACD2001000742D568B7424086A01FF15DCA0001083C4048D4C240C516A005650E8C9FFFFFFFF" & _
		"7004FF30FF15E0A0001083C4185EC3CCCCCCCCCCCCCCCCCC568B7424086A02FF15DCA0001083C4048D4C240C516A005650E892FFFFFFFF7004FF30FF15E0A0001083C4185EC3CCCCA1ACD20010C3CCCCCCCCCCCCCCCCCCCC8B442404A3ACD20010C3CCCC" & _
		"CCCCCCCC8B442404A3A8D20010C3CCCCCCCCCCCCB850A10010C3CCCCCCCCCCCCCCCCCCCCB800120000C3CCCCCCCCCCCCCCCCCCCC56578B7C241081FFE2FFFF7F7765B9210000008D471D83FF040F42C150FF158CA000108BF083C40485F6744757FF7424" & _
		"108D461CC70606000000C7460401000000C74608203C0010C7460C00000000C7461000000000C746140000000050897E18E8297B000083C40CC6443E1C008BC65F5EC35F33C05EC3CCCCCCCCCCCCCCCC538B5C240855568B7424185785DB0F84A7000000" & _
		"833B060F859E00000081FEFEFFFF7F0F83920000008B431885C0792985F67515FF731CFF1590A0001033D283C40489531833C0EB128B6B1C8D4B1C8BD0894C2414F7DAEB098BD08D6B1C896C24148BFE3BF27E2C8D460150FF158CA000108BE883C40485" & _
		"ED7440837B18008B7C24147D0BFF37FF1590A0001083C404892FEB0485C079048BFEF7DF56FF74241C55E8687A000083C40CC6042E00897B18B8010000005F5E5D5BC35F5E5D33C05BC3CCCCCCCCCCCCCCCCCCCCCCCCCCCC8B442404568B48148BF18D56" & _
		"010F1F008A064684C075F92BF25651FF742414E81C53000083C40C8BC65EC3CCCCCCCCCC8D44240C506A00FF742410FF742410E89CFDFFFFFF7004FF30FF15E0A0001083C418C3CCCCCCCCCCCCCCCCCCCCCCCCCC8B442404837818007D048B401CC383C0" & _
		"1CC3CCCCCCCCCCCCCCCCCCCCCCCCCCCC8B44240485C0741A506800A400106A02FF15DCA0001083C40450E891FFFFFF83C40CFF25BCA00010CCCCCCCCCCCCCCCC558BEC83E4F883EC148B4508535657FF7018E879FBFFFF8B7D0C8BF089742418FF7718E8" & _
		"68FBFFFF83C4083BF0757333DB895C241885F60F840C0200000F1F0053FF7718E827FAFFFF8BF88B450853FF7018E819FAFFFF8BD883C4103BDF0F84D101000085DB743A85FF74368B033B07753083F806772BFF2485881900108B431833C93B47180F94" & _
		"C1E99F010000F20F104318660F2E47189FF6C4440F8B9301000033C05F5E5B8BE55DC3837B18007537837F18008B432075123B472075E38B43243B472475DBE9690100008B4B2485C97CCF7F0485C072C93B472075C43B4F2475BFE94D010000837F1801" & _
		"75058B4320EBC78B4F248B472085C97CA57F0485C0729F394320759A394B247595E9230100008B4318998BF08B471833F22BF29933C22BC23BF00F8576FFFFFF57E87EFEFFFF538BD0E876FEFFFF83C4088BC883EE0472118B013B02751083C10483C204" & _
		"83EE0473EF83FEFC743D8A013A020F853EFFFFFF83FEFD742E8A41013A42010F852DFFFFFF83FEFE741D8A41023A42020F851CFFFFFF83FEFF740C8A41033A42030F850BFFFFFF8B742414E9950000008B43188B700885F6743E8B46088944241C8D4424" & _
		"1050FF36FF7718E8904F000083C40C85C07419FF742410FF742420E8BC0E000083C40885C074058B760CEBC68B74241433C9EB45833F04740433F6EB038B77188B760885F6741B8D44241050FF36FF7318E8464F000083C40C85C074CF8B760CEBE18B74" & _
		"2414B901000000EB0C5753E8D8FDFFFF83C4088BC885C90F846DFEFFFF8B5C24188B7D0C43895C24183BDE0F82F7FDFFFF5F5EB8010000005B8BE55DC30F1F0065190010AE170010BE170010DB170010D01800105119001042180010CCCCCCCCCCCCCCCC" & _
		"CCCCCCCCB818000000C3CCCCCCCCCCCCCCCCCCCC8B44240885C07544A1B0D2001085C0740A50FF1590A0001083C4048B44240485C0741F50FF15FCA0001083C40485C075136824A20010E82540000083C40483C8FFC333C0A3B0D2001033C0C383F80175" & _
		"116860A20010E80540000083C40483C8FFC35068B0A20010E8F33F000083C40883C8FFC3CCCCCCCCCCCCCCCCCCCCCCCC568B742418578B7C240C8B074883F8050F87B1000000FF2485241B0010FF7718E8EB170000EB75F20F10471883EC08F20F110424" & _
		"E82718000083C408EB618B471883E800741983E8010F858A000000FF7724FF7720E8461A000083C408EB40FF7724FF7720E80619000083C408EB308B4F188BC19933C22BC28D571C85C979028B125052E867FAFFFF83C408EB11E84D190000EB0A6A20E8" & _
		"0417000083C4048BC8890E85C97512FF15B8A000105F5EC7000C00000083C8FFC38B47085F894108B8010000005EC3FF15B8A000105F5EC7001600000083C8FFC36800A20010E8DDFBFFFF905D1A0010671A00107E1A0010CE1A0010D51A0010AF1A0010" & _
		"CCCCCCCC568B7424088D442414578B7C2410506A00FF74241C5756E804F9FFFF8B08FF700483C90151FF15ECA0001083C41CC6443EFF0083C9FF85C00F48C15F5EC3CCCC83EC10A140D2001033C48944240C8B44241C33C98B5424185633F68954240457" & _
		"8B7C241C85C00F8418020000535566908A1C32480FB6EB8944242C8D45F883F8540F87400100000FB680E01D0010FF2485D81D0010F644243010740980FB2F0F84BC0100003BF176128BC62BC1508D040A5057E8C84D000083C40C80FB08751C6A026880" & _
		"A1001057E8B34D00008B54241C83C40C468BCEE98601000080FB0A751C6A026884A1001057E8924D00008B54241C83C40C468BCEE96501000080FB0D751C6A026888A1001057E8714D00008B54241C83C40C468BCEE94401000080FB09751C6A02688CA1" & _
		"001057E8504D00008B54241C83C40C468BCEE92301000080FB0C751C6A026890A1001057E82F4D00008B54241C83C40C468BCEE90201000080FB22751C6A026894A1001057E80E4D00008B54241C83C40C468BCEE9E100000080FB5C751C6A026898A100" & _
		"1057E8ED4C00008B54241C83C40C468BCEE9C000000080FB2F0F85AD0000006A02689CA1001057E8C84C00008B54241C83C40C468BCEE99B00000080FB200F83910000003BF176128BC62BC1508D040A5057E89D4C000083C40C8B0D00D000108BC583E0" & _
		"0FC1ED040FBE0408500FBE04295068A0A100108D4424206A0750E8F1FDFFFF8B470883C4148B57042BC283F8067E298B0F8B442414890411668B442418668944110483470406468B4F048B078B542410C60401008BCEEB1A6A068D4424185057E82B4C00" & _
		"0083C40C8B542410468BCEEB01468B44242C85C00F8502FEFFFF5D5B3BF176102BF18D040A565057E8FF4B000083C40C8B4C241433C05F5E33CCE8F361000083C410C390D51B0010071D0010000000010000010101010101010101010101010101010101" & _
		"01010001010101010101010101010100010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100CCCCCCCCCCCCCCCCCCCCCC8B442404FF742408FF7018E8B0F1FFFF83C408C3CCCCCCCCCCCCCCCC" & _
		"CCCCCCCC8B442408FF74240CFF70188D44240C50E8FBF1FFFF83C40C85C07501C38B00C3FF74240C8B442408FF74240CFF7018E8FCF1FFFF83C40CC3CCCCCCCCCCCCCCCCE9DB1A0000CCCCCCCCCCCCCCCCCCCCCC8B442404FF742408FF7018E8E0F2FFFF" & _
		"83C408C3CCCCCCCCCCCCCCCCCCCCCCCCFF74240C8B442408FF74240CFF7018E8DCF2FFFF83C40CC3CCCCCCCCCCCCCCCC8B442404FF7018E8C4F3FFFF83C404C3FF74240C8B442408FF74240CFF7018E81CF4FFFF83C40CC3CCCCCCCCCCCCCCCC8B442408" & _
		"85C07811508B442408FF7018E8ABF4FFFF83C408C3683CA30010E8BDF7FFFFCCCCCCCCCCCCCCCCCCCCCCCCCC8B442404FF742408FF7018E8E0F4FFFF83C408C3CCCCCCCCCCCCCCCCCCCCCCCC83EC085355568B74241C576A016830A300105633FFE8364A" & _
		"00008B4424288B5C24348BEB83E502FF7018E821F3FFFF83C41085C00F84F80000008BC383E0038944241085ED74106A0168BCA1001056E8FC49000083C40C837C241001C74424140100000075106A0168C0A1001056E8DD49000083C40C85ED741F8B44" & _
		"242440F6C3087405506A09EB0503C0506A206AFF56E82A4A000083C4108B44241C57FF7018E88AF1FFFF83C40885C07543F6C320742C6A0768E0A1001056E8914900006A0468ACA1001056E8844900006A0468D0A1001056E87749000083C424EB276A04" & _
		"68ACA1001056E86549000083C40CEB158B4C242453415156508B4008FFD083C41085C078528B44241C47FF7018E83EF2FFFF83C4043BF873156A0168B8A1001056E82A49000083C40CE915FFFFFF8B7C241485ED744085FF743C6A0168BCA1001056E809" & _
		"49000083C40CF6C3087413FF7424246A09EB145F5E5D83C8FF5B83C408C38B44242403C0506A206AFF56E84D49000083C41080E30380FB0175186A026834A3001056E8C548000083C40C5F5E5D5B83C408C36A016838A3001056E8AD48000083C40C5F5E" & _
		"5D5B83C408C3CCCC568B742414578B7C241083E62074106A0768E0A1001057E88448000083C40C8B44240CBAF0A100108B48188BC1F7D81BC083C00585C950B8F8A100100F45C25057E85A48000083C40C83F8FF7E1485F674106A0468D0A1001057E841" & _
		"48000083C40C5F5EC3CCCCCCCCCCCCCCCCCCCCCC8B5424045685D274488B74240C85F67440833E00753B8B442410B9401A00105785C00F45C851566AFF6A006A0052E83D0000008BF883C41885FF7910FF36E8AD17000083C404C706000000008BC75F5E" & _
		"C3FF15B8A000105EC7001600000083C8FFC3CCCCCCCCCCCCCCCCCCCCCCCCCCCC83EC08558B6C2420578B7C241455FF742424FF742424FF74242457FF54243C83C4148944240C83F8017D15FF15B8A000105F5DC7001600000083C8FF83C408C38B075356" & _
		"83E8040F849201000083E8017578FF7718E866F0FFFF8BD883C40433F685DB74656666660F1F84000000000056FF7718C744241800000000E81FEFFFFF83C40885C0750833C9894C2410EB22FF7424308D4C241451566A005750E85DFFFFFF83C41885C0" & _
		"0F88D50000008B4C24108B450051FF7018E842EDFFFF83C40885C07855463BF372A6837C2414020F84750200008B4F148B750085C97509394F100F84620200008B46083D801600100F84250200003D801600100F841A0200005068B0A30010E814370000" & _
		"83C40883C8FF5E5B5F5D83C408C38B74241085F60F84EA010000834604FF0F85E00100008B461085C07409FF761456FFD083C4088B0683E8040F84AB01000083E801742683E8010F8437010000FF760CE83F46000056FF1590A0001083C40883C8FF5E5B" & _
		"5F5D83C408C3FF7618E8E2EDFFFFE97B0100008B74241085F60F8481010000834604FF0F85770100008B461085C07409FF761456FFD083C4088B0683E8040F844201000083E80174BD83E8010F84CE000000FF760CE8D645000056FF1590A0001083C408" & _
		"83C8FF5E5B5F5D83C408C38B47188B700885F60F84DDFEFFFF8B4E0833C08B1E8944241085C9741EFF7424308D442414506AFF535751E8F1FDFFFF83C41885C0781E8B4424105053FF7500E81C11000083C40C85C00F888E0000008B760CEBB18B742410" & _
		"85F60F84D0000000834604FF0F85C60000008B461085C07409FF761456FFD083C4088B0683E8040F849100000083E8010F8408FFFFFF83E801741DFF760CE82545000056FF1590A0001083C40883C8FF5E5B5F5D83C408C3837E18008B3D90A000107D08" & _
		"FF761CFFD783C404FF760CE8F444000056FFD783C40883C8FF5E5B5F5D83C408C38B74241085F6744B834604FF75458B461085C07409FF761456FFD083C4088B0683E804741483E8010F848BFEFFFF83E8010F8565FEFFFFEB9AFF7618E892400000FF76" & _
		"0CE89A44000056FF1590A0001083C40C5E5B5F83C8FF5D83C408C351FF15FCA0001083C40485C075186878A30010E8ED34000083C40483C8FF5E5B5F5D83C408C38946148B47108946105E5B5F33C05D83C408C3CCCCCCCCCCCCCCCCCCCCCCCC8B442404" & _
		"FF7014FF742414FF742414FF74241450E82700000083C414C3CCCCCC6A00FF742414FF742414FF742414FF742414E80900000083C414C3CCCCCCCCCC81EC90000000A140D2001033C48984248C0000008B842498000000538B9C24A800000055568BB424" & _
		"A00000008944240C57F20F104618660F2EC0F20F114424140F9AC03C01750768FCA20010EB33DD44241483EC08DD1C24E8DA6A000083C4086683F8017534F20F104618B800A30010660F2F0520A40010B90CA300100F46C1508D442420688000000050E8" & _
		"10F5FFFF83C40C8BF8E93A01000033ED85DB750FA1B0D20010BB18A3001085C00F45D8F20F1046188D44241C83EC08F20F11042453688000000050E8D4F4FFFF8BF883C41485FF0F88230100008D44241C6A2C50E82E6A00008BF083C40885F67405C606" & _
		"2EEB118D44241C6A2E50E8146A000083C4088BF081FB18A3001074126820A3001053E8026A000083C40885C07505BD010000008A44241C3C307C043C397E1383FF017E153C2D75118A44241D2C303C097707B801000000EB0233C083FF7E7D4485C07440" & _
		"85F675408D44241C6A6550E8AF69000083C40885C0757B85ED74778D4C241C498A41018D490184C075F666A124A3001083C702668901A026A30010884102EB4085F67440F68424B00000000474368A4E01468BD684C974200F1F400080F9308BC28A4A01" & _
		"0F44C6428BF084C975EE8A0E84C9740446C606008BFE8D44241C2BF885FF782481FF80000000B87F0000000F4DF8578D44242050FF742418E82B42000083C40C8BC7EB0383C8FF8B8C249C0000005F5E5D5B33CCE81558000081C490000000C3CCCCCCCC" & _
		"CCCCCCCC53568B742410578B7C24103BFE0F848600000085FF745B85F674578B073B06755183F806774CFF2485982900108B4F1833C03B4E185F5E0F94C05BC3F20F104718BA01000000660F2E46185F5E5B9F33C9F6C4440F4BCA8BC1C3837F18008B56" & _
		"1875218B4F208B472485D2750B3B4E2074225F5E33C05BC385C07CF67FEF85C972F0EBE983FA0175198B47203B462075E18B47243B462475D95F5EB8010000005BC38B4E248B462085C97CC67F0485C072C039472075BB394F24EBDB8B4718998BD88B46" & _
		"1833DA2BDA9933C22BC23BD875A056E848EEFFFF578BD0E840EEFFFF83C4088BC883EB047217660F1F4400008B013B02751083C10483C20483EB0473EF83FBFC74938A013A020F8562FFFFFF83FBFD74848A41013A42010F8551FFFFFF83FBFE0F846FFF" & _
		"FFFF8A41023A42020F853CFFFFFF83FBFF0F845AFFFFFF8A41033A4203E94DFFFFFF8B4718558B580885DB74368B6B088D44241850FF33FF7618E8593F000083C40C85C07416FF74241855E888FEFFFF83C40885C074058B5B0CEBCD5D5F5E33C05BC383" & _
		"3E04740433F6EB038B76188B7608660F1F44000085F6741B8D44241850FF36FF7718E80D3F000083C40C85C074CA8B760CEBE15D5F5EB8010000005BC35657E8A0EDFFFF83C4085F5E5BC39059280010ED270010FC2700101A2800100A29001089290010" & _
		"7C280010CCCCCCCCCCCCCCCCCCCCCCCCFF742408FF1590A0001059C3CCCCCCCC8B44240485C07501C3FF4004C3CCCCCC8B44240485C0750333C0C383380575F88B4018C3CCCCCCCCCCCCCCCCCCCCCCCC8B54240485D274558B0A4983F905774DFF248D6C" & _
		"2A00108B4218C38B421883E800740583E80175388B42200B4224742DB801000000C3F20F104218BA01000000660F2E0520A400109F33C9F6C4440F4ACA8BC1C333C03942180F95C0C333C0C36800A20010E896ECFFFF6690172A0010362A00101B2A0010" & _
		"5D2A00105D2A0010542A0010CCCCCCCCCCCCCCCCCCCCCCCC83EC14568B74241CC74424040000000085F60F842C0100008B064883F8050F8714010000FF2485E82B0010DD46185E83C414C38B461883E800742383E8010F85070100008B56248B4E20E891" & _
		"560000F20F11442408DD4424085E83C414C38B56248B4E20E8C7560000F20F11442408DD4424085E83C414C3DB46185EDD5C2404DD44240483C414C3538B1DB8A0001057FFD38D7E1CC70000000000837E18007D048B07EB028BC78D4C240C5150FF1570" & _
		"A00010DD54242083C408837E1800DD5424107D028B3F8B44240C3BC774058038007413DDD8FFD3D9EEC700160000005F5B5E83C414C3F20F100540A40010F20F104C2410660F2EC19FF6C4447B12F20F100558A40010660F2EC19FF6C4447ACFDDD8FFD3" & _
		"83382275145F0F57C0F20F1144240CDD44240C5B5E83C414C3DD4424185F5B5E83C414C3FF15B8A00010C70016000000D9EE5E83C414C36800A20010E81BEBFFFF0F1F00082B0010BB2A0010C32A0010C82B0010C82B0010182B001083EC088B44240C0F" & _
		"57C0660F1304245685C00F84D90000008B0883F9037525837818008B50208B7024745181FEFFFFFF7F7249770583FAFF724283CAFFBEFFFFFF7FEB3883F906752B837818008D481C7D028B098D4424045051E8E131000083C40885C00F85870000008B74" & _
		"24088B542404EB178B7424088B54240483E901746883E901742983E901756683FEFF7C327F0881FA00000080762885F67F387C0881FAFFFFFF7F732E8BC25E83C408C3F20F104818F20F100548A40010660F2FC1720AB8000000805E83C408C3660F2F0D" & _
		"28A40010720AB8FFFFFF7F5E83C408C3F20F2CC15E83C408C38B40185E83C408C333C05E83C408C3CCCCCCCCCCCCCCCC8B4C240483EC0885C90F84B90000008B014883F8050F87AD000000FF2485DC2D00108B411883E800742683E8010F859D0000008B" & _
		"51248B412081FAFFFFFF7F77280F828500000083F8FF731D83C408C38B41208B512483C408C3F20F104918660F2F0D30A40010720C83C8FFBAFFFFFF7F83C408C3F20F100550A40010660F2FC1720B33C0BA0000008083C408C30F28C183C408E9275300" & _
		"008B41189983C408C3837918008D411C7D028B008D0C245150E88A30000083C40885C0750B8B04248B54240483C408C333C033D283C408C36800A20010E826E9FFFF6690992D00105A2D0010222D0010C82D0010C82D0010A12D0010CCCCCCCCCCCCCCCC" & _
		"CCCCCCCC8B44240485C0750333C0C383380475F88B4018C3CCCCCCCCCCCCCCCCCCCCCCCC568B74240885F6750433C05EC3833E06743A8B460C5733FF85C0750CE88F3C000089460C85C0741F50E8D23C00008B46086A016A00FF760C56FFD083C41485C0" & _
		"78058B460C8B388BC75F5EC3837E18008D461C7D028B005EC3CCCCCCCCCCCCCC8B44240485C0750333C0C383380675F88B40189933C22BC2C3CCCCCCCCCCCCCC8B44240485C07501C38B00C3CCCCCCCC8B4C240483EC0885C974368B014883F805772EFF" & _
		"24855C2F00108B411883E800740F83E801757B8B41208B512483C408C38B51248B412085D27C067F0885C0730433C033D283C408C3F20F104118660F2F0538A40010720A83C8FF83CAFF83C408C30F57C9660F2FC877D683C408E96D5100008B41189983" & _
		"C408C3837918008D411C7D028B008D0C245150E8702F000083C40885C075AA8B04248B54240483C408C36800A20010E8A4E7FFFF232F0010F92E0010CA2E0010F12E0010F12E00102B2F0010CCCCCCCCCCCCCCCCCCCCCCCC8B44240485C074048B4014C3" & _
		"33C0C3CC8B4C24048B542408568B74241085C90F844F0100008339030F85460100008B411853555783E8000F84AD00000083E8010F853201000085F67C327F0485D2742C8BC68BFAF7D0F7D7394124721F770539792076185F5D5BC74120FFFFFFFFB801" & _
		"000000C74124FFFFFFFF5EC38BEA8BFEF7DD83D700F7DF85F60F8FD50000007C0885D20F83CB0000008B59248B41203BDF773372043BC5731B03C2C74118000000005F13DE8941205D895924B8010000005B5EC33BDF0F829800000077083BC50F828E00" & _
		"000003C25F13DE8941205D895924B8010000005B5EC385F67C477F0485D274378B592483CDFF8B79202BEAB8FFFFFF7F1BC63BD87C217F043BFD761B03FAC7411801000000897920B8010000005F13DE5D8959245B5EC385F67F357C0485D2732F33FFB8" & _
		"000000802BFA1BC63941247F1F7C0539792073185F5D5BC7412000000000B801000000C74124000000805EC3015120B8010000005F1171245D5B5EC333C05EC36800A20010E8FEE5FFFFCCCCCCCCCCCCCCCCCCCCCCCCCCCC83EC1CA140D2001033C48944" & _
		"24188B442420568B742428FF702483781800FF70208D44240C75076814A20010EB05681CA200106A1550E8F5E9FFFF8D4C241883C4148D51018A014184C075F92BCA8D442404515056E8563800008B4C242883C40C5E33CCE84D4E000083C41CC3CCCCCC" & _
		"8B4C240433C085C97508394424080F94C0C38B093B4C24080F94C0C3CCCCCCCC568B742408837E0400750BFF36FF1590A0001083C404FF7608E8C207000083C4045EC3CCCCCCCCCCCCCCCCCCCCCCCCCC6A20E80900000083C404C3CCCCCCCCCC566A1CFF" & _
		"158CA000108BF083C40485F6744BFF742408C7060500000068A01E0010C7460401000000C74608701F0010C7460C00000000C7461000000000C7461400000000E8A7E0FFFF83C40889461885C0750E56FF1590A0001083C40433C05EC38BC65EC3CCCCCC" & _
		"CCCCCCCCCCCCCCCC6A1CFF158CA000108BC883C40485C974338B442404C70101000000C7410401000000C7410820210010C7410C00000000C7411000000000C74114000000008941188BC1C333C0C3CCCCCCCCCCCCCCCCCC6A20FF158CA0001083C40485" & _
		"C07435F20F10442404C70002000000C7400401000000C7400C00000000C7401000000000C7401400000000C7400880250010F20F114018C333C0C3CCCCCCCCCCCCCCCCCC566A20FF158CA000108BF083C40485F60F8491000000F20F1044240857FF7424" & _
		"14C70602000000C7460401000000C7460C00000000C7461000000000C7461400000000C7460880250010F20F114618FF15FCA000108BF883C40485FF7523FF760CE84A36000056FF1590A0001083C408FF15B8A000105F5EC7000C00000033C0C38B4610" & _
		"85C07409FF761456FFD083C408897E148BC65FC74610C0290010C74608801600105EC333C05EC3CCCCCCCCCC8B442404995250E80400000083C408C36A28FF158CA000108BD083C40485D274418B4424048B4C2408C70203000000C7420401000000C742" & _
		"0810310010C7420C00000000C7421000000000C74214000000008942208BC2894A24C7421800000000C333C0C3CCCCCCCCCCCCCCCCCCCCCC33C0C3CCCCCCCCCCCCCCCCCCCCCCCCCC566A1CFF158CA000108BF083C40485F6745D68A03100106A10C70604" & _
		"000000C7460401000000C7460800370010C7460C00000000C7461000000000C7461400000000E8E92F000083C40889461885C07522FF760CE82735000056FF1590A0001083C408FF15B8A00010C7000C00000033C05EC38BC65EC3CCCCCCCCCCCCCCCCCC" & _
		"8B5424048BC2568D7001660F1F4400008A084084C975F92BC65052E870E0FFFF83C4085EC3CCCCCCCCCCCCCCCCCCCCCCE95BE0FFFFCCCCCCCCCCCCCCCCCCCCCC6A28FF158CA000108BD083C40485D274418B4424048B4C2408C70203000000C742040100" & _
		"0000C7420810310010C7420C00000000C7421000000000C74214000000008942208BC2894A24C7421801000000C333C0C3CCCCCCCCCCCCCCCCCCCCCC538B5C2408558B6C2410568B431857558B4018FFD05055FF731889442424E89D3200008B7C242C83" & _
		"C4108BF03BDF75085F5E5D83C8FF5BC385F6752555FF15FCA0001083C40485C074E656FF7424185750FF7318E83730000083C4145F5E5D5BC38B460885C0740950E8D203000083C404897E0833C05F5E5D5BC3CCCCCCCCCC53558B6C240C56578B7C2418" & _
		"8B4518578B4018FFD08BC883C4048B442420894C2414A802740433F6EB135157FF7518E80C3200008BF083C40C8B4424208B5C241C3BEB744D85F6752FA804751057FF15FCA000108BF883C4048B44242085FF743150FF7424185357FF7518E8A02F0000" & _
		"83C4145F5E5D5BC38B460885C0740950E83B03000083C4045F895E0833C05E5D5BC35F5E5D83C8FF5BC3CCCCCCCCCCCC8B442404FF742408FF7018E8002E000083C408C3CCCCCCCCCCCCCCCCCCCCCCCC518B442408C704240000000085C0741E83380475" & _
		"198D0C2451FF742410FF7018E8DB3100008B44240C83C40C59C333C059C3CCCCCCCCCCCCCCCCCCCCCCCCCCCC8B44240C85C07406C700000000008B4C240485C9740F833904740D85C07406C7000000000033C0C350FF74240CFF7118E88B31000083C40C" & _
		"C3CCCCCCCCCCCCCC83EC10538B5C242455568B742424576A0168B4A100105633FFE8A23200008B44243083C40C85C0740C833804740433C0EB038B40188B68088BCB83E1028BD383E203894C242489542414660F1F44000085ED0F849D0100008B450089" & _
		"4424108B45088944241885FF74146A0168B8A1001056E8493200008B4C243083C40C85C974106A0168BCA1001056E83132000083C40C8BC3C744241C0100000024033C0175106A0168C0A1001056E81132000083C40C8B44242C40837C242400741AF6C3" & _
		"087405506A09EB0503C0506A206AFF56E85B32000083C4108BFB83E72074106A0768C4A1001056E8D431000083C40C6A0168CCA1001056E8C43100008B4C241C83C40C8D51018A014184C075F9532BCA51FF74241856E865E3FFFF6A0168CCA1001056E8" & _
		"9831000083C41C85FF74106A0468D0A1001056E88431000083C40C8BC3B9D8A1001083E0018D400150B8DCA100100F45C15056E8643100008B4C242483C40C85C9755E85FF743A6A0768E0A1001056E8483100006A0468ACA1001056E83B3100006A0468" & _
		"D0A1001056E82E3100008B6D0C83C4248B7C241C8B4C2424E9ABFEFFFF6A0468ACA1001056E80E3100008B6D0C83C40C8B7C241C8B4C2424E98BFEFFFF8B44242C5340508B41085651FFD083C41085C078108B6D0C8B7C241C8B4C2424E966FEFFFF5F5E" & _
		"5D83C8FF5B83C410C38B5424148BC285C9744985FF74456A0168BCA1001056E8B030000083C40CF6C3087418FF74242C6A096AFF56E80A3100008BC383C41083E003EB188B44242C03C0506A206AFF56E8EF3000008B44242483C41083F80175186A0268" & _
		"E8A1001056E86630000083C40C5F5E5D5B83C410C36A0168ECA1001056E84E30000083C40C5F5E5D5B83C410C3CCCCCC568B74240885F6747C834604FF75768B461085C07409FF761456FFD083C4088B0683E804743E83E801742F83E80175113946187D" & _
		"0CFF761CFF1590A0001083C404FF760CE8D72F000056FF1590A0001083C408B8010000005EC3FF7618E87ED7FFFFEB08FF7618E8A42B0000FF760CE8AC2F000056FF1590A0001083C40CB8010000005EC333C05EC3CCCCCCCCCCCCCC8B4C240485C97412" & _
		"833901750D8B442408894118B801000000C333C0C3CCCCCC8B44240485C0742E833802752981780880160010F20F10442408F20F114018750F6A006A006A0050E87300000083C410B801000000C333C0C3CCCCCCCCCCCCCC8B4C240485C9741D83390375" & _
		"188B44240899894120B801000000895124C7411800000000C333C0C3CCCCCCCCCCCCCCCC8B54240485D27420833A03751B8B4424088B4C240C894220B801000000894A24C7421800000000C333C0C3CCCCCCCCCC568B742408578B461085C07409FF7614" & _
		"56FFD083C4088B4424148946148B4424188946108B44241085C075548B0683F8067750FF2485583B00105FC74608000000005EC35FC74608202100105EC35FC74608802500105EC35FC74608103100105EC35FC74608003700105EC35FC74608701F0010" & _
		"5EC35FC74608203C00105EC38946085F5EC366900A3B0010143B00101E3B0010283B0010323B00103C3B0010463B0010CCCCCCCCCCCCCCCCCCCCCCCC8B5424088BC2568D7001660F1F4400008A084084C975F92BC65052FF742410E80CDAFFFF83C40C5E" & _
		"C3CCCCCCCCCCCCCCE9FBD9FFFFCCCCCCCCCCCCCCCCCCCCCC8B54240485D27420833A03751B8B4424088B4C240C894220B801000000894A24C7421801000000C333C0C3CCCCCCCCCC568B7424088B461085C07409FF761456FFD083C4088B44240C894614" & _
		"8B4424108946105EC3CCCCCCCCCCCCCCCCCCCCCC538B5C2414568B742410578B7C24108B47188944241083E32074106A076828A3001056E8782D000083C40C6A0168CCA1001056E8682D000083C40C8D4F1C837F18007D028B098B442410FF74241C9933" & _
		"C22BC2505156E805DFFFFF6A0168CCA1001056E8382D000083C41C85DB74106A0468D0A1001056E8242D000083C40C5F5E33C05BC3CCCCCCCCCCCCCCCCCCCCCC568B74240885F67507B8ACA100105EC38B460C85C0750CE8042E000089460C85C0742150" & _
		"E8472E00008B46086A016A00FF760C56FFD083C41485C078078B460C5E8B00C333C05EC3CCCCCCCCCCCCCCCC568B74240885F67507B8ACA100105EC38B460C85C0750CE8B42D000089460C85C0742350E8F72D0000FF7424108B46086A00FF760C56FFD0" & _
		"83C41485C078078B460C5E8B00C333C05EC3CCCCCCCCCCCC53568B74240C33DB5733FF85F6750A8D5F04BFACA10010EB378B460C85C0750CE85B2D000089460C85C0742450E89E2D0000FF7424188B46086A00FF760C56FFD083C41485C078088B460C8B" & _
		"58048B388B44241885C0740289188BC75F5E5BC3FF742404E847F0FFFF83C4048B4008C3A1B4D20010C3CCCCCCCCCCCCCCCCCCCC8B4424048B4C24088B1033C03B110F94C0C3CCCCCCCCCCCCCCCCCCCCCCCCCCCC8B4C24048B018B400C8901C3CCCCCCCC" & _
		"8B4424048B008B00C3CCCCCCCCCCCCCC8B4424048B008B4008C3CCCCCCCCCCCC8B44240483F81077088B048508D00010C3B840A60010C3CCCCCCCCCCCCCCCCCC578B7C240857E8451B00008B470483C40485C0740950E8452B000083C404FF772CFF1590" & _
		"A0001057FF1590A0001083C4085FC3CCCCCCCCCCCCCCCCCCCCCCCCCC8B4424048B401CC3CCCCCCCCCCCCCCCC8B4424048B4018C3CCCCCCCCCCCCCCCC6A20E80900000083C404C3CCCCCCCCCC568B3588A00010576A346A01FFD68BF883C40885FF75035F" & _
		"5EC3538B5C24106A1453FFD683C40889472C85C0751057FF1590A0001083C40433C05B5F5EC3E8DD2B000089470485C07517FF772C8B3590A00010FFD657FFD683C40833C05B5F5EC357895F08E8761A000083C4048BC75B5F5EC3CCCCCCCCCCCCCCCCCC" & _
		"CCCCCCCC518D042450FF74240CE8D219000083C40CC3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC558BEC83E4C083EC74538B5D085633F6C744244800000000837D10FF57C64424" & _
		"22018974242C8974245889731889731C0F8C021800008B7D0C751A8BCF8D51018A014184C075F92BCA81F9FFFFFF7F0F87E3170000A19CA000106A006A0489442464FFD08B0DFCA0001083C408894C246485C0741C50FFD183C4048944245885C0750EC7" & _
		"431C100000005F5E5B8BE55DC36894A600106A04FF542464A104A1001083C4088A54242289442440A100A1001089442448A1B8A0001089442450A190A00010894424388B4510F30F100DA8A60010F30F1005B8A600103943180F8444160000F643301074" & _
		"498A0F85F6753680F980723E8AC124E03CC07507BE01000000EB2F8AC124F03CE07507BE02000000EB2080E1F880F9F00F85D2140000BE03000000EB0D80E1C080F9800F85BF1400004E8A178B4B0C8B7B2C885424228974242C8D04898B048783F81A0F" & _
		"87841400008974242CFF2485B85700108B7D0C9080FA20741380FA09740E80FA0A740980FA0D0F859B0000008B43184740897D0C89431884D20F84C01500003B45100F8493150000F6433010746E8A0F85F6755780F98072638AC124E03CC07511BE0100" & _
		"00008AD18974242C88542422EBA28AC124F03CE075118A17BE020000008974242C88542422EB8980E1F880F9F00F850D1400008A17BE030000008974242C88542422E969FFFFFF80E1C080F9800F85ED1300004E8974242C8A1788542422E94DFFFFFF80" & _
		"FA2F750AF64330010F84340A00008B430C8B4B2C8D14808B449104890491E9FF0900000FBEC283C0DE83F8590F87B61300000FB68048580010FF2485245800108D0489C704871A000000FF7304E84A290000C7431400000000E9B10900008D0489C70487" & _
		"03000000FF7304E82C290000C7431400000000E9930900008D0489C704870D000000FF7304E80E290000C7431400000000E9750900008D0489C704870E000000FF7304E8F0280000C7431000000000E95709000085C90F84771400008D0489FF74870CE8" & _
		"80E7FFFF8B4B0C894424508D34898B4B2CC704B1000000008B4B2CC744B104010000008B432CFF74B00CE805F7FFFF8B432CC744B00C000000008B432CFF74B010FF5424448B432C83C40CC744B01000000000FF4B0C8B74242CE9EB0800008B431483F8" & _
		"080F8DA90000008B7D0C660F1F4400008A0F3A886CA400107416F64330010F85981200003A8878A400100F858C120000FF431840894314478B4510897D0C3943180F84A0130000F643301074498A0F85F6753680F980723E8AC124E03CC07507BE010000" & _
		"00EB2F8AC124F03CE07507BE02000000EB2080E1F880F9F00F852E120000BE03000000EB0D80E1C080F9800F851B1200004E8A178B43148974242C8854242283F8080F8C64FFFFFF8974242C8B4304837804007E078B0080382D74030F28C1F30F5AC08B" & _
		"430C83EC088B732CF20F1104248D3C80E813EFFFFF83C4088944BE0C8B430C8B4B2C8D0480837C810C000F842D120000C7448104020000008B430C8B74242C8D0C808B432CC7048800000000E9CD0700006A018D44242650FF7304E8E825000083C40C85" & _
		"C00F88F21100008B7B148D4B1447894C243483FF047D0B83FF037D0B897C243CEB0DBF04000000C744243C03000000F643300175198B430457FF306860A40010FF54244C83C40C85C074238D4B148B4304578B7C244C894C2458FF30894C243C6860A400" & _
		"10FFD783C40C85C075468B4C24348B0183F8040F854B0800008B430C8D0C808B432CC744880C000000008B430C8D0C808B432CC7448804020000008B430C8D0C808B432CC7048800000000E906070000F64330018B74243C75168B430456FF306888A400" & _
		"10FF54244C83C40C85C074188B430456FF306888A40010FFD783C40C85C00F85B01000008B4C24548B0183F8030F85CD070000F20F1005B0A60010E993FEFFFF84D2740980FA5C0F84BB0700006A03684CD00010FF7304E8C024000083C40C85C00F88CA" & _
		"1000008B430C8B4B2CC7432400000000C74320000000008D1480C74314000000008B449104890491E96106000084D2740980FA750F84900B00006A03684CD00010FF7304E86F24000083C40C85C00F88791000008B430CC7432400000000C74320000000" & _
		"00C74314000000008D0C808B432CC7048809000000E9100600006A018D44242650FF7304E82B24000083C40C85C00F88351000008B7B148D73144783FF047D048BC7EB11B8040000008944243C83FF057C078D78018944243CF6433001751D508B4304FF" & _
		"306890A40010FF54244C83C40C85C074218B44243C8D7314508B430489742458FF306890A40010FF54245483C40C85C075238B0683F8040F85AE0600008B430C8B732C6A018D3C80E833ECFFFF83C404E96BFDFFFFF643300175168B430457FF30689CA4" & _
		"0010FF54244C83C40C85C0741A8B430457FF30689CA40010FF54245483C40C85C00F85290F00008B4C24548BF18B0183F8050F854F0600008B430C8B732C6A008D3C80E8D4EBFFFF83C404E90CFDFFFF8B450C33C98944245433FF33C0894C2430894424" & _
		"3C8B4304C7442434010000003948047E5D6A65FF30E8014A00008BD083C40885D275158B43046A45FF30E8EC4900008BD083C40885D2742E8B4304BF01000000C744243001000000C7442434010000008B48048B004803C13BD0740AC744243400000000" & _
		"33FF8B4C24308A54242284D20F84030100008B450C80FA307C0580FA397E3685C9750A80FA65742D80FA457428837C243400740580FA2D741C85FF740580FA2B7413837B10000F85C900000080FA2E0F85C0000000FF44243C33FF897C243480FA2E741A" & _
		"80FA45740580FA657520B901000000894C24308BF9894B10EB0CC7431001000000BF01000000897C24344089450C8B43184089431884D20F841C0E00003B45100F84F30D0000F643301074508B4D0C8A0985F6753680F980723E8AC124E03CC07507BE01" & _
		"000000EB2F8AC124F03CE07507BE02000000EB2080E1F880F9F00F85AC0D0000BE03000000EB0D80E1C080F9800F85990D00004E8B4C24308B450C8974242C8A108854242284D20F8500FFFFFF837B0C007E3680FA2C743180FA5D742C80FA7D742780FA" & _
		"2F742280FA49741D80FA69741880FA20741380FA09740E80FA0A740980FA0D0F85A40D00008B4C243C85C97E2051FF742458FF7304E85E2100008A54242E83C40C85C00F88D10300008B4C243C8B7B048B0780382D752B83F9017F2680FA69740580FA49" & _
		"751C8B430C8D0C808B432CC704881A000000C7431400000000E9EC020000837B10008BCF744DF6433001753D837F04017E3766908B57048B378A4432FF3C65740E3C45740A3C2D74068BCF3C2B7516C64432FF008B4304FF48048B4B048BF9837904017F" & _
		"CF8A542422837B10000F85FC0000008B0180382D75478D4C24705150E82F15000083C40885C07531FF542450833822750AF64330010F85B60C00008B430CFF7424748B732CFF7424748D3C80E86FEAFFFF83C408E9FE0000008A542422837B10000F85A4" & _
		"0000008B43048B0080382D0F848C0000008D4C24785150E84015000083C40885C07576FF542450833822750AF64330010F85570C00008B4C24788BC18B54247C0BC274148B43048B00803830750AF64330010F85350C000081FAFFFFFF7F7724720583F9" & _
		"FF771D8B430C8B732C5251894C24788D3C808954247CE8DDE9FFFF83C408EB6F8B430C8B732C52518D3C80E8F8EAFFFF83C408EB5A8A542422837B10000F84F60B00008B43048B308B78048D4424605056FF1570A000108D043E83C408DD5C24683B4424" & _
		"600F85CA0B00008B430CF20F104424688B732C8D3C808B4304FF3083EC08F20F110424E8ACE8FFFF83C40C8944BE0C8B4B0C8B532C8D0489837C820C000F84760B00008D0489C744820402000000E941F9FFFF80FA5D0F844B0200008B4308483BC80F8D" & _
		"790B00008D0489C7048710000000FF430C8B430C8D34808B432CC704B0000000008B432CC744B004010000008B432CFF74B00CE8C8EEFFFF8B432CC744B00C000000008B432CFF74B010FF5424408B432C83C408C744B010000000008B74242CE9B10000" & _
		"00FF74244C8D0489FF74870CE84BD3FFFF83C40885C00F85D50A00008B430C8D0C808B432CC744880411000000E965F9FFFF8B4308483BC80F8DDB0A00008D0489C7048716000000E95DFFFFFFFF74244C8D0489FF748710FF74870CE8FBE9FFFF83C40C" & _
		"85C00F85850A00008B430C8D0C808B432CFF748810FF54243C8B430C8D0C808B432CC7448810000000008B430C8D0C808B432CC7448804170000008B430C8D0C808B432CC704880000000083C404F30F100DA8A60010F30F1005B8A600108B4B0C8B7B2C" & _
		"8A5424228D04898B048783F81A0F8786090000FF2485B8570010FF7304E8521F00006A018D44242A50FF7304E8E31D000083C41085C00F88ED0900008B430C8D0C808B432CC7048804000000E9440900008D0489C70487000000008B430C8D0C808B432C" & _
		"C7448804120000008B430C8B732C8D3C80E8FAE7FFFF8944BE0C8B430C8A5424228D0C808B432C837C880C000F8503090000C7431C10000000E96D0A00008D0489C70487000000008B430C8D0C808B432CC74488040F0000008B430C8B732C8D3C80E859" & _
		"E5FFFFEBADF64330010F85E90800008D0489C7048708000000FF7304E88B1E00008A54242683C404885328E9A1080000408901E9950800008D0489C704870C000000E986080000408906E97E0800008D04896A00FF74870CE84FD2FFFF8B430C83C4088B" & _
		"4B2C8D0480833C8118750AF64330010F851C090000C744810402000000E93708000080FA2A7507BA05000000EB0E80FA2F0F8506090000BA060000008D04898914878D4424226A0150FF7304E8971C00008A54242E83C40C85C00F880AFFFFFFE9080800" & _
		"008B450C8BF880FA2A0F84890000000F1F4400004089450C8B43184089431884D20F84FB0800003B45100F84C5080000F64330108B550C74498A0A85F6753680F980723E8AC124E03CC07507BE01000000EB2F8AC124F03CE07507BE02000000EB2080E1" & _
		"F880F9F00F8577080000BE03000000EB0D80E1C080F9800F85640800004E8A128B450C8974242C8854242280FA2A75808974242C8B450C2BC7405057FF7304E8DC1B000083C40C85C00F88E60700008B430C8D0C808B432CC7048807000000E93D070000" & _
		"8B450C8BF880FA0A0F84840000004089450C8B43184089431884D20F84390800003B45100F8403080000F64330108B550C74498A0A85F6753680F980723E8AC124E03CC07507BE01000000EB2F8AC124F03CE07507BE02000000EB2080E1F880F9F00F85" & _
		"B5070000BE03000000EB0D80E1C080F9800F85A20700004E8A128B450C8974242C8854242280FA0A75808974242C8B450C2BC75057FF7304E81B1B000083C40C85C00F8825070000E97C0600006A018D44242650FF7304E8FC1A000083C40C85C00F8806" & _
		"070000807C24222F8B430C8D0C808B432C0F8457060000C7048805000000E9520600008B4D0C8BF93A53280F84A30000000F1F0080FA5C0F84EC0000008B4B30F6C101740980FA1F0F8E500700008B4318FF450C4089431884D20F84320700003B45100F" & _
		"84FC060000F6C110744C8B450C8A0885F6753680F980723E8AC124E03CC07507BE01000000EB2F8AC124F03CE07507BE02000000EB2080E1F880F9F00F85AF060000BE03000000EB0D80E1C080F9800F859C0600004E8B4D0C8974242C8A11885424223A" & _
		"53280F8564FFFFFF8974242C2BCF5157FF7304E8141A000083C40C85C00F881E0600008B4304FF7004FF30E80CE5FFFF8B4B0C83C4088D14898B4B2C8944910C8B430C8B4B2C8D0480837C810C000F84ED050000C744810402000000E93C0500002BCF51" & _
		"57FF7304E8BF19000083C40C85C00F88C90500008B430C8D0C808B432CC7448804080000008B430C8D0C808B432CC7048809000000E90F0500000FBEC283C0DE83F8530F87290600000FB680B4580010FF2485A45800108D4424226A0150FF7304E86219" & _
		"000083C40C85C00F886C0500008B430C8B4B2C8D14808B449104890491E9C304000080FA6275096A016898A60010EBCA80FA6E75096A0168BCA10010EBBC80FA7275096A01689CA60010EBAE80FA7475096A0168A0A60010EBA080FA6675AE6A0168A4A6" & _
		"0010EB92C7432000000000C74314000000008D0489C704870A000000E96004000084D20F848105000080FA307C0580FA397E1A80FA417C0580FA467E0B8D429F3C050F876205000080FA397F080FBEFA83EF30EB090FBEFA83E70783C7098B4314B90300" & _
		"00002BC840C1E102D3E78D4B200B39893989431483F8040F8D9B0000008B7D0CFF4318478B4510897D0C3943180F8440050000F643301074748A0F85F6755D80F98072698AC124E03CC07514BE010000008AD18974242C88542422E95DFFFFFF8AC124F0" & _
		"3CE075148A17BE020000008974242C88542422E941FFFFFF80E1F880F9F00F85B40300008A17BE030000008974242C88542422E921FFFFFF80E1C080F9800F85940300004E8974242C8A1788542422E905FFFFFF8B5324C743140000000085D274598BC7" & _
		"2500FC00003D00DC0000752281E2FF030000C743240000000083C24081E7FF030000C1E20A03D789118D5320EB2B6A03684CD00010FF7304E89717000083C40C85C00F88A10300008D4B20C74324000000008D5320EB028BD18B0981F980000000730D88" & _
		"4C24238D442423E9F7FDFFFF8BC181F900080000731EC1E80680E13F0CC080C980884424248D442424884C24256A02E9D1FDFFFF2500FC00003D00D80000751E8B430C894B24C702000000008D0C808B432CC704880B000000E9930200003D00DC000075" & _
		"0C6A03684CD00010E995FDFFFF81F900000100732D8BC1C1E80C0CE0884424288BC1C1E80680E13F243F0C8080C980884424298D442428884C242A6A03E95FFDFFFF81F90000110073B78BC1C1E81224070CF0884424448BC1C1E80C243F0C8088442445" & _
		"8BC1C1E80680E13F243F0C8080C980884424468D442444884C24476A04E91BFDFFFF80FA5D75278D04896A00FF74870CE8D3CBFFFF8B430C83C4088D0C808B432CC744880402000000E9CB01000080FA2C0F85040300008D0489C744870418000000E9B2" & _
		"01000080FA7D75208D0489833C8719750AF64330010F85D5010000C744870402000000E98D01000080FA22740980FA270F85CA020000FF7304885328E8631700008B430C83C4048D0C808B432CC7048813000000E96C0100008B450C8BF83A53280F8491" & _
		"00000080FA5C0F84D90000004089450C8B43184089431884D20F845F0200003B45100F8429020000F64330108B550C74498A0A85F6753680F980723E8AC124E03CC07507BE01000000EB2F8AC124F03CE07507BE02000000EB2080E1F880F9F00F85DB01" & _
		"0000BE03000000EB0D80E1C080F9800F85C80100004E8A128B450C8974242C885424223A53280F8573FFFFFF8974242C8B450C2BC75057FF7304E83D15000083C40C85C00F88470100008B430C8B732C8D3C808B4304FF30FF5424688944BE1083C4048B" & _
		"430C8B4B2C8D0480837C8110000F841A010000C744810414000000EB6C8B450C2BC75057FF7304E8EC14000083C40C85C00F88F60000008B430C8D0C808B432CC744880413000000E928FBFFFF80FA3A0F85870100008D0489C744870415000000EB2680" & _
		"FA7D750D8D0489C744870402000000EB1480FA2C0F85680100008D0489C7448704190000008B430C8D0C808B432CC70488000000008A5424228B7D0CFF431847897D0C84D20F84640100008B74242CE9D7EAFFFFC7431C0E000000E94F010000C7431C04" & _
		"000000E943010000C7431C05000000E933010000C7431C06000000E927010000C7431C0E000000EB20837B0C0075128B432C833800750A83780402750433C0EB05B80100000089431C8B44243C50FF742458FF7304E8F613000083C40C85C00F89E20000" & _
		"00C7431C10000000E9D6000000C7431C07000000E9CA0000008A542422C7431C07000000E9BE000000C7431C02000000E9B2000000C7431C04000000E9A2000000C7431C0D000000E99A0000008B450C2BC7C7431C0E0000005057EB91837B0C00751F8B" & _
		"432C833800751783780402751133C089431C8B450C2BC75057E96CFFFFFFB80100000089431C8B450C2BC75057E958FFFFFFC7431C0C000000EB48C7431C08000000EB3FC7431C09000000EB36C7431C0A000000EB2DC7431C0B000000EB24837B0C0075" & _
		"128B432C833800750A83780402750433C0EB05B80100000089431C8A5424228B4330A810740E837C242C007407C7431C0E0000008B7B0C8B732C8D0CBF84D27419833C8E02752785FF752324033C01751DC7431C04000000EB14833C8E02740E837C8E04" & _
		"027407C7431C030000008B742458566A04FF54246456FF54244483C40C837B1C000F85880000008B430C8D0C808B432CFF74880CE897D2FFFF8B7B0C83C4048944246485FF786A8D34BFC1E6020F1F008B432CC70406000000008B432CC7443004010000" & _
		"008B432CFF74300CE80FE2FFFF8B432CC744300C000000008B432CFF743010FF5424408B432C8D76EC83C40883EF01C74430240000000079B38B4424645F5E5B8BE55DC3C7431C0F00000033C05F5E5B8BE55DC3CC400010A74100103C420010C9430010" & _
		"FA4C00103D4D0010044E0010B54E0010EF4E001032500010E1500010E44400103545001086450010844600106F4A0010E54A00103A5300107F530010D5530010F5540010164B0010314B00100B5500106F4A00107F530010AB420010834C0010794C0010" & _
		"1E42001000420010C4410010E24100104E4C0010FD4B00106C550010000808080801080808080802080802020202020202020202080808080808080808080808030808040808080805080808080803080808080808060808080808080808080803080804" & _
		"08080808050808080808030808080808080766904F5000107E500010C45000106A56001000030303030303030303030303000303030303030303030303030303030303030303030303030303030303030303030303030303030303030303000303030303" & _
		"0103030301030303030303030103030301030102CCCCCCCCCCCCCCCC576A20E898E5FFFF8BF883C40485FF750E8B44240C5FC7001000000033C0C3536AFFFF74241057E834E6FFFF8B4C241C83C40C8B571C8BD88911837F1C00740F85DB740953E826E0" & _
		"FFFF83C40433DB57E82B0000008B470483C40485C0740950E82B10000083C404FF772CFF1590A0001057FF1590A0001083C4088BC35B5FC3568B74240885F67473538B5E0C85DB785C558B2D90A00010578D3C9BC1E702908B462CC70407000000008B46" & _
		"2CC7443804010000008B462CFF74380CE8AFDFFFFF8B462CC744380C000000008B462CFF743810FFD58B462C8D7FEC83C40883EB01C74438240000000079B55F5DC7460C00000000C7461C000000005B5EC3CCCC8B4424048B4C2408894830C3CCCCCCCC" & _
		"8D442408506A00FF74240C680001000068B8D20010E826BAFFFF8B08FF700483C90151FF15ECA0001083C41CC605B7D3001000C3CCCCCCCCCCCCCCCCCCCCCCCC8B442410B9C4A8001053FF74241085C0FF7424100F45C8894C241CE880E2FFFF8BD883C4" & _
		"0885DB750583C8FF5BC3568BF38D4E018A064684C075F95557BF000000002BF174278B6C2414660F1F4400008BC62BC7508D041F5055FF15E4A0001083C40C85C0780D03F83BFE72E35F5D5E33C05BC3FF15B8A00010FF30E85F12000050FF74242868CC" & _
		"A80010E830FFFFFF83C41083C8FF5F5D5E5BC3CCCCCCCCCC6AFFFF742408E80500000083C408C3CCB804100000E8F6260000A140D2001033C48984240010000053E8A20F00008BD885DB752568E8A60010E8E2FEFFFF83C40433C05B8B8C240010000033" & _
		"CCE87424000081C404100000C355568BB42418100000B82000000083FEFF0F44F056E83DE3FFFF8BE883C40485ED753CFF15B8A00010FF30E8B711000050566818A70010E88BFEFFFF53E8050E000083C41433C05E5D5B8B8C240010000033CCE8152400" & _
		"0081C404100000C38BB424141000008D44240C5768001000005056FF15E8A000108BF883C40C85FF7E35660F1F440000578D4424145053E8D40D000083C40C85C0784A68001000008D4424145056FF15E8A000108BF883C40C85FF7FD385FF795CFF15B8" & _
		"A00010FF30E822110000505668B4A70010E8F6FDFFFF55E810E2FFFF53E86A0D000083C41833C0EB6FFF15B8A000108B7304FF30E8F31000005057566860A70010E8C6FDFFFF55E8E0E1FFFF53E83A0D000083C41C33C0EB3FFF7304FF3355E8F8E2FFFF" & _
		"8BF083C40C85F6751A55E8F9E1FFFF50E893E1FFFF5068E8A70010E888FDFFFF83C41055E89FE1FFFF53E8F90C000083C4088BC68B8C24101000005F5E5D5B33CCE80823000081C404100000C3CCCCCCCCCCCCCCCCCCCCCC568B742408576A0056FF15F0" & _
		"A000108BF883C40885FF7921FF15B8A00010FF30E84B1000005056680CA80010E81FFDFFFF83C41033C05F5EC36AFF57E8FFFDFFFF578BF0FF15F4A0001083C40C8BC65F5EC3CCCCCCCCCCCCCCCCCCCCCCCCCCCC8B44240885C0751168A0A80010E8DEFC" & _
		"FFFF83C40483C8FFC36A00FF74241050FF742410E807FDFFFF83C410C3CCCCCC6A00FF74240CFF74240CE81100000083C40CC3CCCCCCCCCCCCCCCCCCCCCCCCCC578B7C240C85FF75126840A80010E88DFCFFFF83C40483C8FF5FC355568B74241068A401" & _
		"0000680103000056FF15F0A000108BE883C40C85ED7923FF15B8A00010FF30E8780F00005056686CA80010E84CFCFFFF83C41083C8FF5E5D5FC35356FF7424205755E875FCFFFF8B3DB8A000108BD8FFD7558B30FF15F4A0001083C414FFD789308BC35B" & _
		"5E5D5FC3CCCCCCCC51568B74240C8D4424045056FF1570A000108B44241883C408DD1833C0397424045E0F94C059C3CCCCCCCCCCCCCCCCCC515356578B3DB8A00010C744240C00000000FFD78B5C24146A0AC700000000008D4424105053FF1574A00010" & _
		"8B74241883C40C3BF374098B4C241889018951040BC2750BFFD783380075088B74240C3BF37512FFD75F5E5BC70016000000B80100000059C35F5E33C05B59C3CCCCCCCC51538B1DB8A0001056C744240800000000FFD38B742410C700000000008A063C" & _
		"2075088A4601463C2074F83C2D75095EB8010000005B59C3576A0A8D4424105056FF1578A000108B7C241883C40C3BFE74098B4C241889018951040BC2750BFFD383380075088B7C240C3BFE7512FFD35F5E5BC70016000000B80100000059C35F5E33C0" & _
		"5B59C3CCCCCCCCCCCCCCCCCC8B44240483F80677088B048550D00010C36A075068FCA80010E8C2FAFFFF83C40C33C0C3CCCCCCCCCCCCCCCCCCCCCCCC33C9B8B8D20010380DB8D200100F44C1C3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC538B5C241C558B6C" & _
		"241C578B7C241053FF742420FF742420FF7424206A0057FFD583C4183DFF0200000F8F610100000F849A00000083F8FF0F849100000085C00F85600100005657E8C3CEFFFF83C40483F8060F8723010000FF24855861001057E80ACEFFFF83C4048B7008" & _
		"0F1F400085F60F84B50000008B068B4E088B760C53556A00505751E874FFFFFF83C4183DFF0200000F84930000003DBB1E0000742D83F8FF742885C074C63D7B1D000074BF50686CA900106A02FF15DCA0001083C40450E858B6FFFF83C40C83C8FF5E5F" & _
		"5D5BC357E887BEFFFF8BF033C983C404894C242485F674455157E831BEFFFF53558D4C2434516A005750E801FFFFFF83C4203DFF02000074243DBB1E000074BE83F8FF74B985C074073D7B1D000075918B4C242441894C24243BCE72BB53FF742424FF74" & _
		"2424FF7424246A0257FFD583C4183DFF0200007F16740D83F8FF0F847AFFFFFF85C075195E5F5D33C05BC33D7B1D000074F23DBB1E00000F845DFFFFFF506830A90010E93BFFFFFF57E88ECDFFFF83C404506898A90010E927FFFFFF3D7B1D00000F8434" & _
		"FFFFFF3DBB1E00000F8429FFFFFF506830A900106A02FF15DCA0001083C40450E863B5FFFF83C40C83C8FF5F5D5BC390E8600010E8600010E8600010E8600010F05F001063600010E8600010CCCCCCCCCCCCCCCCCCCCCCCCFF742410FF7424106A006A00" & _
		"6A00FF742418E8F9FDFFFF83C4183D7B1D00007F14740F85C0740B3DFF020000740483C8FFC333C0C32DBB1E0000F7D81BC0C3CC833D70D00010FF751F0F1F8000000000E8AB0A00008BC883F9FF74F4BA70D0001083C8FFF00FB10A8B5424048BCA568D" & _
		"71018A014184C075F9A170D000102BCE505152E80800000083C40C5EC3CCCCCC8B4C240C8B54240881C1EFBEADDE558B6C240803CA568BF189742414578BF983FA0C0F86E200000083C2F3B8ABAAAAAAF7E2538BC2C1E80340894424140F1F000FB67507" & _
		"0FB645060FB6550BC1E60803F0C1E2080FB64505C1E60803F00FB6450403F8C1E6080FB6450A03FE0FB6750803D00FB6450903F10FB64D03C1E20803D0C1E1080FB6450203C8C1E2080FB6450103F2C1E1088BDE03C8C1CB1C0FB6450083C50CC1E10803" & _
		"C82BCE03F7034C241C33D92BFB8BC3C1C81A03DE33C72BF08BD0C1CA1803C333D68BF22BDAC1CE1003D033F38BFE2BC6C1CF0D03F233F88974241C2BD78BCFC1C91C03FE33CA8B54241883EA0C836C241401895424180F853CFFFFFF5B83FA0C776EFF24" & _
		"95D46300100FB6450BC1E01803C80FB6450AC1E01003C80FB64509C1E00803C80FB6450803C80FB64507C1E01803F80FB64506C1E01003F80FB64505C1E00803F80FB6450403F80FB64503C1E01803F00FB64502C1E01003F00FB64501C1E00803F00FB6" & _
		"450003F08974241833CF8BC7C1C8122BC88BC18BF133742418C1C8152BF033FE8BC6C1C8072BF88BC733CFC1C8102BC88BC18BD1C1C81C33D62BD08BC233FAC1C8122BF88BC733CFC1C8082BC85F5E8BC15DC390CD6300107E630010756300106C630010" & _
		"636300105D630010546300104B630010426300103C630010336300102A63001021630010CCCCCCCCCCCCCCCC8B4C24088B4424048A103A11752084D274128A50013A5101751483C00283C10284D275E433C933C085C90F94C0C31BC933C083C90185C90F" & _
		"94C0C3CCCCCCCCCC6810640010FF356CD00010FF742410FF742410E85804000083C410C3CCCCCCCC5356FF7424108B74241056E8000300008BD883C40885DB75065E83C8FF5BC38BCBB8676666662B4E10F7E957C1FA038BFAC1EF1F03FA79095F5EB8FE" & _
		"FFFFFF5BC38B4610558D2CBFC1E5028B042883F8FF0F84C100000083F8FE0F84B8000000FF4E048B461485C0740653FFD083C4048B4610C7442808000000008B4610C70428FEFFFFFF8B46108B560C03C53BD075153946087510C7460C00000000C74608" & _
		"00000000EB4F8B4E083BC875158B410CC74010000000008B46088B400C894608EB333BD075158B4210C7400C000000008B460C8B401089460CEB1A8B48108B400C89410C8D0CBF8B46108B54880C8B4488108942108B46108D0CBF5DC744881000000000" & _
		"8D0CBF8B46105F5E5BC744880C0000000033C0C35D5F5E83C8FF5BC356578B7C240C837F140074178B770885F674108B471456FFD08B760C83C40485F675F0FF77108B3590A00010FFD657FFD683C4085F5EC3CCCCCCCCCCCCCCCCCC535556578B7C2414" & _
		"8B07660F6E4F04F30FE6C9660F6EC0F30FE6C0F20F5905D8A90010660F2FC80F82910000003DFFFFFF3F7E11BDFFFFFF7F3BC5750B5F5E5D83C8FF5BC38D2C00FF771CFF77186A0055E89A0200008BD883C41085DB74DE8B770885F67433FF368B4318FF" & _
		"D033C9BA04000000394E040F45CA5150FF7608FF3653E879FFFFFF83C41885C00F85B30000008B760C85F675CDFF77108B3590A00010FFD68B4310894710892F8B43088947088B430C5389470CFFD683C4088B44242033D28B1FF7F38B4F108BF18D0492" & _
		"833C81FF741C8D0492833C81FE74138D420133D23BC30F45D08D0492833C86FF75E48B4424188D14928B4C2424C1E20283E1048904328B4710894C10048B4F108B44241C894411088B4F10FF470403CA837F08007555894F0C894F08C74110000000008B" & _
		"47105F5E5DC744100C0000000033C05BC3837B140074178B730885F674108B431456FFD08B760C83C40485F675F0FF73108B3590A00010FFD653FFD683C40883C8FF5F5E5D5BC38B470C89480C8B4F108B470C894411108B4710C744100C000000008B47" & _
		"1003C289470C33C05F5E5D5BC3CCCCCCCCCCCCCCCCCCCCCC53558B6C241056578B7C2414558B4718FFD08B0F33D2F7F183C40433DB8BF285C97E408B47108D0CB68B048883F8FF743283F8FE740E55508B471CFFD083C40885C075268B078D4E01433BD8" & _
		"7D1533F63BC88B47100F45F18D0CB68B048883F8FF75CE5F5E5D33C05BC38B47108D0CB65F5E5D8D04885BC3CCCCCCCCCCCCCCCC8B44240C33D2535556578B7C241433DB8B0FF7F18BF285C97E488B47108D0CB68B048883F8FF743A8B6C24180F1F4000" & _
		"83F8FE740E55508B471CFFD083C40885C075268B078D4E01433BD87D1533F63BC88B47100F45F18D0CB68B048883F8FF75CE5F5E5D33C05BC38B47108D0CB65F5E5D8D04885BC3CCCCCCCCCCCCCCCCCCFF742408FF742408E8F3FEFFFF83C40885C07413" & _
		"8B4C240C85C974058B40088901B801000000C38B44240C85C07406C7000000000033C0C3CCCCCCCCCCCCCCCC566A206A01FF1588A000108BF083C40885F675025EC3578B7C240C6A1457C7460400000000893EFF1588A0001083C40889461085C0750F56" & _
		"FF1590A0001083C40433C05F5EC38B4424108946148B4424148946188B44241889461C85FF7E1533C98B46108D4914C74401ECFFFFFFFF83EF0175ED5F8BC65EC3CCCCCCCCCCCCCC568B742408578B7C24108B46083BC77D4281FFF7FFFF7F7E12FF15B8" & _
		"A00010C7001B0000005F83C8FF5EC383C7083DFFFFFF3F7F0903C03BC70F4CC78BF857FF36FF1594A0001083C40885C074D7897E0889065F33C05EC3CCCCCCCCCCCCCCCC578B7C240885FF7412FF37FF1590A0001057FF1590A0001083C4085FC3CCCCCC" & _
		"56578B7C241485FF784E8B74240CB8FEFFFF7F8B4E042BC13BF87F3C8D470103C13946087F0E5056E853FFFFFF83C40885C078308B0E034E0457FF74241451E8BB2600008B0E83C40C017E048BC78B56045F5EC6040A00C3FF15B8A00010C7001B000000" & _
		"5F83C8FF5EC3CCCCCCCCCCCC538B5C2408568B742410578D7B0483FEFF75028B378B4C241C85C9786E83FEFF7C69B8FFFFFF7F2BC63BC87F5E558D2C0E396B087D195553E8D3FEFFFF83C40885C079085D5F5E83C8FF5BC38D7B048B0F3BCE7D148BC62B" & _
		"C1508B0303C16A0050E81726000083C40CFF7424208B03FF74242003C650E80226000083C40C392F7D02892F5D5F5E33C05BC3FF15B8A000105F5E5BC7001B00000083C8FFC3CCCC566A0C6A01FF1588A000108BF083C40885F674296A20C74608200000" & _
		"00C7460400000000FF158CA0001083C404890685C0750E56FF1590A0001083C40433C05EC3C600008BC65EC3CCCCCCCCCCCCCCCC8B4C24048B01C60000C7410400000000C3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC81EC8C000000A140D2001033C4898424" & _
		"8800000053558BAC24980000005657E8FCA8FFFF8B1DECA000108BF88D8424A8000000506A00FFB424AC0000008B0F8D442424688000000050FF770483C90151FFD383C9FFC68424B30000000083C41C85C00F48C183F87F7716508D44241C5055E80AFE" & _
		"FFFF83C40C8BF8E9A10000008B8424A40000008D8C24A8000000516A00506A00894424208B076A00FF770483C80250FFD383C41CB9FFFFFFFF85C00F48C185C078684050FF158CA000108BF083C40485F674578D8424A8000000508B076A00FF74241883" & _
		"C8016AFF56FF770450FFD38B1D90A000108BF883C41CB8FFFFFFFF85FF0F48F885FF790E56FFD38B74241883C40485FF7814575655E86EFDFFFF568BF8FFD383C4108BC7EB0383C8FF8B8C24980000005F5E5D5B33CCE85313000081C48C000000C3CCCC" & _
		"CCCCCCCC83EC0856C744240800000000C744240400000000FF1510A00010B1043AC81BC083E04005000000F0506A016A006A008D44241450FF1508A0001085C07517FF1514A000106A028BF0FF15DCA00010B9E0A90010EB388D442408506A04FF74240C" & _
		"FF1500A000106A00FF7424088BF0FF1504A0001085F67536FF1514A000106A028BF0FF15DCA00010B904AA001083C404565150E898A9FFFF6A00FF150CA1001083C41069C0A599D6195E83C408C38B4424085E83C408C3CCCCCCCCCCCCCCCCCC83EC18A1" & _
		"40D2001033C489442414A1B8D30010568B74242085C0751A6810AC0010E87723000083C404F7D81BC083E00248A3B8D3001083F8FF751A56FF15C0A0001083C4045E8B4C241433CCE83512000083C418C38B157CD0001033C985D2742033C039B078D000" & _
		"100F848C000000418D04CD000000008B907CD0001085D275E233C983FE0A7C2B0F1F840000000000B8CDCCCCCCF7E6C1EA038D049203C02BF08A8628AC00108BF288440C044183FE0A7DDDB867666666F7EEC1FA028BC2C1E81F03C2BA060000008D0480" & _
		"03C02BF08A8628AC001088440C0485C9786666908A440C04888290D100104283E9018BC279EE3D800000007367EB498A0AB80600000084C974228D72FA0F1F8000000000888890D10010408BD08A0C0684C975F081FA800000007338C68090D1001000B8" & _
		"90D100105E8B4C241433CCE84611000083C418C38B4C2418B890D100105E33CCC68290D1001000E82A11000083C418C3E8B9140000CCCCCCCCCCCCCCCCCCCCCC568B7424088BD68D4A01660F1F4400008A024284C075F92BD18A0E83FA0175278D41D03C" & _
		"0977108B44240C0FBEC983E9305E89088BC2C3FF15B8A000105EC7001600000033C0C380F93074EB33C985D2740E8A040E2C303C0977DC413BCA72F26A0A6A0056FF1578A000108B4C241883C40C8901B8010000005EC3CCCCCCCCCCFF74240CFF74240C" & _
		"FF74240CE8BFAFFFFF83C40CC3CCCCCCCCCCCCCCCCCCCCCC83EC105356578B7C242085FF0F84950000008B74242485F60F8489000000803E00747156FF15FCA000108BD883C40485DB7518FF15B8A0001083CFFFC7000C0000008BC75F5E5B83C410C38D" & _
		"44240C505357E8D90100008BF883C40C85FF75226A04FF742410E8C5C1FFFF83C40885C074108B44241485C074082BF303C68944241453FF1590A0001083C40485FF75268B7C24108B44242885C0740289385F5E33C05B83C410C3FF15B8A0001083CFFF" & _
		"C700160000008BC75F5E5B83C410C3CC56578B7C240C85FF0F849B0000008B74241085F60F848F000000803E0075208B4424148978045FC70000000000C7400800000000C7400CFFFFFFFF33C05EC35356FF15FCA000108BD883C40485DB7513FF15B8A0" & _
		"00105B5F5EC7000C00000083C8FFC3558B6C241C555357E8000100008BF883C40C85FF751F6A04FF7500E8EDC0FFFF83C40885C0740E8B450885C074072BC303C689450853FF1590A0001083C4048BC75D5B5F5EC3FF15B8A000105F5EC7001600000083" & _
		"C8FFC3CCCCCCCCCC83EC14578B7C241CC74424040000000085FF0F84810000008B44242485C07479568D4C242C51508D44241050E8EF0500008BF083C40C85F67859538B5C240C803B00751D8B44242885C0743A538938FF1590A0001083C4048BC65B5E" & _
		"5F83C414C38D442410505357E8430000008BF083C40C85F675108B4C242885C974068B442414890133F653FF1590A0001083C4048BC65B5E5F83C414C3FF15B8A000105FC7001600000083C8FF83C414C3CCCCCC83EC088B44240C53568B74241833DB89" & _
		"44240C895C2408803E2F7415FF15B8A000105E5BC7001600000083C8FF83C408C357466A2F56E8F81E00008BF883C40885FF7402881F558B6C241C6A0555E8ADBFFFFF83C40885C074378D4424105056E8CBFCFFFF83C40885C0745E55E8FEACFFFF8B5C" & _
		"241483C4043BD873415355E8ACACFFFF83C40885C074338944241CEB486A2F6834AC001056E8520400006A7E6838AC001056E8450400008D442434505655E889C4FFFF83C42485C07517FF15B8A00010C700020000005D5F5E83C8FF5B83C408C38B4424" & _
		"1C85FF741CFF742424C6072F57FF742424E812FFFFFF83C40C5D5F5E5B83C408C38B7C242485FF74288B4C24146A0551890F894704E8EEBEFFFF83C40885C0740D5D895F0C33C05F5E5B83C408C38977085D5F5E33C05B83C408C3CCCCCCCCCCCCCCCCCC" & _
		"CCCCCCCC83EC1056578B7C241C85FF742A8B74242085F674228A0684C07518FF37E89EC6FFFF8B44242883C404890733C05F5E83C410C33C2F7415FF15B8A000105F5EC7001600000083C8FF83C410C3556A2F56E8B01D00008BE883C4083BEE75206A00" & _
		"68306F0010FF7424308D460150FF37E88C00000083C4145D5F5E83C410C35356FF15FCA000108BD883C40485DB7517FF15B8A000105B5D5FC7000C00000083C8FF5E83C410C38BC52BC6C60418008D4424105053FF37E805FEFFFF83C40C8BF053FF1590" & _
		"A0001085F6740D83C4048BC65B5D5F5E83C410C36A0068306F0010FF7424388D450150FF742428E81000000083C4185B5D5F5E83C410C3CCCCCCCCCC51568B74240C6A0556E8B2BDFFFF83C40885C074488B44241080382D7516807801007510FF742414" & _
		"56E852AAFFFF83C4085E59C38D4C24045150E8B1FAFFFF83C40885C07446FF74241CFF742418FF74240C56FF54242883C4105E59C36A0456E85BBDFFFF83C40885C07414FF742414FF74241456E806C1FFFF83C40C5E59C3FF15B8A00010C70002000000" & _
		"83C8FF5E59C3CCCCCCCCCCCCCCCCCCCCCCCCCCCC83EC1056578B7C241C85FF742A8B74242085F674228A0684C07518FF37E8FEC4FFFF8B44242883C404890733C05F5E83C410C33C2F7415FF15B8A000105F5EC7001600000083C8FF83C410C3556A2F56" & _
		"E8101C00008BE883C4083BEE7521FF7424308D4601FF742430FF74243050FF37E8EBFEFFFF83C4145D5F5E83C410C35356FF15FCA000108BD883C40485DB7517FF15B8A000105B5D5FC7000C00000083C8FF5E83C410C38BC52BC6C60418008D44241050" & _
		"53FF37E864FCFFFF83C40C8BF053FF1590A0001085F6740D83C4048BC65B5D5F5E83C410C3FF7424388D4501FF742438FF74243850FF742428E86EFEFFFF83C4185B5D5F5E83C410C3CCCCCC83EC14578B7C241CC74424040000000085FF0F84E0000000" & _
		"8B44242485C00F84D4000000568D4C242C51508D44241050E85B0100008BF083C40C85F60F88B0000000538B5C240C8A0384C07523FF37E8CCC3FFFF8B44242C83C404890753FF1590A0001083C4048BC65B5E5F83C414C33C2F7422FF15B8A000105383" & _
		"CEFFC70016000000FF1590A0001083C4048BC65B5E5F83C414C3556A2F53E8C61A00008BE883C4083BEB75048B0FEB1E8D442414C64500005053FF37E863FBFFFF8BF083C40C85F6751E8B4C24186A0068306F0010FF7424348D45015051E881FDFFFF83" & _
		"C4148BF05D53FF1590A0001083C4048BC65B5E5F83C414C3FF15B8A000105FC7001600000083C8FF83C414C3CCCCCCCC53558B6C240C568BF5578D4E010F1F008A064684C075F98B5424182BF18BCA8D79018A014184C075F92BCF52558D59FFE8141A00" & _
		"008BF883C40885FF743066908A44241C2BF38807478BC62BC74003C5508D041F5057E8DC190000FF74242457E8E41900008BF883C41485FF75D25F5E5D5BC3CCCCCCCCCCCCCCCCCCCCCCCCCC5356578B7C241083CEFF85FF0F848B000000E8599DFFFFFF" & _
		"7424188BD86A00FF74241C8B0B6A006A00FF730483C90251FF15ECA0001083C41C85C00F48C685C0785B4050FF158CA000108BF083C40485F67447FF7424188B0B6A00FF74241C83C9016AFF56FF730451FF15ECA000108BD883C41C85DBB8FFFFFFFF0F" & _
		"48D885DB791056FF1590A0001083C4048BC35F5E5BC389378BC35F5E5BC383CEFF5F8BC65E5BC3CCCCCCCCCCCCCCCCCCCCCCCCCC568B7424086A05FF36E8D2B9FFFF83C40885C074116A01FF760CFF36E8BFA6FFFF83C40C5EC38B0685C074158B4E0885" & _
		"C9740E5150E886BEFFFF83C40833C05EC3FF7604E897C1FFFF83C404C746040000000033C05EC3CCCCCCCCCCCCCCCCCC568B74240856E8E5A6FFFF8B4C241083C4043BC87611FF15B8A000105EC7001600000083C8FFC38B442414FF7424105183380056" & _
		"7407E895A6FFFFEB05E8BEA6FFFF8BF083C40C85F6790CFF15B8A00010C700160000008BC65EC3CCCCCCCCCC568B74240856E885A6FFFF8B4C241883C4048D50013B310F45D08B44240C3BC27611FF15B8A000105EC7001600000083C8FFC3FF74241050" & _
		"56E832A6FFFF8BF083C40C85F6790CFF15B8A00010C700160000008BC65EC3CCCCCCCCCCCCCCCCCC8B44241083EC30538B5C2440555633F68D6C242085C0570F45E8C74504FFFFFFFF89750085DB740C8B7C24443933752585FF7525C7450810AE0010C7" & _
		"45000E000000FF15B8A000105F893083C8FF5E5D5B83C430C385FF75DB6A05FF74244CE85CB8FFFF83C40885C07509C7450844AE0010EBC785FF74316A005357E84FA8FFFF83C40C85C07921C745000C000000C7450870AE0010FF15B8A000105F893083" & _
		"C8FF5E5D5B83C430C3FF74244833FF897C2414E878A5FFFF83C40485C00F844C03000057FF74244CE823A5FFFF8BF88B4424188945048D44241C5068A8AE001057E81ABDFFFF83C41485C00F8472030000FF742414E866B4FFFF8BF08D44241C5068D8AE" & _
		"001057E8F4BCFFFF83C41085C00F8427030000FF742418E840B4FFFF83C40489442450BA0CAF00108BCE66908A193A1A751A84DB74128A41013A4201750E83C10283C20284C075E433C0EB051BC083C80185C00F85C30000008D44242050683CAC001057" & _
		"E893BCFFFF83C40C85C07522C7450016000000C7450844AC0010FF15B8A0001083CEFFC70000000000E9580200008D44241C508B442450FF742454FF30E8E6F4FFFF83C40C85C074328B1DB8A00010FFD38B00894500FFD3B974AC0010833802B8A4AC00" & _
		"100F45C8894D08FFD383CEFFC70000000000E90B020000FF74241CFF742424E810ADFFFF83C40885C07522C7450002000000C74508B8AC0010FF15B8A0001083CEFFC70000000000E9D501000033F6E9CE010000B914AF00108BC68A103A11751A84D274" & _
		"128A50013A5101750E83C00283C10284D275E433C0EB051BC083C80185C00F85900000008B5C244C8D44243050FF742454FF33E8E8F4FFFF83C40C85C074328B1DB8A00010FFD38B00894500FFD3B974AC0010833802B8A4AC00100F45C8894D08FFD383" & _
		"CEFFC70000000000E94D0100008D44243050E835FCFFFF8BF083C40485F6791AC7450016000000C7450800AD0010FF15B8A00010C70000000000837C2430000F8515010000C70300000000E90A010000B91CAF00108BC60F1F4400008A103A11751A84D2" & _
		"74128A50013A5101750E83C00283C10284D275E433C0EB051BC083C80185C07516556A01FF74245857FF74245CE866010000E9BA000000B920AF00108BC68A103A11751A84D274128A50013A5101750E83C00283C10284D275E433C0EB051BC083C80185" & _
		"C075125550FF74245857FF74245CE821010000EB78B928AF00108BC68A103A11751A84D274128A50013A5101750E83C00283C10284D275E433C0EB051BC083C80185C07505556A01EB35B830AF00100F1F4400008A0E3A08751A84C974128A4E013A4801" & _
		"750E83C60283C00284C975E433C0EB051BC083C80185C075405550FF74245857FF74245CE8970100008BF083C41485F6781D8B7C2410FF74244847897C2414E82CA2FFFF83C4043BF80F82B4FCFFFF5F8BC65E5D5B83C430C3C7450016000000C7450838" & _
		"AF0010FF15B8A000105F5E5DC7000000000083C8FF5B83C430C3C7450016000000C74508E0AE0010FF15B8A000105F5E5DC7000000000083C8FF5B83C430C3C7450016000000C74508ACAE0010FF15B8A000105F5E5DC7000000000083C8FF5B83C430C3" & _
		"CCCCCCCCCCCCCCCC518D042450683CAC0010FF742414E85DB9FFFF83C40C85C075228B442418C70016000000C7400844AC0010FF15B8A00010C7000000000083C8FF59C3837C241400568B742414578B7C241075456A0056FF37E8A9F1FFFF83C40C85C0" & _
		"74348B3DB8A00010FFD78B7424208B008906FFD7BAA4AC0010B974AC00108338020F45CA894E08FFD75F5EC7000000000083C8FF59C38D44241C506800780010FF742410E8DBABFFFF83C404505657E860F6FFFF8BF883C41485FF742B8B35B8A00010FF" & _
		"D68B5424208B08890AC7420834AD0010FFD6C70000000000FF742408E84FBBFFFF83C4048BC75F5E59C3CCCCCCCCCCCC83EC148D042450686CAD0010FF742424E86BB8FFFF83C40C85C075248B442428C70016000000C7400874AD0010FF15B8A00010C7" & _
		"000000000083C8FF83C414C35357FF742408E895AFFFFF8BD883C4048BFB8D47018A0F4784C975F9568B74242C2BF8575653FF1500A1001083C40C85C075408D4E018A064684C075F92BF13BFE75095E5F33C05B83C414C38B442434C70016000000C740" & _
		"089CAD0010FF15B8A000105E5F5BC7000000000083C8FF83C414C3558D44241450538B5C2430FF33E80BF1FFFF8BE883C40C85ED74378B3DB8A00010FFD78B7424388B08890EFFD7BAFCAD0010B9CCAD00108338020F45CA894E08FFD7C700000000008B" & _
		"C55D5E5F5B83C414C3FF742418E882AAFFFF83C404837C2434007507B800780010EB188D44241450E837F8FFFF8BF883C40485FF783EB8607800108D4C24145150FF7424205653E8D8F4FFFF8BF883C41485FF742B8B35B8A00010FFD68B5424388B0889" & _
		"0AC7420834AD0010FFD6C70000000000FF742418E8C7B9FFFF83C4045D5E8BC75F5B83C414C33B0D40D200107501C3E98F020000CCCCCCCCCCCCCCCCCCCCCCCCF60590D20010207515C5FA7EC062F1FD0878C0C5F97EC0C4E37916C201C38BCC83C4F883" & _
		"E4F8F20F1104248B04248B5424048BE10FBAF21F724A81FA0000E0417307F20F2CC033D2C38BCA0FBAEA14C1E91481E2FFFF1F0081E9330400007D19F7D95333DB0FADC37408F30F2C1D8CAF00105B0FADD0D3EAC383F90C73170FA5C2D3E0C381FA0000" & _
		"F03F7309F20F2CC033C033D2C3F30F2C0D88AF001033C04899C3CCCCCCCCCCCCCCCCCCCCCCCCCCCC83C4F8F20F1104248B54240483C40881FA0000E0417307F20F2CC033D2C381FA0000F0430F8306000000E921FFFFFFCCF60590D20010207515C5FA7E" & _
		"C062F1FD087AC0C5F97EC0C4E37916C201C38BCC83C4F883E4F8F20F1104248B04248B5424048BE10FBAF21F1BC981FA0000E041733CF20F2CC099C38BCA0FBAEA14C1E91481E2FFFF1F0081E9330400007D19F7D95333DB0FADC37408F30F2C1D8CAF00" & _
		"105B0FADD0D3EAC30FA5C2D3E0C381FA0000E043731185C974BEE8B9FFFFFFF7D883D200F7DAC3E306770485C07408F30F2C0D88AF0010BA0000008033C0C3CCF60590D20010207511C5F96EC1C4E37922C20162F1FE087AC0C3660F6EC10F560560AF00" & _
		"10F20F5C0560AF001085D27417660F6ECA0F560D70AF0010F20F5C0D70AF0010F20F58C1C3CCCCCCCCCCCCCCF60590D20010207511C5F96EC1C4E37922C20162F1FE08E6C0C3660F6EC10F560560AF0010F20F5C0560AF001085D27410F20F2ACAF20F59" & _
		"0D80AF0010F20F58C1C3CCCCCCCCCCCCCCCCCCCCCCCCCCCC518D4C24042BC81BC0F7D023C88BC42500F0FFFF3BC8720A8BC159948B00890424C32D001000008500EBE9558BEC6A00FF1540A00010FF7508FF1544A0001068090400C0FF153CA0001050FF" & _
		"1538A000105DC3558BEC81EC240300006A17FF1534A0001085C074056A0259CD29A3C0D40010890DBCD400108915B8D40010891DB4D400108935B0D40010893DACD40010668C15D8D40010668C0DCCD40010668C1DA8D40010668C05A4D40010668C25A0" & _
		"D40010668C2D9CD400109C8F05D0D400108B4500A3C4D400108B4504A3C8D400108D4508A3D4D400108B85DCFCFFFFC70510D4001001000100A1C8D40010A3CCD30010C705C0D30010090400C0C705C4D3001001000000C705D0D30010010000006A0458" & _
		"6BC000C780D4D30010020000006A04586BC0008B0D40D20010894C05F86A0458C1E0008B0D80D20010894C05F86890AF0010E8E0FEFFFF90C9C3558BEC6A08E803000000905DC3558BEC81EC1C0300006A17FF1534A0001085C074058B4D08CD29A3C0D4" & _
		"0010890DBCD400108915B8D40010891DB4D400108935B0D40010893DACD40010668C15D8D40010668C0DCCD40010668C1DA8D40010668C05A4D40010668C25A0D40010668C2D9CD400109C8F05D0D400108B4500A3C4D400108B4504A3C8D400108D4508" & _
		"A3D4D400108B85E4FCFFFFA1C8D40010A3CCD30010C705C0D30010090400C0C705C4D3001001000000C705D0D30010010000006A04586BC0008B4D088988D4D300106890AF0010E803FEFFFF90C9C3558BEC8B450C83E800743383E801742083E8017411" & _
		"83E801740533C040EB30E827080000EB05E8010800000FB6C0EB1FFF7510FF7508E81800000059EB10837D10000F95C00FB6C050E80F010000595DC20C006A106800B40010E8860B00006A00E8560800005984C00F84D4000000E84D0700008845E3B301" & _
		"885DE7C745FC00000000833D00D70010000F85C5000000C70500D7001001000000E87F07000084C0744DE8D60A0000E897060000E8B00600006834A100106830A10010E8ED0B0000595985C07529E82707000084C07420682CA100106828A10010E8C90B" & _
		"00005959C70500D700100200000032DB885DE7C745FCFEFFFFFFE83D00000084DB7543E8530900008BF0833E00741F56E86A0800005984C07414FF750C6A02FF75088B368BCEFF1520A10010FFD6FF05DCD6001033C040EB0F8A5DE7FF75E3E8D2080000" & _
		"59C333C08B4DF064890D00000000595F5E5BC9C36A07E802090000CC6A106820B40010E87C0A0000A1DCD6001085C07F0433C0EB7048A3DCD6001033F6468975E4C745FC00000000E8330600008845E08975FC833D00D7001002756FE8EA060000E8A905" & _
		"0000E8FE090000C70500D7001000000000C745FC00000000E8370000006A00FF7508E864080000595933C984C00F44F18975E4C745FCFEFFFFFFE8220000008BC68B4DF064890D00000000595F5E5BC9C38B75E4FF75E0E81208000059C38B75E4E8A406" & _
		"0000C36A07E84B080000CC6A0C6848B40010E8C50900008B7D0C85FF750F393DDCD600107F0733C0E9DC000000C745FC0000000083FF01740A83FF0274058B5D10EB318B5D105357FF7508E8C90000008BF08975E485F60F84A30000005357FF7508E890" & _
		"FDFFFF8BF08975E485F60F848C0000005357FF7508E89B0400008BF08975E483FF01752785F675235350FF7508E88304000085DB0F95C00FB6C050E8B0FEFFFF595356FF7508E86A00000085FF740583FF0375485357FF7508E835FDFFFF8BF08975E485" & _
		"F674355357FF7508E8440000008BF0EB248B4DEC8B0151FF30683B840010FF7510FF750CFF7508E85B05000083C418C38B65E833F68975E4C745FCFEFFFFFF8BC68B4DF064890D00000000595F5E5BC9C3558BEC568B3598AF001085F6750533C040EB13" & _
		"FF75108BCEFF750CFF7508FF1520A10010FFD65E5DC20C00558BEC837D0C017505E87C030000FF7510FF750CFF7508E8ABFEFFFF83C40C5DC20C00558BEC830D98D200100183EC28C705E4D60010000000006A0AFF1534A0001085C00F84EF0200005356" & _
		"5733C08D7DD833C9530FA28BF35B908907897704894F0889570C8B45D88B4DE48945FC81F1696E65498B45E0356E74656C0BC88B45DC6A013547656E750BC8586A0059530FA28BF35B908907897704894F0889570C75398B45D825F03FFF0F3DC0060100" & _
		"74233D60060200741C3D7006020074153D50060300740E3D6006030074073D700603007507830DE8D60010018B55E033DB33FF8955F4837DFC07895DEC895DE80F8C870000006A075833C9530FA28BF35B908D5DD88903897304894B0889530C8B5DDC8B" & _
		"45E4895DF88945ECF7C3000200007407830DE8D6001002837DD8017C246A075833C941530FA28BF35B908D5DD88903897304894B0889530C8B45E48B5DF88945E86A24583945FC7C1D33C98D7DD8530FA28BF35B908B5DF88907897704894F0889570C8B" & _
		"7DDC8B55F4A198D200108B0D90D2001083C8028B3594D2001083E1FEC705E4D6001001000000A398D20010890D90D20010893594D20010F7C2000010000F847B01000083C804C705E4D6001002000000A398D2001083E1EFB800000018890D90D2001023" & _
		"D0893594D200103BD00F854B01000033C90F01D08945F033F68955F48B45F08B4DF483E00623CE83F8060F852A0100003BCE0F8522010000A198D2001083C808C705E4D6001003000000A398D20010F6C32074798B0D94D2001083C820A398D20010BA00" & _
		"0003D0A190D2001023DA83E0FDC705E4D6001005000000A390D20010890D94D200103BDA754E8B45F0BAE00000008B4DF423C223CE3BC275303BCE752CA190D20010830D98D200104083E0DB8B0D94D20010C705E4D6001006000000A390D20010890D94" & _
		"D20010EB0B8B0D94D20010A190D20010F745EC00008000741025FFFFFFFE890D94D20010A390D20010F745E80000080074608B45F0BAE00000008B4DF423C223CE3BC2754D3BCE75498BC733C9C1EF1025FF00040083E706A3E0D6001081CF29000001F7" & _
		"D1230D94D20010F7D7233D90D20010893D90D20010890D94D200103C01760F83E7BF890D94D20010893D90D200105F5E5B33C0C9C3558BEC83EC148D45F40F57C050660F1345F4FF1524A000108B45F83345F48945FCFF1528A000103145FCFF152CA000" & _
		"103145FC8D45EC50FF1530A000108B45F08D4DFC3345EC3345FC33C1C9C38B0D40D200105657BF4EE640BBBE0000FFFF3BCF740485CE7526E894FFFFFF8BC83BCF7507B94FE640BBEB0E85CE750A0D11470000C1E0100BC8890D40D20010F7D15F890D80" & _
		"D200105EC3558BEC837D0C017512833D98AF0010007509FF7508FF1520A0001033C0405DC20C0068F0D60010FF151CA00010C368F0D60010E83605000059C3B8F8D60010C3E8BE88FFFF8B4804830824894804E8E7FFFFFF8B4804830802894804C3558B" & _
		"EC8B4508568B483C03C80FB741148D511803D00FB741066BF02803F2EB158B4A0C394D0C720A8B420803C139450C720C83C2283BD675E733C05E5DC38BC2EBF956E89904000085C0742064A118000000BE04D700108B5004EB043BD0741033C08BCAF00F" & _
		"B10E85C075F032C05EC3B0015EC3E86804000085C07407E86FFBFFFFEB18E85404000050E8AC0400005985C0740332C0C3E8A5040000B001C36A00E8D000000084C0590F95C0C3E8A704000084C0750332C0C3E89B04000084C07507E892040000EBEDB0" & _
		"01C3E888040000E883040000B001C3558BECE80004000085C07519837D0C017513FF75108B4D1450FF7508FF1520A10010FF5514FF751CFF7518E82C04000059595DC3E8CF03000085C0740C680CD70010E82D04000059C3E82FA7FFFF85C00F84240400" & _
		"00C36A00E82204000059E91C040000558BEC837D08007507C60508D7001001E89FFAFFFFE80204000084C0750432C05DC3E8F503000084C0750A6A00E8EA03000059EBE9B0015DC3558BEC803D09D70010007404B0015DC3568B750885F6740583FE0175" & _
		"62E84903000085C0742685F67522680CD70010E89D0300005985C0750F6818D70010E88E0300005985C0742B32C0EB3083C9FF890D0CD70010890D10D70010890D14D70010890D18D70010890D1CD70010890D20D70010C60509D7001001B0015E5DC36A" & _
		"05E8E3000000CC6A086868B40010E85D020000C745FC00000000B84D5A000066390500000010755DA13C00001081B80000001050450000754CB90B01000066398818000010753E8B4508B9000000102BC15051E8B2FDFFFF595985C07427837824007C21" & _
		"C745FCFEFFFFFFB001EB1F8B45EC8B0033C98138050000C00F94C18BC1C38B65E8C745FCFEFFFFFF32C08B4DF064890D00000000595F5E5BC9C3558BECE84502000085C0740F807D0800750933C0B904D7001087015DC3558BEC803D08D7001000740680" & _
		"7D0C007512FF7508E88E020000FF7508E8860200005959B0015DC3B830D70010C3558BEC81EC24030000566A17FF1534A0001085C074058B4D08CD296A03E8F3000000C70424CC0200008D85DCFCFFFF6A0050E8DD01000083C40C89858CFDFFFF898D88" & _
		"FDFFFF899584FDFFFF899D80FDFFFF89B57CFDFFFF89BD78FDFFFF668C95A4FDFFFF668C8D98FDFFFF668C9D74FDFFFF668C8570FDFFFF668CA56CFDFFFF668CAD68FDFFFF9C8F859CFDFFFF8B4504898594FDFFFF8D45048985A0FDFFFFC785DCFCFFFF" & _
		"010001008B40FC6A50898590FDFFFF8D45A86A0050E8530100008B450483C40CC745A815000040C745AC010000008945B4FF1518A000108BF08D45A88945F88D85DCFCFFFF6A008945FCFF1540A000108D45F850FF1544A0001085C0750D83FE0174086A" & _
		"03E804000000595EC9C3C70524D7001000000000C35356BEF4B30010BBF4B300103BF37319578B3E85FF740A8BCFFF1520A10010FFD783C6043BF372E95F5E5BC35356BEFCB30010BBFCB300103BF37319578B3E85FF740A8BCFFF1520A10010FFD783C6" & _
		"043BF372E95F5E5BC3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC686590001064FF35000000008B442410896C24108D6C24102BE0535657A140D200103145FC33C5508965E8FF75F88B45FCC745FCFEFFFFFF8945F88D45F064A300000000C3558BEC568B7508" & _
		"FF36E8A3000000FF75148906FF7510FF750C5668C67F00106840D20010E84300000083C41C5E5DC3C2000033C040C333C03905A0D200100F95C0C3FF2550A00010FF2554A00010FF2558A00010FF255CA00010FF2560A00010FF2564A00010FF254CA000" & _
		"10FF2568A00010FF25A4A00010FF2580A00010FF25C4A00010FF25CCA00010FF25D0A00010FF25D4A00010FF25C8A00010FF25B0A00010FF25ACA00010FF25B4A00010B001C3558BEC51833DE4D60010018B4D087C5C81F9B40200C0740881F9B50200C0" & _
		"754C0FAE5DFC8B45FC83F03FA8817442A9040200007507B88E0000C0C9C3A902010000742DA9080400007507B8910000C0C9C3A9100800007507B8930000C0C9C3A920100000B88F0000C00F44C88BC1C9C3B8900000C0C9C30000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"0000000046C5000030C5000018C5000000000000FCC40000ECC400001ECA000008CA0000ECC90000D2C90000BCC90000A6C900008CC9000070C900005CC9000048C900002AC900000EC9000000000000A2C5000066C5000070C500007AC5000084C50000" & _
		"8EC5000098C50000C2C500000000000074C60000B4C60000BEC6000000000000E8C600000000000088C60000F6C50000EEC5000000C6000000000000A8C60000000000007EC600000000000076C700005AC700008EC7000048C600006CC60000DCC60000" & _
		"F2C6000038C70000FEC600000CC700001EC70000000000001CC600002EC60000B4C70000ACC7000052C60000CAC60000A2C700000000000098C7000092C600009CC6000000000000D2C60000000000000AC6000014C60000000000009490001000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000302E313800000000303132333435363738392E2B2D6545003031323334353637383961626364656641424344454600005C6200005C6E00005C720000" & _
		"5C7400005C6600005C2200005C5C00005C2F00005C75303025632563000000006E756C6C000000007B0000002C0000000A000000200000001B5B303B33346D00220000001B5B306D000000003A2000003A0000001B5B303B33356D00207D00007D000000" & _
		"747275650000000066616C7365000000696E76616C69642063696E745F74797065000000256C6C6400000000256C6C75000000006A736F6E5F635F7365745F73657269616C697A6174696F6E5F646F75626C655F666F726D61743A206F7574206F66206D" & _
		"656D6F72790A0000000000006A736F6E5F635F7365745F73657269616C697A6174696F6E5F646F75626C655F666F726D61743A206E6F7420636F6D70696C65642077697468205F5F74687265616420737570706F72740A00000000006A736F6E5F635F73" & _
		"65745F73657269616C697A6174696F6E5F646F75626C655F666F726D61743A20696E76616C696420676C6F62616C5F6F725F7468726561642076616C75653A2025640A004E614E00496E66696E697479000000002D496E66696E697479000000252E3137" & _
		"670000002E3066002E3000001B5B303B33326D005B000000205D00005D0000006A736F6E5F6F626A6563745F61727261795F736872696E6B2063616C6C65642077697468206E6567617469766520656D7074795F736C6F74730000006A736F6E5F6F626A" & _
		"6563745F636F70795F73657269616C697A65725F646174613A206F7574206F66206D656D6F72790A00000000000000006A736F6E5F6F626A6563745F636F70795F73657269616C697A65725F646174613A20756E61626C6520746F20636F707920756E6B" & _
		"6E6F776E2073657269616C697A657220646174613A2025700A0000006A736F6E2D632061626F7274732077697468206572726F723A2025730A00000000000000000000000000C0FFFFFFDF41000000000000E043000000000000F043000000000000F07F" & _
		"000000000000E0C1000000000000E0C3000000000000F0FF6E756C6C0000000004000000496E66696E69747900000000694E46494E49545900000000080000004E614E000300000074727565000000000400000066616C73650000000500000073756363" & _
		"65737300636F6E74696E7565000000006E657374696E6720746F6F206465657000000000756E657870656374656420656E64206F6620646174610000756E657870656374656420636861726163746572000000006E756C6C206578706563746564000000" & _
		"626F6F6C65616E206578706563746564000000006E756D6265722065787065637465640061727261792076616C756520736570617261746F7220272C27206578706563746564000071756F746564206F626A6563742070726F7065727479206E616D6520" & _
		"6578706563746564000000006F626A6563742070726F7065727479206E616D6520736570617261746F7220273A27206578706563746564006F626A6563742076616C756520736570617261746F7220272C2720657870656374656400696E76616C696420" & _
		"737472696E672073657175656E636500657870656374656420636F6D6D656E7400000000696E76616C6964207574662D3820737472696E67000000006275666665722073697A65206F766572666C6F77000000006F7574206F66206D656D6F7279000000" & _
		"00000000556E6B6E6F776E206572726F722C20696E76616C6964206A736F6E5F746F6B656E65725F6572726F722076616C75652070617373656420746F206A736F6E5F746F6B656E65725F6572726F725F6465736328290043000000080000000D000000" & _
		"090000000C0000000000807F00000000000000000000F87F000080FF626F6F6C65616E00646F75626C650000696E74006F626A65637400006172726179000000737472696E6700006A736F6E5F6F626A6563745F66726F6D5F66645F65783A207072696E" & _
		"746275665F6E6577206661696C65640A000000006A736F6E5F6F626A6563745F66726F6D5F66645F65783A20756E61626C6520746F20616C6C6F63617465206A736F6E5F746F6B656E65722864657074683D2564293A2025730A00006A736F6E5F6F626A" & _
		"6563745F66726F6D5F66645F65783A206661696C656420746F207072696E746275665F6D656D617070656E642061667465722072656164696E672025642B25642062797465733A20257300006A736F6E5F6F626A6563745F66726F6D5F66645F65783A20" & _
		"6572726F722072656164696E672066642025643A2025730A000000006A736F6E5F746F6B656E65725F70617273655F6578206661696C65643A2025730A0000006A736F6E5F6F626A6563745F66726F6D5F66696C653A206572726F72206F70656E696E67" & _
		"2066696C652025733A2025730A0000006A736F6E5F6F626A6563745F746F5F66696C655F6578743A206F626A656374206973206E756C6C0A000000006A736F6E5F6F626A6563745F746F5F66696C655F6578743A206572726F72206F70656E696E672066" & _
		"696C652025733A2025730A006A736F6E5F6F626A6563745F746F5F66643A206F626A656374206973206E756C6C0A000028666429000000006A736F6E5F6F626A6563745F746F5F66643A206572726F722077726974696E672066696C652025733A202573" & _
		"0A0000006A736F6E5F747970655F746F5F6E616D653A2074797065202564206973206F7574206F662072616E6765205B302C25755D0A00004552524F523A20696E76616C69642072657475726E2076616C75652066726F6D206A736F6E5F635F76697369" & _
		"74207573657266756E633A2025640A00494E5445524E414C204552524F523A205F6A736F6E5F635F76697369742072657475726E65642025640A0000494E5445524E414C204552524F523A205F6A736F6E5F635F766973697420666F756E64206F626A65" & _
		"6374206F6620756E6B6E6F776E20747970653A2025640A001F85EB51B81EE53F6572726F7220437279707441637175697265436F6E74657874412030782530386C7800006572726F7220437279707447656E52616E646F6D2030782530386C7800000000" & _
		"756E6465665F455045524D00756E6465665F454E4F454E5400000000756E6465665F455352434800756E6465665F45494E545200756E6465665F45494F000000756E6465665F454E58494F00756E6465665F453242494700756E6465665F454E4F455845" & _
		"43000000756E6465665F454241444600756E6465665F454348494C4400000000756E6465665F45444541444C4B000000756E6465665F454E4F4D454D00000000756E6465665F45414343455300000000756E6465665F454641554C5400000000756E6465" & _
		"665F454255535900756E6465665F45455849535400000000756E6465665F455844455600756E6465665F454E4F44455600000000756E6465665F454E4F54444952000000756E6465665F45495344495200000000756E6465665F45494E56414C00000000" & _
		"756E6465665F454E46494C4500000000756E6465665F454D46494C4500000000756E6465665F454E4F54545900000000756E6465665F45545854425359000000756E6465665F454642494700756E6465665F454E4F53504300000000756E6465665F4553" & _
		"5049504500000000756E6465665F45524F465300756E6465665F454D4C494E4B00000000756E6465665F455049504500756E6465665F45444F4D0000756E6465665F4552414E474500000000756E6465665F45414741494E000000005F4A534F4E5F435F" & _
		"5354524552524F525F454E41424C45003031323334353637383900007E3100007E30000076616C75650000005061746368206F626A65637420646F6573206E6F7420636F6E7461696E2061202776616C756527206669656C64000000446964206E6F7420" & _
		"66696E6420656C656D656E74207265666572656E6365642062792070617468206669656C64000000496E76616C69642070617468206669656C64000056616C7565206F6620656C656D656E74207265666572656E63656420627920277061746827206669" & _
		"656C6420646964206E6F74206D61746368202776616C756527206669656C6400556E61626C6520746F2072656D6F76652070617468207265666572656E63656420627920277061746827206669656C64000000004661696C656420746F20736574207661" & _
		"6C75652061742070617468207265666572656E63656420627920277061746827206669656C64000066726F6D00000000506174636820646F6573206E6F7420636F6E7461696E2061202766726F6D27206669656C64000000496E76616C69642061747465" & _
		"6D707420746F206D6F766520706172656E7420756E6465722061206368696C6400000000446964206E6F742066696E6420656C656D656E74207265666572656E6365642062792066726F6D206669656C64000000496E76616C69642066726F6D20666965" & _
		"6C64000045786163746C79206F6E65206F66202A62617365206F7220636F70795F66726F6D206D757374206265206E6F6E2D4E554C4C00005061746368206F626A656374206973206E6F74206F662074797065206A736F6E5F747970655F617272617900" & _
		"556E61626C6520746F20636F707920636F70795F66726F6D207573696E67206A736F6E5F6F626A6563745F646565705F636F7079282900006F7000005061746368206F626A65637420646F6573206E6F7420636F6E7461696E20276F7027206669656C64" & _
		"0000000070617468000000005061746368206F626A65637420646F6573206E6F7420636F6E7461696E20277061746827206669656C640000746573740000000072656D6F76650000616464007265706C616365006D6F766500000000636F707900000000" & _
		"5061746368206F626A6563742068617320696E76616C696420276F7027206669656C6400000000000000000000003043000000000000000000000000000030450000000000000000000000000000F041FFFFFFFF0000C03FC0D3001010D4001000000000" & _
		"00000000C0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040D20010C0B000100100000020A100100000000000000000000000000001000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000C4B00010000000000000000000000000000000000000000024A100100000000000000000" & _
		"FFF8276A00000000020000005900000040B100004097000000000000FFF8276A000000000C000000140000009CB100009C97000000000000FFF8276A000000000D00000040020000B0B10000B09700000000000000000000000000006590000018000000" & _
		"03800380DCB000004400000020B1000020000000C0610000F96100003D8300004D830000E28700001D88000089880000C5880000F0880000788900007D8900008089000083890000EE890000F68900005E8A0000668A000000100000E06F00003B820000" & _
		"E50D00006590000042000000139100007A000000525344535326850C9DDFDB4BA3844F53A35D7F8101000000433A5C64776E5C7663706B672D6D61737465725C6275696C6474726565735C6A736F6E2D635C7838362D77696E646F77732D72656C5C6A73" & _
		"6F6E2D632E70646200000000000000002400000024000000000000001600000000000000001000008D8100002E74657874246D6E0000000000A00000200100002E696461746124350000000020A10000080000002E3030636667000028A1000004000000" & _
		"2E43525424584341000000002CA10000040000002E4352542458435A0000000030A10000040000002E435254245849410000000034A10000040000002E4352542458495A0000000038A10000040000002E43525424585041000000003CA1000004000000" & _
		"2E4352542458505A0000000040A10000040000002E435254245854410000000044A100000C0000002E4352542458545A0000000050A10000700F00002E72646174610000C0B00000040000002E726461746124737864617461000000C4B000007C000000" & _
		"2E726461746124766F6C746D6400000040B10000B00200002E7264617461247A7A7A646267000000F0B30000040000002E7274632449414100000000F4B30000040000002E72746324495A5A00000000F8B30000040000002E7274632454414100000000" & _
		"FCB30000040000002E72746324545A5A0000000000B40000900000002E786461746124780000000090B40000240E00002E65646174610000B4C20000040100002E6964617461243200000000B8C30000140000002E6964617461243300000000CCC30000" & _
		"200100002E6964617461243400000000ECC40000460500002E696461746124360000000000D00000A80200002E64617461000000A8D200008C0400002E6273730000000000E00000600000002E727372632430310000000060E00000800100002E727372" & _
		"632430320000000000000000000000000000000000000000FEFFFFFF00000000D0FFFFFF00000000FEFFFFFF000000007185001000000000FEFFFFFF00000000D0FFFFFF00000000FEFFFFFF000000003E860010000000000000000031860010FEFFFFFF" & _
		"00000000D4FFFFFF00000000FEFFFFFF1D8700103C87001000000000FEFFFFFF00000000D8FFFFFF00000000FEFFFFFF1F8E0010328E001000000000000000000000000000000000FFFFFFFF0000000018B90000010000007000000070000000B8B40000" & _
		"78B6000038B80000406D0000B0190000C0190000401A0000101500002015000080610000401E0000601E0000801E0000B01E0000D01E0000F01E0000001F0000201F0000501F00009021000060250000C0270000C0290000005B0000105B0000D05C0000" & _
		"D0290000E0290000002A0000902A0000002C0000002D0000002E0000202E0000802E0000A02E0000B02E0000802F0000902F000080310000B03D0000C03D0000D03D000010340000F03D0000003E0000103E0000D0310000E031000050320000A0320000" & _
		"F0320000A0330000B03300001034000020340000A0340000D0340000E034000040350000C03500006036000080360000C0360000F01E000080390000103A0000303A0000703A0000A03A0000D03A0000803B0000B03B0000C03B0000F03B0000305D0000" & _
		"605D0000805D0000B03C0000003D0000503D000080160000105E0000405E0000B05E0000C0780000506F0000D0700000C072000060750000203E0000403E0000803E0000903E0000A03E0000B03E0000303F0000703F00001059000090590000105A0000" & _
		"405F0000705F000070140000B0140000E0140000B0140000F014000000150000A0690000C0690000306A0000D06A0000206B0000406B000023B9000034B9000049B9000070B900008CB900009BB90000AEB90000BBB90000D1B90000EBB9000005BA0000" & _
		"1FBA00003CBA000055BA00006FBA000088BA00009FBA0000B5BA0000D7BA0000E9BA000003BB000017BB00002EBB000044BB000054BB00006ABB000082BB000099BB0000ADBB0000C3BB0000DABB0000F1BB00000CBC000021BC000038BC000051BC0000" & _
		"65BC000079BC000090BC0000A5BC0000BCBC0000DABC0000F0BC00000BBD000027BD00003DBD000057BD00006FBD000086BD00009FBD0000B3BD0000C9BD0000DEBD0000F5BD00000CBE000027BE00003EBE000055BE00006FBE000086BE00009DBE0000" & _
		"B7BE0000D1BE0000E1BE0000F9BE000010BF000024BF00003ABF000055BF00006CBF000087BF00009EBF0000B7BF0000C9BF0000DDBF0000F5BF000010C000002FC0000051C0000075C0000087C0000098C00000AAC00000BBC00000CCC00000DEC00000" & _
		"EFC0000001C1000019C100002BC1000042C100005DC100006EC1000082C1000095C10000ABC10000C6C10000D9C10000F0C1000002C2000019C2000022C200002BC2000038C2000040C200004DC200005BC2000069C200007CC200008CC2000099C20000" & _
		"A8C2000000000100020003000400050006000700080009000A000B000C000D000E000F0010001100120013001400150016001700180019001A001B001C001D001E001F0020002100220023002400250026002700280029002A002B002C002D002E002F00" & _
		"30003100320033003400350036003700380039003A003B003C003D003E003F0040004100420043004400450046004700480049004A004B004C004D004E004F0050005100520053005400550056005700580059005A005B005C005D005E005F0060006100" & _
		"620063006400650066006700680069006A006B006C006D006E006F006A736F6E2D632E646C6C005F6A736F6E5F635F7374726572726F72006A736F6E5F635F6F626A6563745F73697A656F66006A736F6E5F635F7365745F73657269616C697A6174696F" & _
		"6E5F646F75626C655F666F726D6174006A736F6E5F635F7368616C6C6F775F636F70795F64656661756C74006A736F6E5F635F76657273696F6E006A736F6E5F635F76657273696F6E5F6E756D006A736F6E5F635F7669736974006A736F6E5F6F626A65" & _
		"63745F61727261795F616464006A736F6E5F6F626A6563745F61727261795F62736561726368006A736F6E5F6F626A6563745F61727261795F64656C5F696478006A736F6E5F6F626A6563745F61727261795F6765745F696478006A736F6E5F6F626A65" & _
		"63745F61727261795F696E736572745F696478006A736F6E5F6F626A6563745F61727261795F6C656E677468006A736F6E5F6F626A6563745F61727261795F7075745F696478006A736F6E5F6F626A6563745F61727261795F736872696E6B006A736F6E" & _
		"5F6F626A6563745F61727261795F736F7274006A736F6E5F6F626A6563745F646565705F636F7079006A736F6E5F6F626A6563745F646F75626C655F746F5F6A736F6E5F737472696E67006A736F6E5F6F626A6563745F657175616C006A736F6E5F6F62" & _
		"6A6563745F667265655F7573657264617461006A736F6E5F6F626A6563745F66726F6D5F6664006A736F6E5F6F626A6563745F66726F6D5F66645F6578006A736F6E5F6F626A6563745F66726F6D5F66696C65006A736F6E5F6F626A6563745F67657400" & _
		"6A736F6E5F6F626A6563745F6765745F6172726179006A736F6E5F6F626A6563745F6765745F626F6F6C65616E006A736F6E5F6F626A6563745F6765745F646F75626C65006A736F6E5F6F626A6563745F6765745F696E74006A736F6E5F6F626A656374" & _
		"5F6765745F696E743634006A736F6E5F6F626A6563745F6765745F6F626A656374006A736F6E5F6F626A6563745F6765745F737472696E67006A736F6E5F6F626A6563745F6765745F737472696E675F6C656E006A736F6E5F6F626A6563745F6765745F" & _
		"74797065006A736F6E5F6F626A6563745F6765745F75696E743634006A736F6E5F6F626A6563745F6765745F7573657264617461006A736F6E5F6F626A6563745F696E745F696E63006A736F6E5F6F626A6563745F69735F74797065006A736F6E5F6F62" & _
		"6A6563745F697465725F626567696E006A736F6E5F6F626A6563745F697465725F656E64006A736F6E5F6F626A6563745F697465725F657175616C006A736F6E5F6F626A6563745F697465725F696E69745F64656661756C74006A736F6E5F6F626A6563" & _
		"745F697465725F6E657874006A736F6E5F6F626A6563745F697465725F7065656B5F6E616D65006A736F6E5F6F626A6563745F697465725F7065656B5F76616C7565006A736F6E5F6F626A6563745F6E65775F6172726179006A736F6E5F6F626A656374" & _
		"5F6E65775F61727261795F657874006A736F6E5F6F626A6563745F6E65775F626F6F6C65616E006A736F6E5F6F626A6563745F6E65775F646F75626C65006A736F6E5F6F626A6563745F6E65775F646F75626C655F73006A736F6E5F6F626A6563745F6E" & _
		"65775F696E74006A736F6E5F6F626A6563745F6E65775F696E743634006A736F6E5F6F626A6563745F6E65775F6E756C6C006A736F6E5F6F626A6563745F6E65775F6F626A656374006A736F6E5F6F626A6563745F6E65775F737472696E67006A736F6E" & _
		"5F6F626A6563745F6E65775F737472696E675F6C656E006A736F6E5F6F626A6563745F6E65775F75696E743634006A736F6E5F6F626A6563745F6F626A6563745F616464006A736F6E5F6F626A6563745F6F626A6563745F6164645F6578006A736F6E5F" & _
		"6F626A6563745F6F626A6563745F64656C006A736F6E5F6F626A6563745F6F626A6563745F676574006A736F6E5F6F626A6563745F6F626A6563745F6765745F6578006A736F6E5F6F626A6563745F6F626A6563745F6C656E677468006A736F6E5F6F62" & _
		"6A6563745F707574006A736F6E5F6F626A6563745F7365745F626F6F6C65616E006A736F6E5F6F626A6563745F7365745F646F75626C65006A736F6E5F6F626A6563745F7365745F696E74006A736F6E5F6F626A6563745F7365745F696E743634006A73" & _
		"6F6E5F6F626A6563745F7365745F73657269616C697A6572006A736F6E5F6F626A6563745F7365745F737472696E67006A736F6E5F6F626A6563745F7365745F737472696E675F6C656E006A736F6E5F6F626A6563745F7365745F75696E743634006A73" & _
		"6F6E5F6F626A6563745F7365745F7573657264617461006A736F6E5F6F626A6563745F746F5F6664006A736F6E5F6F626A6563745F746F5F66696C65006A736F6E5F6F626A6563745F746F5F66696C655F657874006A736F6E5F6F626A6563745F746F5F" & _
		"6A736F6E5F737472696E67006A736F6E5F6F626A6563745F746F5F6A736F6E5F737472696E675F657874006A736F6E5F6F626A6563745F746F5F6A736F6E5F737472696E675F6C656E677468006A736F6E5F6F626A6563745F75736572646174615F746F" & _
		"5F6A736F6E5F737472696E67006A736F6E5F70617273655F646F75626C65006A736F6E5F70617273655F696E743634006A736F6E5F70617273655F75696E743634006A736F6E5F70617463685F6170706C79006A736F6E5F706F696E7465725F67657400" & _
		"6A736F6E5F706F696E7465725F67657466006A736F6E5F706F696E7465725F736574006A736F6E5F706F696E7465725F73657466006A736F6E5F746F6B656E65725F6572726F725F64657363006A736F6E5F746F6B656E65725F66726565006A736F6E5F" & _
		"746F6B656E65725F6765745F6572726F72006A736F6E5F746F6B656E65725F6765745F70617273655F656E64006A736F6E5F746F6B656E65725F6E6577006A736F6E5F746F6B656E65725F6E65775F6578006A736F6E5F746F6B656E65725F7061727365" & _
		"006A736F6E5F746F6B656E65725F70617273655F6578006A736F6E5F746F6B656E65725F70617273655F766572626F7365006A736F6E5F746F6B656E65725F7265736574006A736F6E5F746F6B656E65725F7365745F666C616773006A736F6E5F747970" & _
		"655F746F5F6E616D65006A736F6E5F7574696C5F6765745F6C6173745F657272006D635F6465627567006D635F6572726F72006D635F6765745F6465627567006D635F696E666F006D635F7365745F6465627567006D635F7365745F7379736C6F670070" & _
		"72696E746275665F66726565007072696E746275665F6D656D617070656E64007072696E746275665F6D656D736574007072696E746275665F6E6577007072696E746275665F726573657400737072696E74627566000000DCC300000000000000000000" & _
		"0AC5000010A00000CCC30000000000000000000058C5000000A0000018C400000000000000000000DCC500004CA0000054C400000000000000000000BEC7000088A00000E0C400000000000000000000DEC7000014A10000A8C400000000000000000000" & _
		"00C80000DCA0000078C40000000000000000000020C80000ACA000003CC40000000000000000000042C8000070A0000070C40000000000000000000064C80000A4A00000C8C40000000000000000000084C80000FCA0000068C400000000000000000000" & _
		"A6C800009CA00000D8C400000000000000000000C8C800000CA100004CC400000000000000000000E8C8000080A00000000000000000000000000000000000000000000046C5000030C5000018C5000000000000FCC40000ECC400001ECA000008CA0000" & _
		"ECC90000D2C90000BCC90000A6C900008CC9000070C900005CC9000048C900002AC900000EC9000000000000A2C5000066C5000070C500007AC5000084C500008EC5000098C50000C2C500000000000074C60000B4C60000BEC6000000000000E8C60000" & _
		"0000000088C60000F6C50000EEC5000000C6000000000000A8C60000000000007EC600000000000076C700005AC700008EC7000048C600006CC60000DCC60000F2C6000038C70000FEC600000CC700001EC70000000000001CC600002EC60000B4C70000" & _
		"ACC7000052C60000CAC60000A2C700000000000098C7000092C600009CC6000000000000D2C60000000000000AC6000014C600000000000087024765744C6173744572726F720000470347657456657273696F6E00004B45524E454C33322E646C6C0000" & _
		"C100437279707441637175697265436F6E74657874410000DC00437279707452656C65617365436F6E7465787400D200437279707447656E52616E646F6D000041445641504933322E646C6C000047006D656D6D6F76650048006D656D73657400004A00" & _
		"73747263687200004C00737472737472000046006D656D63707900004B00737472726368720025005F5F7374645F747970655F696E666F5F64657374726F795F6C697374000035005F6578636570745F68616E646C6572345F636F6D6D6F6E0056435255" & _
		"4E54494D453134302E646C6C0000180066726565000019006D616C6C6F6300001A007265616C6C6F630010006273656172636800190071736F72740000005F5F616372745F696F625F66756E630003005F5F737464696F5F636F6D6D6F6E5F7666707269" & _
		"6E74660023005F6572726E6F00000D005F5F737464696F5F636F6D6D6F6E5F76737072696E746600570061626F7274005E00737472746F64000035005F64636C61737300170063616C6C6F6300008E007374726E636D700034005F7374726E69636D7000" & _
		"13007365746C6F63616C65006300737472746F6C6C006500737472746F756C6C000049005F6F70656E0030005F74696D6536340067007374726572726F7200001000676574656E76000038005F696E69747465726D0039005F696E69747465726D5F6500" & _
		"41005F7365685F66696C7465725F646C6C0019005F636F6E6669677572655F6E6172726F775F61726776000035005F696E697469616C697A655F6E6172726F775F656E7669726F6E6D656E74000036005F696E697469616C697A655F6F6E657869745F74" & _
		"61626C65000024005F657865637574655F6F6E657869745F7461626C650017005F6365786974000029005F7374726475700017005F636C6F7365000052005F72656164006B005F777269746500006170692D6D732D77696E2D6372742D686561702D6C31" & _
		"2D312D302E646C6C00006170692D6D732D77696E2D6372742D7574696C6974792D6C312D312D302E646C6C006170692D6D732D77696E2D6372742D737464696F2D6C312D312D302E646C6C006170692D6D732D77696E2D6372742D72756E74696D652D6C" & _
		"312D312D302E646C6C006170692D6D732D77696E2D6372742D636F6E766572742D6C312D312D302E646C6C006170692D6D732D77696E2D6372742D6D6174682D6C312D312D302E646C6C00006170692D6D732D77696E2D6372742D737472696E672D6C31" & _
		"2D312D302E646C6C00006170692D6D732D77696E2D6372742D6C6F63616C652D6C312D312D302E646C6C00006170692D6D732D77696E2D6372742D74696D652D6C312D312D302E646C6C00006170692D6D732D77696E2D6372742D656E7669726F6E6D65" & _
		"6E742D6C312D312D302E646C6C00EA05556E68616E646C6564457863657074696F6E46696C7465720000A805536574556E68616E646C6564457863657074696F6E46696C746572003B0247657443757272656E7450726F6365737300C8055465726D696E" & _
		"61746550726F636573730000B503497350726F636573736F724665617475726550726573656E74007E045175657279506572666F726D616E6365436F756E746572003C0247657443757272656E7450726F63657373496400400247657443757272656E74" & _
		"54687265616449640000130347657453797374656D54696D65417346696C6554696D65003E0144697361626C655468726561644C69627261727943616C6C73009103496E697469616C697A65534C6973744865616400AD03497344656275676765725072" & _
		"6573656E740000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000068A1001058A10010A8A40010B0A40010BCA40010D0A40010E8A4001000A50010" & _
		"10A5001024A5001034A5001058A5001080A50010ACA50010D0A50010E8A50010FCA5001014A600102CA60010EFBFBD00ACA10010BCA60010C4A60010CCA60010D0A60010D8A60010E0A60010C0610010FFFFFFFF00000000010000002AAA001002000000" & _
		"36AA00100300000046AA00100400000052AA0010050000005EAA0010060000006AAA00100700000076AA00100800000082AA00100900000092AA00100A0000009EAA001024000000AEAA00100C000000BEAA00100D000000CEAA00100E000000DEAA0010" & _
		"10000000EEAA001011000000FAAA0010120000000AAB00101300000016AB00101400000026AB00101500000036AB00101600000046AB00101700000056AB00101800000066AB00101900000076AB00108B00000086AB00101B00000096AB00101C000000" & _
		"A2AB00101D000000B2AB00101E000000C2AB00101F000000CEAB001020000000DEAB001021000000EAAB001022000000F6AB00100B00000006AC001000000000000000004552524E4F3D0000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004EE640BB00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"0000000000000000B119BF44759800000000000000000000FFFFFFFFFFFFFFFF01000000FFFFFFFF010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"0000000000000100180000001800008000000000000000000000000000000100020000003000008000000000000000000000000000000100090400004800000060E000007D010000000000000000000000000000000000003C3F786D6C2076657273696F" & _
		"6E3D27312E302720656E636F64696E673D275554462D3827207374616E64616C6F6E653D27796573273F3E0D0A3C617373656D626C7920786D6C6E733D2775726E3A736368656D61732D6D6963726F736F66742D636F6D3A61736D2E763127206D616E69" & _
		"6665737456657273696F6E3D27312E30273E0D0A20203C7472757374496E666F20786D6C6E733D2275726E3A736368656D61732D6D6963726F736F66742D636F6D3A61736D2E7633223E0D0A202020203C73656375726974793E0D0A2020202020203C72" & _
		"657175657374656450726976696C656765733E0D0A20202020202020203C726571756573746564457865637574696F6E4C6576656C206C6576656C3D276173496E766F6B6572272075694163636573733D2766616C736527202F3E0D0A2020202020203C" & _
		"2F72657175657374656450726976696C656765733E0D0A202020203C2F73656375726974793E0D0A20203C2F7472757374496E666F3E0D0A3C2F617373656D626C793E0D0A00000000000000000000000000000000000000000000000000000000000000" & _
		"0000000000100000A00000003D30853045318C311132E6320E331E337633253451346134723482349E34B934D534E134F534053511354F357435E9351E363936CB360A3712372437AA3788398C399039943998399C39A039C939D439E639F239053A123A" & _
		"243A593AE93A093B1A3B243B283B2C3B303B343B383B673B843BCA3BD13B033C243C453C663C873CA83CC93CEE3C283D3F3DD83DDC3D3A3F7E3FBA3FD93F000000200000B8000000253032303F3051308C30AD30F13009313231443158317531AB31E331" & _
		"2D32EC32F73203336433CD337E34963409351E352A35A735E8350C361436193641364636A636AD3620372B37E93798399C39A039A439A839AC39B039C639133A443A613A6C3A703A743A783A7C3A803AB73A1B3B3F3B7A3B923BCA3BDC3BE83BEC3BF03B" & _
		"F43BF83BFC3BB83CD03C1E3D633D793DD13DDC3DE03DE43DE83DEC3DF03DC63E023F533F5C3F603F643F683F6C3F703F00300000B0000000F930143138313F31AF31E531FD310B32363254327532A432DA32F53236334133593362338A339133B433D933" & _
		"2534333449347C348534E43409357F35103612376D378537A537E237F2371E38323842384E386E387B388838A838063950396839BA39CC39F739403A063B183B223B2C3B363B403B4A3B583B5C3B603B643B683B6C3B703B3E3C4E3C7E3C923CBA3C0A3D" & _
		"633DC13D2C3E323E633E6A3EB33EE13EFF3EC63FD63F0000004000004000000002300D301D3026302F303E304630C830B931C031C432D63218343D34A134B734DB34F4344535D235F335323648360B3A9A3BA23BC23B000000500000C000000044304B30" & _
		"86309430A230B030BE301D32B832B837BC37C037C437C837CC37D037D437D837DC37E037E437E837EC37F037F437F837FC370038043808380C381038143818381C382038243828382C383038343838383C3840384438A438A838AC38B0387D398439A439" & _
		"313A453A4E3A653ABC3AD63AE73A1B3B353B7E3B8C3BCD3B003C133C213C3F3C513C8F3CDB3CEA3CF83C163D393D8A3DAE3DBD3DCB3DED3DFA3D1E3E463E683EB43EF33E4C3F553F733F793FEC3F000000600000B400000043304B300331173138314031" & _
		"58315C316031643168316C317031C231DD31FA311D33D433D833DC33E033E433E833EC33F033F433F833FC330034043451345734B835EF356E363737C738E938FA385B398339AD39B4391A3ABD3AD73AF63A063B473B663BFA3B253C963CB63CC03CCA3C" & _
		"CF3CE23CF03CFA3C043D093D1C3D443D4F3D5D3D723D7E3D973DA53DB93DE33D123E263E523E6A3E703E893E923EE93E173F763F853FD53FF93F000000700000C000000053306230AB30BB30213159316B319E31143221324032F9322133423351338333" & _
		"9B3342349934E334F2342435C035D635E6352D3648365A36223736375B37753718384D388438A938F73804392E39523958399C39C239E839233A3E3A443A733A813A893AC13AC73AE13A313B3F3B473B7E3B843BA53BF03B323C673CE33CE93C083D0E3D" & _
		"2D3D333D563D773D7D3DB03DC13DC63DE83D0B3E1C3E483E693E6F3EA83ED93EDF3E103F213F263F593F733F933FA43FC83FE23F008000006C0100004E307930C2302D316331723191319931A831B031C231E131E931F93142324B3256325D3270327E32" & _
		"84328A32903296329C32A332AA32B132B832BF32C632CD32D532DD32E532F132FA32FF3205330F3319332933393349335233783386338C33923398339E33A433AB33B233B933C033C733CE33D533DD33E533ED33F833FD3303340D3417342A342F349134" & _
		"C034CD34EE34F3340C3511351E35603568359B35A535B335D135E93552366436263763377D37B037BA37C6375F38AE3806390C3915391E3927392D393339483951395F3967399D39A639AF39BA39C239CC39D739E039E639063A0C3A163A1C3A253A2B3A" & _
		"333A383A4C3A513A853A933A9B3AA13AA73AB43ABA3AD93AE83AF13AFE3A143B4E3B573B683B743B803B863B8C3B983B0D3CB13CD13C023D353D5B3D6A3D813D873D8D3D933D993D9F3DA53DBA3DD23DD93DDF3DF13DFB3D633E703E943EA73E733F8C3F" & _
		"963FB03FBC3FC13FD43FE83FED3F0000009000003C000000003021303E30803085309F30A930AF30B530BB30C130C730CD30D330D930DF30E530EB30F130F730FD30033109310F311C31000000A00000140000002031903F943FDC3FE03FE83F00B00000" & _
		"1C000000403058301834383444345C3460347C348034000000D00000840000000030043008300C301030143018301C302030243028302C303030343038303C304030443048305030543058305C306030643068306C307C3084308C3094309C30A430AC30" & _
		"B430BC30C430CC30D430DC30E430EC30F430FC3004310C3114311C3124312C3134313C3144314C3154315C3164316C3174317C31843100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")
EndFunc

Func __JsonC_Dll_X64()
    Return Binary("0x" & _
        "4D5A90000300000004000000FFFF0000B800000000000000400000000000000000000000000000000000000000000000000000000000000000000000080100000E1FBA0E00B409CD21B8014CCD21546869732070726F6772616D2063616E6E6F74206265" & _
		"2072756E20696E20444F53206D6F64652E0D0D0A2400000000000000CA7C8FD88E1DE18B8E1DE18B8E1DE18B8765728B9C1DE18B0994E08A8C1DE18B09941C8B8A1DE18B0994E28A8A1DE18B0994E58A861DE18B0994E48A831DE18BF79CE08A8B1DE18B" & _
		"8E1DE08BC61DE18B1594E58A801DE18B1594E18A8F1DE18B15941E8B8F1DE18B1594E38A8F1DE18B526963688E1DE18B00000000000000000000000000000000504500006486060099F8276A0000000000000000F00022200B020E2C0092000000560000" & _
		"00000000E49600000010000000000080010000000010000000020000060000000500040006000000000000000030010000040000000000000200600100001000000000000010000000000000000010000000000000100000000000000000000010000000" & _
		"10D20000240E000034E000000401000000100100E001000000000100EC0A0000000000000000000000200100B800000050C300005400000000000000000000000000000000000000000000000000000010C2000040010000000000000000000000B00000" & _
		"600200000000000000000000000000000000000000000000000000002E7465787400000028910000001000000092000000040000000000000000000000000000200000602E726461746100001239000000B00000003A0000009600000000000000000000" & _
		"00000000400000402E64617461000000800B000000F000000006000000D00000000000000000000000000000400000C02E70646174610000EC0A000000000100000C000000D60000000000000000000000000000400000402E72737263000000E0010000" & _
		"001001000002000000E20000000000000000000000000000400000402E72656C6F630000B8000000002001000002000000E40000000000000000000000000000400000420000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000048895C24084889742410574883EC20488B7908488BF2488BD94883FFFE772A488D5701E81801000085C0751D488B03488934F848FF430833C0488B5C2430488B7424384883C4205FC3488B5C" & _
		"2430B8FFFFFFFF488B7424384883C4205FC3CCCC4883EC384C8944242041B9080000004C8B4208488B12FF15D4A100004883C438C3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC48896C2410488974241848897C242041564883EC20498BC0498BE848F7D04C8B" & _
		"F2488BF9483BD07769488B41084A8D3402483BD0735C483BF0775748895C2430488BDA483BD673220F1F840000000000488B07488B0CD84885C97406488B4718FFD048FFC3483BDE72E6488B074C8B47084C2BC649C1E003488D14F04A8D0CF0E8CB8E00" & _
		"0048296F08488B5C243033C0EB05B8FFFFFFFF488B6C2438488B742440488B7C24484883C420415EC3CCCCCC48895C2408574883EC20488B4110488BDA488BF9483BD0724848B9FFFFFFFFFFFFFF7F483BC1730D4803C0483BC2480F42C2488BD848B8FF" & _
		"FFFFFFFFFFFF1F483BD8772A488B0F488D14DD00000000FF15A39F00004885C0741448890748895F1033C0488B5C24304883C4205FC3488B5C2430B8FFFFFFFF4883C4205FC3CCCC48895C2408574883EC2033DB488BF94839590876266666660F1F8400" & _
		"00000000488B07488B0CD84885C97406488B4718FFD048FFC3483B5F0872E5488B0FFF153C9F0000488BCF488B5C24304883C4205F48FF25289F0000CCCCCCCCCCCCCCCC483B5108720333C0C3488B01488B04D0C3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC" & _
		"48895C241048896C2418574883EC20488BFA498BE8488B5108488BD9483BFA0F829A0000004883FFFE0F87DA0000004889742430488D7701488BD6E8C0FEFFFF85C0741A488B742430B8FFFFFFFF488B5C2438488B6C24404883C4205FC3483B7B087312" & _
		"488B03488B0CF84885C97406488B4318FFD0488B0348892CF8488B4B08483BF97618488B034C8BC74C2BC133D249C1E003488D0CC8E8088D000048397B08770448897308488B74243033C0488B5C2438488B6C24404883C4205FC34883FAFF744448FFC2" & _
		"E833FEFFFF85C07538488B034C8B43084C2BC749C1E003488D14F8488D4A08E8B48C0000488B0348892CF848FF430833C0488B5C2438488B6C24404883C4205FC3488B5C2438B8FFFFFFFF488B6C24404883C4205FC3CCCC488B4108C3CCCCCCCCCCCCCC" & _
		"CCCCCCCC48895C24084889742410574883EC20488BF185D278544863FA48B8FFFFFFFFFFFFFF1F483BF87342B920000000FF15A59D0000488BD84885C0742F488D0CFD000000004889781048C740080000000048897018FF157F9D00004889034885C075" & _
		"1B488BCBFF15669D000033C0488B5C2430488B7424384883C4205FC3488B742438488BC3488B5C24304883C4205FC3CC48895C240848896C24104889742418574883EC20498BE8488BFA488BD94883FAFE775E488D7201488BD6E811FDFFFF85C0754E48" & _
		"3B7B087312488B03488B0CF84885C97406488B4318FFD0488B0348892CF8488B4B08483BF97618488B034C8BC74C2BC133D249C1E003488D0CC8E8738B000048397B0877044889730833C0EB05B8FFFFFFFF488B5C2430488B6C2438488B7424404883C4" & _
		"205FC3CCCCCCCCCC48895C2408574883EC20488BF948B8FFFFFFFFFFFFFF1F488B4908482BC1483BD07357488D1C11483B5F1074407615488BD3488BCF488B5C24304883C4205FE95CFCFFFF488B0FB8010000004885DB480F44D8488D14DD00000000FF" & _
		"15379C00004885C0741448890748895F1033C0488B5C24304883C4205FC3488B5C2430B8FFFFFFFF4883C4205FC3CCCCCCCCCCCC4C8BCA41B808000000488B5108488B0948FF25019D0000CCCCCCCCCCCCCCCCCC488D0519E60000C3CCCCCCCCCCCCCCCC" & _
		"488BC448894808488950104C8940184C894820574883EC40833DD5DE000000488BF97440488958F0B901000000488970E8488D7010FF152D9C0000488BD8E8ADFFFFFF4533C948897424204C8BC7488BD3488B08FF15269C0000488B742430488B5C2438" & _
		"4883C4405FC3CCCCCCCCCCCC48894C240848895424104C894424184C894C24205356574883EC30488BF9488D742458B902000000FF15CA9B0000488BD8E84AFFFFFF4533C948897424204C8BC7488BD3488B08FF15C39B00004883C4305F5E5BC3CCCCCC" & _
		"CCCCCCCCCCCCCCCC8B051EDE0000C3CCCCCCCCCCCCCCCCCC890D0EDE0000C3CCCCCCCCCCCCCCCCCC890DFADD0000C3CCCCCCCCCCCCCCCCCC488D05799C0000C3CCCCCCCCCCCCCCCCB800120000C3CCCCCCCCCCCCCCCCCCCC48895C240848897424105748" & _
		"83EC2048B8CEFFFFFFFFFFFF7F488BFA488BF1483BD077704883FA08488D4A31B839000000480F42C8FF158D9A0000488BD84885C07451C70006000000488D4B30C74004010000004C8BC7488D05A2290000488BD64889430833C0488943104889431848" & _
		"89432048897B28E802890000488BC3C6443B3000488B5C2430488B7424384883C4205FC3488B5C243033C0488B7424384883C4205FC3CCCCCCCCCCCCCCCCCCCC48895C240848896C2410488974241857415641574883EC20498BD8488BEA488BF14885C9" & _
		"0F84AE0000008339060F85A50000004881FBFEFFFF7F0F8398000000488B41284885C0792D4885DB7518488B4930FF15B899000033C94C8D7E3048894E288BC1EB174C8B76304C8D7E30488BC848F7D9EB0A4C8D7930488BC84D8BF7488BFB483BD97E27" & _
		"488D4B01FF15869900004C8BF04885C0743E48837E28007D09498B0FFF15669900004D8937EB054885C07906488BFB48F7DF4C8BC3488BD5498BCEE80688000041C6041E00B80100000048897E28EB0233C0488B5C2440488B6C2448488B7424504883C4" & _
		"20415F415E5FC3CCCCCCCCCCCCCCCCCCCCCCCCCC48895C24084889742410574883EC20488B5920488BF2488BCBE8C8870000448BC0488BD3488BCE488BF8E8A15E0000488B5C24308BC7488B7424384883C4205FC3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC" & _
		"48895424104C894424184C894C24205356574883EC30488BFA488D742460488BD9E8AAFCFFFF4533C948897424204C8BC7488BD3488B08FF15239900004883C4305F5E5BC3CCCCCCCCCCCCCCCCCCCCCC40534883EC20488BD94885C9741DB902000000FF" & _
		"15DF9800004C8BC3488D15BD9C0000488BC8E885FFFFFFFF15A7980000CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC48895C241048896C241848897424205741544155415641574883EC204C8BE14C8BEA488B4928E825FAFFFF498B4D284C8BF8E819FAFFFF4C" & _
		"3BF80F858000000033ED4D85FF0F84F5010000488D1D9EE6FFFF498B4D28488BD5E8B2F8FFFF498B4C2428488BD5488BF8E8A2F8FFFF4C8BF0483BC70F84BA0100004885C074414885FF743C4863003B07753583F80677308B8C835C1B00004803CBFFE1" & _
		"8B472833C9413946280F94C1E97F010000F2410F104628660F2E47287A060F847401000033C0488B5C2458488B6C2460488B7424684883C420415F415E415D415C5FC341837E2800752F837F28007512488B473033C9493946300F94C1E92E010000498B" & _
		"46304885C078B933C9483B47300F94C1E917010000837F2801488B4730750E33C9493946300F94C1E9FF0000004885C0788E33C9493946300F94C1E9EC0000004D8B4E28488B4F284D8BC149F7D8488BC14D0F48C148F7D8480F48C14C3BC00F855BFFFF" & _
		"FF4885C97906488B5730EB04488D5730498D4E304D85C97903488B09E86385000085C00F8533FFFFFFE9A2000000498B4628488B5808660F1F4400004885DB743B488B134C8D442450488B4F28488B7310E8865A000085C07417488B542450488BCEE845" & _
		"0F000085C07406488B5B18EBCB33C9488D1D12E5FFFFEB4C833F04740433DBEB04488B5F28488B5B084885DB741B488B134C8D442450498B4E28E8395A000085C074CA488B5B18EBE0B901000000488D1DD3E4FFFFEB0D488BD7498BCEE8D6FDFFFF8BC8" & _
		"85C90F848CFEFFFF48FFC5493BEF0F8212FEFFFFB801000000E978FEFFFF6690441B0000AC190000BD190000EF190000A21A00002F1B0000501A0000CCCCCCCCCCCCCCCCB828000000C3CCCCCCCCCCCCCCCCCCCC40534883EC20488BD985D2754D488B0D" & _
		"B4D800004885C97406FF15919500004885DB7425488BCBFF155B9600004885C07519488D0DF7970000E822470000B8FFFFFFFF4883C4205BC333C048890576D8000033C04883C4205BC383FA017517488D0D0A980000E8F5460000B8FFFFFFFF4883C420" & _
		"5BC3488D0D43980000E8DE460000B8FFFFFFFF4883C4205BC3CCCCCC48895C2408574883EC208B01488BD9488B7C2450FFC883F8050F87C8000000488D0DBAE3FFFF48988B9481301D00004803D1FFE28B4B28E8C4180000EB6AF20F104328E808190000" & _
		"EB5E8B4B2885C9741483F9010F85A9000000488B4B30E8BD1B0000EB43488B4B30E8821A0000EB38488B43284C8D4330488BC848F7D9480F48C84885C079034D8B004863D1498BC8E8CBF9FFFFEB11E8C41A0000EB0AB920000000E8D817000048890748" & _
		"8BC84885C0751CFF15D7940000C7000C000000B8FFFFFFFF488B5C24304883C4205FC3488B430848894108B801000000488B5C24304883C4205FC3FF15A3940000488B5C2430C70016000000B8FFFFFFFF4883C4205FC3488D0D6E960000E8A1FBFFFFCC" & _
		"541C00005E1C00006A1C0000B71C0000BE1C0000901C0000CCCCCCCCCCCCCCCC4C894424184C894C2420535556574883EC38498BD8488D6C2478488BF2488BF9E8DBF7FFFF48896C24284C8BCB4C8BC648C744242000000000488BD7488B084883C901FF" & _
		"153F940000B9FFFFFFFFC64437FF0085C00F48C14883C4385F5E5D5BC3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC4C8BDC535557415641574883EC40488B05EBD500004833C4488944243833DB458BF9498BE84C8BF2488BF9448BD34D85C00F84E201000049" & _
		"8973184D8963204C8D25FAE1FFFF66660F1F840000000000410FB6341E48FFCD8D46F883F8540F87D20000004898410FB68404FC1F0000418B8C84F41F00004903CCFFE141F6C710740A4080FE2F0F845A010000493BDA7612448BC34B8D1416452BC248" & _
		"8BCFE89D5800004080FE087509488D15A0940000EB6B4080FE0A7509488D1595940000EB5C4080FE0D7509488D158A940000EB4D4080FE097509488D157F940000EB3E4080FE0C7509488D1574940000EB2F4080FE227509488D1569940000EB204080FE" & _
		"5C7509488D155E940000EB114080FE2F0F85C8000000488D154F94000041B802000000488BCFE81558000048FFC34C8BD3E9B30000004080FE200F83A6000000493BDA7612448BC34B8D1416452BC2488BCFE8E9570000488B0DE2D00000488BC683E00F" & _
		"4C8BC649C1E8040FBE1408450FBE0C084C8D05F593000089542420488D4C2430BA07000000E802FEFFFF48634F088B470C2BC183F8067E2F8B442430488BD148031748FFC34C8BD389020FB74424346689420448634F088D4106894708488B07C6440106" & _
		"00EB1E41B806000000488D542430488BCFE86257000048FFC34C8BD3EB0348FFC34885ED0F855EFEFFFF4C8BA42488000000488BB42480000000493BDA7612412BDA4B8D1416448BC3488BCFE82757000033C0488B4C24384833CCE8C87000004883C440" & _
		"415F415E5F5D5BC33C1E0000F61E0000000000010000010101010101010101010101010101010101010100010101010101010101010101000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101" & _
		"00CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC488B4928E997EFFFFFCCCCCCCCCCCCCC48894C24084883EC28488B5228488D4C2430E8D9EFFFFF4885C075054883C428C3488B004883C428C3CCCCCCCCCCCCCC488B4928E9E7EFFFFFCCCCCCCCCCCCCC4885C974" & _
		"6C534883EC20834104FF488BD97559488B41184885C07406488B5120FFD08B0B83E904742883E901741883F901752748837B28007D20488B4B30FF154C900000EB14488B4B28E8C1F0FFFFEB09488B4B28E846500000488B4B10E8BD550000488BCBFF15" & _
		"249000004883C4205BC3CCCCCCCCCCCCCCCCCCCCCCCCCCCC488B4928E9E7F0FFFFCCCCCCCCCCCCCC488B4928E9F7F0FFFFCCCCCCCCCCCCCC488B4928E907F2FFFFCCCCCCCCCCCCCC488B4928E997F2FFFFCCCCCCCCCCCCCC4883EC2885D27810488B4928" & _
		"4863D24883C428E918F3FFFF488D0D59930000E83CF7FFFFCCCCCCCCCCCCCCCCCCCCCCCC488B4928E987F3FFFFCCCCCCCCCCCCCC48895C2410448944241848894C240855565741544155415641574883EC20488BFA458BF8488BD9488D15FA920000488B" & _
		"CF41B801000000418BE94533E4E80E550000488B4B288BF5448BF583E6024183E601E859F1FFFF4885C00F842B01000041FFC7458BEC85F6741541B801000000488D1525910000488BCFE8D154000041BC010000004585F6741885F67518458BC4488D15" & _
		"08910000488BCFE8B0540000EB2C85F67428BAFFFFFFFF488BCF40F6C508740B458BCF41B809000000EB0A478D0C3F41B820000000E822550000488B4B28498BD5E896EFFFFF488BC84885C0755B488BCF40F6C520743E41B807000000488D15D0900000" & _
		"E85354000041B804000000488D1582900000488BCFE83E54000041B804000000488D1595900000488BCFE829540000EB2741B804000000488D1556900000E815540000EB13488B4008448BCD458BC7488BD7FFD085C07872488B4C2460498D5D014C8BEB" & _
		"488B4928E84BF0FFFF483BD8731C458BC4488D1524900000488BCFE8D4530000488B5C2460E9E0FEFFFF448B7C247085F674494585E4744441B801000000488D15FB8F0000488BCFE8A7530000BAFFFFFFFF488BCF40F6C5087412458BCF41B809000000" & _
		"EB11B8FFFFFFFFEB3C478D0C3F41B820000000E8185400004585F6741385F6750F41B802000000488D153E910000EB0D41B801000000488D1533910000488BCFE84B530000488B5C24684883C420415F415E415D415C5F5E5DC3CCCCCCCCCCCC48895C24" & _
		"084889742410574883EC20418BD9488BFA488BF183E320741541B807000000488D157E8F0000488BCFE8FE5200008B4E28488D157C8F00008BC1F7D8488D05798F0000451BC04183C00585C9488BCF480F44D0E8D452000083F8FF7E1985DB741541B804" & _
		"000000488D15228F0000488BCFE8B6520000488B5C2430488B7424384883C4205FC3CCCCCCCCCCCC40534883EC30488BDA4885C9745A4885D2745548833A00754F4D85C048897C2440488D0598F7FFFF41B9FFFFFFFF490F45C04533C048894424284889" & _
		"54242033D2E83A0000008BF885C0790F488B0BE8EC18000048C703000000008BC7488B7C24404883C4305BC3FF15E28C0000C70016000000B8FFFFFFFF4883C4305BC3CC40564154415541574883EC484C8BBC2490000000488BF14C8BA424980000004C" & _
		"897C242041FFD4448BE883F8017D1DFF159B8C0000C70016000000B8FFFFFFFF4883C448415F415D415C5EC38B0E48895C247048896C24784889BC248000000033FF4C8974244083E9040F844801000083F901757C488B4E28E802EEFFFF488BE88BDF48" & _
		"85C074690F1F840000000000488B4E28488BD348897C2430E89FECFFFF4885C0750A488BD74889542430EB29488D4C24304C8964242848894C24204C8BCB488BC84533C0488BD6E830FFFFFF85C07879488B542430498B0F488B4928E83BEAFFFF85C078" & _
		"6448FFC3483BDD729F4183FD020F8483010000488B4E20498B1F4885C9750A48397E180F8469010000488B5308488D05E41C0000483BD00F8429010000488D0524F2FFFF483BD00F8419010000488D0D448F0000E8CF3C0000BFFFFFFFFF8BC7E9330100" & _
		"00488B5C24304885DB0F84EC000000BDFFFFFFFF016B040F85DE000000488B43184885C07409488B5320488BCBFFD08B0B83E9040F84A600000083E901742283F9010F85A100000048397B280F8D97000000488B4B30FF15B88A0000E988000000488B4B" & _
		"28E82AEBFFFFEB7D488B4628BDFFFFFFFF488B58084885DB0F8423FFFFFF488B4B104C8BC74C8B3348897C24304885C97426488D4424304C896424284C8BCD48894424204D8BC6488BD6E801FEFFFF85C0781A4C8B442430498B0F498BD6E8AD11000085" & _
		"C07806488B5B18EBA8488B5C24304885DB7420E934FFFFFF488B4B28E83B4A0000488B4B10E8B24F0000488BCBFF15198A0000B8FFFFFFFFEB32FF15E48A00004885C07515488D0DE88D0000E8AB3B0000BFFFFFFFFF8BC7EB1248894320488B4E184889" & _
		"4B188BC7EB0233C0488BBC2480000000488B6C2478488B5C24704C8B7424404883C448415F415D415C5EC3CCCCCCCCCCCCCCCCCCCCCCCCCC4883EC38488B41204889442420E82E0000004883C438C3CCCCCCCCCCCCCCCCCC4883EC3848C7442420000000" & _
		"00E80E0000004883C438C3CCCCCCCCCCCCCCCCCC48895C241855565741544155415641574881ECB0000000488B05D2CB00004833C448898424A0000000F20F105928458BF9488BBC24100100004C8BE2660F2EDB0F9AC03C0175094C8D057E8C0000EB32" & _
		"0F28C30F5405F68D0000660F2F05DE8D00000F93C03C01752F0F57C04C8D055D8C0000660F2FD8488D05628C00004C0F46C0BA80000000488D4C2420E8EFF4FFFF8BD8E96001000033ED4C8D2D4B8C0000448BF54885FF7511488B05D8CB0000498BFD48" & _
		"85C0480F45F866490F7ED9488D4C24204C8BC7BA80000000E8AFF4FFFF8BD885C00F8843010000BA2C000000488D4C2420E832770000488BF04885C07405C6002EEB12BA2E000000488D4C2420E816770000488BF0493BFD7414488D15DF8B0000488BCF" & _
		"E8057700004885C0750641BE010000000FB64C24208D41D03C09761583FB017E1580F92D75100FB64424212C303C097705BD0100000083FB7E7D5585ED74514885F67551BA65000000488D4C2420E8B17600004885C00F85960000004585F60F848D0000" & _
		"00488D4C242048FFC980790100488D490175F60FB705628B000083C3026689010FB605578B0000884102EB504885F6744F41F6C7047449807E0100488D5E01488BCB74310FB6130F1F4000660F1F84000000000080FA30488BC10FB65101480F44C348FF" & _
		"C1488BD884D275E83810740548FFC38813488D4424202BD885DB782281FB80000000B87F0000000F4DD8448BC3488D542420498BCCE8164D00008BC3EB05B8FFFFFFFF488B8C24A00000004833CCE8AD660000488B9C24000100004881C4B0000000415F" & _
		"415E415D415C5F5E5DC3CCCC48895C24184889742420574883EC20488BFA488BF1483BCA0F84120200004885C90F84F70100004885D20F84EE0100004863013B020F85E301000083F8060F87DA010000488D1595D5FFFF8B8C82682C00004803CAFFE18B" & _
		"4F2833DB394E280F94C38BC3488B5C2440488B7424484883C4205FC3F20F104628660F2E47280F8BBA00000033DB8BC3488B5C2440488B7424484883C4205FC3837E28008B4F28752C488B463085C974094885C00F886C01000033DB483B47300F94C38B" & _
		"C3488B5C2440488B7424484883C4205FC3488B473083F90174094885C00F883F01000033DB483946300F94C38BC3488B5C2440488B7424484883C4205FC34C8B4E28488B4F284D8BC149F7D8488BC14D0F48C148F7D8480F48C14C3BC00F8565FFFFFF48" & _
		"8D57304885C97903488B12488D4E304D85C97903488B09E89C74000085C00F8540FFFFFFBB010000008BC3488B5C2440488B7424484883C4205FC3488B462848896C2438488B58084885DB7449488B134C8D442430488B4F28488B6B10E8AE49000085C0" & _
		"7417488B542430488BCDE86DFEFFFF85C07406488B5B18EBCB488B6C243833DB8BC3488B5C2440488B7424484883C4205FC3833F047405488BFBEB04488B7F28488B7F084885FF741B488B174C8D442430488B4E28E85249000085C0740B488B7F18EBE0" & _
		"BB01000000488B6C24388BC3488B5C2440488B7424484883C4205FC3488BD7488BCE488B5C2440488B7424484883C4205FE9D2ECFFFF33C0488B5C2440488B7424484883C4205FC3488B5C2440B801000000488B7424484883C4205FC30F1F00502C0000" & _
		"772A0000942A0000B82A00007B2B0000242C00001A2B0000CCCCCCCCCCCCCCCCCCCCCCCC488BCA48FF25A6840000CCCCCCCCCCCC4885C9750333C0C3FF4104488BC1C3CC4885C9750333C0C383390575F8488B4128C3CCCCCCCCCCCCCCCCCCCCCCCCCCCC" & _
		"4883EC284885C9750733C04883C428C38B1183EA01745183EA01743283EA01741333C083FA037543483941280F95C04883C428C38B512885D2740583FA01753033C0483941300F95C04883C428C3F20F1049280F57C0660F2EC87A0274ABB80100000048" & _
		"83C428C38B41284883C428C3488D0D51860000E884EBFFFFCCCCCCCC48895C2410574883EC3033FF488BD948897C24404885C9742E8B0983E9010F844401000083E9010F842B01000083E9010F84C600000083F903741AFF151F840000C700160000000F" & _
		"57C0488B5C24484883C4305FC30F29742420FF15008400008938488D7B3048837B28007D05488B0FEB03488BCF488D542440FF154083000048837B28000F28F07D03488B3F488B442440483BC77405803800741FFF15BE8300000F287424200F57C0C700" & _
		"16000000488B5C24484883C4305FC3F20F1005D5870000660F2EC67A027410F20F1005DD870000660F2EC67A10750EFF157F83000083382275030F57F60F28C60F28742420488B5C24484883C4305FC38B4B2885C9744183F9017574488B4B300F57C048" & _
		"85C97810F2480F2AC1488B5C24484883C4305FC3488BC183E10148D1E8480BC1F2480F2AC0F20F58C0488B5C24484883C4305FC30F57C0F2480F2A4330488B5C24484883C4305FC3F20F104328488B5C24484883C4305FC3660F6E4328488B5C2448F30F" & _
		"E6C04883C4305FC3488D0DC5840000E8F8E9FFFFCCCCCCCCCCCCCCCC4883EC284533C04C894424304885C90F84BF0000008B1183FA03754C443941284C8B4130741148B8FFFFFFFFFFFFFF7F4C3BC04C0F43C083EA010F848C00000083EA01744D83FA01" & _
		"0F85860000004981F8000000807E4E4981F8FFFFFF7F7D59418BC04883C428C383FA0675CA488D41304C3941287D03488B00488D542430488BC8E86938000085C075494C8B442430EBBCF20F104928F20F100571860000660F2FC1720AB8000000804883" & _
		"C428C3660F2F0D39860000720AB8FFFFFF7F4883C428C3F20F2CC14883C428C38B41284883C428C333C04883C428C3CCCCCCCCCC4883EC284885C9750733C04883C428C38B1183EA010F84A300000049B8FFFFFFFFFFFFFF7F83EA01745683EA01742E83" & _
		"FA0375D54883792800488D41307D03488B00488D542430488BC8E8C137000085C075B6488B4424304883C428C38B512885D2741383FA01755E488B4130493BC0731D4883C428C3488B41304883C428C3F20F104928660F2F0D8B8500007208498BC04883" & _
		"C428C3F20F100599850000660F2FC1720F48B800000000000000804883C428C3F2480F2CC14883C428C3486341284883C428C3488D0D0A830000E83DE8FFFFCCCCCCCCCCCCCCCCCCCCCCCCCC4885C9750333C0C383390475F8488B4128C3CCCCCCCCCCCC" & _
		"CCCCCCCCCCCCCCCC40534883EC20488BD94885C9750833C04883C4205BC38339067455488B411048897C243033FF4885C0750EE870470000488943104885C07429488BC8E8BF470000488B430841B901000000488B53104533C0488BCBFFD085C0780748" & _
		"8B4310488B38488BC7488B7C24304883C4205BC34883792800488D41307D03488B004883C4205BC3CCCCCCCCCCCCCCCCCCCCCCCC4885C9750333C0C383390675F8488B412848F7D8480F484128C3CCCCCCCCCCCC4885C9750333C0C38B01C3CCCCCCCCCC" & _
		"4883EC284885C974618B1183EA010F84B500000083EA01745883EA01742E83FA0375474883792800488D41307D03488B00488D542430488BC8E8A236000085C07528488B4424304883C428C38B512885D2740E83FA01757A488B41304883C428C3488B41" & _
		"304885C0790233C04883C428C3F20F104928660F2F0DE2830000720C48C7C0FFFFFFFF4883C428C30F57C0660F2FC177D5F20F1005BB83000033C9660F2FC87217F20F5CC8660F2FC8730D48B80000000000000080488BC8F2480F2CC14803C14883C428" & _
		"C3486341284883C428C3488D0D3F810000E872E6FFFFCCCC4885C97405488B4120C333C0C3CCCCCC4883EC284885C90F84D50000008339030F85CC000000448B41284585C074584183F8010F85C00000004885D27E1C488BC248F7D048394130761048C7" & _
		"4130FFFFFFFF418BC04883C428C3488BC248F7D84885D2797F4C8B41304C3BC0498D0410488941307372C7412800000000B8010000004883C428C34885D27E324C8B413048B8FFFFFFFFFFFFFF7F482BC24C3BC07E19498D0410C7412801000000488941" & _
		"30B8010000004883C428C34885D2792449B80000000000000080498BC0482BC2483941307D0E4C894130B8010000004883C428C348015130B8010000004883C428C333C04883C428C3488D0D38800000E86BE5FFFFCCCCCCCCCCCCCCCCCCCCCC40534883" & _
		"EC40488B0543C000004833C448894424384C8B49304C8D051C80000083792800488BDABA15000000488D4C242074074C8D050A800000E8A1E9FFFF488D4C2420E85D6C0000448BC0488D542420488BCBE837430000488B4C24384833CCE8DA5C00004883" & _
		"C4405BC3CCCCCCCC33C04885C9750685D20F94C0C339110F94C0C3CCCCCCCCCCCCCCCCCCCCCCCCCC40534883EC2083790800488BD97509488B09FF15287D0000488B5B104885DB7468834304FF7562488B43184885C07409488B5320488BCBFFD08B0B83" & _
		"E904742883E901741883F901752748837B28007D20488B4B30FF15E57C0000EB14488B4B28E85ADDFFFFEB09488B4B28E8DF3C0000488B4B10E856420000488BCB4883C4205B48FF25B77C00004883C4205BC3CCB920000000E906000000CCCCCCCCCCCC" & _
		"48895C2408574883EC208BF9B930000000FF15917C0000488BD84885C07446C70005000000488D0DE4EBFFFFC74004010000008BD7488D05D4ECFFFF4889430833C0488943104889431848894320E87DDEFFFF488943284885C07516488BCBFF153B7C00" & _
		"0033C0488B5C24304883C4205FC3488BC3488B5C24304883C4205FC340534883EC208BD9B930000000FF15157C00004885C0742F488D0D91EEFFFFC700010000004889480833C9488948104889481848894820C74004010000008958284883C4205BC348" & _
		"83C4205BC3CCCCCC4883EC380F29742420B9300000000F28F0FF15C17B00004885C0743533C9C70002000000488948104889481848894820488D0D09F2FFFF48894808C7400401000000F20F1170280F287424204883C438C30F287424204883C438C3CC" & _
		"CCCCCCCC48895C2408574883EC300F29742420B9300000000F28F0488BFAFF15587B0000488BD84885C0745AC70002000000488BCFC740040100000033C0488943104889431848894320488D0593F1FFFF48894308F20F117328FF15EC7B0000488BF848" & _
		"85C07530488B4B10E893400000488BCBFF15FA7A0000FF15647B0000C7000C00000033C0488B5C24400F287424204883C4305FC3488B43184885C07409488B5320488BCBFFD00F28742420488D050EF6FFFF48894318488D05A3E1FFFF48894308488BC3" & _
		"48897B20488B5C24404883C4305FC3CCCCCCCCCCCCCCCCCCCCCCCCCC40534883EC204863D9B938000000FF15847A000033D24885C07431C70003000000488D0D98FCFFFF48894808C7400401000000488950104889501848895020488958308950284883" & _
		"C4205BC3488BC24883C4205BC3CCCCCCCCCCCCCCCCCCCCCC40534883EC20488BD9B938000000FF15247A00004885C07433488D0D40FCFFFFC700030000004889480833C9488948104889481848894820C7400401000000488958308948284883C4205BC3" & _
		"4883C4205BC3CCCCCCCCCCCCCCCCCCCCCCCCCCCC33C0C3CCCCCCCCCCCCCCCCCCCCCCCCCC40534883EC20B930000000FF15B7790000488BD84885C0745EC70004000000488D155AFCFFFFC7400401000000B910000000488D05E70200004889430833C048" & _
		"8943104889431848894320E850370000488943284885C07526488B4B10E8EE3E0000488BCBFF1555790000FF15BF790000C7000C00000033C04883C4205BC3488BC34883C4205BC3CCCCCCCCCCCCCCCC40534883EC20488BD9E8F8670000488BD0488BCB" & _
		"4883C4205BE952DEFFFFCCCC4863D2E948DEFFFFCCCCCCCCCCCCCCCC40534883EC20488BD9B938000000FF15F47800004885C07437488D0D10FBFFFFC700030000004889480833C9488948104889481848894820C740040100000048895830C740280100" & _
		"00004883C4205BC34883C4205BC3CCCCCCCCCCCCCCCCCCCC48895C240848896C2410488974241848897C242041564883EC30488B4128488BE9488BCA498BF8488BF24C8B482841FFD1488B4D28448BC0488BD6448BF0E8AD3B0000488BD8483BEF7507B8" & _
		"FFFFFFFFEB3F4885DB7526488BCEFF15187900004885C074E6488B4D28458BCE4C8BC7895C2420488BD0E885380000EB14488B48104885C97405E87504000048897B1033C0488B5C2440488B6C2448488B742450488B7C24584883C430415EC3CCCCCCCC" & _
		"48895C240848896C2410488974241857415641574883EC30488B4128488BFA488BE9458BF1488BCF498BF0488B5028FFD2448BF841F6C602740433DBEB12488B4D28458BC7488BD7E8F33A0000488BD8483BEE744B4885DB753041F6C604750C488BCFFF" & _
		"155F780000488BF84885FF742F488B4D28458BCF4C8BC64489742420488BD7E8C8370000EB1B488B4B104885C97405E8B80300004889731033C0EB05B8FFFFFFFF488B5C2450488B6C2458488B7424604883C430415F415E5FC3CCCC488B4928E9C73500" & _
		"00CCCCCCCCCCCCCC4883EC2848C7442430000000004885C9741D8339047518488B49284C8D442430E80B3B0000488B4424304883C428C333C04883C428C3CCCCCCCCCCCCCCCCCCCC33C04D85C074034989004885C9741783390474094D85C0740D498900" & _
		"C3488B4928E9CA3A0000C3CCCCCCCCCCCCCCCCCC488B4928E927390000CCCCCCCCCCCCCC448944241853555657415441564883EC38488BDA488BF9488BCB488D158378000041B801000000418BE933F6E82F3C00008BC64885FF7409833F047504488B47" & _
		"284C8B7008448BE54183E4024C896C24788BFD4C897C243083E701897C2470904D85F60F84EC010000498B064D8B6E10488944242085F6741541B801000000488D1522780000488BCBE8D23B00004585E4741541B801000000488D150C780000488BCBE8" & _
		"B83B0000448BFDC7442428010000004183E70174254585E4752041B801000000488D15E5770000488BCBE88D3B00008BB42480000000FFC6EB368BB42480000000FFC64585E47428BAFFFFFFFF488BCB40F6C508740B448BCE41B809000000EB0A448D0C" & _
		"3641B820000000E8EC3B00008BFD83E720741541B807000000488D1590770000488BCBE8303B000041B801000000488D1583770000488BCBE81B3B0000488B4C2420E827640000488B542420448BCD4C8BC0488BCBE8BEE1FFFF41B801000000488D1551" & _
		"770000488BCBE8E93A000085FF741541B804000000488D153C770000488BCBE8D03A0000488D05397700004585FF488D152B770000488BCB480F44D0458D4701E8AF3A00004D85ED7571488BCB85FF744A41B807000000488D150E770000E8913A000041" & _
		"B804000000488D15C0760000488BCBE87C3A000041B804000000488D15D3760000488BCBE8673A00004D8B7618488B742428E959FEFFFF41B804000000488D1588760000E8473A00004D8B7618488B742428E939FEFFFF498B4508448BCD448BC6488BD3" & _
		"498BCDFFD085C0780E4D8B7618488B742428E915FEFFFFB8FFFFFFFFE9910000008B7C24708BC74585E4745985F6745541B801000000488D153B760000488BCBE8E7390000BAFFFFFFFF488BCB40F6C508741A448B8C248000000041B809000000E8663A" & _
		"00008BC583E001EB188B84248000000041B820000000448D0C00E8493A00008BC785C074144585E4750F41B802000000488D1511760000EB0D41B801000000488D1506760000488BCBE87A3900004C8B7C24304C8B6C24784883C438415E415C5F5E5D5B" & _
		"C3CCCCCC40534883EC20488BD94885C9746A834104FF7564488B41184885C07406488B5120FFD08B0B83E904742883E901741883F901752748837B28007D20488B4B30FF155B730000EB14488B4B28E8D0D3FFFFEB09488B4B28E855330000488B4B10E8" & _
		"CC380000488BCBFF1533730000B8010000004883C4205BC333C04883C4205BC34885C9740E8339017509895128B801000000C333C0C3CCCCCCCCCCCCCCCCCCCC4883EC284885C9742E8339027529488D05DBD9FFFFF20F11492848394108750D4533C945" & _
		"33C033D2E863000000B8010000004883C428C333C04883C428C3CCCC4885C9741983390375144863C248894130B801000000C7412800000000C333C0C3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC4885C97416833903751148895130B801000000C741280000" & _
		"0000C333C0C3CCCC48895C240848896C2410488974241848897C242041564883EC20488B4118498BE94D8BF0488BF2488BD94885C07406488B5120FFD04C89732048896B184885F6757348630383F806776F488D15DFC0FFFF8B8C82A43F00004803CAFF" & _
		"E148C7430800000000EB52488D0592E4FFFF48894308EB45488D0565E8FFFF48894308EB38488D0518F4FFFF48894308EB2B488D053BFBFFFF48894308EB1E488D053EE2FFFF48894308EB11488D050101000048894308EB0448897308488B5C2430488B" & _
		"6C2438488B742440488B7C24484883C420415EC32D3F0000373F0000443F0000513F00005E3F00006B3F0000783F000048895C2408574883EC20488BF9488BDA488BCAE83E6000004C8BC0488BD3488BCF488B5C24304883C4205FE940D7FFFF4D63C0E9" & _
		"38D7FFFFCCCCCCCCCCCCCCCC4885C97416833903751148895130B801000000C7412801000000C333C0C3CCCC48895C24084889742410574883EC20488B4118498BF8488BF2488BD94885C0741E488B5120FFD04889732048897B18488B5C2430488B7424" & _
		"384883C4205FC3488B5C243048897120488B742438488979184883C4205FC3CCCCCCCCCCCCCCCCCC48895C240848896C2410488974241848897C242041564883EC204C8B7128418BF1418BE9488BDA488BF983E620741541B807000000488D1514740000" & _
		"488BCBE83C36000041B801000000488D158F720000488BCBE82736000048837F2800488D57307D03488B124D8BC6448BCD49F7D8488BCB4D0F48C6E8C4DCFFFF41B801000000488D1557720000488BCBE8EF35000085F6741541B804000000488D154272" & _
		"0000488BCBE8D6350000488B5C243033C0488B6C2438488B742440488B7C24484883C420415EC3CCCCCCCCCCCCCCCCCC40534883EC20488BD94885C9750D488D05D77100004883C4205BC3488B41104885C0750EE8E7360000488943104885C0742F488B" & _
		"C8E836370000488B430841B901000000488B53104533C0488BCBFFD085C0780D488B4310488B004883C4205BC333C04883C4205BC3CCCCCCCCCCCCCC48895C2408574883EC208BFA488BD94885C97512488D0561710000488B5C24304883C4205FC3488B" & _
		"41104885C0750EE86C360000488943104885C07431488BC8E8BB360000488B4308448BCF488B53104533C0488BCBFFD085C07812488B4310488B00488B5C24304883C4205FC3488B5C243033C04883C4205FC3CCCCCCCCCC48895C240848896C24104889" & _
		"74241848897C242041564883EC2033DB4D8BF08BEA488BF98BF34885C9750EBE04000000488D1DC5700000EB41488B41104885C0750EE8D9350000488947104885C0742A488BC8E828360000488B4708448BCD488B57104533C0488BCFFFD085C0780B48" & _
		"8B471048637008488B18488BC34D85F67403498936488B5C2430488B6C2438488B742440488B7C24484883C420415EC348895C24084889742410574883EC20488B5920488BF2488BCBE8185D0000448BC0488BD3488BCE488BF8E8F1330000488B5C2430" & _
		"8BC7488B7424384883C4205FC3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC4883EC28E867EDFFFF488B40084883C428C3CCCCCCCCCCCCCCCCCCCCCCCCCCCC488B0509B10000C3CCCCCCCCCCCCCCCC488B1233C04839110F94C0C3CCCCCCCC488B01488B501848" & _
		"8911C3CCCCCCCCCC488B01488B00C3CCCCCCCCCCCCCCCCCC488B01488B4010C3CCCCCCCCCCCCCCCC83F910770F4863C1488D0D61AC0000488B04C1C3488D0575740000C3CCCCCCCC40534883EC20488BD9E8721E0000488B4B084885C97405E8F4320000" & _
		"488B4B38FF155A6D0000488BCB4883C4205B48FF254B6D0000CCCCCCCCCCCCCCCCCCCCCC8B4124C3CCCCCCCCCCCCCCCCCCCCCCCC48634120C3CCCCCCCCCCCCCCCCCCCCCCB920000000E906000000CCCCCCCCCCCC48895C2408574883EC204863F9BA4800" & _
		"0000B901000000FF15E36C0000488BD84885C07438488BCFBA20000000FF15CD6C0000488943384885C07418E8EF330000488943084885C07520488B4B38FF15BC6C0000488BCBFF15B36C000033C0488B5C24304883C4205FC3488BCB897B10E89B1D00" & _
		"00488BC3488B5C24304883C4205FC3CCCCCCCCCCCCCCCCCCCCCCCCCC48895C2408574883EC20488BD9B920000000E859FFFFFF488BF84885C0750F33DB8BC3488B5C24304883C4205FC341B8FFFFFFFF488BD3488BCFE851000000837F2400488BD8740F" & _
		"4885C07408488BC8E88BF8FFFF33DB488BCFE8211D0000488B4F084885C97405E8A3310000488B4F38FF15096C0000488BCFFF15006C0000488BC3488B5C24304883C4205FC3CCCC4489442418488954241055565741564157488D6C24C94881ECB00000" & _
		"004533FFC64567014C897DB7488BF14C897DC7418BFF4C897920458BF74183F8FF0F8C8C1A00007514488BCAE8795A0000483DFFFFFF7F0F87761A000033D248899C24A8000000B904000000FF159A6B00004885C07432488BC8FF154C6C0000488945C7" & _
		"4885C07520C746241000000033C0488B9C24A80000004881C4B0000000415F415E5F5E5DC34C89A424A0000000488D15807200004C89AC2498000000B9040000000F29B424800000000F297C2470440F29442460FF152E6B00000FB6556749BC00260000" & _
		"010000004C8B556FF30F103564720000F30F103D4C720000F2440F10054B720000448B5D77488D1DA0B9FFFF44395E200F844F180000F64640107453410FB60A4585F6753B80F98072450FB6C124E03CC0750841BE01000000EB340FB6C124F03CE07508" & _
		"41BE02000000EB2380E1F880F9F00F857216000041BE03000000EB0F80E1C080F9800F855E16000041FFCE410FB6128855674C6346144C8B4E38498BC048C1E005428B0C0883F91A0F871D16000066660F1F8400000000004863C18B8C83386000004803" & _
		"CBFFE19080FA200F87AA000000480FBEC2490FA3C40F839C0000008B462049FFC2FFC04C89556F89462084D20F84AF170000413BC30F8482170000F6464010746A410FB60A4585F6755280F980725C0FB6C124E03CC0750E41BE01000000884D670FB6D1" & _
		"EB9E0FB6C124F03CE0750F410FB61241BE02000000885567EB8680E1F880F9F00F8598150000410FB61241BE03000000885567E968FFFFFF80E1C080F9800F857A15000041FFCE410FB612885567E94DFFFFFF80FA2F750AF64640010F84B90A00004863" & _
		"5614488B4E3848C1E2058B440A0489040A0FB65567E9ECFEFFFF0FBEC283C0DE83F8590F874915000048980FB68403C86000008B8C83A46000004803CBFFE14963C048C1E00542C704081A000000488B4E08E8A5300000448B5D774C8B556F0FB6556744" & _
		"897E1CE99AFEFFFF4963C048C1E00542C7040803000000488B4E08E878300000448B5D774C8B556F0FB6556744897E1CE96DFEFFFF4963C048C1E00542C704080D000000488B4E08E84B300000448B5D774C8B556F0FB6556744897E1CE940FEFFFF4963" & _
		"C048C1E00542C704080E000000488B4E08E81E300000448B5D774C8B556F0FB6556744897E18E913FEFFFF4585C00F841D1600004963C848C1E1054A8B4C0910E8CFE3FFFF48635E14488BF8488B4E3848C1E305488945B744893C0B488B4E38C7441904" & _
		"01000000488B4E38488B4C1910E89EF4FFFF488B4E384C897C1910488B4E38488B4C1918FF1526680000488B4638448B5D774C8B556F4C897C1818488D1DCEB6FFFFFF4E140FB65567E98CFDFFFF448B461C4183F8080F8DB00000000F1F4000410FB602" & _
		"4963C83A841940B600007417F64640010F85CC1300003A841950B600000F85BF130000FF462041FFC049FFC24489461C4C89556F44395E200F84B7130000F64640107453410FB60A4585F6753B80F98072450FB6C124E03CC0750841BE01000000EB340F" & _
		"B6C124F03CE0750841BE02000000EB2380E1F880F9F00F856E13000041BE03000000EB0F80E1C080F9800F855A13000041FFCE410FB6128855674183F8080F8C54FFFFFF488B4608837808007E0D488B0080382D75050F28C6EB030F28C7F30F5AC04863" & _
		"7E14488B5E3848C1E705E845EBFFFF4889441F1048634614488B4E3848C1E00548837C0810000F8487130000488B7DB7488D1DADB5FFFFC744080402000000E9FA070000488B4E08488D556741B801000000E88D2C000085C00F88541300008B5E1CFFC3" & _
		"83FB047D0983FB037D098BFBEB0ABB04000000BF03000000F6464001751B488B5608488D0D876B00004C63C3488B12FF157367000085C0741B488B5608488D0D6C6B00004C63C3488B12FF153867000085C075418B461C83F8040F85C108000048634E14" & _
		"488D1D15B5FFFF488B4638488B7DB748C1E1054C897C011048634E14488B463848C1E105C744010402000000E945070000F6464001751B488B5608488D0D366B00004C63C7488B12FF15F666000085C0741F488B5608488D0D1B6B00004C63C7488B12FF" & _
		"15BB66000085C00F85211200008B461C83F8030F8540080000410F28C0E9B0FEFFFF4584FF0F853C08000080FA5C0F8433080000488B4E08488D1511A5000041B803000000E86E2B000085C00F883512000048635614488B4E38448B5D774C8B556F48C1" & _
		"E20548C746280000000044897E1C8B440A0489040A0FB65567E900FBFFFF4584FF0F85870C000080FA750F847E0C0000488B4E08488D15B1A4000041B803000000E80E2B000085C00F88D511000048634E14488B4638448B5D774C8B556F48C1E10548C7" & _
		"46280000000044897E1CC70401090000000FB65567E9A0FAFFFF488B4E08488D556741B801000000E8C32A000085C00F888A1100008B5E1CFFC383FB047D048BFBEB0FBF0400000083FB057C05BB05000000F6464001751B488B5608488D0DF16900004C" & _
		"63C7488B12FF15A965000085C0741B488B5608488D0DD66900004C63C7488B12FF156E65000085C075278B461C83F8040F85F706000048637E14B901000000488B5E3848C1E705E860E8FFFFE966FDFFFFF6464001751B488B5608488D0D9A6900004C63" & _
		"C3488B12FF154665000085C0741F488B5608488D0D7F6900004C63C3488B12FF150B65000085C00F857D1000008B461C83F8050F859006000048637E1433C9488B5E3848C1E705E8FCE7FFFFE902FDFFFF488B4E0833DB4D8BEA458BE7BF010000003959" & _
		"087E57488B09BA65000000E8A05200004C8BC04885C07519488B4E08BA45000000488B09E8875200004C8BC04885C0741D488B56088BDF448BFF8B4208FFC84863C848030A4C3BC1740433FF33DB448B5D774C8B556F0FB6556784D20F84F00000006690" & _
		"8D42D03C0976314585FF75078D42BBA8DF742585FF740580FA2D741C85DB740580FA2B7413837E18000F85BF00000080FA2E0F85B600000033FF41FFC480FA2E74168D42BBA8DF751B41BF0100000044897E18418BFFEB0CC7461801000000BF01000000" & _
		"8B462049FFC2FFC04C89556F89462084D20F849D0F0000413BC30F84730F0000F64640107453410FB60A4585F6753B80F98072450FB6C124E03CC0750841BE01000000EB340FB6C124F03CE0750841BE02000000EB2380E1F880F9F00F85280F000041BE" & _
		"03000000EB0F80E1C080F9800F85140F000041FFCE410FB6128BDF88556784D20F8512FFFFFF837E14007E3480FA2F771048B90026000001900000480FA3D1721F8D42B73C340F87370F000048B90100100001001000480FA3C10F83230F00004585E47E" & _
		"1B488B4E08458BC4498BD5E8242800000FB6556785C00F88420E00004C8B4608498B0080382D754D4183FC017F478D42B7A8DF754048634E14488D1DF4B0FFFF488B463849BC0026000001000000488B7DB7448B5D774C8B556F48C1E1054533FFC70401" & _
		"1A0000000FB6556744897E1CE989F7FFFF837E1800498BC8745EF6464001754E41837808017E47660F1F840000000000496350084D8B08420FB6440AFF3C65740F3C45740B3C2D7407498BC83C2B751A42C6440AFF00488B4608FF4808488B4E084C8BC1" & _
		"837908017FC60FB65567837E18000F85DD000000488B0980392D7540488D55BFE81718000085C0752FFF15ED610000833822750AF64640010F85090E000048637E14488B4DBF488B5E3848C1E705E829E7FFFFE9D60000000FB65567837E18000F858B00" & _
		"0000488B4608488B0880392D7475488D55CFE85118000085C07564FF1597610000833822750AF64640010F85B30D0000488B55CF4885D27416488B4608488B08803930750AF64640010F85940D000048637E1448B8FFFFFFFFFFFFFF7F488B5E38488BCA" & _
		"48C1E705483BD0770B488955BFE8A2E6FFFFEB52E8CBE7FFFFEB4B0FB65567837E18000F84660D0000488B4608488D55D7488B3848635808488BCFFF15736000004803DF483B5DD70F853D0D0000488B560848637E14488B5E3848C1E705488B12E80EE5" & _
		"FFFF4889441F1048634E14488B5638488BC148C1E00548837C1010000F84ED0C0000488B7DB7488D1D13AFFFFF4863C149BC002600000100000048C1E005C74410040200000048634E1448C1E1054533FFE94C01000080FA5D0F84A40200008B4610FFC8" & _
		"443BC00F8DCA0C00004963C048C1E00542C704081000000048634E148D4101894614488D5901488B463848C1E30544893C03488B4638C744180401000000488B4E38488B4C1910E830ECFFFF488B46384C897C1810488B4E38488B4C1918FF15B85F0000" & _
		"488B4638448B5D774C8B556F4C897C1818488D1D60AEFFFF0FB65567E921F5FFFF4963C8488BD748C1E1054A8B4C0910E8A3CEFFFF85C00F850A0C000048634E14488B463848C1E105C744010411000000EB7F8B4610FFC8443BC00F8D0E0C00004963C0" & _
		"48C1E00542C7040816000000E93FFFFFFF4963C84C8BC748C1E1054A8B5409184A8B4C0910E88AE6FFFF85C00F85B10B000048634614488B4E3848C1E005488B4C0818FF150B5F000048634E14488B463848C1E1054C897C011848634E14488B463848C1" & _
		"E105C74401041700000048634E1448C1E105488B4638448B5D774C8B556F44893C010FB65567E94FF4FFFF488B4E08E83C260000488B4E08488D556741B801000000E86924000085C00F88300B000048634E14488B46384C8B556F48C1E105C704010400" & _
		"0000E9440A00004963C048C1E00546893C0848634E14488B463848C1E105C74401041200000048637E14488B5E3848C1E705E895E4FFFF4889441F1048634E14488B46380FB6556748C1E10548837C0110000F841E0A00004C8B556FE9EE0900004963C0" & _
		"48C1E00546893C0848634E14488B463848C1E105C74401040F00000048637E14488B5E3848C1E705E84BE1FFFF4889441F1048634E14488B46380FB6556748C1E10548837C0110000F84C40900004C8B556FE994090000F64640010F85BD0900004963C0" & _
		"48C1E00542C7040808000000488B4E08E82F2500000FB655674C8B556F885630E9620900004C8B556FFFC089461CE9500900004963C048C1E00542C704080C000000E93C0900004963C833D248C1E1054A8B4C0910E89ACDFFFF48634614488B4E3848C1" & _
		"E005833C0818750AF64640010F85110A00004C8B556FC744080402000000E9EC08000080FA2A7507B905000000EB0E80FA2F0F85F7090000B9060000004963C0488D556748C1E00541B80100000042890C08488B4E08E8C52200000FB6556785C00F88E3" & _
		"0800004C8B556FE9B30800004D8BCA80FA2A0F848D0000000F1F40008B462049FFC2FFC04C89556F89462084D20F84D6090000413BC30F84AD090000F64640107453410FB60A4585F6753B80F98072450FB6C124E03CC0750841BE01000000EB340FB6C1" & _
		"24F03CE0750841BE02000000EB2380E1F880F9F00F855909000041BE03000000EB0F80E1C080F9800F854509000041FFCE410FB61288556780FA2A0F8577FFFFFF488B4E08458BC2452BC1498BD141FFC0E80222000085C00F88C908000048634E14488B" & _
		"46384C8B556F48C1E105C7040107000000E9DD0700004D8BCA80FA0A0F848B00000066908B462049FFC2FFC04C89556F89462084D20F8406090000413BC30F84DD080000F64640107453410FB60A4585F6753B80F98072450FB6C124E03CC0750841BE01" & _
		"000000EB340FB6C124F03CE0750841BE02000000EB2380E1F880F9F00F858908000041BE03000000EB0F80E1C080F9800F857508000041FFCE410FB61288556780FA0A0F8577FFFFFF488B4E08458BC2452BC1498BD1E83521000085C00F88FC0700004C" & _
		"8B556FE913070000488B4E08488D556741B801000000E81121000085C00F88D807000048634E14488B46384C8B556F48C1E105807D672F0F84EA060000C7040105000000E9E20600004D8BCA3A56300F84A90000000F1F800000000080FA5C0F84FC0000" & _
		"008B4E40F6C101740980FA1F0F8E110800008B462049FFC2FFC04C89556F89462084D20F84EC070000413BC30F84C3070000F6C1107453410FB60A4585F6753B80F98072450FB6C124E03CC0750841BE01000000EB340FB6C124F03CE0750841BE020000" & _
		"00EB2380E1F880F9F00F857007000041BE03000000EB0F80E1C080F9800F855C07000041FFCE410FB6128855673A56300F855EFFFFFF488B4E08458BC2452BC1498BD1E81C20000085C00F88E3060000488B4E088B5108488B09E835E1FFFF4863561448" & _
		"8B4E3848C1E2054889440A1048634614488B4E3848C1E00548837C0810000F84AB0600004C8B556FC744080402000000E9BA050000488B4E08458BC2452BC1498BD1E8B91F000085C00F888006000048634E14488B463848C1E105C74401040800000048" & _
		"634E14488B46384C8B556F48C1E105C7040109000000E9800500000FBEC283C0DE83F8530F87CD06000048980FB68403346100008B8C83246100004803CBFFE1488D556741B801000000488B4E08E8491F000085C00F881006000048635614488B4E384C" & _
		"8B556F48C1E2058B440A0489040AE92405000080FA627509488D15A1600000EB3680FA6E7509488D15575B0000EB2880FA727509488D1589600000EB1A80FA747509488D157F600000EB0C80FA667522488D1575600000488B4E0841B801000000E8D21E" & _
		"000085C00F88990500004C8B556F48635614488B4E3848C1E2058B440A0489040AE9AD04000044897E2844897E1C4963C048C1E00542C704080A000000E991040000669084D20F84E30500008D42D03C0976128D42BF3C05760B8D429F3C050F87CA0500" & _
		"00440FBEC280FA397F064183E830EB084183E0074183C0098B461CB9030000002BC8C1E10241D3E0440B4628FFC04489462889461C83F8040F8D96000000FF462049FFC24C89556F44395E200F8489050000F64640107470410FB60A4585F6755880F980" & _
		"72620FB6C124E03CC0751141BE01000000884D670FB6D1E960FFFFFF0FB6C124F03CE07512410FB61241BE02000000885567E945FFFFFF80E1F880F9F00F852D050000410FB61241BE03000000885567E927FFFFFF80E1C080F9800F850F05000041FFCE" & _
		"410FB612885567E90CFFFFFF8B4E2C44897E1C85C97450418BC02500FC00003D00DC0000751B81E1FF0300004181E0FF03000083C140C1E10A4103C8894E28EB22488B4E08488D15F496000041B803000000E8511D000085C00F88180400004C8B556F44" & _
		"897E2C8B4E28488D562881F980000000730C884D7F488D557FE9CEFDFFFF8BC181F9000800007320C1E806488D55A70CC080E13F80C9808845A7884DA841B802000000E9AAFDFFFF2500FC00003D00D80000751E488B4638894E2C48634E1448C1E10544" & _
		"893AC704010B000000E9D10200003D00DC0000751241B803000000488D1556960000E967FDFFFF81F900000100732E8BC1488D55ABC1E80C41B8030000000CE08845AB8BC1C1E80680E13F243F0C8080C9808845AC884DADE931FDFFFF81F90000110073" & _
		"B08BC1488D55AFC1E81241B80400000024070CF08845AF8BC1C1E80C243F0C808845B08BC1C1E80680E13F243F0C8080C9808845B1884DB2E9EDFCFFFF80FA5D75304963C833D248C1E1054A8B4C0910E897C6FFFF48634E14488B46384C8B556F48C1E1" & _
		"05C744010402000000E9F901000080FA2C0F85960300004963C048C1E00542C744080418000000E9DB01000080FA7D75264963C048C1E00542833C0819750AF64640010F850502000042C744080402000000E9B001000080FA22740980FA270F85510300" & _
		"00488B4E08885630E8671D000048634E14488B46384C8B556F48C1E105C7040113000000E98A0100004D8BCA3A56300F849200000080FA5C0F84E70000008B462049FFC2FFC04C89556F89462084D20F84AC020000413BC30F8483020000F64640107453" & _
		"410FB60A4585F6753B80F98072450FB6C124E03CC0750841BE01000000EB340FB6C124F03CE0750841BE02000000EB2380E1F880F9F00F852F02000041BE03000000EB0F80E1C080F9800F851B02000041FFCE410FB6128855673A56300F856EFFFFFF48" & _
		"8B4E08458BC2452BC1498BD1E8DB1A000085C00F88A2010000488B4E0848637E14488B5E3848C1E705488B09FF15D25500004889441F1848634614488B4E3848C1E00548837C0818000F846C0100004C8B556FC744080414000000EB7E488B4E08458BC2" & _
		"452BC1498BD1E87D1A000085C00F884401000048634E14488B463848C1E105C744010413000000E9BFFAFFFF80FA3A0F85FA0100004963C048C1E00542C744080415000000EB3080FA7D75124963C048C1E00542C744080402000000EB1980FA2C0F85D1" & _
		"0100004963C048C1E00542C74408041900000048634E14488B463848C1E10544893C010FB65567FF462049FFC24C89556F84D20F84C8010000488B7DB7E937E9FFFFC746240E000000E9B3010000C7462410000000E9A7010000C7462404000000E99B01" & _
		"0000B90E000000EB1D837E14007512488B4638833800750983780402418BCF7405B901000000B824000000488BD6890C02E963010000C7462405000000E957010000C7462406000000E94B010000C746240E000000EB21837E14007513488B4638833800" & _
		"750A83780402750433C0EB05B801000000894624458BC4498BD5488B4E08E83919000085C00F890A010000C7462410000000E9FE000000C7462407000000E9F20000000FB65567C7462407000000E9E6000000C7462402000000E9DA000000C746240400" & _
		"0000E9CA000000C746240D000000E9C2000000452BD1C746240E000000458BC2498BD1EB91837E14007512488B4638833800750983780402418BC77405B801000000894624452BD1498BD1458BC2E963FFFFFFC746240C000000EB79B90E000000EB1D83" & _
		"7E14007512488B4638833800750983780402418BCF7405B901000000B824000000488BD6890C10EB44C7462408000000EB3FC7462409000000EB36C746240A000000EB2DC746240B000000EB24837E14007512488B4638833800750983780402418BC774" & _
		"05B8010000008946240FB65567448B4E40440F284424600F287C24700F28B424800000004C8BAC24980000004C8BA424A000000041F6C110740C4585F67407C746240E0000004C635614488D5E144D8BC2488D7E3849C1E0054C03463884D2742E418338" & _
		"02754C488D5E14488D7E384585D2753F4180E103488D5E14488D7E384180F901752DC7462404000000EB1C41833802741E4183780402488D5E14488D7E38740FC7462403000000488D7E38488D5E14488B55C7B904000000FF15C6510000488B4DC7FF15" & _
		"A4510000837E24000F8536E6FFFF486303488B0F48C1E005488B4C0810E8E6CCFFFF4863334C8BF04885F67852488BDE48C1E3054533FF90488B0F44893C0B488B0FC7440B0401000000488B0F488B4C0B10E8B1DDFFFF488B074C897C0310488B0F488B" & _
		"4C0B18FF153B5100004883EE01488B07488D5BE04C897C033879B9498BC6E9BFE5FFFFC746240F00000033C04881C4B0000000415F415E5F5E5DC39000470000DE470000B7480000604A0000035400005054000022550000DC5500001D5600007F570000" & _
		"705800006A4B0000CA4B00002A4C0000294D000016510000A9510000C15A0000145B0000755B0000A45C0000DB510000FD510000BF5C000016510000145B00003E490000795300006F5300008A4800005D480000034800003048000015530000BB520000" & _
		"365D00000008080808010808080808020808020202020202020202020808080808080808080808080308080408080808050808080808030808080808080608080808080808080808030808040808080805080808080803080808080808076690A4570000" & _
		"DB570000525800005B5E0000000303030303030303030303030003030303030303030303030303030303030303030303030303030303030303030303030303030303030303030003030303030103030301030303030303030103030301030102CCCCCCCC" & _
		"CCCCCCCC48895C24084889742410574883EC20488BF9488BF2B920000000E881E2FFFF488BD84885C07516C70610000000488B5C2430488B7424384883C4205FC341B8FFFFFFFF488BD7488BCBE872E3FFFF8B4B24488BF8890E837B2400740F4885C074" & _
		"08488BC8E8A7DBFFFF33FF488BCBE83D000000488B4B084885C97405E8BF140000488B4B38FF15254F0000488BCBFF151C4F0000488B5C2430488BC7488B7424384883C4205FC3CCCCCCCCCCCCCCCCCC4885C90F848F000000534883EC2048896C243048" & _
		"8BD9488974243833ED486371144885F6785D48897C2440488BFE48C1E705488B4338892C07488B4338C744380401000000488B4B38488B4C3910E80DDBFFFF488B433848896C3810488B4B38488B4C3918FF15954E00004883EE01488B4338488D7FE048" & _
		"896C383879B4488B7C2440488B742438896B14896B24488B6C24304883C4205BC3CCCCCCCCCCCCCC895140C3CCCCCCCCCCCCCCCCCCCCCCCC48894C240848895424104C894424184C894C242053574883EC38488BD9488D7C2458E839B2FFFF48897C2428" & _
		"488D154D9100004C8BCB48C74424200000000041B800010000488B084883C901FF15964E0000C60526920000004883C4385F5BC348896C2418488974242041564883EC20488BC24C8D35725700004D85C98BE9488BC8418BD04D0F45F1E842DEFFFF488B" & _
		"F04885C07516B8FFFFFFFF488B6C2440488B7424484883C420415EC348895C2430488BCE48897C2438E8683C000033DB488BF84885C074290F1F840000000000448BC7488D1433442BC38BCDFF15164E00004863C885C078254803D9483BDF72DF33C048" & _
		"8B5C2430488B7C2438488B6C2440488B7424484883C420415EC3FF15AC4D00008B08E8051700004C8BC0488D0DD3560000498BD6E8D3FEFFFFB8FFFFFFFFEBBFCCCCCCCCCCCCCCCCCCCCCCCCBAFFFFFFFFE906000000CCCCCCCCCCCC4053564156B83010" & _
		"0000E8912C0000482BE0488B05678F00004833C448898424201000008BDA448BF1E8F2130000488BF04885C07513488D0D63540000E86EFEFFFF33C0E95C010000B8200000004889AC246010000083FBFF0F44D88BCBE88DDFFFFF488BE84885C0752DFF" & _
		"15FF4C00008B08E8581600004C8BC0488D0D4E5400008BD3E827FEFFFF488BCEE8FF11000033C0E90501000041B8001000004889BC2468100000488D542420418BCEFF15DC4C00004863F885C07E340F1F440000448BC7488D542420488BCEE8F0110000" & _
		"85C0785341B800100000488D542420418BCEFF15A84C00004863F885C07FD14885FF7959FF15764C00008B08E8CF1500004C8BC0488D0D6D540000418BD6E89DFDFFFF488BCDE865DEFFFF488BCEE86D11000033C0EB6EFF15434C00008B5E088B08E899" & _
		"1500004C8BC8488D0DDF530000448BC78BD3E865FDFFFFEBC6448B4608488BCD488B16E8B4DFFFFF488BD84885C0751E488BCDE854DEFFFF8BC8E8EDDDFFFF488BD0488D0D33540000E82EFDFFFF488BCDE8F6DDFFFF488BCEE8FE100000488BC3488BBC" & _
		"2468100000488BAC2460100000488B8C24201000004833CCE8BB2A00004881C430100000415E5E5BC3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC48895C2408574883EC2033D2488BD9FF15CB4B00008BF885C0792CFF157F4B00008B08E8D81400004C8BC048" & _
		"8D0DD6530000488BD3E8A6FCFFFF33C0488B5C24304883C4205FC3BAFFFFFFFF8BCFE8DDFDFFFF8BCF488BD8FF158A4B0000488BC3488B5C24304883C4205FC3CCCCCCCC4883EC284885D27516488D0D28540000E85BFCFFFFB8FFFFFFFF4883C428C345" & _
		"33C94883C428E9A5FCFFFFCCCCCCCCCC4533C0E908000000CCCCCCCCCCCCCCCC48895C241048896C2418574883EC20418BE8488BFA488BD94885D27521488D0D6C530000E807FCFFFFB8FFFFFFFF488B5C2438488B6C24404883C4205FC3BA0103000048" & _
		"8974243041B8A4010000FF15DC4A00008BF085C07926FF15904A00008B08E8E91300004C8BC0488D0D4F530000488BD3E8B7FBFFFFB8FFFFFFFFEB2C4C8BCB448BC5488BD78BCEE800FCFFFF8BF8FF15584A00008BCE8B18FF15964A0000FF15484A0000" & _
		"89188BC7488B742430488B5C2438488B6C24404883C4205FC3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC48895C2410574883EC20488BDA488BF9488D542430FF156549000033C0F20F110348397C2430488B5C24380F94C04883C4205FC3CCCCCCCCCCCCCCCC" & _
		"CCCCCCCC48895C2410574883EC20488BFA48C744243000000000488BD9FF15C149000041B80A000000488D542430488BCBC70000000000FF15FF4800004C8B4424304C3BC374034889074885C07510FF158F490000833800750A4C8B4424304C3BC3751C" & _
		"FF157A490000C70016000000B801000000488B5C24384883C4205FC3488B5C243833C04883C4205FC3CCCCCCCCCCCCCC48895C2410574883EC20488BFA48C744243000000000488BD9FF1531490000C700000000000FB6033C20750F0F1F40000FB64301" & _
		"48FFC33C2074F53C2D744741B80A000000488D542430488BCBFF154D480000488B4C2430483BCB74034889074885C07510FF15E5480000833800750A488B4C2430483BCB751CFF15D0480000C70016000000B801000000488B5C24384883C4205FC3488B" & _
		"5C243833C04883C4205FC3CCCCCCCCCCCCCCCCCCCCCCCCCC4883EC2883F90677134863C1488D0D7D870000488B04C14883C428C38BD141B807000000488D0DDD510000E8B0F9FFFF33C04883C428C3CCCCCCCCCCCCCCCCCC33C9488D05178B0000380D11" & _
		"8B0000480F44C1C3CCCCCCCCCCCCCCCCCCCCCCCC48895C241048896C24185741544155415641574883EC30488BAC24880000004D8BF94C8BB424800000004D8BE04C8BEA48896C24284C894C2420488BF94D8BC84C8BC233D241FFD68BD883F8FF0F8400" & _
		"02000085C074483DFF0200000F84F10100003D7B1D00000F84E60100003DBB1E00000F84DB010000B902000000FF15D5470000448BC3488D1553510000488BC8E87BAEFFFFB8FFFFFFFFE9B4010000488BCF4889742460E854C7FFFF83F8060F876D0100" & _
		"00488D15D495FFFF48988B8C82DC6B00004803CAFFE1488BCFE85EC6FFFF488B48084885C90F84DC000000488B71184533C94C8B01488BD7488B491048896C24284C89742420E801FFFFFF8BD83DFF0200000F84AF0000003DBB1E00000F843701000083" & _
		"F8FF0F842E01000085C0740B3D7B1D00000F85DB000000488BCEEBA2488BCFE8A4B6FFFF33C9488BF048898C24800000004885C0746D6690488BD1488BCFE865B6FFFF4C8D8C248000000048896C24284533C04C89742420488BD7488BC8E885FEFFFF8B" & _
		"D83DFF02000074373DBB1E00000F84BF00000083F8FF0F84B600000085C074073D7B1D00007567488B8C248000000048FFC148898C2480000000483BCE729548896C24284D8BCC4D8BC54C897C2420BA02000000488BCF41FFD68BD883F8FF747185C074" & _
		"3D3DFF02000074363D7B1D0000742F3DBB1E00007458B902000000FF1557460000488D15D84F0000EB34B902000000FF1543460000488D1504500000EB2033C0EB2C488BCFE8D6C5FFFFB9020000008BD8FF1521460000488D1512500000448BC3488BC8" & _
		"E8C7ACFFFFB8FFFFFFFF488B742460488B5C2468488B6C24704883C430415F415E415D415C5FC3908E6B00008E6B00008E6B00008E6B00003A6A0000A46A00008E6B0000CCCCCCCCCCCCCCCC4883EC384C894C242833D24C894424204533C94533C0E855" & _
		"FDFFFF85C0741C3DFF02000074153D7B1D0000740E2DBB1E0000F7D81BC04883C438C333C04883C438C3CCCCCCCCCCCCCCCCCCCCCCCCCCCC40534883EC208B0584840000488BD983F8FF7519E8D70D00008BD083F8FF74F4B8FFFFFFFFF00FB115638400" & _
		"00488BCBE891330000448B0554840000488BD0488BCB4883C4205BE904000000CCCCCCCC40534181C0EFBEADDE48897C24184403C2488BFA4C8BD1458BD8418BD84883FA0C0F861001000048897424104C8D4AF348B8ABAAAAAAAAAAAAAA49F7E1488BF2" & _
		"48C1EE0348FFC6486BC6F44803F86690410FB64206410FB64A04450FB64A07410FB6520BC1E20841C1E1084403C8410FB6420541C1E1084403C8410FB6420A03D041C1E108410FB642094503CB4403C9C1E208410FB64A0803D0410FB64202C1E2084103" & _
		"D003D1410FB64A03C1E108448BC203C841C1C81C410FB64201C1E10803C8410FB602C1E1084983C20C03C8428D040A2BCA03CB4433C1452BC8418BD0C1CA1A4133D1428D0C002BC2448BC241C1C8184433C08D0411412BC8418BD0C1CA1033D1428D0C00" & _
		"448BCA41C1C90D2BC24433C88D1C0A458BC141C1C81C412BC94433C1458D1C194883EE010F851EFFFFFF488B742410488D0D2292FFFF8B84B9C86E0000488B7C24184803C1FFE0410FB6420BC1E0184403C0410FB6420AC1E0104403C0410FB64209C1E0" & _
		"084403C0410FB642084403C0410FB64207C1E0184403D8410FB64206C1E0104403D8410FB64205C1E0084403D8410FB642044403D8410FB64203C1E01803D8410FB64202C1E01003D8410FB64201C1E00803D8410FB60203D84533C3418BC3C1C812442B" & _
		"C0418BC0418BC8C1C81533CB2BC88BC1448BC9C1C8074533CB442BC8418BC1458BD1C1C8104533D0442BD0418BC2418BD233D1C1C81C2BD08BCA4133D1C1C9122BD18BCA4133D2C1C9082BD18BC25BC3418BC05BC30F1F00C06E00005F6E0000556E0000" & _
		"4B6E0000416E0000396E00002E6E0000236E0000186E0000106E0000056E0000FA6D0000EF6D0000CCCCCCCC4883EC28E81331000033C985C00F94C18BC14883C428C3CCCCCCCCCCCCCCCCCC48895C240848896C2410488974241848897C242041564883" & _
		"EC204C8B3597810000488BEA4863F1BA38000000B901000000FF15D941000033DB488BF84885C07425BA28000000895804488BCE8930FF15BC410000488947184885C0750E488BCFFF15BA410000488BC3EB3248896F20488D056AFFFFFF488947304C89" & _
		"77284885F67E17488B4F18488D5B2848C7440BD8FFFFFFFF4883EE0175E9488BC7488B5C2430488B6C2438488B742440488B7C24484883C420415EC3CCCCCCCCCCCCCCCC40534883EC20488BD9E8E20300004C8BC04885C0750BB8FFFFFFFF4883C4205B" & _
		"C34C8B4B18498BC848897C2438492BC948B8676666666666666648F7E9488BFA48C1FF04488BC748C1E83F4803F87914488B7C243848C7C1FEFFFFFF8BC14883C4205BC3488D04BF4889742430488D34C5000000004A833C0EFD0F87D7000000FF4B0448" & _
		"8B43204885C07405498BC8FFD0488B43184533C048C7C1FEFFFFFF4C89443010488B431848890C06488B4318488B53104803C6483BD0751048394308750A4C8943104C894308EB5C488B4B08483BC87516488B41184C894020488B4308488B481848894B" & _
		"08EB3D483BD07516488B42204C894018488B4310488B482048894B10EB22488B4820488B401848894118488D0CBF488B4318488B54C818488B44C82048894220488B4318488D0CBF488B7424304C8944C820488D0CBF488B4318488B7C24384C8944C818" & _
		"418BC88BC14883C4205BC3488B742430B9FFFFFFFF488B7C24388BC14883C4205BC3CCCC40574883EC204883792000488BF9742748895C2430488B59084885DB74146690488B4720488BCBFFD0488B5B184885DB75EE488B5C2430488B4F18FF15AF3F00" & _
		"00488BCF4883C4205F48FF25A03F000048895C240848896C2410488974241848897C24204154415641574883EC308B01458BF1660F6E49044D8BF8F30FE6C94C8BE2488BF1660F6EC0F30FE6C0F20F59051B4A0000660F2FC80F82A80000003DFFFFFF3F" & _
		"7E13BDFFFFFF7F3BC5750DB8FFFFFFFFE98F0100008D2C004C8B493033D24C8B41288BCDE873030000488BF84885C074DA488B5E084885DB743C6690488B5728488B0BFFD28B4B08448BC84C8B4310F7D9488BCF1BD283E20489542420488B13E847FFFF" & _
		"FF85C00F85CB000000488B5B184885DB75C6488B4E18FF15CC3E0000488B4718488BCF48894618892E488B470848894608488B471048894610FF15A93E0000448B1633D24C8B4618418BC641F7F24533DB4D8BC8488D0C9249833CC8FF742D660F1F8400" & _
		"00000000488D0C9249833CC8FE74198D4A01418BC3413BCA0F45C18BD0488D048049833CC0FF75DC8B4C2470488D14924D8924D183E104488B4618894CD008488B46184C897CD010488B4618FF4604488D0CD04C395E08755748894E1048894E084C8959" & _
		"20488B46184C895CD018EB6A48837F2000741F488B5F084885DB74160F1F4000488B4720488BCBFFD0488B5B184885DB75EE488B4F18FF15E43D0000488BCFFF15DB3D0000B8FFFFFFFFEB2C488B461048894818488B4610488B4E18488944D120488B46" & _
		"184C895CD018488B4618488D0CD048894E1033C0488B5C2450488B6C2458488B742460488B7C24684883C430415F415E415CC3CCCCCCCCCCCCCCCCCC8B4104C3CCCCCCCCCCCCCCCCCCCCCCCC48895C240848896C2410488974241848897C242041564883" & _
		"EC20488B4128488BF9488BCA488BEAFFD0448B0733D241F7F033DB8BF24585C07E59488B4718488D0C924C8D34CD00000000498B0C064883F9FF743F4883F9FE740D488B4730488BD5FFD085C075498B078D4E01FFC33BD87D2133F63BC8488B47180F45" & _
		"F1488D0CB64C8D34CD00000000498B0C064883F9FF75C133C0488B5C2430488B6C2438488B742440488B7C24484883C420415EC3488B47184903C6EBDCCCCCCCCCCCCCCC48895C240848896C2410488974241848897C242041564883EC20448B09488BEA" & _
		"33D2418BC041F7F133DB488BF98BF24585C97E5B488B41184C8D04924E8D34C500000000498B0C064883F9FF744166904883F9FE740D488B4730488BD5FFD085C075498B078D4E01FFC33BD87D2133F63BC8488B47180F45F1488D0CB64C8D34CD000000" & _
		"00498B0C064883F9FF75C133C0488B5C2430488B6C2438488B742440488B7C24484883C420415EC3488B47184903C6EBDCCCCCCCCCCCCCCCCCCCCCCC40534883EC20498BD8E872FEFFFF4885C074174885DB7407488B4010488903B8010000004883C420" & _
		"5BC34885DB740748C7030000000033C04883C4205BC3CCCC48896C2410488974241857415641574883EC204C8BFA4863F1BA38000000B901000000498BE94D8BF0FF15713B0000488BF84885C0746048895C2440BA2800000033DB8930488BCE895804FF" & _
		"154F3B0000488947184885C0750D488BCFFF154D3B000033C0EB2B4C897F204C89772848896F304885F67E17488B4718488D5B2848C74403D8FFFFFFFF4883EE0175E9488BC7488B5C2440488B6C2448488B7424504883C420415F415E5FC3CCCCCCCCCC" & _
		"40574883EC208B410C488BF93BC27C0833C04883C4205FC381FAF7FFFF7F7E17FF154A3B0000C7001B000000B8FFFFFFFF4883C4205FC348895C24308D5A083DFFFFFF3F7F0903C03BC30F4CC38BD8488B094863D3FF159D3A00004885C07510488B5C24" & _
		"30B8FFFFFFFF4883C4205FC3895F0C488B5C243048890733C04883C4205FC3CCCCCCCCCCCCCCCCCCCCCCCCCC4885C9741F534883EC20488BD9488B09FF155A3A0000488BCBFF15513A00004883C4205BC3CCCCCCCCCCCCCCCCCCCCCC48895C2408488974" & _
		"2410574883EC204963F8488BF2488BD94585C078568B4908B8FEFFFF7F2BC13BF87F488D570103D139530C7F0C488BCBE803FFFFFF85C0783E48634B084C8BC748030B488BD6E8AB280000017B08488B0348634B08C60401008BC7488B5C2430488B7424" & _
		"384883C4205FC3FF15373A0000C7001B000000488B5C2430B8FFFFFFFF488B7424384883C4205FC3CCCCCCCCCCCCCCCCCCCCCCCC48895C2410488974241857415641574883EC204D63F1458BF8488D59088BFA488BF183FAFF75028B3B4585C9787F83FF" & _
		"FF7C7AB8FFFFFF7F2BC7443BF07F6E48896C2440428D2C3739690C7D2D8BD5E84CFEFFFF85C0791EB8FFFFFFFF488B6C2440488B5C2448488B7424504883C420415F415E5FC3488D5E0848630B3BCF7D118BC733D22BC148030E4C63C0E8B42700004863" & _
		"CF4D8BC648030E418BD7E8A3270000392B7D02892B33C0EBB0FF155D390000C7001B000000B8FFFFFFFFEBA240534883EC20BA10000000B901000000FF15BA380000488BD84885C0742AB920000000C7400C20000000C7400800000000FF15B138000048" & _
		"89034885C07511488BCBFF159838000033C04883C4205BC3C60000488BC34883C4205BC3CCCCCCCC488B01C60000C7410800000000C3CCCC4C8BDC498953104D8943184D894B20535556574154415641574881ECD0000000488B05C97A00004833C44889" & _
		"8424C0000000488BDA498D7B18488BF1E83F9CFFFF4533FF48897C24284C8BCB4C897C242041B880000000488D542440488B084C8BF04883C901FF159C38000048C7C5FFFFFFFF4488BC24BF00000085C04C897C24300F48C583F87F7717448BC0488D54" & _
		"2440488BCEE896FDFFFF8BF8E9A8000000488BBC24180100004C8DA42420010000498B0E4C8BCF4883C9024C896424284533C04C897C242033D2FF153838000085C00F48C585C0786E4863C848FFC1FF1593370000488BD84885C0745A498B0E4C8BCF48" & _
		"83C9014C896424284C8BC54C897C2420488BD0FF15FB37000085C08BF80F48FD85FF7912488BCBFF154F370000488B5C243085FF781D448BC7488BD3488BCEE8F8FCFFFF488BCB8BF8FF152D3700008BC7EB028BC5488B8C24C00000004833CCE8871600" & _
		"004881C4D0000000415F415E415C5F5E5D5BC3CCCCCCCCCC40534883EC3033C0894424404889442448FF15C9350000B9400000F0BA000000F03C0441B9010000000F46CA4533C0894C242033D2488D4C2448FF159035000085C0751CFF159E350000B902" & _
		"0000008BD8FF1531370000488D156A410000EB42488B4C24484C8D442440BA04000000FF154B350000488B4C244833D28BD8FF154435000085DB7539FF155A350000B9020000008BD8FF15ED360000488D154E410000448BC3488BC8E8939DFFFF33C9FF" & _
		"154337000069C0A599D6194883C4305BC38B4424404883C4305BC3CCCCCCCCCC40534883EC40488B05A37800004833C448894424388BD98B0D437A000085C97522488D0D38430000E8E52400004885C0B901000000BAFFFFFFFF0F44CA890D1D7A000083" & _
		"F9FF751B8BCBFF1540360000488B4C24384833CCE8431500004883C4405BC3488B057E7500004C8D0D7F84FFFF4533C04885C0742C418BD0418BC89042399C09F0F000000F84CE00000048FFC2488BCA48C1E1044A8B8409F8F000004885C075DB83FB0A" & _
		"7C34488D4C242090B8CDCCCCCC488D4901F7E341FFC0C1EA038D049203C02BD84863C38BDA420FB6840888BE00008841FF83FA0A7DD2B8676666664D63C0F7EBC1FA028BC2C1E81F03D08D049203C02BD84863C3420FB6840888BE000041B90600000042" & _
		"884404204D85C0781D488D0DFA760000458D4807420FB64404204983E8018801488D490179EE4963C94881F980000000737D488D05CB760000C6040100488B4C24384833CCE84A1400004883C4405BC30FB61041B90600000084D27428488D0DA6760000" & _
		"482BC80F1F4000660F1F840000000000881408488D40010FB61041FFC184D275EF4963C94881F980000000731E488D056C76000044880401488B4C24384833CCE8EB1300004883C4405BC3E868150000CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCE97BA4FF" & _
		"FFCCCCCCCCCCCCCCCCCCCCCC48895C2408488974241048897C241841564883EC404D8BF0488BFA488BD94885C90F84890000004885D20F8480000000803A00746F488BCAFF15EA340000488BF04885C0750EFF1574340000C7000C000000EB684C8D4424" & _
		"20488BD6488BCBE83C0200008BD885C07528488B4C2420BA04000000E877B6FFFF85C07415488B4424304885C0740B482BFE4803C74889442430488BCEFF15B533000085DB7522488B5C24284D85F6740349891E33C0EB13FF150A340000C70016000000" & _
		"BBFFFFFFFF8BC3488B5C2450488B742458488B7C24604883C440415EC3CCCCCCCCCCCCCC48895C241048896C2418574883EC20498BD8488BFA488BE94885C90F84B40000004885D20F84AB000000803A00752533C0498948084989004989401041C74018" & _
		"FFFFFFFF488B5C2438488B6C24404883C4205FC3488BCF4889742430FF15E6330000488BF04885C07526FF1570330000C7000C000000B8FFFFFFFF488B742430488B5C2438488B6C24404883C4205FC34C8BC3488BD6488BCDE8220100008BE885C07524" & _
		"488B0BBA04000000E85FB5FFFF85C07413488B4B104885C9740A482BCE4803CF48894B10488BCEFF159F3200008BC5EBA6FF1505330000488B5C2438488B6C2440C70016000000B8FFFFFFFF4883C4205FC3CCCCCCCCCCCCCCCCCCCC4C8BDC4D8943184D" & _
		"894B2055574883EC6849C743A800000000498BC0488BFA488BE94885C974794885C074744D8D432049895BE8488BD0498D4BA8E8D00700008BD885C0784E4889742458488B742420803E00750A4885FF742A48892FEB254C8D442428488BD6488BCDE851" & _
		"0000008BD885C0750F4885FF7408488B44243048890733DB488BCEFF15E3310000488B7424588BC3488B5C24604883C4685F5DC3FF153A320000C70016000000B8FFFFFFFF4883C4685F5DC3CCCCCCCCCCCCCCCC48894C24085657415541564883EC2833" & _
		"FF4D8BF0803A2F488BF24C8BE9741CFF15FB310000C70016000000B8FFFFFFFF4883C428415E415D5F5EC348895C245848FFC648896C2460488BCE4C89642468BA2F0000004C897C2420E8FD1F00004C8BF84885C074034088384C8B642450BA05000000" & _
		"498BCCE8D4B3FFFF488BCE8BD8E800200000488BE885DB0F84940000000FBE0E4883F80175258D41D03C0977088D41D04863F8EB4DFF1571310000C70016000000B8FFFFFFFFE98901000080F93074E54885ED74190F1F80000000000FB6043E2C303C09" & _
		"77CF48FFC7483BFD72EE33D241B80A000000488BCEFF157D300000488BF8498BCCE8C2A0FFFF483BF80F83E5000000488BD7498BCCE88EA0FFFF4885C00F84D10000004889442450E9DF000000488D15D83D0000488BCEE82E1F0000488BD84885C0743C" & _
		"0F1F4000C6032F48FFCD48FFC34C8BC54C2BC3488BCB49FFC04C03C6488D5301E8EF1E0000488D159C3D0000488BCBE8F21E0000488BD84885C075C8488BCEE8061F0000488D15813D0000488BCE488BE8E8D01E0000488BD84885C0743E660F1F440000" & _
		"C6037E48FFCD48FFC34C8BC54C2BC3488BCB49FFC04C03C6488D5301E88F1E0000488D15403D0000488BCBE8921E0000488BD84885C075C84C8D442450488BD6498BCCE8E8B8FFFF85C07513FF152E300000C70002000000B8FFFFFFFFEB49488B442450" & _
		"4D85FF741641C6072F4D8BC6488B4C2450498BD7E8E3FDFFFFEB294D85F67422BA050000004D892E498BCD49894608E818B2FFFF85C0740641897E18EB044989761033C04C8B642468488B6C2460488B5C24584C8B7C24204883C428415E415D5F5EC3CC" & _
		"CCCCCCCCCCCCCCCC48895C241848896C2420574883EC50498BE8488BDA488BF94885C9742D4885D274280FB60284C0751D488B09E86FBBFFFF33C048892F488B5C2470488B6C24784883C4505FC33C2F7421FF15602F0000C70016000000B8FFFFFFFF48" & _
		"8B5C2470488B6C24784883C4505FC3BA2F0000004C89742468488BCBE8871D00004C8BF0483BC37524488B0F488D53014C8D0D4DFAFFFF48C7442420000000004C8BC5E89C000000E982000000488BCB4889742460FF15612F0000488BF04885C07513FF" & _
		"15EB2E0000C7000C000000B8FFFFFFFFEB54498BC64C8D442430482BC3488BD6C6043000488B0FE8A4FCFFFF8BD8488BCE85C0740AFF15452E00008BC3EB27FF153B2E0000488B4C2438498D56014C8D0DCBF9FFFF48C7442420000000004C8BC5E81A00" & _
		"0000488B7424604C8B742468488B5C2470488B6C24784883C4505FC348895C241048896C2418488974242041564883EC20488BDA4D8BF1BA05000000498BE8488BF1E875B0FFFF85C00F84BC00000048897C24300FBE3B4080FF2D752C807B0100752648" & _
		"8BD5488BCEE8CE9CFFFF488B7C2430488B5C2438488B6C2440488B7424484883C420415EC3488BCBE8611C0000488BD04883F801750E8D47D03C0977548D47D04898EB374080FF30744733C94885D274190F1F80000000000FB6040B2C303C09772F48FF" & _
		"C1483BCA72EE33D241B80A000000488BCBFF15FD2C00004C8B4C24504C8BC5488BD0488BCE41FFD6E979FFFFFFFF15912D0000C70016000000B8FFFFFFFFE963FFFFFFBA04000000488BCEE8A4AFFFFF85C074134C8BC5488BD3488BCEE852B4FFFFE944" & _
		"FFFFFFFF15572D0000C70002000000B8FFFFFFFFE92EFFFFFFCCCCCCCCCCCCCC48895C2418555741574883EC504D8BF9498BE8488BDA488BF94885C9742E4885D274290FB60284C0751E488B09E8FEB8FFFF33C048892F488B9C24800000004883C45041" & _
		"5F5F5DC33C2F7422FF15EE2C0000C70016000000B8FFFFFFFF488B9C24800000004883C450415F5F5DC3BA2F0000004C89742478488BCBE8141B00004C8BF0483BC37524488B842490000000488D5301488B0F4D8BCF4C8BC54889442420E829FEFFFFE9" & _
		"82000000488BCB4889742470FF15EE2C0000488BF04885C07513FF15782C0000C7000C000000B8FFFFFFFFEB54498BC64C8D442430482BC3488BD6C6043000488B0FE831FAFFFF8BD8488BCE85C0740AFF15D22B00008BC3EB27FF15C82B0000488B8424" & _
		"90000000498D5601488B4C24384D8BCF4C8BC54889442420E8A7FDFFFF488B7424704C8B742478488B9C24800000004883C450415F5F5DC3CCCCCCCCCCCCCCCCCCCCCCCC4C8BDC4D8943184D894B205355574883EC7049C743A800000000498BC0488BEA" & _
		"488BF94885C90F84D00000004885C00F84C70000004D8D4320488BD0498D4BA8E8DB0000008BD885C00F88BE0000004889742468488B7424300FB60684C0750D488B0FE878B7FFFF48892FEB773C2F7413FF15792B0000BBFFFFFFFFC70016000000EB60" & _
		"BA2F0000004C89742460488BCEE8AE1900004C8BF0483BC67505488B0FEB1EC600004C8D442438488B0F488BD6E81AF9FFFF8BD885C07523488B4C2440498D560148C7442420000000004C8D0D4BF6FFFF4C8BC5E8A3FCFFFF8BD84C8B742460488BCEFF" & _
		"15932A0000488B7424688BC34883C4705F5D5BC3FF15EE2A0000C70016000000B8FFFFFFFF4883C4705F5D5BC3CCCCCCCCCCCCCCCCCCCCCC48895C240848896C2410488974241857415641574883EC30498BF8488BEA488BF149C7C7FFFFFFFF4885C90F" & _
		"848D000000E83A8EFFFF48897C24284C8BCD4533C048C74424200000000033D24C8BF0488B084883C902FF159C2A000085C0410F48C785C078584863C848FFC1FF15F6290000488BD84885C07444498B0E4C8BCD4883C90148897C24284D8BC748C74424" & _
		"2000000000488BD0FF155A2A000085C08BF8410F48FF85FF790D488BCBFF15AD2900008BC7EB0A48891E8BC7EB03418BC7488B5C2450488B6C2458488B7424604883C430415F415E5FC3CCCCCCCCCCCC48895C240848896C24104889742418574883EC20" & _
		"498BE9498BF0488BDA488BF9E86B99FFFF483BD87613FF15C0290000C70016000000B8FFFFFFFFEB2F837D00004C8BC6488BD3488BCF7407E82F99FFFFEB05E84899FFFF8BD885C0790CFF158C290000C700160000008BC3488B5C2430488B6C2438488B" & _
		"7424404883C4205FC3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC48895C240848896C24104889742418574883EC20498BD9498BE8488BF2488BF9E8DB98FFFF483B3B4C8D48014C0F45C8493BF17613FF1525290000C70016000000B8FFFFFFFFEB224C8BC548" & _
		"8BD6488BCFE89A98FFFF8BD885C0790CFF15FE280000C700160000008BC3488B5C2430488B6C2438488B7424404883C4205FC3CC405356574154415541564881EC880000004533ED488D5C24404D85C94D8BF04C8BE2488BF1490F45D9418BFD48C74308" & _
		"FFFFFFFF44892B4D85C0740A493938750E4885C9750E488D0563370000EB1D4885F675F2BA05000000498BCCE8AFAAFFFF85C07530488D057C370000C7030E00000048894310FF1564280000448928B8FFFFFFFF4881C488000000415E415D415C5F5E5B" & _
		"C34885F674214533C0498BD6488BCEE8E89AFFFF85C0790FC7030C000000488D055F370000EBB74889AC24C0000000498BCC4C89BC24800000004D8BFDE8AA97FFFF4885C00F84DE02000090498BD7498BCCE87597FFFF4C8D8424D00000004C897B0848" & _
		"8D1552370000488BC8488BF0E887B0FFFF85C00F84E1020000488B8C24D0000000E8D2A6FFFF4C8D8424D8000000488BCE488D1554370000488BF8E858B0FFFF85C00F84A9020000488B8C24D8000000E8A3A6FFFF488D1568370000488BCF488BE8E8ED" & _
		"15000085C00F85B90000004C8D442438488BCE488D1556340000E815B0FFFF85C07524C70316000000488D054C34000048894310FF154A270000BFFFFFFFFF448928E902020000498B0E4C8D442430488BD5E86DF2FFFF85C0743CFF15232700008B0889" & _
		"0BFF1519270000488D0D6A340000833802488D0530340000480F44C848894B10FF15FA260000BFFFFFFFFF448928E9B2010000488B542430488B4C2438E84E9FFFFF85C07512C70302000000488D053D340000E974FFFFFF418BFDE985010000488D159D" & _
		"360000488BCFE81D15000085C00F85CF000000498B0E4C8D442458488BD5E8B9F2FFFF85C0743CFF158F2600008B08890BFF1585260000488D0DD6330000833802488D059C330000480F44C848894B10FF1566260000BFFFFFFFFF448928E91E01000048" & _
		"8B4C2458BA05000000E87AA8FFFF488B4C245885C074318B54247041B801000000E82295FFFF8BF885C0793F488D05DD330000C7031600000048894310FF1515260000448928EB234885C97411488B5424684885D27407E85CAEFFFFEB0A488B4C2460E8" & _
		"E0B1FFFF418BFD4C396C24580F85A70000004D892EE99F000000488D15BF350000488BCFE83714000085C0751B41B90100000048895C24204C8BC5488BD6498BCEE8EE000000EB6F488D1595350000488BCFE80914000085C075184533C948895C24204C" & _
		"8BC5488BD6498BCEE8C3000000EB44488D1572350000488BCFE8DE13000085C0750841B901000000EB16488D155F350000488BCFE8C313000085C075534533C94C8BC548895C2420488BD6498BCEE89D0100008BF885FF7814498BCC49FFC7E8CC94FFFF" & _
		"4C3BF80F8223FDFFFF8BC7488BAC24C00000004C8BBC24800000004881C488000000415E415D415C5F5E5BC3488D0501350000EB10488D05A0340000EB07488D055F340000C7031600000048894310FF15D7240000448928B8FFFFFFFFEBACCCCCCCCCCC" & _
		"CCCCCCCCCCCCCCCC48895C240844894C2420574883EC40488BC2498BD8488BF94C8D442430488BC8488D1585310000E844ADFFFF85C07532488B442470488D0D7C310000C7001600000048894810FF1574240000C70000000000B8FFFFFFFF488B5C2450" & _
		"4883C4405FC3837C2468007542488B0F4533C0488BD3E889EFFFFF85C07430FF153F240000488B5C24708B08890BFF1530240000488D1551310000488D0D7A310000833802480F44CA48894B10EB9B488B4C2430E8FB9EFFFF4C8BC04C8D0D11FAFFFF48" & _
		"8D442468488BD3488BCF4889442420E8ACF6FFFF8BD885C07430FF15E0230000488B5424708B08488D05C231000048894210890AFF15C6230000C70000000000488B4C2430E8A6AFFFFF8BC3488B5C24504883C4405FC3CCCCCCCCCCCCCCCCCC48895C24" & _
		"1048896C2418488974242041564883EC60488BC2498BF04C8BF14C8D442430488BC8488D159B310000418BE9E81BACFFFF85C0752D488B842490000000488D0D88310000C7001600000048894810FF154823000033DB8918B8FFFFFFFFE991010000488B" & _
		"4C243048897C2470E83BA2FFFF488BC8488BD8E8861100004C8BC0488BD6488BCB488BF8FF156623000085C07541488BCEE868110000483BF8750733C0E948010000488B842490000000488D0D3F310000C7001600000048894810FF15D722000033DB89" & _
		"18B8FFFFFFFFE91B010000498B0E4C8D442438488BD3E8D9EEFFFF8BF885C07440FF15AD220000488B9C24900000008B08890BFF159B220000488D151C310000488D0D45310000833802480F44CA48894B10FF157C22000033DB8918E9C3000000488B4C" & _
		"2440E8599DFFFF33DB85ED75094C8D0D6CF8FFFFEB5B488B4C2438BA05000000E87BA4FFFF488B4C243885C074178B54245041B801000000E82391FFFF8BF885C07927EB714885C97411488B5424484885D27407E877AAFFFFEB0F488B4C2440E8FBADFF" & _
		"FF48895C24404C8D0D9FF8FFFF4C8B442440488D442438488BD64889442420498BCEE8A5F4FFFF8BF885C0742FFF15D9210000488B9424900000008B08488D05B82F000048894210890AFF15BC2100008918488B4C2440E8A0ADFFFF8BC7488B7C24704C" & _
		"8D5C2460498B5B18498B6B20498B7328498BE3415EC3CCCC4883EC284D8B4138488BCA498BD1E80D000000B8010000004883C428C3CCCCCC4053458B18488BDA4183E3F84C8BC941F600044C8BD17413418B40084D635004F7D84C03D14863C84C23D149" & _
		"63C34A8B1410488B43108B4808488B4308F64401030F74100FB6440103B9F0FFFFFF4823C14C03C84C33CA498BC95BE910000000CCCCCCCCCCCC66660F1F840000000000483B0D09630000751048C1C11066F7C1FFFF7501C348C1C910E996000000CCCC" & _
		"CCCCCCCCCCCC66660F1F8400000000004883EC104C8914244C895C24084D33DB4C8D5424184C2BD04D0F42D3654C8B1C25100000004D3BD37316664181E200F04D8D9B00F0FFFF41C603004D3BD375F04C8B14244C8B5C24084883C410C3CCCC40534883" & _
		"EC20488BD933C9FF153F1F0000488BCBFF153E1F0000FF15281F0000488BC8BA090400C04883C4205B48FF250C1F000048894C24084883EC38B917000000FF15F01E000085C07407B902000000CD29488D0D96640000E8CD010000488B4424384889057D" & _
		"650000488D4424384883C0084889050D650000488B0566650000488905D7630000488B442440488905DB640000C705B1630000090400C0C705AB63000001000000C705B563000001000000B808000000486BC000488D0DAD63000048C7040102000000B8" & _
		"08000000486BC000488B0DB561000048894C0420B808000000486BC001488B0DE061000048894C0420488D0DB42F0000E8FFFEFFFF904883C438C3CC4883EC28B908000000E806000000904883C428C3894C24084883EC28B917000000FF15091E000085" & _
		"C074088B4424308BC8CD29488D0DAE630000E875000000488B44242848890595640000488D4424284883C00848890525640000488B057E640000488905EF620000C705D5620000090400C0C705CF62000001000000C705D962000001000000B808000000" & _
		"486BC000488D0DD16200008B54243048891401488D0D022F0000E84DFEFFFF904883C428C3CCCCCC48895C2420574883EC40488BD9FF15A11D0000488BBBF8000000488D542450488BCF4533C0FF15811D00004885C07435488B542450488D4C245848C7" & _
		"442438000000004C8BC848894C24304C8BC7488D4C246048894C242833C948895C2420FF153F1D0000488B5C24684883C4405FC3405356574883EC40488BD9FF15331D0000488BB3F800000033FF4533C0488D542460488BCEFF15111D00004885C0743C" & _
		"488B542460488D4C246848C7442438000000004C8BC848894C24304C8BC6488D4C247048894C242833C948895C2420FF15CF1C0000FFC783FF027CAE4883C4405F5E5BC34883EC2885D2743983EA01742883EA01741683FA01740AB8010000004883C428" & _
		"C3E8F2040000EB05E8C30400000FB6C04883C428C3498BD04883C428E90F0000004D85C00F95C14883C428E91801000048895C2408488974241048897C242041564883EC20488BF24C8BF133C9E86205000084C00F84C8000000E8E90300008AD8884424" & _
		"4040B701833DB9660000000F85C5000000C705A966000001000000E83404000084C0744FE837080000E876030000E895030000488D15221E0000488D0D131E0000E8940B000085C07529E8D103000084C07420488D15F21D0000488D0DE31D0000E86E0B" & _
		"0000C70554660000020000004032FF8ACBE8360600004084FF753FE87C060000488BD8488338007424488BC8E88305000084C074184C8BC6BA02000000498BCE488B034C8B0D6E1D000041FFD1FF05E5650000B801000000EB0233C0488B5C2430488B74" & _
		"2438488B7C24484883C420415EC3B907000000E83406000090CCCCCC48895C2408574883EC30408AF98B05A565000085C07F0D33C0488B5C24404883C4305FC3FFC889058C650000E8CF0200008AD888442420833DA2650000027536E8E3030000E88602" & _
		"0000E869070000C70587650000000000008ACBE86C05000033D2408ACFE8860500000FB6D8E8E60300008BC3EBA3B907000000E8B00500009090CCCC488BC4488958204C89401889501048894808565741564883EC40498BF08BFA4C8BF185D2750F3915" & _
		"086500007F0733C0E9E50000008D42FF83F8017740488B05F02B00004885C075058D5801EB08FF15601C00008BD8895C243085DB0F84AE0000004C8BC68BD7498BCEE8A5FDFFFF8BD88944243085C00F84930000004C8BC68BD7498BCEE88E0100008BD8" & _
		"8944243083FF01753685C075324C8BC633D2498BCEE8720100004885F60F95C1E8CBFEFFFF488B057C2B00004885C0740E4C8BC633D2498BCEFF15E91B000085FF740583FF03753C4C8BC68BD7498BCEE833FDFFFF8BD88944243085C07425488B05422B" & _
		"00004885C075058D5801EB104C8BC68BD7498BCEFF15AA1B00008BD8895C2430EB0633DB895C24308BC3488B5C24784883C440415E5F5EC348895C24084889742410574883EC20498BF88BDA488BF183FA017505E81F0000004C8BC78BD3488BCE488B5C" & _
		"2430488B7424384883C4205FE99BFEFFFFCCCCCC48895C241855488BEC4883EC30488B05885C000048BB32A2DF2D992B0000483BC37577488D4D1048C7451000000000FF15EF180000488B4510488945F0FF15E91800008BC0483145F0FF15E51800008B" & _
		"C0488D4D18483145F0FF15DD1800008B4518488D4DF048C1E02048334518483345F04833C148B9FFFFFFFFFFFF00004823C148B933A2DF2D992B0000483BC3480F44C1488905025C0000488B5C245048F7D0488905335C00004883C4305DC3CC4883EC28" & _
		"83FA01751048833D0B2A0000007506FF1553180000B8010000004883C428C3CC488D0D0163000048FF2532180000CCCC488D0DF1620000E9FC070000488D05F5620000C34883EC28E82B7DFFFF48830824E8E6FFFFFF488308024883C428C3CC4883EC28" & _
		"E88F07000085C0742165488B042530000000488B4808EB05483BC8741433C0F0480FB10DBC62000075EE32C04883C428C3B001EBF7CCCCCC4883EC28E85307000085C07407E8AA040000EB19E83B0700008BC8E8A607000085C0740432C0EB07E89F0700" & _
		"00B0014883C428C34883EC2833C9E82D01000084C00F95C04883C428C3CCCCCC4883EC28E88F07000084C0750432C0EB12E88207000084C07507E879070000EBECB0014883C428C34883EC28E867070000E862070000B0014883C428C3CCCCCC48895C24" & _
		"0848896C24104889742418574883EC20498BF9498BF08BDA488BE9E8AC06000085C0751683FB0175114C8BC633D2488BCD488BC7FF1532190000488B5424588B4C2450488B5C2430488B6C2438488B7424404883C4205FE9D40600004883EC28E8670600" & _
		"0085C07410488D0DBC6100004883C428E9CF060000E8EE9DFFFF85C07505E8C70600004883C428C34883EC2833C9E8BD0600004883C428E9B40600004883EC2885C97507C6057561000001E878030000E89B06000084C0750432C0EB14E88E06000084C0" & _
		"750933C9E883060000EBEAB0014883C428C3CCCC40534883EC20803D3C610000008BD9756783F901776AE8D505000085C0742885DB7524488D0D26610000E83706000085C07510488D0D2E610000E82706000085C0742E32C0EB33660F6F05D127000048" & _
		"83C8FFF30F7F05F5600000488905FE600000F30F7F05FE60000048890507610000C605D160000001B0014883C4205BC3B905000000E8FE000000CCCC4883EC184C8BC1B84D5A00006639058165FFFF757848630DB465FFFF488D157165FFFF4803CA8139" & _
		"50450000755FB80B0200006639411875544C2BC20FB751144883C2184803D10FB74106488D0C804C8D0CCA48891424493BD174188B4A0C4C3BC1720A8B420803C14C3BC072084883C228EBDF33D24885D2750432C0EB14837A24007D0432C0EB0AB001EB" & _
		"0632C0EB0232C04883C418C340534883EC208AD9E8BF04000033D285C0740B84DB7507488715FE5F00004883C4205BC340534883EC20803DF35F0000008AD9740484D2750CE8160500008ACBE80F050000B0014883C4205BC3CCCCCC488D051D600000C3" & _
		"C705FA5F000000000000C3CC48895C240855488DAC2440FBFFFF4881ECC00500008BD9B917000000FF15DE14000085C074048BCBCD29B903000000E8C0FFFFFF33D2488D4DF041B8D0040000E839040000488D4DF0FF15E9140000488B9DE8000000488D" & _
		"95D8040000488BCB4533C0FF15C71400004885C0743F488B95D8040000488D8DE004000048C7442438000000004C8BC848894C24304C8BC3488D8DE804000048894C2428488D4DF048894C242033C9FF157B140000488B85C8040000488D4C2450488985" & _
		"E800000033D2488D85C804000041B8980000004883C00848898588000000E89F030000488B85C80400004889442460C744245015000040C744245401000000FF15C71300008BD833C9488D4424504889442440488D45F04889442448FF15FA130000488D" & _
		"4C2440FF15F713000085C0750D83FB0174088D4803E8BAFEFFFF488B9C24D00500004881C4C00500005DC3CC48895C2408574883EC20488D1D8B2A0000488D3D842A0000EB12488B034885C07406FF15941500004883C308483BDF72E9488B5C24304883" & _
		"C4205FC348895C2408574883EC20488D1D5F2A0000488D3D582A0000EB12488B034885C07406FF15581500004883C308483BDF72E9488B5C24304883C4205FC3C20000CC48895C241048896C24184889742420574883EC1033C033C90FA281F16E74656C" & _
		"81F2696E65490BD18BE8B80100000081F347656E750BD38D48FF0FA28BF9755E25F03FFF0F48C705A85600000080000048C705A5560000FFFFFFFF3DC006010074283D6006020074213D70060200741A05B0F9FCFF83F820772448B90100010001000000" & _
		"480FA3C17314448B05A75D00004183C8014489059C5D0000EB07448B05935D00004533C9418BF1458BD1458BD983FD077C40418D410733C90FA28BF2448BCB0FBAE309730B4183C802448905645D000083F8017C0DB8070000008D48FA0FA2448BD2B824" & _
		"0000003BE87C0733C90FA2448BDB488B05EB5500004883E0FEC705E555000001000000C705DF55000002000000488905CC5500000FBAE714731F4883E0EFC705C055000002000000488905B1550000C705B3550000060000000FBAE71B0F833301000033" & _
		"C90F01D048C1E220480BD048895424200FBAE71C0F83FC000000488B44242024063C060F85ED0000008B0579550000B2E083C808C705665500000300000089056455000041F6C120746283C820C7054D5500000500000089054B550000B9000003D0488B" & _
		"05335500004423C94883E0FD48890525550000443BC97537488B44242022C23AC27525488B050E550000830D13550000404883E0DBC7050155000006000000488905F2540000EB07488B05E95400000FBAE617730C480FBAF018488905D7540000410FBA" & _
		"E213734A488B44242022C23AC2753F418BCB418BC348C1E91025FF00040083E1068905F95B00004881C92900000148F7D148230D9C54000048890D955400003C01760B4883E1BF48890D86540000410FBAE2157315488B442420480FBAE0137309480FBA" & _
		"356A54000007488B5C242833C0488B6C2430488B7424384883C4105FC3CCCCCCB801000000C3CCCC33C03905685400000F95C0C3CCCCCCCCFF25CA100000FF25CC100000FF25DE100000FF25E8100000FF25EA100000FF25BC100000FF25E6100000FF25" & _
		"B8100000FF25C2100000FF2504120000FF25EE110000FF25F8100000FF254A110000FF2584110000FF255E110000FF2550110000FF2542110000FF2534110000FF2516110000FF2518110000B001C3CCCCCCCCCCCCCCCCCCCCCC66660F1F840000000000" & _
		"FFE0CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC66660F1F840000000000FF25DA11000040554883EC20488BEA8A4D404883C4205DE958FAFFFFCC40554883EC20488BEA8A4D20E846FAFFFF904883C4205DC3CC40554883EC20488BEA4883C4205D" & _
		"E9B7F8FFFFCC40554883EC30488BEA488B018B1048894C2428895424204C8D0DD8F2FFFF4C8B45708B5568488B4D60E8F8F7FFFF904883C4305DC3CC4055488BEA488B0133C98138050000C00F94C18BC15DC3CC00000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"F2E3000000000000DCE3000000000000C4E30000000000000000000000000000A8E300000000000098E3000000000000FEE8000000000000E8E8000000000000CCE8000000000000B2E80000000000009CE800000000000086E80000000000006CE80000" & _
		"0000000050E80000000000003CE800000000000028E80000000000000AE8000000000000EEE7000000000000DAE7000000000000C0E7000000000000ACE7000000000000000000000000000012E40000000000001CE400000000000044E4000000000000" & _
		"58E400000000000026E400000000000070E400000000000030E40000000000003AE40000000000004EE4000000000000000000000000000072E500000000000068E500000000000028E50000000000000000000000000000A6E500000000000000000000" & _
		"000000003CE5000000000000B4E4000000000000A2E4000000000000AAE400000000000000000000000000005CE5000000000000000000000000000034E60000000000004CE6000000000000B0E500000000000018E6000000000000F6E5000000000000" & _
		"DCE5000000000000CAE50000000000009AE500000000000020E5000000000000FCE4000000000000BCE50000000000000000000000000000D0E40000000000006AE600000000000006E5000000000000E2E400000000000072E60000000000007EE50000" & _
		"0000000060E6000000000000000000000000000046E500000000000086E500000000000056E600000000000032E500000000000050E5000000000000000000000000000090E50000000000000000000000000000C8E4000000000000BEE4000000000000" & _
		"00000000000000002C9D0080010000002C9D00800100000070A000800100000090A000800100000090A00080010000000000000000000000FE9F008001000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"000000000000000000000000000000000000000000000000000000000000000000000000302E313800000000303132333435363738392E2B2D6545003031323334353637383961626364656641424344454600005C6200005C6E00005C7200005C740000" & _
		"5C6600005C2200005C5C00005C2F00005C75303025632563000000006E756C6C000000007B0000002C0000000A00000020000000000000001B5B303B33346D00220000001B5B306D000000003A2000003A000000000000001B5B303B33356D00207D0000" & _
		"7D000000747275650000000066616C7365000000696E76616C69642063696E745F74797065000000256C6C6400000000256C6C7500000000000000006A736F6E5F635F7365745F73657269616C697A6174696F6E5F646F75626C655F666F726D61743A20" & _
		"6F7574206F66206D656D6F72790A000000000000000000006A736F6E5F635F7365745F73657269616C697A6174696F6E5F646F75626C655F666F726D61743A206E6F7420636F6D70696C65642077697468205F5F74687265616420737570706F72740A00" & _
		"000000006A736F6E5F635F7365745F73657269616C697A6174696F6E5F646F75626C655F666F726D61743A20696E76616C696420676C6F62616C5F6F725F7468726561642076616C75653A2025640A004E614E00496E66696E6974790000000000000000" & _
		"2D496E66696E697479000000252E3137670000002E3066002E300000000000001B5B303B33326D005B000000205D00005D000000000000006A736F6E5F6F626A6563745F61727261795F736872696E6B2063616C6C65642077697468206E656761746976" & _
		"6520656D7074795F736C6F7473000000000000006A736F6E5F6F626A6563745F636F70795F73657269616C697A65725F646174613A206F7574206F66206D656D6F72790A00000000000000006A736F6E5F6F626A6563745F636F70795F73657269616C69" & _
		"7A65725F646174613A20756E61626C6520746F20636F707920756E6B6E6F776E2073657269616C697A657220646174613A2025700A0000006A736F6E2D632061626F7274732077697468206572726F723A2025730A0000000000C0FFFFFFDF4100000000" & _
		"0000E043000000000000F043000000000000F07F000000000000E0C1000000000000E0C3000000000000F0FF0000000000000000000000000000F07F000000000000F07FFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF7F6E756C6C000000000400000008000000" & _
		"496E66696E6974790000000000000000694E46494E495459000000004E614E000300000074727565000000000400000066616C736500000005000000000000007375636365737300636F6E74696E756500000000000000006E657374696E6720746F6F20" & _
		"646565700000000000000000756E657870656374656420656E64206F6620646174610000756E657870656374656420636861726163746572000000006E756C6C206578706563746564000000626F6F6C65616E2065787065637465640000000000000000" & _
		"6E756D6265722065787065637465640061727261792076616C756520736570617261746F7220272C2720657870656374656400000000000071756F746564206F626A6563742070726F7065727479206E616D65206578706563746564000000006F626A65" & _
		"63742070726F7065727479206E616D6520736570617261746F7220273A2720657870656374656400000000006F626A6563742076616C756520736570617261746F7220272C272065787065637465640000000000696E76616C696420737472696E672073" & _
		"657175656E636500657870656374656420636F6D6D656E740000000000000000696E76616C6964207574662D3820737472696E67000000006275666665722073697A65206F766572666C6F77000000006F7574206F66206D656D6F7279000000556E6B6E" & _
		"6F776E206572726F722C20696E76616C6964206A736F6E5F746F6B656E65725F6572726F722076616C75652070617373656420746F206A736F6E5F746F6B656E65725F6572726F725F6465736328290043000000080000000D000000090000000C000000" & _
		"0000807F00000000000000000000F87F000080FF00000000626F6F6C65616E00646F75626C650000696E74006F626A65637400006172726179000000737472696E670000000000006A736F6E5F6F626A6563745F66726F6D5F66645F65783A207072696E" & _
		"746275665F6E6577206661696C65640A000000006A736F6E5F6F626A6563745F66726F6D5F66645F65783A20756E61626C6520746F20616C6C6F63617465206A736F6E5F746F6B656E65722864657074683D2564293A2025730A00000000000000000000" & _
		"6A736F6E5F6F626A6563745F66726F6D5F66645F65783A206661696C656420746F207072696E746275665F6D656D617070656E642061667465722072656164696E672025642B25642062797465733A2025730000000000006A736F6E5F6F626A6563745F" & _
		"66726F6D5F66645F65783A206572726F722072656164696E672066642025643A2025730A00000000000000006A736F6E5F746F6B656E65725F70617273655F6578206661696C65643A2025730A000000000000006A736F6E5F6F626A6563745F66726F6D" & _
		"5F66696C653A206572726F72206F70656E696E672066696C652025733A2025730A000000000000006A736F6E5F6F626A6563745F746F5F66696C655F6578743A206F626A656374206973206E756C6C0A00000000000000006A736F6E5F6F626A6563745F" & _
		"746F5F66696C655F6578743A206572726F72206F70656E696E672066696C652025733A2025730A00000000006A736F6E5F6F626A6563745F746F5F66643A206F626A656374206973206E756C6C0A00002866642900000000000000006A736F6E5F6F626A" & _
		"6563745F746F5F66643A206572726F722077726974696E672066696C652025733A2025730A0000006A736F6E5F747970655F746F5F6E616D653A2074797065202564206973206F7574206F662072616E6765205B302C25755D0A0000000000004552524F" & _
		"523A20696E76616C69642072657475726E2076616C75652066726F6D206A736F6E5F635F7669736974207573657266756E633A2025640A0000000000494E5445524E414C204552524F523A205F6A736F6E5F635F76697369742072657475726E65642025" & _
		"640A000000000000494E5445524E414C204552524F523A205F6A736F6E5F635F766973697420666F756E64206F626A656374206F6620756E6B6E6F776E20747970653A2025640A001F85EB51B81EE53F6572726F7220437279707441637175697265436F" & _
		"6E74657874412030782530386C780000000000006572726F7220437279707447656E52616E646F6D2030782530386C7800000000756E6465665F455045524D0000000000756E6465665F454E4F454E5400000000756E6465665F45535243480000000000" & _
		"756E6465665F45494E54520000000000756E6465665F45494F00000000000000756E6465665F454E58494F0000000000756E6465665F45324249470000000000756E6465665F454E4F45584543000000756E6465665F45424144460000000000756E6465" & _
		"665F454348494C4400000000756E6465665F45444541444C4B000000756E6465665F454E4F4D454D00000000756E6465665F45414343455300000000756E6465665F454641554C5400000000756E6465665F45425553590000000000756E6465665F4545" & _
		"5849535400000000756E6465665F45584445560000000000756E6465665F454E4F44455600000000756E6465665F454E4F54444952000000756E6465665F45495344495200000000756E6465665F45494E56414C00000000756E6465665F454E46494C45" & _
		"00000000756E6465665F454D46494C4500000000756E6465665F454E4F54545900000000756E6465665F45545854425359000000756E6465665F45464249470000000000756E6465665F454E4F53504300000000756E6465665F45535049504500000000" & _
		"756E6465665F45524F46530000000000756E6465665F454D4C494E4B00000000756E6465665F45504950450000000000756E6465665F45444F4D000000000000756E6465665F4552414E474500000000756E6465665F45414741494E000000005F4A534F" & _
		"4E5F435F5354524552524F525F454E41424C45003031323334353637383900007E3100007E30000076616C7565000000000000005061746368206F626A65637420646F6573206E6F7420636F6E7461696E2061202776616C756527206669656C64000000" & _
		"446964206E6F742066696E6420656C656D656E74207265666572656E6365642062792070617468206669656C64000000496E76616C69642070617468206669656C6400000000000056616C7565206F6620656C656D656E74207265666572656E63656420" & _
		"627920277061746827206669656C6420646964206E6F74206D61746368202776616C756527206669656C6400556E61626C6520746F2072656D6F76652070617468207265666572656E63656420627920277061746827206669656C640000000000000000" & _
		"4661696C656420746F207365742076616C75652061742070617468207265666572656E63656420627920277061746827206669656C64000066726F6D00000000506174636820646F6573206E6F7420636F6E7461696E2061202766726F6D27206669656C" & _
		"64000000496E76616C696420617474656D707420746F206D6F766520706172656E7420756E6465722061206368696C6400000000446964206E6F742066696E6420656C656D656E74207265666572656E6365642062792066726F6D206669656C64000000" & _
		"496E76616C69642066726F6D206669656C6400000000000045786163746C79206F6E65206F66202A62617365206F7220636F70795F66726F6D206D757374206265206E6F6E2D4E554C4C0000000000005061746368206F626A656374206973206E6F7420" & _
		"6F662074797065206A736F6E5F747970655F61727261790000000000556E61626C6520746F20636F707920636F70795F66726F6D207573696E67206A736F6E5F6F626A6563745F646565705F636F7079282900006F700000000000005061746368206F62" & _
		"6A65637420646F6573206E6F7420636F6E7461696E20276F7027206669656C64000000007061746800000000000000005061746368206F626A65637420646F6573206E6F7420636F6E7461696E20277061746827206669656C6400007465737400000000" & _
		"72656D6F76650000616464007265706C616365006D6F766500000000636F7079000000005061746368206F626A6563742068617320696E76616C696420276F7027206669656C64000000000080F500800100000020F60080010000000000000000000000" & _
		"0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF40010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"000000000000000000000000C0F30080010000000000000000000000000000000000000060B200800100000070B2008001000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000" & _
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000C4008001000000000000000000000000000000" & _
		"0000000068B200800100000078B200800100000080B200800100000088B200800100000090B20080010000000000000099F8276A0000000002000000590000007CC400007CAA00000000000099F8276A000000000C00000014000000D8C40000D8AA0000" & _
		"0000000099F8276A000000000D00000058020000ECC40000ECAA0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"0000000000000000000000000000000000000000180000000380038018C40000440000005CC4000020000000566C0000756C0000856C00008F9100000B9200002092000077920000459800005B9800001B9B0000159C0000479C0000879E0000969E0000" & _
		"F89E0000489F0000999F000000100000A080000030910000B00E000058A000000800000096A000009200000052534453F95C4F5B459CDE439958C45B2CACC2BC01000000433A5C64776E5C7663706B672D6D61737465725C6275696C6474726565735C6A" & _
		"736F6E2D635C7836342D77696E646F77732D72656C5C6A736F6E2D632E7064620000000000000000230000002300000000000000150000000000000000100000609000002E74657874246D6E0000000060A00000360000002E74657874246D6E24303000" & _
		"96A00000920000002E7465787424780000B00000600200002E696461746124350000000060B20000380000002E3030636667000098B20000080000002E4352542458434100000000A0B20000080000002E4352542458435A00000000A8B2000008000000" & _
		"2E4352542458494100000000B0B20000080000002E4352542458495A00000000B8B20000080000002E4352542458504100000000C0B20000080000002E4352542458505A00000000C8B20000080000002E4352542458544100000000D0B2000010000000" & _
		"2E4352542458545A00000000E0B20000201100002E7264617461000000C400007C0000002E726461746124766F6C746D640000007CC40000CC0200002E7264617461247A7A7A64626700000048C70000080000002E727463244941410000000050C70000" & _
		"080000002E72746324495A5A0000000058C70000080000002E727463245441410000000060C70000080000002E72746324545A5A0000000068C70000A80A00002E7864617461000010D20000240E00002E6564617461000034E00000F00000002E696461" & _
		"746124320000000024E10000140000002E696461746124330000000038E10000600200002E696461746124340000000098E300007A0500002E696461746124360000000000F00000500400002E6461746100000050F40000300700002E62737300000000" & _
		"00000100EC0A00002E7064617461000000100100600000002E727372632430310000000060100100800100002E7273726324303200000000000000000000000000000000000000000000000000000000000000000000000000000000010F06000F640700" & _
		"0F3406000F320B70010A04000A3406000A320670010F06000F5408000F3407000F320B702105020005640600401200006F12000084C700002100020000640600401200006F12000084C7000021000000401200006F12000084C700000114080014640800" & _
		"145407001434060014321070010401000462000001150800157409001564080015540700153211E0210502000534060090100000CB100000E8C700002100000090100000CB100000E8C700000118020018721470210D04000D6406000434070060150000" & _
		"8415000020C8000021000000601500008415000020C80000011B04001B521770166015300106020006320230011A0A001A7409001A6408001A5407001A3406001A3216E0011A0A001A740B001A640A001A5409001A3408001A5216E001180A0018640C00" & _
		"18540B0018340A00185214F012E0107001040100044200000109010009420000010903000968020004620000010F06000F6802000A3408000A520670010A04000A3409000A5206702105020005680200502D0000A52D0000D8C800002100020000680200" & _
		"502D0000A52D0000D8C8000021000000502D0000A52D0000D8C800002105020005740600C0300000DF3000005CC8000021000000C0300000DF3000005CC80000010F06000F6409000F3408000F320B702105020005540700202A00007F2B000040C90000" & _
		"2100020000540700202A00007F2B000040C9000021000000202A00007F2B000040C9000001060200065202302105020005740800602400007C24000088C9000021000000602400007C24000088C900000116040016521270116010300112050012620E70" & _
		"0D600C500B30000001580B0058F4060051D40F0011620DE00BC00970086007500630000019150200067202302090000038000000011E0A001E340D001E321AF018E016D014C0127011601050191D06000E720AF008E00670055004302090000038000000" & _
		"2108040008C4110004641000C01D0000F71D000014CA000021000000C01D0000F71D000014CA000019290B00173420001701160010F00EE00CD00AC0087007600650000020900000A000000001180A0018640A001854090018340800183214F012E01070" & _
		"010A02000A320630011C0C001C640D001C540C001C340B001C3218F016E014D012C0107001670D0067E408006074100058540F0053340E000C8208F006D004C002600000010E02000E320A30210D04000D64070005540600406200004E620000D4CA0000" & _
		"21050200057408004E62000066620000DCCA0000210000004E62000066620000DCCA000021000000406200004E620000D4CA0000011D07001D01160011F00FE00D700C600B500000210802000834150050450000AB45000028CB0000212F0A002F880600" & _
		"297807002468080017D4130008C414000A5F00001F60000074CB0000210002000034150050450000AB45000028CB00002100000050450000AB45000028CB0000192405001201060205E003600230000020900000201000002108020008540C0240640000" & _
		"8E64000098CB00002108020008740D028E640000DE640000B0CB0000210000008E640000DE640000B0CB000021000000406400008E64000098CB000001480800486406000F5408000F3407000F320B70010A04000A3407000A3206700110060010640900" & _
		"1054080010320CE0210D04000D74070005340600506300009C63000018CC0000210004000074070000340600506300009C63000018CC0000011A03001A6216701530000001170A0017540E0017340D00175213F011E00FD00DC00B702105020005640C00" & _
		"70690000126A000064CC00002100000070690000126A000064CC00000113080013640A001354090013320FF00DE00B70210502000534080090750000C7750000A0CC00002100000090750000C7750000A0CC000001060200063202702105020005340600" & _
		"5071000060710000D8CC0000210000005071000060710000D8CC0000011E0C001E740D001E640C001E540B001E340A001E521AF018E016C02105020005740700E06F0000087000005CC80000210904000964060000740700E06F0000087000005CC80000" & _
		"210004000074070000640600E06F0000087000005CC8000001020100023000002105020005740300A06C0000A96C000064CD00002105020005640200A96C0000C76C00006CCD000021000000A96C0000C76C00006CCD000021000000A06C0000A96C0000" & _
		"64CD00000113080013640A001334090013320FF00DE00B702105020005540800A0770000DF770000B4CD000021000000A0770000DF770000B4CD00002100020000540800A0770000DF770000B4CD00001932090020011A0019F017E015C0137012601150" & _
		"1030000020900000C000000021050200053406004076000077760000D8CC000021000200003406004076000077760000D8CC00000115080015740C0015640B0015340A00157211E00111030011C20D700C5000002104020004340C00D07E0000007F0000" & _
		"5CCE00002105020005640B00007F0000167F000068CE000021000000007F0000167F000068CE000021000000D07E0000007F00005CCE00000175080075E40D000F540F000F340E000F920B702105020005640C0000820000AC820000B0CE000021000000" & _
		"00820000AC820000B0CE00000112040012D20E700D500C302105020005640D00C08500000F860000E8CE00002105020005E40C000F86000049860000F4CE0000210000000F86000049860000F4CE000021000000C08500000F860000E8CE000021050200" & _
		"05640600D07D0000277E000084C700002100020000640600D07D0000277E000084C7000021000000D07D0000277E000084C700000178080078E40F000D3410000D9209F0077006502105020005640E00708400001F85000074CF00002100000070840000" & _
		"1F85000074CF000001150800156409001554080015340700153211E021050200057406004083000073830000ACCF0000210000004083000073830000ACCF000021000200007406004083000073830000ACCF0000015A0D005AF4040050C40D0048540C00" & _
		"40340B000F420BE009D007700660000001110800110111000AE008D006C00470036002302113040013F4100008541800D08800008B89000018D000002100040000F4100000541800D08800008B89000018D00000010F04000F340A000F720B7001150800" & _
		"156411001554100015340F0015B211E02105020005740E00108E00007B8E000068D0000021000000108E00007B8E000068D000000100000000000000010401000412000001080100084200000109010009620000010A04000A340D000A72067001080400" & _
		"087204700360023011150800157409001564070015340600153211E00AA000000200000058940000C794000096A00000000000002A9500003595000096A00000000000000106020006320250110A04000A3408000A5206700AA00000040000006F950000" & _
		"91950000ADA000000000000064950000A5950000C6A0000000000000AE950000B9950000ADA0000000000000AE950000BA950000C6A0000000000000091A06001A340F001A7216E0147013600AA0000001000000F1950000CE960000DAA00000CE960000" & _
		"0106020006520250010D04000D340A000D52065009040100042200000AA0000001000000739A0000FD9A000010A10000FD9A00000102010002500000011505001534BA001501B80006500000011408001464070014540600143405001412107001000000" & _
		"000000000100000000000000000000000000000000000000FFFFFFFF0000000098D6000001000000700000007000000038D20000F8D30000B8D50000107B0000801B0000901B0000201C00006016000070160000006C00006020000070200000A0200000" & _
		"3021000040210000502100006021000070210000A02100006024000090270000202A0000902C0000306400004064000010660000A02C0000B02C0000D02C0000502D0000E02E0000C02F0000A0300000C030000050310000703100008031000060320000" & _
		"70320000E03300003043000050430000604300007037000070430000804300009043000090340000A03400002035000070350000D0350000B0360000103700007037000080370000103800003038000040380000A038000050390000103A0000203A0000" & _
		"603A0000903A0000A03D0000203E0000403E0000803E0000B03E0000D03E0000C03F0000F03F0000004000002040000080660000B0660000C066000050410000C041000040420000E042000090670000D067000060680000D0880000F07C0000D07E0000" & _
		"00820000C0850000A0430000C043000000440000104400002044000030440000C0440000504500009061000040620000E0620000106900005069000060150000D015000030160000D01500004016000050160000D076000000770000A077000060780000" & _
		"C0780000D0780000A3D60000B4D60000C9D60000F0D600000CD700001BD700002ED700003BD7000051D700006BD7000085D700009FD70000BCD70000D5D70000EFD7000008D800001FD8000035D8000057D8000069D8000083D8000097D80000AED80000" & _
		"C4D80000D4D80000EAD8000002D9000019D900002DD9000043D900005AD9000071D900008CD90000A1D90000B8D90000D1D90000E5D90000F9D9000010DA000025DA00003CDA00005ADA000070DA00008BDA0000A7DA0000BDDA0000D7DA0000EFDA0000" & _
		"06DB00001FDB000033DB000049DB00005EDB000075DB00008CDB0000A7DB0000BEDB0000D5DB0000EFDB000006DC00001DDC000037DC000051DC000061DC000079DC000090DC0000A4DC0000BADC0000D5DC0000ECDC000007DD00001EDD000037DD0000" & _
		"49DD00005DDD000075DD000090DD0000AFDD0000D1DD0000F5DD000007DE000018DE00002ADE00003BDE00004CDE00005EDE00006FDE000081DE000099DE0000ABDE0000C2DE0000DDDE0000EEDE000002DF000015DF00002BDF000046DF000059DF0000" & _
		"70DF000082DF000099DF0000A2DF0000ABDF0000B8DF0000C0DF0000CDDF0000DBDF0000E9DF0000FCDF00000CE0000019E0000028E0000000000100020003000400050006000700080009000A000B000C000D000E000F00100011001200130014001500" & _
		"16001700180019001A001B001C001D001E001F0020002100220023002400250026002700280029002A002B002C002D002E002F0030003100320033003400350036003700380039003A003B003C003D003E003F0040004100420043004400450046004700" & _
		"480049004A004B004C004D004E004F0050005100520053005400550056005700580059005A005B005C005D005E005F0060006100620063006400650066006700680069006A006B006C006D006E006F006A736F6E2D632E646C6C005F6A736F6E5F635F73" & _
		"74726572726F72006A736F6E5F635F6F626A6563745F73697A656F66006A736F6E5F635F7365745F73657269616C697A6174696F6E5F646F75626C655F666F726D6174006A736F6E5F635F7368616C6C6F775F636F70795F64656661756C74006A736F6E" & _
		"5F635F76657273696F6E006A736F6E5F635F76657273696F6E5F6E756D006A736F6E5F635F7669736974006A736F6E5F6F626A6563745F61727261795F616464006A736F6E5F6F626A6563745F61727261795F62736561726368006A736F6E5F6F626A65" & _
		"63745F61727261795F64656C5F696478006A736F6E5F6F626A6563745F61727261795F6765745F696478006A736F6E5F6F626A6563745F61727261795F696E736572745F696478006A736F6E5F6F626A6563745F61727261795F6C656E677468006A736F" & _
		"6E5F6F626A6563745F61727261795F7075745F696478006A736F6E5F6F626A6563745F61727261795F736872696E6B006A736F6E5F6F626A6563745F61727261795F736F7274006A736F6E5F6F626A6563745F646565705F636F7079006A736F6E5F6F62" & _
		"6A6563745F646F75626C655F746F5F6A736F6E5F737472696E67006A736F6E5F6F626A6563745F657175616C006A736F6E5F6F626A6563745F667265655F7573657264617461006A736F6E5F6F626A6563745F66726F6D5F6664006A736F6E5F6F626A65" & _
		"63745F66726F6D5F66645F6578006A736F6E5F6F626A6563745F66726F6D5F66696C65006A736F6E5F6F626A6563745F676574006A736F6E5F6F626A6563745F6765745F6172726179006A736F6E5F6F626A6563745F6765745F626F6F6C65616E006A73" & _
		"6F6E5F6F626A6563745F6765745F646F75626C65006A736F6E5F6F626A6563745F6765745F696E74006A736F6E5F6F626A6563745F6765745F696E743634006A736F6E5F6F626A6563745F6765745F6F626A656374006A736F6E5F6F626A6563745F6765" & _
		"745F737472696E67006A736F6E5F6F626A6563745F6765745F737472696E675F6C656E006A736F6E5F6F626A6563745F6765745F74797065006A736F6E5F6F626A6563745F6765745F75696E743634006A736F6E5F6F626A6563745F6765745F75736572" & _
		"64617461006A736F6E5F6F626A6563745F696E745F696E63006A736F6E5F6F626A6563745F69735F74797065006A736F6E5F6F626A6563745F697465725F626567696E006A736F6E5F6F626A6563745F697465725F656E64006A736F6E5F6F626A656374" & _
		"5F697465725F657175616C006A736F6E5F6F626A6563745F697465725F696E69745F64656661756C74006A736F6E5F6F626A6563745F697465725F6E657874006A736F6E5F6F626A6563745F697465725F7065656B5F6E616D65006A736F6E5F6F626A65" & _
		"63745F697465725F7065656B5F76616C7565006A736F6E5F6F626A6563745F6E65775F6172726179006A736F6E5F6F626A6563745F6E65775F61727261795F657874006A736F6E5F6F626A6563745F6E65775F626F6F6C65616E006A736F6E5F6F626A65" & _
		"63745F6E65775F646F75626C65006A736F6E5F6F626A6563745F6E65775F646F75626C655F73006A736F6E5F6F626A6563745F6E65775F696E74006A736F6E5F6F626A6563745F6E65775F696E743634006A736F6E5F6F626A6563745F6E65775F6E756C" & _
		"6C006A736F6E5F6F626A6563745F6E65775F6F626A656374006A736F6E5F6F626A6563745F6E65775F737472696E67006A736F6E5F6F626A6563745F6E65775F737472696E675F6C656E006A736F6E5F6F626A6563745F6E65775F75696E743634006A73" & _
		"6F6E5F6F626A6563745F6F626A6563745F616464006A736F6E5F6F626A6563745F6F626A6563745F6164645F6578006A736F6E5F6F626A6563745F6F626A6563745F64656C006A736F6E5F6F626A6563745F6F626A6563745F676574006A736F6E5F6F62" & _
		"6A6563745F6F626A6563745F6765745F6578006A736F6E5F6F626A6563745F6F626A6563745F6C656E677468006A736F6E5F6F626A6563745F707574006A736F6E5F6F626A6563745F7365745F626F6F6C65616E006A736F6E5F6F626A6563745F736574" & _
		"5F646F75626C65006A736F6E5F6F626A6563745F7365745F696E74006A736F6E5F6F626A6563745F7365745F696E743634006A736F6E5F6F626A6563745F7365745F73657269616C697A6572006A736F6E5F6F626A6563745F7365745F737472696E6700" & _
		"6A736F6E5F6F626A6563745F7365745F737472696E675F6C656E006A736F6E5F6F626A6563745F7365745F75696E743634006A736F6E5F6F626A6563745F7365745F7573657264617461006A736F6E5F6F626A6563745F746F5F6664006A736F6E5F6F62" & _
		"6A6563745F746F5F66696C65006A736F6E5F6F626A6563745F746F5F66696C655F657874006A736F6E5F6F626A6563745F746F5F6A736F6E5F737472696E67006A736F6E5F6F626A6563745F746F5F6A736F6E5F737472696E675F657874006A736F6E5F" & _
		"6F626A6563745F746F5F6A736F6E5F737472696E675F6C656E677468006A736F6E5F6F626A6563745F75736572646174615F746F5F6A736F6E5F737472696E67006A736F6E5F70617273655F646F75626C65006A736F6E5F70617273655F696E74363400" & _
		"6A736F6E5F70617273655F75696E743634006A736F6E5F70617463685F6170706C79006A736F6E5F706F696E7465725F676574006A736F6E5F706F696E7465725F67657466006A736F6E5F706F696E7465725F736574006A736F6E5F706F696E7465725F" & _
		"73657466006A736F6E5F746F6B656E65725F6572726F725F64657363006A736F6E5F746F6B656E65725F66726565006A736F6E5F746F6B656E65725F6765745F6572726F72006A736F6E5F746F6B656E65725F6765745F70617273655F656E64006A736F" & _
		"6E5F746F6B656E65725F6E6577006A736F6E5F746F6B656E65725F6E65775F6578006A736F6E5F746F6B656E65725F7061727365006A736F6E5F746F6B656E65725F70617273655F6578006A736F6E5F746F6B656E65725F70617273655F766572626F73" & _
		"65006A736F6E5F746F6B656E65725F7265736574006A736F6E5F746F6B656E65725F7365745F666C616773006A736F6E5F747970655F746F5F6E616D65006A736F6E5F7574696C5F6765745F6C6173745F657272006D635F6465627567006D635F657272" & _
		"6F72006D635F6765745F6465627567006D635F696E666F006D635F7365745F6465627567006D635F7365745F7379736C6F67007072696E746275665F66726565007072696E746275665F6D656D617070656E64007072696E746275665F6D656D73657400" & _
		"7072696E746275665F6E6577007072696E746275665F726573657400737072696E7462756600000058E100000000000000000000B6E3000020B0000038E10000000000000000000004E4000000B00000E8E10000000000000000000090E40000B0B00000" & _
		"68E2000000000000000000007CE6000030B1000080E3000000000000000000009CE6000048B2000000E300000000000000000000BEE60000C8B10000A0E200000000000000000000DEE6000068B1000038E20000000000000000000000E7000000B10000" & _
		"40E30000000000000000000022E7000008B2000090E20000000000000000000044E7000058B1000070E30000000000000000000066E7000038B2000058E20000000000000000000086E7000020B100000000000000000000000000000000000000000000" & _
		"F2E3000000000000DCE3000000000000C4E30000000000000000000000000000A8E300000000000098E3000000000000FEE8000000000000E8E8000000000000CCE8000000000000B2E80000000000009CE800000000000086E80000000000006CE80000" & _
		"0000000050E80000000000003CE800000000000028E80000000000000AE8000000000000EEE7000000000000DAE7000000000000C0E7000000000000ACE7000000000000000000000000000012E40000000000001CE400000000000044E4000000000000" & _
		"58E400000000000026E400000000000070E400000000000030E40000000000003AE40000000000004EE4000000000000000000000000000072E500000000000068E500000000000028E50000000000000000000000000000A6E500000000000000000000" & _
		"000000003CE5000000000000B4E4000000000000A2E4000000000000AAE400000000000000000000000000005CE5000000000000000000000000000034E60000000000004CE6000000000000B0E500000000000018E6000000000000F6E5000000000000" & _
		"DCE5000000000000CAE50000000000009AE500000000000020E5000000000000FCE4000000000000BCE50000000000000000000000000000D0E40000000000006AE600000000000006E5000000000000E2E400000000000072E60000000000007EE50000" & _
		"0000000060E6000000000000000000000000000046E500000000000086E500000000000056E600000000000032E500000000000050E5000000000000000000000000000090E50000000000000000000000000000C8E4000000000000BEE4000000000000" & _
		"00000000000000008D024765744C6173744572726F720000500347657456657273696F6E00004B45524E454C33322E646C6C0000C100437279707441637175697265436F6E74657874410000DC00437279707452656C65617365436F6E7465787400D200" & _
		"437279707447656E52616E646F6D000041445641504933322E646C6C00003D006D656D6D6F7665003E006D656D736574000040007374726368720000420073747273747200003B006D656D636D7000003C006D656D637079000041007374727263687200" & _
		"08005F5F435F73706563696669635F68616E646C6572000025005F5F7374645F747970655F696E666F5F64657374726F795F6C6973740000564352554E54494D453134302E646C6C0000180066726565000019006D616C6C6F6300001A007265616C6C6F" & _
		"630010006273656172636800190071736F72740000005F5F616372745F696F625F66756E630003005F5F737464696F5F636F6D6D6F6E5F76667072696E74660021005F6572726E6F00000D005F5F737464696F5F636F6D6D6F6E5F76737072696E746600" & _
		"540061626F7274005E00737472746F6400008B007374726C656E0000170063616C6C6F6300008E007374726E636D700034005F7374726E69636D700013007365746C6F63616C65006300737472746F6C6C006500737472746F756C6C000049005F6F7065" & _
		"6E008600737472636D70000030005F74696D6536340064007374726572726F7200001000676574656E76000036005F696E69747465726D0037005F696E69747465726D5F65003F005F7365685F66696C7465725F646C6C0018005F636F6E666967757265" & _
		"5F6E6172726F775F61726776000033005F696E697469616C697A655F6E6172726F775F656E7669726F6E6D656E74000034005F696E697469616C697A655F6F6E657869745F7461626C65000022005F657865637574655F6F6E657869745F7461626C6500" & _
		"16005F6365786974000029005F7374726475700017005F636C6F7365000052005F72656164006B005F777269746500006170692D6D732D77696E2D6372742D686561702D6C312D312D302E646C6C00006170692D6D732D77696E2D6372742D7574696C69" & _
		"74792D6C312D312D302E646C6C006170692D6D732D77696E2D6372742D737464696F2D6C312D312D302E646C6C006170692D6D732D77696E2D6372742D72756E74696D652D6C312D312D302E646C6C006170692D6D732D77696E2D6372742D636F6E7665" & _
		"72742D6C312D312D302E646C6C006170692D6D732D77696E2D6372742D737472696E672D6C312D312D302E646C6C00006170692D6D732D77696E2D6372742D6C6F63616C652D6C312D312D302E646C6C00006170692D6D732D77696E2D6372742D74696D" & _
		"652D6C312D312D302E646C6C00006170692D6D732D77696E2D6372742D656E7669726F6E6D656E742D6C312D312D302E646C6C00090552746C43617074757265436F6E7465787400110552746C4C6F6F6B757046756E6374696F6E456E74727900001805" & _
		"52746C5669727475616C556E77696E640000FB05556E68616E646C6564457863657074696F6E46696C7465720000B805536574556E68616E646C6564457863657074696F6E46696C74657200410247657443757272656E7450726F6365737300D8055465" & _
		"726D696E61746550726F636573730000B803497350726F636573736F724665617475726550726573656E740081045175657279506572666F726D616E6365436F756E74657200420247657443757272656E7450726F636573734964004602476574437572" & _
		"72656E74546872656164496400001A0347657453797374656D54696D65417346696C6554696D6500420144697361626C655468726561644C69627261727943616C6C73009A03496E697469616C697A65534C6973744865616400B0034973446562756767" & _
		"657250726573656E7400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000F8B2008001000000E8B200800100000080B600800100000088B600800100000098B6008001000000B0B6008001000000C8B60080" & _
		"01000000E0B6008001000000F0B600800100000008B700800100000018B700800100000040B700800100000068B700800100000098B7008001000000C0B7008001000000D8B7008001000000F0B700800100000008B800800100000020B8008001000000" & _
		"EFBFBD00000000003CB3008001000000B0B8008001000000B8B8008001000000C0B8008001000000C4B8008001000000CCB8008001000000D4B8008001000000506C008001000000FFFFFFFF000000000000000000000000010000000000000056BC0080" & _
		"01000000020000000000000066BC008001000000030000000000000076BC008001000000040000000000000086BC008001000000050000000000000096BC0080010000000600000000000000A6BC0080010000000700000000000000B6BC008001000000" & _
		"0800000000000000C6BC0080010000000900000000000000D6BC0080010000000A00000000000000E6BC0080010000002400000000000000F6BC0080010000000C0000000000000006BD0080010000000D0000000000000016BD0080010000000E000000" & _
		"0000000026BD008001000000100000000000000036BD008001000000110000000000000046BD008001000000120000000000000056BD008001000000130000000000000066BD008001000000140000000000000076BD0080010000001500000000000000" & _
		"86BD008001000000160000000000000096BD0080010000001700000000000000A6BD0080010000001800000000000000B6BD0080010000001900000000000000C6BD0080010000008B00000000000000D6BD0080010000001B00000000000000E6BD0080" & _
		"010000001C00000000000000F6BD0080010000001D0000000000000006BE0080010000001E0000000000000016BE0080010000001F0000000000000026BE008001000000200000000000000036BE008001000000210000000000000046BE008001000000" & _
		"220000000000000056BE0080010000000B0000000000000066BE008001000000000000000000000000000000000000004552524E4F3D00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"000000000000000032A2DF2D992B00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000CD5D20D266D4FFFF7598000000000000FFFFFFFF00000000FFFFFFFF" & _
		"FFFFFFFF010000000200000000000800000000000000000200000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000005E10000068C7000060100000" & _
		"81100000E0C7000090100000CB100000E8C70000CB10000022110000FCC70000221100003D11000010C8000040110000BE11000078C70000C01100001812000078C70000401200006F12000084C700006F1200009E12000094C700009E120000FF120000" & _
		"A8C70000FF1200005E130000BCC7000070130000FF13000068C70000001400009B140000CCC70000A01400002A15000078C70000601500008415000020C8000084150000C415000028C80000C4150000CA15000040C80000D01500002516000050C80000" & _
		"801600002617000068C70000301700002318000078CA0000301800007118000068C7000080180000C5180000B4C90000D0180000021900005CC8000010190000781B000098CA0000901B00001D1C00005CC80000201C0000481D000078C70000501D0000" & _
		"B11D0000C0C90000C01D0000F71D000014CA0000F71D0000C71F00002CCA0000C71F00005120000044CA00007020000099200000B4C80000B02000002221000090CA00007021000095210000ACC80000B0210000CA230000FCC90000D02300005A240000" & _
		"68C70000602400007C24000088C900007C240000C824000090C90000C8240000DF240000A4C90000E024000083270000B4CA000090270000A7270000E0C70000B0270000C7270000E0C70000D02700001E2A000054CA0000202A00007F2B000040C90000" & _
		"7F2B0000D62B000050C90000D62B0000242C000064C90000242C0000842C000078C90000D02C00004D2D0000ACC80000502D0000A52D0000D8C80000A52D00000B2E0000E4C800000B2E00004C2E0000F8C800004C2E0000D92E00000CC90000E02E0000" & _
		"BB2F0000ACC80000C02F000094300000ACC80000C0300000DF3000005CC80000DF300000303100001CC90000303100004431000030C90000803100005F320000ACC800007032000066330000ACC8000070330000DC330000ECC90000003400008F340000" & _
		"5CC80000A03400002035000078C70000203500006D3500005CC8000070350000CB350000BCC80000D0350000A3360000C8C80000B0360000053700005CC8000010370000623700005CC8000080370000083800005CC80000103800002E3800005CC80000" & _
		"40380000963800005CC80000A03800004C3900007CC80000503900000E3A000094C80000203A0000563A0000ACC80000A03A00009D3D0000D0C90000A03D0000203E00005CC80000403E00007E3E0000ACC80000D03E0000C03F000064C80000C03F0000" & _
		"F03F000078C70000204000007740000068C70000804000004741000064C8000050410000B94100005CC80000C04100003B42000078C7000040420000E042000064C80000E04200002143000068C700003043000042430000ACC80000C0430000F5430000" & _
		"5CC8000030440000B344000078C70000C04400004E45000078C7000050450000AB45000028CB0000AB450000F54500003CCB0000F54500000A5F000050CB00000A5F00001F60000074CB00001F6000008861000088CB0000906100003762000068C70000" & _
		"406200004E620000D4CA00004E62000066620000DCCA000066620000C3620000F4CA0000C3620000D862000008CB0000D8620000D962000018CB0000F06200005063000058CC0000506300009C63000018CC00009C630000FE63000028CC0000FE630000" & _
		"2464000040CC0000406400008E64000098CB00008E640000DE640000B0CB0000DE640000DD650000C4CB0000DD650000E5650000D8CB0000E565000001660000E8CB0000106600007C66000078C7000080660000AB660000ACC80000C066000081670000" & _
		"F8CB000090670000C46700000CCC0000D0670000596800000CCC000060680000036900000CCC00001069000047690000ACC8000070690000126A000064CC0000126A0000C36B00007CCC0000C36B0000F86B000090CC0000006C0000426C0000E0C70000" & _
		"506C00009C6C00005CC80000A06C0000A96C000064CD0000A96C0000C76C00006CCD0000C76C0000D76D000080CD0000D76D0000EF6D000094CD0000EF6D0000FC6E0000A4CD0000006F0000176F0000ACC80000206F0000D86F000064C80000E06F0000" & _
		"087000005CC80000087000004470000020CD0000447000003771000034CD0000377100004E7100004CCD00005071000060710000D8CC00006071000087710000E0CC000087710000A0710000F4CC0000A0710000B773000004CD0000D073000089740000" & _
		"64C80000907400004575000064C80000507500008E7500005CC8000090750000C7750000A0CC0000C775000027760000B4CC0000277600003B760000C8CC00004076000077760000D8CC000077760000B076000020CE0000B0760000C376000034CE0000" & _
		"D0760000F576000090CA0000007700009477000068C70000A0770000DF770000B4CD0000DF77000002780000C8CD00000278000016780000DCCD0000167800004D780000ECCD00004D78000060780000DCCD000060780000BC7800005CC80000D0780000" & _
		"3B7A000000CE0000407A00000B7B000088C90000107B0000D17C0000ECC90000F07C0000C97D000048CE0000D07D0000277E000084C70000277E0000607E00003CCF0000607E0000A57E000050CF0000A57E0000C67E000064CF0000D07E0000007F0000" & _
		"5CCE0000007F0000167F000068CE0000167F0000647F00007CCE0000647F0000707F000090CE0000707F0000887F0000A0CE0000907F0000F7810000F8CF000000820000AC820000B0CE0000AC8200002B830000C4CE00002B83000040830000D8CE0000" & _
		"4083000073830000ACCF00007383000097830000C0CF000097830000AD830000D4CF0000AD8300002F840000E4CF00002F84000069840000D4CF0000708400001F85000074CF00001F8500009E85000088CF00009E850000B48500009CCF0000C0850000" & _
		"0F860000E8CE00000F86000049860000F4CE000049860000A486000008CF0000A4860000BC8600001CCF0000BC860000D58600002CCF0000E0860000BA87000094C80000C087000041880000CCC7000050880000CF880000CCC70000D08800008B890000" & _
		"18D000008B890000B08C00002CD00000B08C0000E38C000044D00000F08C0000078E00005CD00000108E00007B8E000068D000007B8E0000079000007CD00000079000001E90000090D00000209000003D900000ACC8000040900000A090000064CD0000" & _
		"B0900000CE900000A0D00000E09000002E910000A8D0000030910000649100005CC800006491000037920000B8D00000389200004C920000ACC800004C920000E9920000B0D00000EC9200005C930000C0D000005C930000D0930000CCD00000D0930000" & _
		"20940000ACC800002094000036950000D8D0000038950000BB9500001CD10000BC950000E496000070D10000E49600002197000068C7000024970000D3970000A0D10000D4970000F7970000ACC800001C98000037980000ACC800003898000071980000" & _
		"ACC8000074980000A8980000ACC80000A8980000BD980000ACC80000C0980000E8980000ACC80000E8980000FD980000ACC800000099000060990000CCC700006099000090990000ACC8000090990000A4990000ACC80000A4990000DE990000ACC80000" & _
		"E09900006B9A00005CC800006C9A0000049B0000ACD10000049B0000289B00005CC80000289B0000519B00005CC80000689B0000B39C0000D4D10000B49C0000F09C000078C70000F09C00002C9D000078C70000309D0000C59F0000E4D1000070A00000" & _
		"72A00000F8D1000090A0000096A0000000D2000096A00000ADA0000014D10000ADA00000C6A0000014D10000C6A00000DAA0000014D10000DAA0000010A1000098D1000010A1000028A10000CCD100000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010018000000180000800000000000000000000000000000010002000000" & _
		"30000080000000000000000000000000000001000904000048000000601001007D010000000000000000000000000000000000003C3F786D6C2076657273696F6E3D27312E302720656E636F64696E673D275554462D3827207374616E64616C6F6E653D" & _
		"27796573273F3E0D0A3C617373656D626C7920786D6C6E733D2775726E3A736368656D61732D6D6963726F736F66742D636F6D3A61736D2E763127206D616E696665737456657273696F6E3D27312E30273E0D0A20203C7472757374496E666F20786D6C" & _
		"6E733D2275726E3A736368656D61732D6D6963726F736F66742D636F6D3A61736D2E7633223E0D0A202020203C73656375726974793E0D0A2020202020203C72657175657374656450726976696C656765733E0D0A20202020202020203C726571756573" & _
		"746564457865637574696F6E4C6576656C206C6576656C3D276173496E766F6B6572272075694163636573733D2766616C736527202F3E0D0A2020202020203C2F72657175657374656450726976696C656765733E0D0A202020203C2F73656375726974" & _
		"793E0D0A20203C2F7472757374496E666F3E0D0A3C2F617373656D626C793E0D0A000000000000000000000000000000000000000000000000000000000000000000000000B000001400000060A268A270A278A280A290A200C0000020000000E0A1E8A1" & _
		"68A280A288A210A328A330A338A340A348A3000000F000008400000000A008A010A018A020A028A030A038A040A048A050A058A060A068A070A078A080A088A090A0A0A0A8A0B0A0B8A0C0A0C8A0D0A0D8A0F8A008A118A128A138A148A158A168A178A1" & _
		"88A198A1A8A1B8A1C8A1D8A1E8A1F8A108A218A228A238A248A258A268A278A288A298A2A8A2B8A2C8A2D8A2E8A2F8A208A30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & _
		"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")
EndFunc

#EndRegion Embedded DLL
;--------------------------------------------------------------------------------------------------------------------------------------
