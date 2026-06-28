#include-once
#include "FA.Namespace.au3"
#include "..\UI\UI.Namespace.au3"

#Region --- page objects ---
#EndRegion

#Region --- page methods ---

_AutoItObject_AddMethod($FA_User_Login,    "from_Windows",   "FA_User_Login_from_Windows")

Func FA_User_Login_from_Windows($oSelf, $user)

	With $UI.Practice_Pages.Pages.Forms.HTML_Form
		.from_Windows(testlog())
		.submit($user.Item("Username"), $user.Item("Password"), testlog())
	EndWith

EndFunc

#EndRegion
