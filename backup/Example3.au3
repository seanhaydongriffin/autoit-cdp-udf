#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6

#include "AutoItObject.au3"

Opt("MustDeclareVars", 1)

; Initialize AutoItObject
_AutoItObject_Startup()


Global $oLinkedList = LinkedList()
$oLinkedList.add("0x123")
For $i = 1 To 5
    $oLinkedList.add($i)
Next
$oLinkedList.add("abcd")
$oLinkedList.add(5.786)

For $vElement In $oLinkedList
    ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $vElement = ' & $vElement & @CRLF & '>Error code: ' & @error & @CRLF)
    ;$tt = $vElement
    ;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $tt = ' & $tt & @CRLF & '>Error code: ' & @error & @CRLF)
Next

;MsgBox(262144, "Count = " & $oLinkedList.count, $sOut)


$oLinkedList.remove(4) ; remove fourth element

For $vElement In $oLinkedList
ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $vElement = ' & $vElement & @CRLF & '>Error code: ' & @error & @CRLF)
    ;$sOut &= $vElement & @CRLF
Next

;MsgBox(262144, "Count = " & $oLinkedList.count, $sOut)



;**********************************************
Func __Element__($data, $nextEl = 0)
    Local $oObj = _AutoItObject_Create()
    _AutoItObject_AddProperty($oObj, "next", $ELSCOPE_PUBLIC, 0)
    _AutoItObject_AddProperty($oObj, "data", $ELSCOPE_PUBLIC, 0)
    $oObj.next = $nextEl
    $oObj.data = $data
    Return $oObj
EndFunc    ;==>__Element__

Func LinkedList()
    Local $oObj = _AutoItObject_Create()
    _AutoItObject_AddProperty($oObj, "first")
    _AutoItObject_AddProperty($oObj, "last")
    _AutoItObject_AddProperty($oObj, "size")
    _AutoItObject_AddMethod($oObj, "count", "_LinkedList_count")
    _AutoItObject_AddMethod($oObj, "add", "_LinkedList_add")
    _AutoItObject_AddMethod($oObj, "at", "_LinkedList_at")
    _AutoItObject_AddMethod($oObj, "remove", "_LinkedList_remove")

    ; Add enum
    _AutoItObject_AddEnum($oObj, "_LinkedList_EnumNext" ,"_LinkedList_EnumReset")

    Return $oObj
EndFunc    ;==>LinkedList

Func _LinkedList_remove($self, $index)
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
EndFunc    ;==>_LinkedList_remove

Func _LinkedList_add($self, $newdata)
    Local $iSize = $self.size
    Local $oLast = $self.last
    If $iSize = 0 Then
        $self.first = __Element__($newdata)
        $self.last = $self.first
    Else
        $oLast.next = __Element__($newdata)
        $self.last = $oLast.next
    EndIf
    $self.size = $iSize + 1
EndFunc    ;==>_LinkedList_add

Func _LinkedList_at($self, $index)
    Local $i = 0
    For $Element In $self
        If $i = $index Then Return $Element
        $i += 1
    next
    Return SetError(1, 0, 0)
EndFunc    ;==>_LinkedList_at

Func _LinkedList_count($self)
    Return $self.size
EndFunc    ;==>_LinkedList_count

Func _LinkedList_EnumReset(ByRef $self, ByRef $iterator)
    #forceref $self
    $iterator = 0
EndFunc    ;==>_LinkedList_EnumReset

Func _LinkedList_Enumnext(ByRef $self, ByRef $iterator)
    If $self.size = 0 Then Return SetError(1, 0, 0)
    If Not IsObj($iterator) Then
        $iterator = $self.first
        Return $iterator.data
    EndIf
    If Not IsObj($iterator.next) Then Return SetError(1, 0, 0)
    $iterator = $iterator.next
    Return $iterator.data
EndFunc    ;==>_LinkedList_Enumnext


 