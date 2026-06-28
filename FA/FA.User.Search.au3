#include-once
#include "FA.Namespace.au3"
#include "..\UI\UI.Namespace.au3"


#Region --- page objects ---
#EndRegion

#Region --- page methods ---

_AutoItObject_AddMethod($FA_User_Search,    "from_Windows",             "FA_User_Search_from_Windows")
_AutoItObject_AddMethod($FA_User_Search,    "from_Practice_Pages",      "FA_User_Search_from_Practice_Pages")

Func FA_User_Search_from_Windows($oSelf, $user)

    $FA.User.Login.from_Windows($user, testlog())
    $FA.User.Search.from_Practice_Pages($user, testlog())

EndFunc

Func FA_User_Search_from_Practice_Pages($oSelf, $user)

    With $UI.Practice_Pages.Pages.Forms.Text_Inputs
        .from_Practice_Pages(testlog())
        .submit($user.Item("Username"), testlog())
    EndWith

EndFunc

#EndRegion
