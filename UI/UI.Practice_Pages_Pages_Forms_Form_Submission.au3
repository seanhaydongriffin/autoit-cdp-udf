#include-once
#include "UI.Namespace.au3"

#Region --- page objects ---
#EndRegion

#Region --- page methods ---

_AutoItObject_AddMethod($UI_Practice_Pages_Pages_Forms_Form_Submission, "get_search",   "UI_Practice_Pages_Pages_Forms_Form_Submission_get_search")

Func UI_Practice_Pages_Pages_Forms_Form_Submission_get_search($oSelf)
    Return $qaPage1.locator("//li[@id='_valuesearch']")
EndFunc

#EndRegion
