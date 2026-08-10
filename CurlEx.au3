#AutoIt3Wrapper_UseX64=y
#include-once
#include "Curl.au3"
#include "JsonCEx.au3"

Global $g_CookieFile = "cookie.txt"

Global $g_oCurlStatusText = ObjCreate("Scripting.Dictionary")
$g_oCurlStatusText.Add(100, "Continue")
$g_oCurlStatusText.Add(101, "Switching Protocols")
$g_oCurlStatusText.Add(102, "Processing")
$g_oCurlStatusText.Add(103, "Early Hints")
$g_oCurlStatusText.Add(200, "OK")
$g_oCurlStatusText.Add(201, "Created")
$g_oCurlStatusText.Add(202, "Accepted")
$g_oCurlStatusText.Add(203, "Non-Authoritative Information")
$g_oCurlStatusText.Add(204, "No Content")
$g_oCurlStatusText.Add(205, "Reset Content")
$g_oCurlStatusText.Add(206, "Partial Content")
$g_oCurlStatusText.Add(300, "Multiple Choices")
$g_oCurlStatusText.Add(301, "Moved Permanently")
$g_oCurlStatusText.Add(302, "Found")
$g_oCurlStatusText.Add(303, "See Other")
$g_oCurlStatusText.Add(304, "Not Modified")
$g_oCurlStatusText.Add(307, "Temporary Redirect")
$g_oCurlStatusText.Add(308, "Permanent Redirect")
$g_oCurlStatusText.Add(400, "Bad Request")
$g_oCurlStatusText.Add(401, "Unauthorized")
$g_oCurlStatusText.Add(402, "Payment Required")
$g_oCurlStatusText.Add(403, "Forbidden")
$g_oCurlStatusText.Add(404, "Not Found")
$g_oCurlStatusText.Add(405, "Method Not Allowed")
$g_oCurlStatusText.Add(406, "Not Acceptable")
$g_oCurlStatusText.Add(407, "Proxy Authentication Required")
$g_oCurlStatusText.Add(408, "Request Timeout")
$g_oCurlStatusText.Add(409, "Conflict")
$g_oCurlStatusText.Add(410, "Gone")
$g_oCurlStatusText.Add(411, "Length Required")
$g_oCurlStatusText.Add(412, "Precondition Failed")
$g_oCurlStatusText.Add(413, "Payload Too Large")
$g_oCurlStatusText.Add(414, "URI Too Long")
$g_oCurlStatusText.Add(415, "Unsupported Media Type")
$g_oCurlStatusText.Add(416, "Range Not Satisfiable")
$g_oCurlStatusText.Add(417, "Expectation Failed")
$g_oCurlStatusText.Add(418, "I'm a teapot")
$g_oCurlStatusText.Add(422, "Unprocessable Entity")
$g_oCurlStatusText.Add(425, "Too Early")
$g_oCurlStatusText.Add(426, "Upgrade Required")
$g_oCurlStatusText.Add(428, "Precondition Required")
$g_oCurlStatusText.Add(429, "Too Many Requests")
$g_oCurlStatusText.Add(431, "Request Header Fields Too Large")
$g_oCurlStatusText.Add(451, "Unavailable For Legal Reasons")
$g_oCurlStatusText.Add(500, "Internal Server Error")
$g_oCurlStatusText.Add(501, "Not Implemented")
$g_oCurlStatusText.Add(502, "Bad Gateway")
$g_oCurlStatusText.Add(503, "Service Unavailable")
$g_oCurlStatusText.Add(504, "Gateway Timeout")
$g_oCurlStatusText.Add(505, "HTTP Version Not Supported")
$g_oCurlStatusText.Add(507, "Insufficient Storage")
$g_oCurlStatusText.Add(511, "Network Authentication Required")


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

Func Curl_Get($sUrl, $oHeaderList = Null, $jOptions = Null)

	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	Local $Html = $Curl ; any number as identify
	Local $Header = $Curl + 1 ; any number as identify

    Curl_SetOptions($Curl, $Html, $Header, $sUrl, Null, $oHeaderList, $jOptions)

	Local $Code = Curl_Easy_Perform($Curl)
	Local $bodyObj = _JsonC_Object()
    Local $ctype = Curl_Easy_GetInfo($Curl, $CURLINFO_CONTENT_TYPE)

	If $Code = $CURLE_OK Then

   		$body = BinaryToString(Curl_Data_Get($Html))

        If StringInStr($ctype, "application/json") Then
            ; Parse JSON into a json-c object
            $bodyObj = _JsonC_TokenerParse($body)
        Else
            $bodyObj = _JsonC_ObjectNewString($body)
        EndIf

	Else
		ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
		$bodyObj = ""
	EndIf

    $jResponse = _JsonC_Object()
    $jResponse.add("status", Curl_Easy_GetInfo($Curl, $CURLINFO_RESPONSE_CODE))
    $jResponse.add("statusText", $g_oCurlStatusText.Item(Curl_Easy_GetInfo($Curl, $CURLINFO_RESPONSE_CODE)))
    $jResponse.add("headers", BinaryToString(Curl_Data_Get($Header)))
    $jResponse.add("body", _JsonC_Object($bodyObj))
    $jResponse.add("contentType", $ctype)
    ;_JsonC_ObjectObjectAdd($jResponse, "contentLength", _JsonC_ObjectNewInt(12345))
    ;_JsonC_ObjectObjectAdd($jResponse, "cookies", _JsonC_ObjectNewString(""))
    ;_JsonC_ObjectObjectAdd($jResponse, "error", _JsonC_ObjectNewString("null"))

	Curl_Easy_Cleanup($Curl)
	Curl_Data_Cleanup($Header)
	Curl_Data_Cleanup($Html)

	return $jResponse
EndFunc

 ; $username = "", $password = "")

Func Curl_Post($sUrl, $sPostData, $oHeaderList = Null, $jOptions = Null)

    Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	Local $Html = $Curl ; any number as identify
	Local $Header = $Curl + 1 ; any number as identify

    Curl_SetOptions($Curl, $Html, $Header, $sUrl, $sPostData, $oHeaderList, $jOptions)

	Local $Code = Curl_Easy_Perform($Curl)
	Local $bodyObj = ""
    Local $ctype = Curl_Easy_GetInfo($Curl, $CURLINFO_CONTENT_TYPE)

	If $Code = $CURLE_OK Then

   		$body = BinaryToString(Curl_Data_Get($Html))

        If StringInStr($ctype, "application/json") Then
            ; Parse JSON into a json-c object
            $bodyObj = _JsonC_TokenerParse($body)
        Else
            $bodyObj = _JsonC_ObjectNewString($body)
        EndIf

	Else
		ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
	EndIf

    $jResponse = _JsonC_Object()
    $jResponse.add("status", Curl_Easy_GetInfo($Curl, $CURLINFO_RESPONSE_CODE))
    $jResponse.add("statusText", $g_oCurlStatusText.Item(Curl_Easy_GetInfo($Curl, $CURLINFO_RESPONSE_CODE)))
    $jResponse.add("headers", BinaryToString(Curl_Data_Get($Header)))
    if $bodyObj = Null Then $bodyObj = ""
    $jResponse.add("body", _JsonC_Object($bodyObj))
    $jResponse.add("contentType", $ctype)
    ;_JsonC_ObjectObjectAdd($jResponse, "contentLength", _JsonC_ObjectNewInt(12345))
    ;_JsonC_ObjectObjectAdd($jResponse, "cookies", _JsonC_ObjectNewString(""))
    ;_JsonC_ObjectObjectAdd($jResponse, "error", _JsonC_ObjectNewString("null"))

	Curl_Easy_Cleanup($Curl)
	Curl_Data_Cleanup($Header)
	Curl_Data_Cleanup($Html)

	return $jResponse
EndFunc

Func Curl_Delete($sUrl, $oHeaderList = Null, $jOptions = Null)

	Local $Curl = Curl_Easy_Init()
	If Not $Curl Then Return

	Local $Html = $Curl ; any number as identify
	Local $Header = $Curl + 1 ; any number as identify

    Curl_SetOptions($Curl, $Html, $Header, $sUrl, Null, $oHeaderList, $jOptions)
    Curl_Easy_Setopt($Curl, $CURLOPT_CUSTOMREQUEST, "DELETE")

	Local $Code = Curl_Easy_Perform($Curl)
	Local $bodyObj = ""
    Local $ctype = Curl_Easy_GetInfo($Curl, $CURLINFO_CONTENT_TYPE)

	If $Code = $CURLE_OK Then

   		$body = BinaryToString(Curl_Data_Get($Html))

        If StringInStr($ctype, "application/json") Then
            ; Parse JSON into a json-c object
            $bodyObj = _JsonC_TokenerParse($body)
        Else
            $bodyObj = _JsonC_ObjectNewString($body)
        EndIf

	Else
		ConsoleWrite(Curl_Easy_StrError($Code) & @LF)
	EndIf

    $jResponse = _JsonC_Object()
    $jResponse.add("status", Curl_Easy_GetInfo($Curl, $CURLINFO_RESPONSE_CODE))
    $jResponse.add("statusText", $g_oCurlStatusText.Item(Curl_Easy_GetInfo($Curl, $CURLINFO_RESPONSE_CODE)))
    $jResponse.add("headers", BinaryToString(Curl_Data_Get($Header)))
    if $bodyObj = Null Then $bodyObj = ""
    $jResponse.add("body", _JsonC_Object($bodyObj))
    $jResponse.add("contentType", $ctype)
    ;_JsonC_ObjectObjectAdd($jResponse, "contentLength", _JsonC_ObjectNewInt(12345))
    ;_JsonC_ObjectObjectAdd($jResponse, "cookies", _JsonC_ObjectNewString(""))
    ;_JsonC_ObjectObjectAdd($jResponse, "error", _JsonC_ObjectNewString("null"))

	Curl_Easy_Cleanup($Curl)
	Curl_Data_Cleanup($Header)
	Curl_Data_Cleanup($Html)

	return $jResponse
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

Func Curl_SetOptions(ByRef $iCurl, $iHtml, $iHeader, $sUrl, $sPostData, $oHeaderList, $jOptions)

    Local $followRedirects = Null, $proxy = Null, $cookieFile = Null, $timeout = 30, $username = Null, $password = Null, $caInfo = @ScriptDir & '\curl-ca-bundle.crt', $sslVerifyPeer = 0

    if $jOptions <> Null Then
        $followRedirects                                = $jOptions.get("followRedirects").value()
        $proxy                                          = $jOptions.get("proxy").value()
        $cookieFile                                     = $jOptions.get("cookieFile").value()
        $timeout                                        = $jOptions.get("timeout").value()
        if $timeout = Null Then $timeout                = 30
        $caInfo                                         = $jOptions.get("caInfo").value()
        if $caInfo = Null Then $caInfo                  = @ScriptDir & '\curl-ca-bundle.crt'
        $sslVerifyPeer                                  = $jOptions.get("sslVerifyPeer").value()
        if $sslVerifyPeer = Null Then $sslVerifyPeer    = 0
        $username                                       = $jOptions.get("username").value()
        $password                                       = $jOptions.get("password").value()
    EndIf

   	Curl_Easy_Setopt($iCurl, $CURLOPT_URL, __Curl_Url_EncodeQueryString($sUrl))
    if $followRedirects = True Then Curl_Easy_Setopt($iCurl, $CURLOPT_FOLLOWLOCATION, 1)
    if $proxy <> Null Then Curl_Easy_Setopt($iCurl, $CURLOPT_PROXY, $proxy)
    if $cookieFile = Null And $g_CookieFile <> "" Then $cookieFile = $g_CookieFile
    if $cookieFile <> Null Then Curl_Easy_Setopt($iCurl, $CURLOPT_COOKIEJAR, $cookieFile)
    if $cookieFile <> Null Then Curl_Easy_Setopt($iCurl, $CURLOPT_COOKIEFILE, $cookieFile)
	Curl_Easy_Setopt($iCurl, $CURLOPT_WRITEFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($iCurl, $CURLOPT_WRITEDATA, $iHtml)
	Curl_Easy_Setopt($iCurl, $CURLOPT_HEADERFUNCTION, Curl_DataWriteCallback())
	Curl_Easy_Setopt($iCurl, $CURLOPT_HEADERDATA, $iHeader)
	if $oHeaderList <> Null Then Curl_Easy_Setopt($iCurl, $CURLOPT_HTTPHEADER, $oHeaderList)
	Curl_Easy_Setopt($iCurl, $CURLOPT_TIMEOUT, $timeout)
	if $sPostData <> Null Then
        Curl_Easy_Setopt($iCurl, $CURLOPT_POST, 1)
        Curl_Easy_Setopt($iCurl, $CURLOPT_COPYPOSTFIELDS, $sPostData)
    EndIf
	;peer verification
	Curl_Easy_Setopt($iCurl, $CURLOPT_CAINFO, $caInfo)
 	Curl_Easy_Setopt($iCurl, $CURLOPT_SSL_VERIFYPEER, $sslVerifyPeer)
    if $username <> Null Then Curl_Easy_Setopt($iCurl, $CURLOPT_USERNAME, $username)
    if $password <> Null Then Curl_Easy_Setopt($iCurl, $CURLOPT_PASSWORD, $password)

EndFunc

Func Curl_BuildHeaderSlist($jHeaders, ByRef $sContentType)

    Local $iter = _JsonC_ObjectIterInit($jHeaders)
    Local $header_list = Null

    Do
        Local $key = _JsonC_ObjectIterGetName($iter)
        Local $valueObj = _JsonC_ObjectIterGetValue($iter)
        Local $value = _JsonC_ObjectGetValue($valueObj)

        ; Detect Content-Type (case-insensitive)
        If StringLower($key) = "content-type" Then
            $sContentType = $value
        EndIf

        Local $header = $key & ": " & $value

        If $header_list = Null Then
            $header_list = Curl_Slist_Append(0, $header)
        Else
            $header_list = Curl_Slist_Append($header_list, $header)
        EndIf
    Until _JsonC_ObjectIterNext($iter) = False

    Return $header_list
EndFunc

; ======================================================================
; __Curl_Url_EncodeQueryString
; Encodes ONLY the query parameter values of a full URL.
; Example:
;   Input:
;     https://host/path?filter=OneTimeCode eq 'ABC'&limit=10
;   Output:
;     https://host/path?filter=OneTimeCode%20eq%20%27ABC%27&limit=10
; ======================================================================
Func __Curl_Url_EncodeQueryString($sUrl)
    ; No query string ? return unchanged
    Local $iPos = StringInStr($sUrl, "?", 0)
    If $iPos = 0 Then Return $sUrl

    ; Split base + query
    Local $sBase = StringLeft($sUrl, $iPos - 1)
    Local $sQuery = StringMid($sUrl, $iPos + 1)

    ; Split into key/value pairs
    Local $aPairs = StringSplit($sQuery, "&", 2)
    Local $aOut[UBound($aPairs)]

    For $i = 0 To UBound($aPairs) - 1
        Local $sPair = $aPairs[$i]

        ; Split on first "=" only
        Local $iEq = StringInStr($sPair, "=", 0)
        If $iEq = 0 Then
            ; No "=" ? keep as-is
            $aOut[$i] = $sPair
            ContinueLoop
        EndIf

        Local $sKey = StringLeft($sPair, $iEq - 1)
        Local $sValue = StringMid($sPair, $iEq + 1)

        ; Encode only the value
        Local $sEncodedValue = Curl_Escape($sValue)

        ; Rebuild pair
        $aOut[$i] = $sKey & "=" & $sEncodedValue
    Next

    ; Reassemble final URL
    Return $sBase & "?" & _ArrayToString($aOut, "&")
EndFunc
