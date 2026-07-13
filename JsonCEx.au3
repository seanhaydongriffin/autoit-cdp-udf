#include-once
#include "AutoItObject.au3"
#include "JsonC.au3"

#region --- Object ---

Func _JsonC_Object($vJson = "")
    Local $o

    if IsString($vJson) Then
        if $vJson = "" Then
			$o = _AutoItObject_Create()
            _AutoItObject_AddProperty($o, "handle",  $ELSCOPE_PUBLIC, _JsonC_ObjectNewObject())
        Else
			Local $h = _JsonC_TokenerParse($vJson)
			If _JsonC_ObjectGetType($h) = $JSONC_TYPE_ARRAY Then Return _JsonC_Array($h)
			$o = _AutoItObject_Create()
            _AutoItObject_AddProperty($o, "handle",  $ELSCOPE_PUBLIC, $h)
        EndIf
	ElseIf _JsonC_ObjectGetType($vJson) = $JSONC_TYPE_ARRAY Then
		Return _JsonC_Array($vJson)
    ElseIf _JsonC_ObjectGetType($vJson) > 0 Then
		$o = _AutoItObject_Create()
        _AutoItObject_AddProperty($o, "handle",  $ELSCOPE_PUBLIC, $vJson)
    EndIf

    _AutoItObject_AddMethod($o, "add", "_JsonC_Object_Add")
    ;_AutoItObject_AddMethod($o, "addJObject", "_JsonC_Object_AddJObject")
    _AutoItObject_AddMethod($o, "get", "_JsonC_Object_Get")
    _AutoItObject_AddMethod($o, "toString", "_JsonC_Object_ToString")
    _AutoItObject_AddMethod($o, "type", "_JsonC_Object_Type")
    _AutoItObject_AddMethod($o, "value", "_JsonC_Object_Value")
    _AutoItObject_AddDestructor($o, "_JsonC_Object_Destroy")

    Return $o
EndFunc

Func _JsonC_Object_Add($this, $key, $value = Null)
    Local $jObj = __JsonC_ToObject($value)
    _JsonC_ObjectObjectAdd($this.handle, $key, $jObj)

    if IsObj($value) Then
        _AutoItObject_AddProperty($this, $key,  $ELSCOPE_PUBLIC, $value)
    ElseIf _JsonC_ObjectGetType($value) > 0 Then
        Local $oChild = _AutoItObject_Create()
        _AutoItObject_AddProperty($oChild, "handle",  $ELSCOPE_PUBLIC, $value)
        _AutoItObject_AddMethod($oChild, "type", "_JsonC_Object_Type")
        _AutoItObject_AddMethod($oChild, "object", "_JsonC_Object_Object")
        _AutoItObject_AddMethod($oChild, "toString", "_JsonC_Object_ToString")
        _AutoItObject_AddMethod($oChild, "get", "_JsonC_Object_Get")
        _AutoItObject_AddProperty($this, $key,  $ELSCOPE_PUBLIC, $oChild)
    Else
        Local $oChild = _AutoItObject_Create()
        _AutoItObject_AddProperty($oChild, "handle",  $ELSCOPE_PUBLIC, _JsonC_ObjectObjectGet($this.handle, $key))
        _AutoItObject_AddMethod($oChild, "type", "_JsonC_Object_Type")
        _AutoItObject_AddMethod($oChild, "value", "_JsonC_Object_Value")
        _AutoItObject_AddProperty($this, $key,  $ELSCOPE_PUBLIC, $oChild)
    EndIf

    Return $this
EndFunc

#cs
Func _JsonC_Object_AddJObject($this, $key, $jObj)
    _JsonC_ObjectObjectAdd($this.handle, $key, $jObj)

    Local $oChild = _AutoItObject_Create()
    _AutoItObject_AddProperty($oChild, "handle",  $ELSCOPE_PUBLIC, $jObj)
    _AutoItObject_AddMethod($oChild, "object", "_JsonC_Object_Object")
    _AutoItObject_AddMethod($oChild, "toString", "_JsonC_Object_ToString")
    _AutoItObject_AddProperty($this, $key,  $ELSCOPE_PUBLIC, $oChild)

    Return $this
EndFunc
#ce

Func _JsonC_Object_Get($this, $sName)
    $obj = _JsonC_ObjectObjectGet($this.handle, $sName)
   	If @error Then Return SetError(1, @error, Null)
    if _JsonC_ObjectGetType($obj) = $JSONC_TYPE_ARRAY Then return _JsonC_Array($obj)
    return _JsonC_Object($obj)
EndFunc

Func _JsonC_Object_ToString($this)
    ;if $this = Null Then ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $this = ' & '$this' & @CRLF & '>Error code: ' & @error & @CRLF)
    Return _JsonC_ObjectToJsonString($this.handle)
EndFunc

Func _JsonC_Object_Type($this)
    Return _JsonC_TypeToName(_JsonC_ObjectGetType($this.handle))
EndFunc

Func _JsonC_Object_Object($this)
    Return $this.handle
EndFunc

Func _JsonC_Object_Value($this)
    Return _JsonC_ObjectGetValue($this.handle)
EndFunc

Func _JsonC_Object_Destroy($this)
EndFunc

#endregion


#region --- Array ---

Func _JsonC_Array($vJson = "")
    Local $oObj = _AutoItObject_Create()

    if IsString($vJson) Then
        if $vJson = "" Then
            _AutoItObject_AddProperty($oObj, "handle",  $ELSCOPE_PUBLIC, _JsonC_ObjectNewArray())
        EndIf
    ElseIf _JsonC_ObjectGetType($vJson) > 0 Then
        _AutoItObject_AddProperty($oObj, "handle",  $ELSCOPE_PUBLIC, $vJson)
    EndIf

    _AutoItObject_AddProperty($oObj, "first")
    _AutoItObject_AddProperty($oObj, "last")
    _AutoItObject_AddProperty($oObj, "size")
    _AutoItObject_AddMethod($oObj, "count", "_JsonC_Array_Count")
    _AutoItObject_AddMethod($oObj, "add", "_JsonC_Array_Add")
    _AutoItObject_AddMethod($oObj, "at", "_JsonC_Array_At")
    _AutoItObject_AddMethod($oObj, "remove", "_JsonC_Array_Remove")
    _AutoItObject_AddMethod($oObj, "toString", "_JsonC_Object_ToString")

    ; Add enum
    _AutoItObject_AddEnum($oObj, "__JsonC_Array_EnumNext" ,"__JsonC_Array_EnumReset")

    Return $oObj
EndFunc

Func _JsonC_Array_Destroy($this)
EndFunc

Func __JsonC_Array_AddObject($obj, $nextEl = 0)
    Local $oObj = _AutoItObject_Create()
    _AutoItObject_AddProperty($oObj, "handle",  $ELSCOPE_PUBLIC, _JsonC_ObjectNewObject())
    _AutoItObject_AddProperty($oObj, "data", $ELSCOPE_PUBLIC, $obj)
    _AutoItObject_AddProperty($oObj, "next", $ELSCOPE_PUBLIC, $nextEl)
    Return $oObj
EndFunc

Func _JsonC_Array_Add($self, $obj)
    Local $iSize = $self.size
    Local $oLast = $self.last
    If $iSize = 0 Then
        $self.first = __JsonC_Array_AddObject($obj)
        $self.last = $self.first

        Local $jObj = __JsonC_ToObject($obj)
        _JsonC_ObjectArrayAdd($self.handle, $jObj)
    Else
        $oLast.next = __JsonC_Array_AddObject($obj)
        $self.last = $oLast.next

        Local $jObj = __JsonC_ToObject($obj)
        _JsonC_ObjectArrayAdd($self.handle, $jObj)
    EndIf
    $self.size = $iSize + 1

    Return $self
EndFunc

Func _JsonC_Array_Remove($self, $index)
    If $self.size = 0 Then Return SetError(1, 0, 0)
    Local $current = $self.first
    Local $previous = 0
    Local $i = 0
    Do
        If $i = $index Then
            If $self.size = 1 Then
                ; very last element
                $self.first = 0
                $self.last = 0
            ElseIf $i = 0 Then
                ; first element
                $self.first = $current.next
            Else
                If $i = $self.size - 1 Then $self.last = $previous ; last element
                $previous.next = $current.next
            EndIf
            $self.size = $self.size - 1
            Return
        EndIf
        $i += 1
        $previous = $current
        $current = $current.next
    Until $current = 0
    Return SetError(2, 0, 0)
EndFunc

Func _JsonC_Array_At($self, $index)
	$obj = _JsonC_ObjectArrayGetIndex($self.handle, $index)
    if _JsonC_ObjectGetType($obj) = $JSONC_TYPE_ARRAY Then return _JsonC_Array($obj)
    return _JsonC_Object($obj)
EndFunc

Func _JsonC_Array_Count($self)
    if _JsonC_ObjectGetType($self.handle) = $JSONC_TYPE_ARRAY Then Return _JsonC_ObjectArrayLength($self.handle)
    Return $self.size
EndFunc

Func __JsonC_Array_EnumReset(ByRef $self, ByRef $iter)
    #forceref $self
    $iterator = 0
EndFunc

Func __JsonC_Array_EnumNext(ByRef $self, ByRef $iterator)
    If $self.size = 0 Then Return SetError(1, 0, 0)
    If Not IsObj($iterator) Then
        $iterator = $self.first
        Return $iterator.data
    EndIf
    If Not IsObj($iterator.next) Then Return SetError(1, 0, 0)
    $iterator = $iterator.next
    Return $iterator.data
EndFunc    ;==>_LinkedList_Enumnext


#endregion

#region --- Miscellaneous ---

Func __JsonC_ToObject($value)
    If IsObj($value) Then
        Return $value.handle
    EndIf

    If IsString($value) Then Return _JsonC_ObjectNewString($value)
    If IsFloat($value) Then Return _JsonC_ObjectNewDouble($value)
    If IsInt($value) Then Return _JsonC_ObjectNewInt($value)
    If IsBool($value) Then Return _JsonC_ObjectNewBoolean($value)

    Return _JsonC_ObjectNewString(String($value))
EndFunc

#endregion
