#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include "CDP.au3"
#include "FA\FA.Namespace.au3"

$cdp.config.enterpriseMode = True

With test("Acceptance Test - Login")

	$user = testdata("User", "User 1")

	With teststep("The user can login")
		$FA.User.Login.from_Windows($user, testlog())
		.expect($UI.Practice_Pages.Pages.Forms.HTML_Form.get_username(testlog())).toHaveText($user.Item("Username"))
		.expect($UI.Practice_Pages.Pages.Forms.HTML_Form.get_password(testlog())).toHaveText($user.Item("Password"))
	EndWith

	$FA.User.Logout.from_Practice_Pages(testlog())

EndWith

With test("Acceptance Test - User Search")

	$user = testdata("User", "User 1")

	With teststep("The user can be searched")
		$FA.User.Search.from_Windows($user, testlog())
		.expect($UI.Practice_Pages.Pages.Forms.Form_Submission.get_search(testlog())).toHaveText($user.Item("Username"))
	EndWith

	$FA.User.Logout.from_Practice_Pages(testlog())

EndWith
