#AutoIt3Wrapper_UseX64=y
#include-once

#include "Curl.au3"

Global $CookieFile = "cookie.txt"

Func Curl_Setopt_Websocket($hCurl)
    ; Required for WebSocket mode
    Curl_Easy_Setopt($hCurl, $CURLOPT_CONNECT_ONLY, 2)

    ; Enable WebSocket mode (required in libcurl 8.x)
    Curl_Easy_Setopt($hCurl, $CURLOPT_WS_OPTIONS, 0)

    ; Required WebSocket headers
    Local $headers = Curl_Slist_Append(0, "Connection: Upgrade")
    $headers = Curl_Slist_Append($headers, "Upgrade: websocket")
    $headers = Curl_Slist_Append($headers, "Sec-WebSocket-Version: 13")
    $headers = Curl_Slist_Append($headers, "Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==")

    Curl_Easy_Setopt($hCurl, $CURLOPT_HTTPHEADER, $headers)
EndFunc

Func Curl_Ws_Send($Handle, $Data)

	$Data = StringToBinary($Data, 4) ; UTF-8
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

Func Curl_Ws_Recv($Handle, $iMax, ByRef $tMeta)
    Local $tBuffer = DllStructCreate("byte[" & $iMax & "]")
    Local $nread   = 0

    ; IMPORTANT: pass 0 for ptr*, read updated pointer from Ret[5]
    Local $Ret = DllCall($g_hlibcurl, (@AutoItX64 ? "int" : "int:cdecl"), "curl_ws_recv", _
        "ptr",       $Handle, _
        "ptr",       DllStructGetPtr($tBuffer), _
        "uint_ptr",  $iMax, _
        "uint_ptr*", $nread, _
        "ptr*",      0)

    If @error Then Return SetError(1, @error, "")

    Local $rc        = $Ret[0]
    Local $ReadBytes = $Ret[4]
    Local $pMeta     = $Ret[5]   ; <-- THIS is the metadata pointer

    ; Build struct if metadata exists
    $tMeta = 0
    If $pMeta <> 0 Then
        $tMeta = DllStructCreate( _
            "int age;" & _
            "int flags;" & _
            "int64 offset;" & _
            "int64 bytesleft;" & _
            (@AutoItX64 ? "uint64 len" : "uint len"), _
            $pMeta)
    EndIf

    If $rc <> 0 Or $ReadBytes = 0 Then Return SetExtended($rc, "")

    Local $bin = DllStructGetData($tBuffer, 1)
    $bin = BinaryMid($bin, 1, $ReadBytes)

    Return SetExtended($rc, BinaryToString($bin))
EndFunc

Func Curl_Get($url, $Slist = Null, $username = Null, $password = Null)
	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	Local $Html = $Curl ; any number as identify
	Local $Header = $Curl + 1 ; any number as identify

	Curl_Easy_Setopt($Curl, $CURLOPT_URL, $url)

	Curl_Easy_Setopt ( $Curl, $CURLOPT_ACCEPT_ENCODING, 'gzip, deflate, br, zstd' ) ; Possible values : '', 'identity', 'deflate' or 'gzip'

	if $username <> Null Then Curl_Easy_Setopt($Curl, $CURLOPT_USERNAME, $username)
	if $password <> Null Then Curl_Easy_Setopt($Curl, $CURLOPT_PASSWORD, $password)

	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_WRITEDATA, $Html)
	Curl_Easy_Setopt($Curl, $CURLOPT_COOKIEJAR, $CookieFile)
	Curl_Easy_Setopt($Curl, $CURLOPT_COOKIEFILE, $CookieFile)
	Curl_Easy_Setopt($Curl, $CURLOPT_HEADERFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($Curl, $CURLOPT_HEADERDATA, $Header)
	if $Slist <> Null Then Curl_Easy_Setopt($Curl, $CURLOPT_HTTPHEADER, $Slist)
	Curl_Easy_Setopt($Curl, $CURLOPT_TIMEOUT, 30)

	;peer verification
	curl_easy_setopt($Curl, $CURLOPT_CAINFO, @ScriptDir & '\curl-ca-bundle.crt') ;
 	Curl_Easy_Setopt($Curl, $CURLOPT_SSL_VERIFYPEER, 0)

	Local $Code = Curl_Easy_Perform($Curl)
	Local $response = ""

	If $Code = $CURLE_OK Then
 		$response = BinaryToString(Curl_Data_Get($Html))
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
	Local $response = ""

	If $Code = $CURLE_OK Then
 		$response = BinaryToString(Curl_Data_Get($Html))
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

