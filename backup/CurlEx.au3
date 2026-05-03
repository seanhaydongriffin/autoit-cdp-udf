#AutoIt3Wrapper_UseX64=y
#include-once

#include "Curl.au3"

Global $CookieFile = "cookie.txt"


Func Curl_Setopt_Websocket($Handle)
	Return DllCall($g_hlibcurl, (@AutoItX64 ? "int" : "int:cdecl"), "curl_easy_setopt", "ptr", $Handle, "int", $CURLOPT_CONNECT_ONLY, "long", 2)[0]
EndFunc



Func Curl_Ws_Send($Handle, $Data)
    $Data = Binary($Data)
    Local $DataLen = BinaryLen($Data)

    Local $tBuffer = DllStructCreate("byte[" & $DataLen & "]")
    DllStructSetData($tBuffer, 1, $Data)

    Local $sent = 0

    Local $Ret = DllCall($g_hlibcurl, (@AutoItX64 ? "int" : "int:cdecl"), "curl_ws_send", _
        "ptr",       $Handle, _
        "ptr",       DllStructGetPtr($tBuffer), _
        "uint_ptr",  $DataLen, _
        "uint_ptr*", $sent, _
        "int64",     0, _
        "uint",      1)

    If @error Then
        ConsoleWrite("WS SEND: DllCall error = " & @error & @CRLF)
		$tBuffer = 0
        Return SetError(1, @error, 0)
    EndIf

    Local $rc      = $Ret[0]
    Local $SentLen = $Ret[4]

	$tBuffer = 0
    Return SetExtended($SentLen, $rc)
EndFunc



Func Curl_Ws_Recv($Handle, $iMax = 4096)
    Local $tBuffer = DllStructCreate("byte[" & $iMax & "]")
    Local $nread   = 0
    Local $pMeta   = 0

    Local $Ret = DllCall($g_hlibcurl, (@AutoItX64 ? "int" : "int:cdecl"), "curl_ws_recv", _
        "ptr",       $Handle, _
        "struct*",   $tBuffer, _
        "uint_ptr",  $iMax, _
        "uint_ptr*", $nread, _
        "ptr*",      $pMeta)

    If @error Then Return SetError(1, @error, "")

    Local $rc = $Ret[0]
    Local $ReadBytes = $Ret[4]

    If $rc <> 0 Or $ReadBytes = 0 Then Return SetExtended($rc, "")

    Local $bin = DllStructGetData($tBuffer, 1)
    $bin = BinaryMid($bin, 1, $ReadBytes)

	$tBuffer = 0
    Return SetExtended($rc, BinaryToString($bin))
EndFunc



#cs
Func Curl_Ws_Recv($Handle, $iMax = 4096)
    Local $tBuffer = DllStructCreate("byte[" & $iMax & "]")
    Local $nread   = 0
    Local $meta    = 0

    Local $Ret = DllCall($g_hlibcurl, (@AutoItX64 ? "int" : "int:cdecl"), "curl_ws_recv", _
        "ptr",       $Handle, _
        "ptr",       DllStructGetPtr($tBuffer), _
        "uint_ptr",  $iMax, _
        "uint_ptr*", $nread, _
        "int*",      $meta)

    If @error Then
        ConsoleWrite("WS RECV: DllCall error = " & @error & @CRLF)
		$tBuffer = 0
        Return SetError(1, @error, "")
    EndIf

    Local $rc        = $Ret[0]
    Local $ReadBytes = $Ret[4]
    Local $MetaFlag  = $Ret[5]

    ; CURLE_AGAIN (81) = no data yet, not fatal
    If $rc = 81 Then
        ; Just no data – nothing to process this tick
		$tBuffer = 0
        Return SetExtended($rc, "")
    EndIf

    ; Any other non‑zero rc – log it and stop using this handle
    If $rc <> 0 Then
        ConsoleWrite("WS RECV: rc=" & $rc & " nread=" & $ReadBytes & " meta=" & $MetaFlag & @CRLF)
		$tBuffer = 0
        Return SetExtended($rc, "")
    EndIf

    If $ReadBytes = 0 Then
		$tBuffer = 0
		Return SetExtended($rc, "")
	EndIf

    Local $bin = DllStructGetData($tBuffer, 1)
    $bin = BinaryMid($bin, 1, $ReadBytes)

	$tBuffer = 0
    Return SetExtended($rc, BinaryToString($bin))
EndFunc
#ce









Func Curl_Get($url, $Slist, $username = "", $password = "")
	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return
	;$iBufferSize = 32 ;128

	Local $Html = $Curl ; any number as identify
	Local $Header = $Curl + 1 ; any number as identify

	Curl_Easy_Setopt($Curl, $CURLOPT_URL, $url)
	;Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)
	;Curl_Easy_Setopt($Curl, $CURLOPT_PROXY, "localhost:8888")

	;Curl_Easy_Setopt ( $Curl, $CURLOPT_ACCEPT_ENCODING, '' ) ; Possible values : '', 'identity', 'deflate' or 'gzip'
	Curl_Easy_Setopt ( $Curl, $CURLOPT_ACCEPT_ENCODING, 'gzip, deflate, br, zstd' ) ; Possible values : '', 'identity', 'deflate' or 'gzip'
	;Curl_Easy_Setopt ( $Curl, $CURLOPT_BUFFERSIZE, $iBufferSize )

	Curl_Easy_Setopt($Curl, $CURLOPT_USERNAME, $username)
	Curl_Easy_Setopt($Curl, $CURLOPT_PASSWORD, $password)

	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Html)
	Curl_Easy_Setopt($Curl, $CURLOPT_COOKIEJAR, $CookieFile)
	Curl_Easy_Setopt($Curl, $CURLOPT_COOKIEFILE, $CookieFile)
	Curl_Easy_Setopt($Curl, $CURLOPT_HEADERFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_HEADERDATA, $Header)
	Curl_Easy_Setopt($Curl, $CURLOPT_HTTPHEADER, $Slist)
	Curl_Easy_Setopt($Curl, $CURLOPT_TIMEOUT, 30)

	;peer verification
	curl_easy_setopt($Curl, $CURLOPT_CAINFO, @ScriptDir & '\curl-ca-bundle.crt') ;
 	Curl_Easy_Setopt($Curl, $CURLOPT_SSL_VERIFYPEER, 0)

	Local $Code = Curl_Easy_Perform($Curl)
	;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $Code = ' & $Code & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
	Local $response = ""

	If $Code = $CURLE_OK Then
		;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $CURLE_OK = ' & $CURLE_OK & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
		;ConsoleWrite($CookieFile & @CRLF & FileRead(@ScriptDir & "\" & $CookieFile) & @CRLF)
		;ConsoleWrite("Content Type: " & Curl_Easy_GetInfo($Curl, $CURLINFO_CONTENT_TYPE) & @LF)
		;ConsoleWrite("Download Size: " & Curl_Easy_GetInfo($Curl, $CURLINFO_SIZE_DOWNLOAD) & @LF)
		;ConsoleWrite('Header: ' & @CRLF & BinaryToString(Curl_Data_Get($Header)) & @LF)
 		$response = BinaryToString(Curl_Data_Get($Html))
		;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $response = ' & $response & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
	Else
		ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
	EndIf

	Curl_Easy_Cleanup($Curl)
	Curl_Data_Cleanup($Header)
	Curl_Data_Cleanup($Html)

	return $response
EndFunc

Func Curl_Post($url, $Slist, $Post, $username = "", $password = "")
	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	Local $Html = $Curl ; any number as identify
	Local $Header = $Curl + 1 ; any number as identify

	Curl_Easy_Setopt($Curl, $CURLOPT_USERNAME, $username)
	Curl_Easy_Setopt($Curl, $CURLOPT_PASSWORD, $password)

	Curl_Easy_Setopt($Curl, $CURLOPT_URL, $url)
	Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)
	;Curl_Easy_Setopt($Curl, $CURLOPT_PROXY, "127.0.0.1:8888")
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Html)
	Curl_Easy_Setopt($Curl, $CURLOPT_COOKIEJAR, $CookieFile)
	Curl_Easy_Setopt($Curl, $CURLOPT_COOKIEFILE, $CookieFile)
	Curl_Easy_Setopt($Curl, $CURLOPT_HEADERFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_HEADERDATA, $Header)
	Curl_Easy_Setopt($Curl, $CURLOPT_HTTPHEADER, $Slist)
	Curl_Easy_Setopt($Curl, $CURLOPT_TIMEOUT, 30)
	Curl_Easy_Setopt($Curl, $CURLOPT_POST, 1)
	if StringLen($Post) > 0 Then Curl_Easy_Setopt($Curl, $CURLOPT_COPYPOSTFIELDS, $Post)

	;peer verification
	curl_easy_setopt($Curl, $CURLOPT_CAINFO, @ScriptDir & '\curl-ca-bundle.crt') ;
 	Curl_Easy_Setopt($Curl, $CURLOPT_SSL_VERIFYPEER, 0)

	Local $Code = Curl_Easy_Perform($Curl)
	;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $Code = ' & $Code & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
	Local $response = ""

	If $Code = $CURLE_OK Then
		;ConsoleWrite($CookieFile & @CRLF & FileRead(@ScriptDir & "\" & $CookieFile) & @CRLF)
		;ConsoleWrite("Content Type: " & Curl_Easy_GetInfo($Curl, $CURLINFO_CONTENT_TYPE) & @LF)
		;ConsoleWrite("Download Size: " & Curl_Easy_GetInfo($Curl, $CURLINFO_SIZE_DOWNLOAD) & @LF)
		;ConsoleWrite('Header: ' & @CRLF & BinaryToString(Curl_Data_Get($Header)) & @LF)
 		$response = BinaryToString(Curl_Data_Get($Html))
		;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $response = ' & $response & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
	Else
		ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
	EndIf

	Curl_Easy_Cleanup($Curl)
	Curl_Data_Cleanup($Header)
	Curl_Data_Cleanup($Html)

	return $response
EndFunc


Func Curl_UploadFile($url, $Slist, $filepath, $username = "", $password = "")
    Local $Curl = Curl_Easy_Init()
    If Not $Curl Then Return

	Local $HttpPost = 0
    Local $LastItem = 0

    ; Add the file field (this is the important part)
    Curl_FormAdd($HttpPost, $LastItem, _
        $CURLFORM_COPYNAME, "file", _
        $CURLFORM_FILE, $filepath, _
        $CURLFORM_END)

    Local $Html = $Curl
    Local $Header = $Curl + 1

    Curl_Easy_Setopt($Curl, $CURLOPT_USERNAME, $username)
    Curl_Easy_Setopt($Curl, $CURLOPT_PASSWORD, $password)

    Curl_Easy_Setopt($Curl, $CURLOPT_URL, $url)
    Curl_Easy_Setopt($Curl, $CURLOPT_HTTPHEADER, $Slist)
    Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
    Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Html)

	Curl_Easy_Setopt($Curl, $CURLOPT_FOLLOWLOCATION, 1)
	;Curl_Easy_Setopt($Curl, $CURLOPT_PROXY, "127.0.0.1:8888")
    Curl_Easy_Setopt($Curl, $CURLOPT_HEADERFUNCTION, Curl_DataWriteCallback())
    Curl_Easy_Setopt($Curl, $CURLOPT_HEADERDATA, $Header)
    Curl_Easy_Setopt($Curl, $CURLOPT_TIMEOUT, 30)

	Curl_Easy_Setopt($Curl, $CURLOPT_HTTPPOST, $HttpPost)
    Curl_Easy_Setopt($Curl, $CURLOPT_SSL_VERIFYPEER, 0)

    Local $Code = Curl_Easy_Perform($Curl)
    Local $response = BinaryToString(Curl_Data_Get($Html))

    Curl_Easy_Cleanup($Curl)
    Curl_Data_Cleanup($Header)
    Curl_Data_Cleanup($Html)
	Curl_FormFree($HttpPost)

    Return $response
EndFunc

