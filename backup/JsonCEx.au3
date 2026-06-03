#include-once
#include <AutoItObject.au3>
#include <Array.au3>
#include "JsonC.au3" ; your existing low-level UDF

#region --- Object ---

Func JsonC_Object()
    Local $o = _AutoItObject_Create()
    _AutoItObject_AddProperty($o, "handle",  $ELSCOPE_PUBLIC, _JsonC_ObjectNewObject())

    _AutoItObject_AddMethod($o, "add", "JsonC_Object_add")
    _AutoItObject_AddMethod($o, "get", "JsonC_Object_get")
    _AutoItObject_AddMethod($o, "toString", "JsonC_Object_toString")
    _AutoItObject_AddMethod($o, "type", "JsonC_Object_Type")
    _AutoItObject_AddMethod($o, "value", "JsonC_Object_Value")
    _AutoItObject_AddDestructor($o, "JsonC_Object_destroy")

    Return $o
EndFunc

Func JsonC_Object_add($this, $key, $value = Null)
    Local $jObj = JsonC_ToObject($value)
    _JsonC_ObjectObjectAdd($this.handle, $key, $jObj)

    if IsString($value) Then
        Local $oChild = _AutoItObject_Create()
        _AutoItObject_AddProperty($oChild, "handle",  $ELSCOPE_PUBLIC, _JsonC_ObjectObjectGet($this.handle, $key))
        _AutoItObject_AddMethod($oChild, "type", "JsonC_Object_Type")
        _AutoItObject_AddMethod($oChild, "value", "JsonC_Object_Value")
        _AutoItObject_AddProperty($this, $key,  $ELSCOPE_PUBLIC, $oChild)
    Else
        _AutoItObject_AddProperty($this, $key,  $ELSCOPE_PUBLIC, $value)
    EndIf

    Return $this
EndFunc



Func JsonC_Object_get($this, $key)
    Local $h = _JsonC_ObjectObjectGet($this.handle, $key)
    Return JsonC_FromHandle($h)
EndFunc

Func JsonC_Object_toString($this)
    Return _JsonC_ObjectToJsonString($this.handle)
EndFunc

Func JsonC_Object_Type($this)
    Return _JsonC_TypeToName(_JsonC_ObjectGetType($this.handle))
EndFunc

Func JsonC_Object_Value($this)
    Return _JsonC_ObjectGetValue($this.handle)
EndFunc

Func JsonC_Object_destroy($this)
    ;json_object_put($this.handle)
EndFunc

#endregion


#region --- Array ---

Func JsonC_Array()
    Local $oObj = _AutoItObject_Create()
    _AutoItObject_AddProperty($oObj, "handle",  $ELSCOPE_PUBLIC, _JsonC_ObjectNewArray())

    _AutoItObject_AddProperty($oObj, "first")
    _AutoItObject_AddProperty($oObj, "last")
    _AutoItObject_AddProperty($oObj, "size")
    _AutoItObject_AddMethod($oObj, "count", "JsonC_Array_count")
    _AutoItObject_AddMethod($oObj, "add", "JsonC_Array_Add")
    _AutoItObject_AddMethod($oObj, "at", "JsonC_Array_at")
    _AutoItObject_AddMethod($oObj, "remove", "JsonC_Array_remove")
    _AutoItObject_AddMethod($oObj, "toString", "JsonC_Object_toString")

    ; Add enum
    _AutoItObject_AddEnum($oObj, "JsonC_Array_EnumNext" ,"JsonC_Array_EnumReset")

    Return $oObj
EndFunc

Func JsonC_Array_destroy($this)
    ;json_object_put($this.handle)
EndFunc

Func JsonC_Array_AddObject($obj, $nextEl = 0)
    Local $oObj = _AutoItObject_Create()
    _AutoItObject_AddProperty($oObj, "handle",  $ELSCOPE_PUBLIC, _JsonC_ObjectNewObject())
    _AutoItObject_AddProperty($oObj, "data", $ELSCOPE_PUBLIC, $obj)
    _AutoItObject_AddProperty($oObj, "next", $ELSCOPE_PUBLIC, $nextEl)
    Return $oObj
EndFunc

Func JsonC_Array_Add($self, $obj)
    Local $iSize = $self.size
    Local $oLast = $self.last
    If $iSize = 0 Then
        $self.first = JsonC_Array_AddObject($obj)
        $self.last = $self.first

        Local $jObj = JsonC_ToObject($obj)
        _JsonC_ObjectArrayAdd($self.handle, $jObj)
    Else
        $oLast.next = JsonC_Array_AddObject($obj)
        $self.last = $oLast.next

        Local $jObj = JsonC_ToObject($obj)
        _JsonC_ObjectArrayAdd($self.handle, $jObj)
    EndIf
    $self.size = $iSize + 1

    Return $self
EndFunc

Func JsonC_Array_remove($self, $index)
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

Func JsonC_Array_at($self, $index)
    Local $i = 0
    For $Element In $self
        If $i = $index Then Return $Element
        $i += 1
    next
    Return SetError(1, 0, 0)
EndFunc

Func JsonC_Array_count($self)
    Return $self.size
EndFunc

Func JsonC_Array_EnumReset(ByRef $self, ByRef $iter)
    #forceref $self
    $iterator = 0
EndFunc

Func JsonC_Array_Enumnext(ByRef $self, ByRef $iterator)
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

Func JsonC_ToObject($value)
    If IsObj($value) Then
        Return $value.handle
    EndIf

    If IsString($value) Then Return _JsonC_ObjectNewString($value)
    If IsFloat($value) Then Return _JsonC_ObjectNewDouble($value)
    If IsInt($value) Then Return _JsonC_ObjectNewInt($value)
    If IsBool($value) Then Return _JsonC_ObjectNewBoolean($value)

    Return _JsonC_ObjectNewString(String($value))
EndFunc

Func JsonC_FromHandle($h)
    ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $h = ' & $h & @CRLF & '>Error code: ' & @error & @CRLF)
    If $h = 0 Then Return Null

    Switch _JsonC_ObjectGetType($h)
        Case $JSONC_TYPE_OBJECT
            ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $o = ' & '$o' & @CRLF & '>Error code: ' & @error & @CRLF)
            Local $o = JsonC_Object()
            $o.handle = $h
            ;json_object_get($h)
            Return $o

        Case $JSONC_TYPE_ARRAY
            ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $o = ' & '$o' & @CRLF & '>Error code: ' & @error & @CRLF)
            Local $a = JsonC_Array()
            $a.handle = $h
            ;json_object_get($h)
            Return $a

        Case Else
            ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $o = ' & '$o' & @CRLF & '>Error code: ' & @error & @CRLF)
            Return _JsonC_ObjectGetValue($h)
    EndSwitch
EndFunc

#endregion
