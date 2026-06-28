#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include "CDP.au3"
#include "UI\UI.Namespace.au3"

$cdp.config.enterpriseMode = True

With test("System Test - Login")

	$html_form = $UI.Practice_Pages.Pages.Forms.HTML_Form
	$text_inputs_form = $UI.Practice_Pages.Pages.Forms.Text_Inputs
	$form_submission = $UI.Practice_Pages.Pages.Forms.Form_Submission
	$user = testdata("User", "User 1")

	With teststep("Login to Practice Pages")
		With $html_form
			.from_Windows(testlog())
			.submit($user.Item("Username"), $user.Item("Password"), testlog())
		EndWith
	EndWith

	With teststep("Verify the login was successful")
		.expect($html_form.get_username(testlog())).toHaveText($user.Item("Username"))
		.expect($html_form.get_password(testlog())).toHaveText($user.Item("Password"))
	EndWith
EndWith

With test("System Test - username Search")

	With teststep("Navigate to Text Inputs")
		With $text_inputs_form
			.from_Practice_Pages(testlog())
		EndWith
	EndWith

	With teststep("Search for username")
		With $text_inputs_form
			.submit($user.Item("Username"), testlog())
		EndWith
	EndWith

	With teststep("Verify the search was successful")
		.expect($form_submission.get_search(testlog())).toHaveText($user.Item("Username"))
	EndWith

EndWith

$qaChrome.close()
