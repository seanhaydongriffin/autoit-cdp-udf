#include-once
#include "UI.Namespace.au3"

#Region --- page objects ---
#EndRegion

#Region --- page methods ---

_AutoItObject_AddMethod($UI_Practice_Pages_Pages_Forms_Text_Inputs, "from_Practice_Pages",  "UI_Practice_Pages_Pages_Forms_Text_Inputs_from_Practice_Pages")
_AutoItObject_AddMethod($UI_Practice_Pages_Pages_Forms_Text_Inputs, "submit",               "UI_Practice_Pages_Pages_Forms_Text_Inputs_submit")

Func UI_Practice_Pages_Pages_Forms_Text_Inputs_from_Practice_Pages($oSelf)
	$qaPage1.goto(testdata("Environment", "URL") & "pages/forms/text-inputs/")
EndFunc

Func UI_Practice_Pages_Pages_Forms_Text_Inputs_submit($oSelf, $Search)
    $qaPage1.locator("//input[@id='search-input']").sendKeys($Search)
    $qaPage1.locator("//input[@type='submit' and @name='submitbutton']").click(True)
EndFunc

#EndRegion
