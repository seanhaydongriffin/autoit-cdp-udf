#include-once
#include "UI.Namespace.au3"

#Region --- page objects ---
#EndRegion

#Region --- page methods ---

_AutoItObject_AddMethod($UI_Practice_Pages_Pages_Forms_HTML_Form, "from_Windows",   "UI_Practice_Pages_Pages_Forms_HTML_Form_from_Windows")
_AutoItObject_AddMethod($UI_Practice_Pages_Pages_Forms_HTML_Form, "submit",         "UI_Practice_Pages_Pages_Forms_HTML_Form_submit")
_AutoItObject_AddMethod($UI_Practice_Pages_Pages_Forms_HTML_Form, "get_username",   "UI_Practice_Pages_Pages_Forms_HTML_Form_get_username")
_AutoItObject_AddMethod($UI_Practice_Pages_Pages_Forms_HTML_Form, "get_password",   "UI_Practice_Pages_Pages_Forms_HTML_Form_get_password")

Func UI_Practice_Pages_Pages_Forms_HTML_Form_from_Windows($oSelf)
	$qaChrome = $browser.launch($CDPBROWSER_CHROME, _JsonC_Object().add("port", 9102).add("profile", @ScriptDir & "\chrometestingprofile").add("clearCookies", True))
	$qaPage1 = $qaChrome.newPage()
	$qaPage1.goto(testdata("Environment", "URL") & "pages/forms/html-form/")
EndFunc

Func UI_Practice_Pages_Pages_Forms_HTML_Form_submit($oSelf, $Username, $Password)
    $qaPage1.locator("//input[@name='username']").sendKeys($Username)
    $qaPage1.locator("//input[@name='password']").sendKeys($Password)
    $qaPage1.locator("//input[@type='submit' and @name='submitbutton']").click(True)
EndFunc

Func UI_Practice_Pages_Pages_Forms_HTML_Form_get_username($oSelf)
    Return $qaPage1.locator("//li[@id='_valueusername']")
EndFunc

Func UI_Practice_Pages_Pages_Forms_HTML_Form_get_password($oSelf)
    Return $qaPage1.locator("//li[@id='_valuepassword']")
EndFunc

#EndRegion
