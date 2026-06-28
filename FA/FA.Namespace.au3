#include-once
#include "..\CDP.au3"

#Region --- FA Namespace Tree ---

Global $FA 											        = _AutoItObject_Create()

Global $FA_User                                             = _AutoItObject_Create()
Global $FA_User_Search                                      = _AutoItObject_Create()
Global $FA_User_Login                                       = _AutoItObject_Create()
Global $FA_User_Logout                                      = _AutoItObject_Create()

#EndRegion

#Region --- FA Includes ---

#include "FA.User.au3"
#include "FA.User.Login.au3"
#include "FA.User.Logout.au3"
#include "FA.User.Search.au3"

#EndRegion

#Region --- UI Namespace Tree Assembly ---

_AutoItObject_AddProperty($FA, 								"User",             $ELSCOPE_PUBLIC,    $FA_User)
_AutoItObject_AddProperty($FA_User, 				        "Search", 			$ELSCOPE_PUBLIC,    $FA_User_Search)
_AutoItObject_AddProperty($FA_User, 				        "Login", 			$ELSCOPE_PUBLIC,    $FA_User_Login)
_AutoItObject_AddProperty($FA_User, 				        "Logout", 			$ELSCOPE_PUBLIC,    $FA_User_Logout)

#EndRegion


#Region --- miscellaneous functions ---

#EndRegion
