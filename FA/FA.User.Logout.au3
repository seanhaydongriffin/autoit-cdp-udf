#include-once
#include "FA.Namespace.au3"
#include "..\UI\UI.Namespace.au3"


#Region --- page objects ---
#EndRegion

#Region --- page methods ---

_AutoItObject_AddMethod($FA_User_Logout,    "from_Practice_Pages",   "FA_User_Logout_from_Practice_Pages")

Func FA_User_Logout_from_Practice_Pages($oSelf)
	$qaChrome.close()
EndFunc

#EndRegion
