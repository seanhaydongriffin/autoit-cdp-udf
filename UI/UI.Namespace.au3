#include-once
#include "..\CDP.au3"

Global $qaChrome = Null, $qaPage1 = Null, $qaPage2 = Null

#Region --- UI Namespace Tree ---

Global $UI 											        = _AutoItObject_Create()

Global $UI_Practice_Pages                                   = _AutoItObject_Create()
Global $UI_Practice_Pages_Pages                             = _AutoItObject_Create()
Global $UI_Practice_Pages_Pages_Forms                       = _AutoItObject_Create()
Global $UI_Practice_Pages_Pages_Forms_HTML_Form             = _AutoItObject_Create()
Global $UI_Practice_Pages_Pages_Forms_Text_Inputs           = _AutoItObject_Create()
Global $UI_Practice_Pages_Pages_Forms_Form_Submission       = _AutoItObject_Create()

#EndRegion

;#include "Toolkit.CLS.au3"

#Region --- UI Includes ---

#include "UI.Practice_Pages.au3"
#include "UI.Practice_Pages_Pages.au3"
#include "UI.Practice_Pages_Pages_Forms.au3"
#include "UI.Practice_Pages_Pages_Forms_HTML_Form.au3"
#include "UI.Practice_Pages_Pages_Forms_Text_Inputs.au3"
#include "UI.Practice_Pages_Pages_Forms_Form_Submission.au3"

#EndRegion

#Region --- UI Namespace Tree Assembly ---

_AutoItObject_AddProperty($UI, 								"Practice_Pages",   $ELSCOPE_PUBLIC,    $UI_Practice_Pages)
_AutoItObject_AddProperty($UI_Practice_Pages, 				"Pages", 			$ELSCOPE_PUBLIC,    $UI_Practice_Pages_Pages)
_AutoItObject_AddProperty($UI_Practice_Pages_Pages, 		"Forms", 			$ELSCOPE_PUBLIC,    $UI_Practice_Pages_Pages_Forms)
_AutoItObject_AddProperty($UI_Practice_Pages_Pages_Forms,   "HTML_Form", 		$ELSCOPE_PUBLIC,    $UI_Practice_Pages_Pages_Forms_HTML_Form)
_AutoItObject_AddProperty($UI_Practice_Pages_Pages_Forms,   "Text_Inputs", 		$ELSCOPE_PUBLIC,    $UI_Practice_Pages_Pages_Forms_Text_Inputs)
_AutoItObject_AddProperty($UI_Practice_Pages_Pages_Forms,   "Form_Submission",  $ELSCOPE_PUBLIC,    $UI_Practice_Pages_Pages_Forms_Form_Submission)

#EndRegion


#Region --- miscellaneous functions ---

Func UnixTime()
    Local $rslt = DllCall("msvcrt.dll", "int:cdecl", "time", "int", 0)
    If @error = 0 Then Return $rslt[0]
    Return -1
EndFunc

Func testlog($sScriptName = @ScriptName, $iLine = @ScriptLineNumber)
	Return "Script [" & $sScriptName & "] called <AutoItObject $FuncName> at line " & $iLine
EndFunc

#EndRegion
