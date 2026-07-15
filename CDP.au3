#AutoIt3Wrapper_UseX64=y
FileInstall(".\curl-ca-bundle.crt", ".\")
FileInstall(".\libcurl-x64.dll", ".\")
FileInstall(".\selenium-manager.exe", ".\")
FileInstall(".\sqlite3_xsv.dll", ".\")
FileInstall(".\sqlite3.exe", ".\")

; ======================================================================================================================
;   AutoIt CDP UDF
;   Direct Chrome DevTools Protocol automation for AutoIt
;
;	NOTE - Add the following line to your SciTEUser.properties for UTF8 / Unicode console support:
;
;	output.code.page=65001
;
; ======================================================================================================================

#region --- Core Includes & Globals ---

#include-once
#include <AutoItConstants.au3>
#include <StringConstants.au3>
#include <Array.au3>
#include <String.au3>
#include <WinAPIProc.au3>
#include "JsonCEx.au3" ; this includes "AutoItObject.au3"
#include "CurlEx.au3"
#include "SQLite-XSV.au3"

Global Const $WINHTTP_WEB_SOCKET_RECEIVE_FLAG_PEEK = 1
Global $CDP_DISABLE_ALIASES
Global Enum $CDP_BROWSER, $CDP_PAGE

Global Enum _
		$CDPVIDEO_ON, _
		$CDPVIDEO_OFF
		; $CDPVIDEO_RETAIN_ON_FAILURE, _			; todo
		;$CDPVIDEO_ON_FIRST_RETRY					; todo

; Global CDP registry: wsHandle → state object
Global $g_CDP_Browsers = ObjCreate("Scripting.Dictionary")
Global $g_CDP_TestEnv = ""

$AutoItError = ObjEvent("AutoIt.Error", "ErrFunc") ; Install a custom error handler

Global $g_CDP_FfmpegHandle = Null
Global $g_CDP_FfmpegDataXml = ObjCreate("MSXML2.DOMDocument")
Global $g_CDP_FfmpegDataNode = $g_CDP_FfmpegDataXml.createElement("b64")
$g_CDP_FfmpegDataNode.dataType = "bin.base64"
Global $g_fChromeStartTime = 0

#endregion

#region --- Initialization ---

_SQLite_XSV_Startup()
_JsonC_Startup()
_AutoItObject_Startup()

Local $cdpState = _AutoItObject_Create()
_AutoItObject_AddProperty($cdpState, "indentLevel",     	$ELSCOPE_PUBLIC, 0)
_AutoItObject_AddProperty($cdpState, "events",  			$ELSCOPE_PUBLIC, ObjCreate("Scripting.Dictionary"))

Global $cdpConfig = _AutoItObject_Create()
_AutoItObject_AddProperty($cdpConfig, "timeout", 			$ELSCOPE_PUBLIC, 5000)
_AutoItObject_AddProperty($cdpConfig, "debug", 				$ELSCOPE_PUBLIC, False)
_AutoItObject_AddProperty($cdpConfig, "infoPopups", 		$ELSCOPE_PUBLIC, False)
_AutoItObject_AddProperty($cdpConfig, "errorPopups", 		$ELSCOPE_PUBLIC, False)
_AutoItObject_AddProperty($cdpConfig, "enterpriseMode", 	$ELSCOPE_PUBLIC, False)
_AutoItObject_AddProperty($cdpConfig, "video", 				$ELSCOPE_PUBLIC, $CDPVIDEO_OFF)

Global $cdpBrowser = _AutoItObject_Create()
_AutoItObject_AddMethod($cdpBrowser, "exists", 				"_CDP_Browser_Exists")
_AutoItObject_AddMethod($cdpBrowser, "launch", 				"_CDP_Browser_Launch")
_AutoItObject_AddMethod($cdpBrowser, "attach", 				"_CDP_Browser_Attach")
_AutoItObject_AddMethod($cdpBrowser, "isRunning", 			"_CDP_Browser_IsRunning")
_AutoItObject_AddMethod($cdpBrowser, "forceClose", 			"_CDP_Browser_ForceClose")

Global $cdpApi = _AutoItObject_Create()
_AutoItObject_AddMethod($cdpApi, "get", 					"_CDP_Api_Get")
_AutoItObject_AddMethod($cdpApi, "post", 					"_CDP_Api_Post")
_AutoItObject_AddMethod($cdpApi, "put", 					"_CDP_Api_Put")
_AutoItObject_AddMethod($cdpApi, "patch", 					"_CDP_Api_Patch")
_AutoItObject_AddMethod($cdpApi, "delete", 					"_CDP_Api_Delete")

Global $cdp = _AutoItObject_Create()
_AutoItObject_AddProperty($cdp, "state", 					$ELSCOPE_PUBLIC, $cdpState)
_AutoItObject_AddProperty($cdp, "config", 					$ELSCOPE_PUBLIC, $cdpConfig)
_AutoItObject_AddProperty($cdp, "browser", 					$ELSCOPE_PUBLIC, $cdpBrowser)
_AutoItObject_AddProperty($cdp, "api", 						$ELSCOPE_PUBLIC, $cdpApi)

If Not IsDeclared("CDP_DISABLE_ALIASES") Or Not $CDP_DISABLE_ALIASES Then
    Global $browser = $cdp.browser
    Global $api 	= $cdp.api
    Global $config  = $cdp.config
EndIf

$cdp.state.events.Item("Page.loadEventFired") = "_OnPageLoad"

; UTF8 / Unicode support
DllCall("kernel32.dll", "bool", "SetConsoleOutputCP", "uint", 65001)
DllCall("kernel32.dll", "bool", "SetConsoleCP", "uint", 65001)

#endregion

#region --- CDP Transport Layer (low-level) ---

Func _CDP_Connect($iUrl)

	Local $hCurl = Curl_Easy_Init()
	Curl_Easy_Setopt($hCurl, $CURLOPT_URL, $iUrl)
	Curl_Setopt_Websocket($hCurl)
	Curl_Easy_Perform($hCurl)
	Return $hCurl

EndFunc

Func __CDP_Send($wsHandle, $sJson)
    Local $rc = Curl_Ws_Send($wsHandle, $sJson)
    Local $sent = @extended

    ; rc = CURLcode, sent = bytes sent
    If $rc <> 0 Or $sent = 0 Then
        if $cdp.config.debug = True Then ConsoleWrite("CDP SEND: failed rc=" & $rc & " sent=" & $sent & @CRLF)
        Return SetError(1, $rc, False)
    EndIf

    Return True
EndFunc

Func _CDP_SendCommand($oContext, $sMethod, $oParams = Null)

	If Not $g_CDP_Browsers.Exists($oContext.wsPort) Then Return SetError(2, 0, 0)
	Local $oState = $g_CDP_Browsers.Item($oContext.wsPort)

	; Allocate id
    Local $iId = $oState.Item("nextId")
    $oState.Item("nextId") = $iId + 1

	Local $jCmd = _JsonC_Object()
	$jCmd.add("id", $iId)
	$jCmd.add("method", $sMethod)
	If $oContext.type = $CDP_PAGE Then $jCmd.add("sessionId", $oContext.sessionId)
	If $oParams <> Null Then $jCmd.add("params", $oParams)
	Local $sJson = $jCmd.toString()

    if $cdp.config.debug = True Then ConsoleWrite("SEND: " & $sJson & @CRLF)

    __CDP_Send($oContext.wsHandle, $sJson)
    Return $iId
EndFunc

Func _CDP_SendCommand2($wsPort, $wsHandle, $iType, $sSessionId, $sMethod, $oParams = Null)

	If Not $g_CDP_Browsers.Exists($wsPort) Then Return SetError(2, 0, 0)
	Local $oState = $g_CDP_Browsers.Item($wsPort)

	; Allocate id
    Local $iId = $oState.Item("nextId")
    $oState.Item("nextId") = $iId + 1

	Local $jCmd = _JsonC_Object()
	$jCmd.add("id", $iId)
	$jCmd.add("method", $sMethod)
	If $iType = $CDP_PAGE Then $jCmd.add("sessionId", $sSessionId)
	If $oParams <> Null Then $jCmd.add("params", $oParams)
	Local $sJson = $jCmd.toString()

    if $cdp.config.debug = True Then ConsoleWrite("SEND: " & $sJson & @CRLF)

    __CDP_Send($wsHandle, $sJson)
    Return $iId
EndFunc

Func _CDP_SendSync($oContext, $method, $params = Null, $timeout = 10000)

    If Not $g_CDP_Browsers.Exists($oContext.wsPort) Then Return SetError(2, 0, Null)

    ; 2. Get per‑browser CDP state
    Local $oState = $g_CDP_Browsers.Item($oContext.wsPort)

	; Send command → get ID
    Local $id = _CDP_SendCommand($oContext, $method, $params)

    ; Wait for response
    Local $t = TimerInit()
	Local $pending = $oState.Item("pending")

    While TimerDiff($t) < $timeout
		If $pending.Exists($id) Then
            Local $resp = $pending.Item($id)
            $pending.Remove($id)
            Return $resp
        EndIf
        Sleep(1)
    WEnd

    Return SetError(1, 0, Null)
EndFunc




Func _CDP_RecvLoop()

    Local $keys = $g_CDP_Browsers.Keys

    For $i = 0 To UBound($keys) - 1

        Local $wsPort 	= $keys[$i]
        Local $oState 	= $g_CDP_Browsers.Item($wsPort)
        Local $hWs    	= $oState.Item("wsHandle")
		Local $fullMsg	= ""

		Do

			; -------------------------------
			; 1. Read full WebSocket frame
			; -------------------------------
			$fullMsg = __CDP_ReadFullWsFrame($hWs)
			If @error Then
				; rc=81 → no data
				If @error = 81 Then ContinueLoop

				; rc=56 → connection closed
				If @error = 56 Then
					If $cdp.config.debug Then ConsoleWrite("CDP RECV LOOP: connection closed (rc=56)" & @CRLF)
					__CDP_RemoveBrowserState($wsPort)
					ContinueLoop
				EndIf

				; Any other error
				;If $cdp.config.debug Then ConsoleWrite("CDP RECV LOOP: fatal error rc=" & @error & @CRLF)
				;__CDP_RemoveBrowserState($wsPort)
				ContinueLoop
			EndIf

			; Filter messages
			If StringLeft($fullMsg, 6) = '{"id":' Or StringLeft($fullMsg, 31) = '{"method":"Page.loadEventFired"' Or StringLeft($fullMsg, 32) = '{"method":"Target.targetCreated"' Or StringLeft($fullMsg, 32) = '{"method":"Page.screencastFrame"' Then

				; Debug output
				If $cdp.config.debug Then ConsoleWrite("RECV: " & $fullMsg & @CRLF)

				; -------------------------------
				; 2. Parse JSON
				; -------------------------------
				Local $msgObj = _JsonC_TokenerParse($fullMsg)
				If $msgObj = 0 Then ContinueLoop

				Local $msgIdObj     = _JsonC_ObjectObjectGet($msgObj, "id")
				Local $msgMethodObj = _JsonC_ObjectObjectGet($msgObj, "method")

				Local $msgId = ""
				Local $msgMethod = ""

				If $msgIdObj <> 0 Then $msgId = _JsonC_ObjectGetValue($msgIdObj)
				If $msgMethodObj <> 0 Then $msgMethod = _JsonC_ObjectGetValue($msgMethodObj)

				if $msgMethod = "Target.targetCreated" Then
					Local $paramsObj = _JsonC_ObjectObjectGet($msgObj, "params")
					Local $targetInfoObj = _JsonC_ObjectObjectGet($paramsObj, "targetInfo")
					Local $typeObj = _JsonC_ObjectObjectGet($targetInfoObj, "type")
					Local $typeVal = _JsonC_ObjectGetString($typeObj)
					if $typeVal = "page" Then
						_JsonC_ObjectObjectGet($targetInfoObj, "openerId")
						if @error = 0 Then
							Local $targetIdObj = _JsonC_ObjectObjectGet($targetInfoObj, "targetId")
							Local $targetIdVal = _JsonC_ObjectGetString($targetIdObj)
							$oState.Item("nextTargetId") = $targetIdVal
							if $oState.Item("contextId") = Null Then
								Local $browserContextIdObj = _JsonC_ObjectObjectGet($targetInfoObj, "browserContextId")
								Local $browserContextIdVal = _JsonC_ObjectGetString($browserContextIdObj)
								$oState.Item("contextId") = $browserContextIdVal
							EndIf
						EndIf
					EndIf
				EndIf

				;if $cdp.config.video = $CDPVIDEO_ON And $msgMethod = "Page.screencastFrame" Then
				if $g_CDP_FfmpegHandle <> Null And $msgMethod = "Page.screencastFrame" Then
					Local $sessionIdVal = _JsonC_ObjectGetString(_JsonC_ObjectObjectGet($msgObj, "sessionId"))
					Local $paramsObj = _JsonC_ObjectObjectGet($msgObj, "params")
					Local $paramsSessionIdVal = _JsonC_ObjectGetInt(_JsonC_ObjectObjectGet($paramsObj, "sessionId"))
					Local $dataVal = _JsonC_ObjectGetString(_JsonC_ObjectObjectGet($paramsObj, "data"))
					Local $fChromeTimestamp = _JsonC_ObjectGetDouble(_JsonC_ObjectObjectGet(_JsonC_ObjectObjectGet($paramsObj, "metadata"), "timestamp"))

					; decode base64 $dataVal
					$g_CDP_FfmpegDataNode.text = $dataVal
					$dataVal = $g_CDP_FfmpegDataNode.nodeTypedValue

					Local $tBuf = DllStructCreate("byte[" & BinaryLen($dataVal) & "]")
					DllStructSetData($tBuf, 1, $dataVal)

					$fChromeTimestamp = $fChromeTimestamp * 1000
					if $g_fChromeStartTime = 0 Then $g_fChromeStartTime = $fChromeTimestamp
					Local $timestampMs = $fChromeTimestamp - $g_fChromeStartTime

					DllCall($g_CDP_FfmpegHandle, "int", "WriteFrame", "ptr", DllStructGetPtr($tBuf), "int", BinaryLen($dataVal), "double", $timestampMs)

					;_CDP_SendCommand($oBrowser, "Page.screencastFrameAck", _JsonC_Object().add("targetId", $defaultTargetId))
					_CDP_SendCommand2($wsPort, $hWs, $CDP_PAGE, $sessionIdVal, "Page.screencastFrameAck", _JsonC_Object().add("sessionId", $paramsSessionIdVal))

				EndIf

				; -------------------------
				; 3. RESPONSE (has "id")
				; -------------------------
				If $msgId <> "" Then
					$oState.Item("pending").Item($msgId) = $msgObj
				EndIf

				; -------------------------
				; 4. EVENT (has "method")
				; -------------------------
				If $msgMethod <> "" Then
					If $cdp.state.events.Exists($msgMethod) Then
						Call($cdp.state.events.Item($msgMethod), $wsPort, $msgObj)
					EndIf

					If $msgMethod = "Inspector.detached" Then
						__CDP_RemoveBrowserState($wsPort)
					EndIf
				EndIf

			Endif
		Until $fullMsg = ""

    Next
EndFunc


Func __CDP_ReadFullWsFrame($hWs)
    Local $buffer = ""
    Local $tMeta, $chunk, $rc

    While True
        $chunk = Curl_Ws_Recv($hWs, 65536, $tMeta)
        $rc = @extended

        ; No data yet
        If $rc = 81 Then
            If $buffer = "" Then Return SetError(81, 0, "")
            ContinueLoop
        EndIf

        ; Connection closed
        If $rc = 56 Then Return SetError(56, 0, "")

        ; Any other error
        If $rc <> 0 Then Return SetError($rc, 0, "")

        ; Append chunk
        If $chunk <> "" Then $buffer &= $chunk

        ; If no metadata, assume frame complete (defensive)
        If Not IsDllStruct($tMeta) Then ExitLoop

        ; bytesleft == 0 → final fragment
        Local $bytesleft = DllStructGetData($tMeta, "bytesleft")
        If $bytesleft = 0 Then ExitLoop
    WEnd

    Return $buffer
EndFunc


Func __CDP_RemoveBrowserState($wsPort)
    ; Remove this browser's CDP state
    If $g_CDP_Browsers.Exists($wsPort) Then
        $g_CDP_Browsers.Remove($wsPort)
		if $cdp.config.debug = True Then ConsoleWrite("DEBUG: Browser closed. Browsers remaining = " & $g_CDP_Browsers.Count & @CRLF)
    EndIf

    ; If no browsers remain, stop the recv loop
    If $g_CDP_Browsers.Count = 0 Then
        AdlibUnRegister("_CDP_RecvLoop")
		if $cdp.config.debug = True Then ConsoleWrite("DEBUG: _CDP_RecvLoop unregistered" & @CRLF)
    EndIf
EndFunc


Func _CDP_NewParams()
    Return ObjCreate("Scripting.Dictionary")
EndFunc

Func _CDP_WaitForLoad($oContext, $timeout = 20000)

    If Not $g_CDP_Browsers.Exists($oContext.wsPort) Then Return False

    Local $oState = $g_CDP_Browsers.Item($oContext.wsPort)

    ; Reset load flag
    $oState.Item("pageLoaded") = False

    ; Wait for load event
    Local $t = TimerInit()
    While Not $oState.Item("pageLoaded")
        If TimerDiff($t) > $timeout Then Return False
        ;Sleep(10)
    WEnd

    Return $oContext
EndFunc


Func _CDP_Evaluate($oContext, $sExpression)

    Return _CDP_SendSync($oContext, "Runtime.evaluate", _JsonC_Object().add("expression", $sExpression))

EndFunc

Func _OnPageLoad($wsKey, $msgObj)
	If Not $g_CDP_Browsers.Exists($wsKey) Then Return
    Local $oState = $g_CDP_Browsers.Item($wsKey)
    ; Mark this browser as having fired a load event
    $oState.Item("pageLoaded") = True
EndFunc


#endregion


#region --- API Class ---

Func _CDP_Api_Get($oSelf, $sUrl, $oHeaderData = Null, $jOptions = Null)

	Local $oHeaderList = Null, $sContentType = Null
	if $oHeaderData <> Null Then
		$oHeaderData = $oHeaderData.handle
	    If IsString($oHeaderData) Then $oHeaderData = _JsonC_TokenerParse($oHeaderData)
		if $oHeaderData <> Null Then $oHeaderList = Curl_BuildHeaderSlist($oHeaderData, $sContentType)
	EndIf

	; call curl get
	Local $response = Curl_Get($sUrl, $oHeaderList, $jOptions)
	Return $response

EndFunc

Func _CDP_Api_Post($oSelf, $sUrl, $vPostData, $oHeaderData = Null, $jOptions = Null)

	if IsString($vPostData) = False Then $vPostData = $vPostData.handle
	Local $oHeaderList = Null, $sContentType = Null
	if $oHeaderData <> Null Then
		$oHeaderData = $oHeaderData.handle
	    If IsString($oHeaderData) Then $oHeaderData = _JsonC_TokenerParse($oHeaderData)
		if $oHeaderData <> Null Then $oHeaderList = Curl_BuildHeaderSlist($oHeaderData, $sContentType)
	EndIf
	If StringInStr($sContentType, "application/json") And IsString($vPostData) = False Then $vPostData = _JsonC_ObjectToJsonString($vPostData)

	; call curl post
	Local $response = Curl_Post($sUrl, $vPostData, $oHeaderList, $jOptions)
	Return $response

EndFunc

Func _CDP_Api_Delete($oSelf, $sUrl, $oHeaderData = Null, $jOptions = Null)

	Local $oHeaderList = Null, $sContentType = Null
	if $oHeaderData <> Null Then
		$oHeaderData = $oHeaderData.handle
	    If IsString($oHeaderData) Then $oHeaderData = _JsonC_TokenerParse($oHeaderData)
		if $oHeaderData <> Null Then $oHeaderList = Curl_BuildHeaderSlist($oHeaderData, $sContentType)
	EndIf

	; call curl get
	Local $response = Curl_Delete($sUrl, $oHeaderList, $jOptions)
	Return $response

EndFunc

#endregion


#region --- Browser Class ---

Func _CDP_Browser_IsRunning($oSelf, $port)
    Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
    If @error Then Return False

    Local $url = "http://localhost:" & $port & "/json/version"

    ; Attempt the GET request
    $oHTTP.Open("GET", $url, False)
    If @error Then Return False

    $oHTTP.Send()
    If @error Then Return False

    ; If we got here, Chrome responded
    Return True
EndFunc

Func _CDP_Browser_ForceClose($oSelf, $port)
    ;If Not $oSelf.isRunning($port) Then Return False

    Local $sPort = "--remote-debugging-port=" & $port
    Local $aList = ProcessList("chrome.exe")

    For $i = 1 To $aList[0][0]
        Local $pid = $aList[$i][1]
        Local $cmd = _WinAPI_GetProcessCommandLine($pid)

        If StringInStr($cmd, $sPort) Then
            ProcessClose($pid)
            Return True
        EndIf
    Next

    Return False
EndFunc

Func _CDP_Browser_Exists($oSelf, $port)
	Return $g_CDP_Browsers.Exists($port)
EndFunc

Func _CDP_Browser_Launch($oSelf, $browser = Default, $port = Default, $startupSwitches = Default, $profile = Default, $windowSize = Default, $clearCookies = False)

	if $cdp.config.infoPopups = True Then SplashTextOn("AutoIt CDP", "Preparing browser ...", 420, 120)

	if $browser = Default Then $browser = @ProgramFilesDir & "\Google\Chrome\Application\chrome.exe"
	if $port = Default Then $port = 9222
	if $startupSwitches = Default Then $startupSwitches = "--no-first-run --no-default-browser-check --disable-gpu --disable-dev-shm-usage --disable-extensions --disable-background-networking --disable-renderer-backgrounding --disable-sync --metrics-recording-only --mute-audio --hide-crash-restore-bubble --noerrdialogs --disable-infobars --disable-popup-blocking --enable-automation --silent-launch"
	if $profile = Default Then $profile = @ScriptDir & "\chromeprofile"
	if $windowSize <> Default Then $startupSwitches = $startupSwitches & ' --window-size=' & $windowSize

	; force close any browser instances already on this port
	$cdp.browser.forceClose($port)

    If IsString($browser) And StringInStr($browser, "@") > 0 Then
		; it's a browser specifier
		$browserSpecifier = $browser
		$browser = __CDP_ResolveBrowserSpecifier($browserSpecifier)
		if @error > 0 Then
			ConsoleWrite('Browser specifier ' & $browserSpecifier & ' not found. Exiting.' & @CRLF)
			Exit
		EndIf
	ElseIf Not FileExists($browser) Then
        ConsoleWrite('Browser path ' & $browser & ' not found. Exiting.' & @CRLF)
        Exit
	EndIf

	; always delete previous sessions in the user profile
	;	to simplify detection of the correct websocket
	DirRemove($profile & "\Default\Sessions", 1)

	if $clearCookies = True Then
		FileDelete($profile & "\Default\Cookies")
		FileDelete($profile & "\Default\Cookies-journal")
		FileDelete($profile & "\Default\Network\Cookies")
		FileDelete($profile & "\Default\Network\Cookies-journal")
	EndIf

	; removing annoying notifications
	if FileExists($profile & "\Default\Preferences") Then
		Local $jPrefs = _JsonC_TokenerParse(FileRead($profile & "\Default\Preferences"))
		If $jPrefs <> Null Then
			Local $jProfile = _JsonC_ObjectObjectGet($jPrefs, "profile")
			If $jProfile = Null Then
				$jPasswordManagerLeakDetection = _JsonC_ObjectNewObject()
				_JsonC_ObjectObjectAdd($jPasswordManagerLeakDetection, "password_manager_leak_detection", _JsonC_ObjectNewBoolean(False))
				_JsonC_ObjectObjectAdd($jPrefs, "profile", $jPasswordManagerLeakDetection)
			else
				_JsonC_ObjectObjectAdd($jProfile, "password_manager_leak_detection", _JsonC_ObjectNewBoolean(False))
			endif
		endif
		FileDelete($profile & "\Default\Preferences")
		FileWrite($profile & "\Default\Preferences", _JsonC_ObjectToJsonString($jPrefs))
	EndIf

	if $cdp.config.infoPopups = True Then ControlSetText("AutoIt CDP", "", "Static1", 'Launching browser ... ')
	Local $cmd = '"' & $browser & '" --remote-debugging-port=' & $port & ' --user-data-dir="' & $profile & '" ' & $startupSwitches ; & ' chrome://newtab'
	if $cdp.config.debug = True Then __CDP_ConsoleWrite(_StringRepeat("  ", $cdp.state.indentLevel) & '▶ 🔧 Running ' & $cmd & @CRLF)
    Run($cmd)

	if $cdp.config.infoPopups = True Then SplashOff()

    Sleep(500) ; give Chrome time to start

	if $g_CDP_Browsers.Count = 0 Then
		AdlibRegister("_CDP_RecvLoop", 5)
		if $cdp.config.debug = True Then ConsoleWrite("DEBUG: _CDP_RecvLoop registered" & @CRLF)
	EndIf

	Local $wsHandle = Number(__CDP_Browser_Connect($port))

    Local $oState = ObjCreate("Scripting.Dictionary")
    $oState.Add("wsHandle",  $wsHandle)
    $oState.Add("pending", ObjCreate("Scripting.Dictionary"))
    $oState.Add("contextId", Null)
    $oState.Add("nextTargetId", Null)
    $oState.Add("nextId",  1)
    $oState.Add("pageLoaded", False)
    ;$oState.Add("type", $CDP_BROWSER)

	$g_CDP_Browsers.Add($port, $oState)

    ; Create Browser object
    Local $oBrowser = _AutoItObject_Create()

    ; Add methods
    _AutoItObject_AddMethod($oBrowser, "newPage", "_CDP_Browser_NewPage")
    ;_AutoItObject_AddMethod($oBrowser, "headlessShell", "_CDP_Browser_NewHeadlessShell")
    _AutoItObject_AddMethod($oBrowser, "getNewPage", "_CDP_Browser_GetNewPage")
	_AutoItObject_AddMethod($oBrowser, "close", "_CDP_Browser_Close")

    ; Add properties
    _AutoItObject_AddProperty($oBrowser, "type", $ELSCOPE_READONLY, $CDP_BROWSER)
    ;_AutoItObject_AddProperty($oBrowser, "wsUrl", $ELSCOPE_PUBLIC, $browserWsUrl)
    _AutoItObject_AddProperty($oBrowser, "wsPort", $ELSCOPE_PUBLIC, $port)
    _AutoItObject_AddProperty($oBrowser, "wsHandle", $ELSCOPE_PUBLIC, $wsHandle)
    _AutoItObject_AddProperty($oBrowser, "activeTargetId", $ELSCOPE_PUBLIC, 0)

	; Listen for targets like new tabs / pages
	_CDP_Browser_SetDiscoverTargets($oBrowser)

	; Remove the default "New Tab"
	Local $defaultTargetId = _CDP_Browser_GetDefaultTabTargetId($oBrowser)

	If $defaultTargetId <> Null Then
		_CDP_SendCommand($oBrowser, "Target.closeTarget", _JsonC_Object().add("targetId", $defaultTargetId))
	EndIf

    Return $oBrowser
EndFunc

Func _CDP_Browser_SetDiscoverTargets($oSelf)
    _CDP_SendCommand($oSelf, "Target.setDiscoverTargets", _JsonC_Object().add("discover", True))
EndFunc


Func _CDP_Browser_GetDefaultTabTargetId($oSelf)

    Local $resp = _CDP_SendSync($oSelf, "Target.getTargets")
    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $targetInfosObj = _JsonC_ObjectObjectGet($resultObj, "targetInfos")
	Local $targetInfos = _JsonC_ObjectArrayGetObjects($targetInfosObj)

	For $targetInfo in $targetInfos
		Local $typeObj = _JsonC_ObjectObjectGet($targetInfo, "type")
		Local $typeVal = _JsonC_ObjectGetValue($typeObj)
        If $typeVal = "page" Then
			Local $urlObj = _JsonC_ObjectObjectGet($targetInfo, "url")
			Local $urlVal = _JsonC_ObjectGetValue($urlObj)
			If $urlVal = "chrome://newtab/" Or $urlVal = "about:blank" Then
				Local $targetIdObj = _JsonC_ObjectObjectGet($targetInfo, "targetId")
				Local $targetIdVal = _JsonC_ObjectGetValue($targetIdObj)
				Return $targetIdVal
			EndIf
		EndIf
	Next

    Return Null
EndFunc

Func __CDP_Browser_Connect($port)

	$jResp = $api.get('http://localhost:' & $port & '/json/version')
	Local $browserWsUrl = $jResp.body.get("webSocketDebuggerUrl").value()

	If $browserWsUrl = Null Then
		__CDP_ConsoleWrite("No browser WebSocket found" & @CRLF)
		Return
	EndIf

	if $cdp.config.debug = True Then __CDP_ConsoleWrite(_StringRepeat("  ", $cdp.state.indentLevel) & '▶ 🔧 Browser WebSocket Url: ' & $browserWsUrl & @CRLF)

	; Connect to the browser level websocket
	return _CDP_Connect($browserWsUrl)

EndFunc


Func _CDP_Browser_NewPage($oSelf)

	; create a target
    Local $resp = _CDP_SendSync($oSelf, "Target.createTarget", _JsonC_Object().add("url", "about:blank"))
	Local $targetIdVal = _JsonC_Object($resp).get("result").get("targetId").value()

	; attach to the target
    Local $resp = _CDP_SendSync($oSelf, "Target.attachToTarget", _JsonC_Object().add("targetId", $targetIdVal).add("flatten", True))
	Local $sessionIdVal = _JsonC_Object($resp).get("result").get("sessionId").value()

	; inform the parent browser object that this is the active target
	$oSelf.activeTargetId = $targetIdVal

    ; Create Page object
	return __CDP_Page_Object($oSelf, $oSelf.wsPort, $oSelf.wsHandle, $sessionIdVal, $targetIdVal)

EndFunc

#cs
Func _CDP_Browser_NewHeadlessShell($oSelf)

	; connect the page level websocket to the browser level websocket

	$cdp.state.activePageWs = $oSelf.wsHandle
	ConsoleWrite("Page WebSocket Handle: " & $cdp.state.activePageWs & @CRLF)

	; create a target

    Local $oParams = _CDP_NewParams()
    $oParams.Add("url", "about:blank")
    Local $resp = _CDP_SendSync("Target.createTarget", $oParams)

    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $targetIdObj = _JsonC_ObjectObjectGet($resultObj, "targetId")
    Local $targetIdVal = _JsonC_ObjectGetValue($targetIdObj)

	; attach to the target

    Local $oParams = _CDP_NewParams()
    $oParams.Add("targetId", $targetIdVal)
    $oParams.Add("flatten", True)
    Local $resp = _CDP_SendSync("Target.attachToTarget", $oParams)

    Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
    Local $sessionIdObj = _JsonC_ObjectObjectGet($resultObj, "sessionId")
    Local $sessionIdVal = _JsonC_ObjectGetValue($sessionIdObj)

	; Set the active session Id to that of the headless-shell

	$cdp.state.activeSessionId = $sessionIdVal
	ConsoleWrite("Page Session Id: " & $cdp.state.activeSessionId & @CRLF)

    ; Enable core domains

    _CDP_SendSync($oSelf, "DOM.enable")
    _CDP_SendSync($oSelf, "Page.enable")
    _CDP_SendSync($oSelf, "Runtime.enable")

    ; Create Page object

    Local $oPage = _AutoItObject_Create()

    ; Add action methods

    _AutoItObject_AddMethod($oPage, "goto",      	"_CDP_Page_Goto")
    _AutoItObject_AddMethod($oPage, "locator",    	"_CDP_Page_Locator")
    _AutoItObject_AddMethod($oPage, "locatorNow", 	"_CDP_Page_LocatorNow")
    _AutoItObject_AddMethod($oPage, "evaluate",  	"_CDP_Page_Evaluate")

	; Add getter methods

	_AutoItObject_AddMethod($oPage, "url",      	"_CDP_Page_Url")
    _AutoItObject_AddMethod($oPage, "title",      	"_CDP_Page_Title")
    _AutoItObject_AddMethod($oPage, "content",     	"_CDP_Page_Content")
    _AutoItObject_AddMethod($oPage, "viewportSize",	"_CDP_Page_ViewportSize")

    ; Add properties

    ;_AutoItObject_AddProperty($oPage, "wsUrl", $ELSCOPE_PUBLIC, $pageWsUrl)
    _AutoItObject_AddProperty($oPage, "wsPort", $ELSCOPE_PUBLIC, $oSelf.wsPort)
    _AutoItObject_AddProperty($oPage, "wsHandle", $ELSCOPE_PUBLIC, $cdp.state.activePageWs)

    Return $oPage

EndFunc
#ce

Func _CDP_Browser_GetNewPage($oSelf)

	$timeout = 10000

    ; Wait for response
    Local $t = TimerInit()
    While TimerDiff($t) < $timeout

		Local $oState = $g_CDP_Browsers.Item($oSelf.wsPort)

		if $oState.Item("nextTargetId") <> Null Then

			; attach to the target
			Local $resp = _CDP_SendSync($oSelf, "Target.attachToTarget", _JsonC_Object().add("targetId", $oState.Item("nextTargetId")).add("flatten", True))
			Local $sessionIdVal = _JsonC_Object($resp).get("result").get("sessionId").value()
			$oState.Item("nextTargetId") = Null
			return __CDP_Page_Object($oSelf, $oSelf.wsPort, $oSelf.wsHandle, $sessionIdVal, $oState.Item("nextTargetId"))

		EndIf

		Sleep(1)
	WEnd

	if $cdp.config.debug = True Then ConsoleWrite("DEBUG: _CDP_Browser_GetNewPage timed out." & @CRLF)

	Return Null
EndFunc

Func _CDP_Browser_Close($oSelf)

    if $cdp.config.video = $CDPVIDEO_ON Then
		DllCall($g_CDP_FfmpegHandle, "int", "StopRecorder")
		DllClose($g_CDP_FfmpegHandle)
	EndIf

    _CDP_SendCommand($oSelf, "Browser.close")
	Sleep(500)
	__CDP_RemoveBrowserState($oSelf.wsPort)
    Return $oSelf

EndFunc

#endregion

#region --- Page Class ---

Func __CDP_Page_Object($parent, $wsPort, $wsHandle, $sessionId, $targetId)

    Local $oPage = _AutoItObject_Create()

    ; Add action methods
    _AutoItObject_AddMethod($oPage, "goto",      	"_CDP_Page_Goto")
    _AutoItObject_AddMethod($oPage, "locator",    	"_CDP_Page_Locator")
    _AutoItObject_AddMethod($oPage, "locatorNow", 	"_CDP_Page_LocatorNow")
    _AutoItObject_AddMethod($oPage, "evaluate",  	"_CDP_Page_Evaluate")
    _AutoItObject_AddMethod($oPage, "bringToFront",	"_CDP_Page_BringToFront")
    _AutoItObject_AddMethod($oPage, "setContent",	"_CDP_Page_SetContent")
    _AutoItObject_AddMethod($oPage, "waitForLoad", 	"_CDP_WaitForLoad")
    _AutoItObject_AddMethod($oPage, "screenshot",  	"_CDP_Page_Screenshot")

	; Add getter methods
	_AutoItObject_AddMethod($oPage, "url",      	"_CDP_Page_Url")
    _AutoItObject_AddMethod($oPage, "title",      	"_CDP_Page_Title")
    _AutoItObject_AddMethod($oPage, "content",     	"_CDP_Page_Content")
    _AutoItObject_AddMethod($oPage, "viewportSize",	"_CDP_Page_ViewportSize")

    ; Add properties
    _AutoItObject_AddProperty($oPage, "type", $ELSCOPE_READONLY, $CDP_PAGE)
    _AutoItObject_AddProperty($oPage, "parent", $ELSCOPE_READONLY, $parent)
    ;_AutoItObject_AddProperty($oPage, "wsUrl", $ELSCOPE_PUBLIC, $pageWsUrl)
    _AutoItObject_AddProperty($oPage, "wsPort", $ELSCOPE_PUBLIC, $wsPort)
    _AutoItObject_AddProperty($oPage, "wsHandle", $ELSCOPE_PUBLIC, $wsHandle)
    _AutoItObject_AddProperty($oPage, "sessionId", $ELSCOPE_PUBLIC, $sessionId)
    _AutoItObject_AddProperty($oPage, "targetId", $ELSCOPE_PUBLIC, $targetId)

    ; Enable core domains
    _CDP_SendCommand($oPage, "DOM.enable")
    _CDP_SendCommand($oPage, "Page.enable")
    _CDP_SendCommand($oPage, "Runtime.enable")
    ;_CDP_SendSync($oPage, "Network.enable")


	_CDP_SendCommand($oPage, "Page.startScreencast", _JsonC_Object().add("format", "jpeg").add("quality", 80).add("maxWidth", 1280).add("maxHeight", 720))



    Return $oPage

EndFunc

Func _CDP_Page_Goto($oSelf, $url, $waitForLoad = True)

    _CDP_SendCommand($oSelf, "Page.navigate", _JsonC_Object().add("url", $url))
	if $waitForLoad Then _CDP_WaitForLoad($oSelf)
    Return $oSelf

EndFunc

Func _CDP_Page_Evaluate($oSelf, $expression)

	Local $evalObj = _CDP_Evaluate($oSelf, $expression)
	;_CDP_WaitForLoad()
	Local $valueObjVal = _JsonC_Object($evalObj).get("result").get("result").get("value").value()
    If $valueObjVal = "" Then Return 0
	return $valueObjVal

EndFunc

Func _CDP_Page_BringToFront($oSelf)

	_CDP_SendSync($oSelf, "Target.activateTarget", _JsonC_Object().add("targetId", $oSelf.targetId))
	; inform the parent browser object that this is the active target
	$oSelf.parent.activeTargetId = $oSelf.targetId

EndFunc


Func _CDP_Page_SetContent($oSelf, $sHtml)

    Local $resp = _CDP_SendSync($oSelf, "Page.getFrameTree")
	Local $frameIdVal = _JsonC_Object($resp).get("result").get("frameTree").get("frame").get("id").value()
	_CDP_SendSync($oSelf, "Page.setDocumentContent", _JsonC_Object().add("frameId", $frameIdVal).add("html", $sHtml))

EndFunc

Func _CDP_Page_Url($oSelf)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.evaluate", _JsonC_Object().add("expression", "window.location.href").add("returnByValue", True))
	Return _JsonC_Object($resp).get("result").get("result").get("value").value()

EndFunc

Func _CDP_Page_Title($oSelf)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.evaluate", _JsonC_Object().add("expression", "document.title").add("returnByValue", True))
	Return _JsonC_Object($resp).get("result").get("result").get("value").value()

EndFunc

Func _CDP_Page_Content($oSelf)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.evaluate", _JsonC_Object().add("expression", "document.documentElement.outerHTML").add("returnByValue", True))
	Return _JsonC_Object($resp).get("result").get("result").get("value").value()

EndFunc

Func _CDP_Page_ViewportSize($oSelf)

    Local $resp = _CDP_SendSync($oSelf, "Page.getLayoutMetrics")
	Local $layoutViewport = _JsonC_Object($resp).get("result").get("layoutViewport")

    Local $a[2]
    $a[0] = $layoutViewport.get("clientWidth").value()
    $a[1] = $layoutViewport.get("clientHeight").value()
    Return $a

EndFunc

Func _CDP_Page_Screenshot($oSelf, $sPath, $bFullPage = True)
    Local $resp = _CDP_SendSync($oSelf, "Page.captureScreenshot", _JsonC_Object().add("format", "png").add("captureBeyondViewport", True))
	Local $data = _JsonC_Object($resp).get("result").get("data").value()
	Local $bPng = __CDP_Base64Decode($data)
	Local $hFile = FileOpen($sPath, 18) ; 18 = binary mode
	FileWrite($hFile, $bPng)
	FileClose($hFile)
EndFunc

Func __CDP_Perform_Search($selector)

	for $i = 1 to 2

		Local $resp = _CDP_SendSync("DOM.performSearch", _JsonC_Object().add("query", $selector))
		Local $searchIdVal = _JsonC_Object($resp).get("result").get("searchId").value()
		ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $searchIdVal = ' & $searchIdVal & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

		Local $resp = _CDP_SendSync("DOM.getSearchResults", _JsonC_Object().add("searchId", $searchIdVal).add("fromIndex", 0).add("toIndex", 1))
		Local $nodeIdsObj = _JsonC_Object($resp).get("result").get("nodeIds")

		For $i = 0 to $nodeIdsObj.count() - 1
			$nodeIdVal = $nodeIdsObj.at($i).value()
			if $nodeIdVal = 0 Then ExitLoop
			return $nodeIdVal
		Next

		_CDP_SendSync("DOM.getDocument", _JsonC_Object().add("depth", -1))
	Next

	Return Null

EndFunc

#cs

Func __CDP_Object_To_Node($oSelf)

	for $i = 1 to 2

		;Local $hStarttime = TimerInit()
		Local $resp = _CDP_SendSync($oSelf, "DOM.requestNode", _JsonC_Object().add("objectId", $oSelf.objectId))
		;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : TimerDiff($hStarttime) = ' & TimerDiff($hStarttime) & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
		Local $nodeIdVal = _JsonC_Object($resp).get("result").get("nodeId").value()
		if $nodeIdVal <> 0 Then Return $nodeIdVal
		;Local $hStarttime = TimerInit()
		_CDP_SendSync($oSelf, "DOM.getDocument", _JsonC_Object().add("depth", 0))
		;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : TimerDiff($hStarttime) = ' & TimerDiff($hStarttime) & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

	Next

EndFunc
#ce

Func __CDP_Object_To_Node2($oSelf)

	for $i = 1 to 2

		Local $backendNodeIdVal

		if $i = 1 Then
			Local $hStarttime = TimerInit()
			Local $resp = _CDP_SendSync($oSelf, "DOM.describeNode", _JsonC_Object().add("objectId", $oSelf.objectId))
			ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : TimerDiff($hStarttime) = ' & TimerDiff($hStarttime) & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
			$backendNodeIdVal = _JsonC_Object($resp).get("result").get("node").get("backendNodeId").value()
		Else

			Local $hStarttime = TimerInit()
			_CDP_SendSync($oSelf, "DOM.getDocument", _JsonC_Object().add("depth", 0))
			ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : TimerDiff($hStarttime) = ' & TimerDiff($hStarttime) & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
		EndIf

		Local $hStarttime = TimerInit()

		Local $resp = _CDP_SendSync($oSelf, "DOM.pushNodesByBackendIdsToFrontend", _JsonC_Object().add("backendNodeIds", _JsonC_Array().add($backendNodeIdVal)))
		ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : TimerDiff($hStarttime) = ' & TimerDiff($hStarttime) & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
		Local $resultObj = _JsonC_Object($resp).get("result")
		Local $resultType = $resultObj.type()
		ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $resultType = ' & $resultType & @CRLF & '>Error code: ' & @error & @CRLF)
Exit

		Local $resultObj = _JsonC_ObjectObjectGet($resp, "result")
		if _JsonC_ObjectIsType($resultObj, $JSONC_TYPE_NULL) = 1 Then ContinueLoop

		Local $nodeIdsObj = _JsonC_ObjectObjectGet($resultObj, "nodeIds")
		$nodeIds = _JsonC_ObjectArrayGetObjects($nodeIdsObj)
		Local $nodeIdVal

		For $nodeId in $nodeIds
			$nodeIdVal = _JsonC_ObjectGetValue($nodeId)
			ExitLoop
		Next

		if $nodeIdVal <> 0 Then Return $nodeIdVal

	Next

	Return 0

EndFunc


; "DOM.requestNode" the slowest - often also requires "DOM.getDocument" - about 170ms
; "DOM.describeNode" is fast but produces a backendNodeId not a nodeId
;	can pass this backendNodeId into "DOM.pushNodesByBackendIdsToFrontend" - it is slow about 175ms




Func _CDP_Page_Locator($oSelf, $selector)

    Local $type = ""
	Local $nodeIdVal = Null

    ; Explicit prefixes
    If StringLeft($selector, 6) = "xpath=" Then
        $type = "xpath"
        $selector = StringTrimLeft($selector, 6)

    ElseIf StringLeft($selector, 4) = "css=" Then
        $type = "css"
        $selector = StringTrimLeft($selector, 4)

    ; Auto-detect XPath
    ElseIf StringLeft($selector, 2) = "//" Then
        $type = "xpath"

    ; Auto-detect CSS
    Else
        $type = "css"
    EndIf

    Local $expr = ""

    If $type = "xpath" Then
		$expr = 'document.evaluate("' & $selector & '", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue'
    Else
        $expr = "document.querySelector(`" & $selector & "`)"
    EndIf

	$timeout = 10000

    ; Wait for response
    Local $t = TimerInit()
    While TimerDiff($t) < $timeout

		Local $resp = _CDP_Evaluate($oSelf, $expr)

		; Parse objectId
		Local $objectIdObj = _JsonC_Object($resp).get("result").get("result").get("objectId")

		if $objectIdObj <> Null Then

			Local $objectIdVal = $objectIdObj.value()

			; Create the Locator object
			Local $oLocator = _AutoItObject_Create()

			; Add action methods
			_AutoItObject_AddMethod($oLocator, "objectToNode", "_CDP_Locator_ObjectToNode")
			_AutoItObject_AddMethod($oLocator, "click", "_CDP_Locator_Click")										; done
			_AutoItObject_AddMethod($oLocator, "dblClick", "_CDP_Locator_DoubleClick")								; done
			_AutoItObject_AddMethod($oLocator, "hover", "_CDP_Locator_Hover")										; done
			_AutoItObject_AddMethod($oLocator, "tap", "_CDP_Locator_Tap")											; todo - Reqs CDP Commands Input.dispatchTouchEvent
			_AutoItObject_AddMethod($oLocator, "fill", "_CDP_Locator_Fill")											; done
			_AutoItObject_AddMethod($oLocator, "sendKeys", "_CDP_Locator_SendKeys")									; done
			_AutoItObject_AddMethod($oLocator, "press", "_CDP_Locator_Press")										; todo - Reqs CDP Commands Input.dispatchKeyEvent
			_AutoItObject_AddMethod($oLocator, "check", "_CDP_Locator_Check")										; done
			_AutoItObject_AddMethod($oLocator, "uncheck", "_CDP_Locator_Uncheck")									; done
			_AutoItObject_AddMethod($oLocator, "setChecked", "_CDP_Locator_SetChecked")								; done
			_AutoItObject_AddMethod($oLocator, "selectOption", "_CDP_Locator_SelectOption")							; done
			_AutoItObject_AddMethod($oLocator, "focus", "_CDP_Locator_Focus")										; done
			_AutoItObject_AddMethod($oLocator, "blur", "_CDP_Locator_Blur")											; done
			_AutoItObject_AddMethod($oLocator, "clear", "_CDP_Locator_Clear")										; todo - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "dragTo", "_CDP_Locator_DragTo")										; todo - Reqs CDP Commands DOM.getBoxModel, Input.dispatchMouseEvent
			_AutoItObject_AddMethod($oLocator, "setInputFiles", "_CDP_Locator_SetInputFiles")						; todo - Reqs CDP Commands DOM.setFileInputFiles
			_AutoItObject_AddMethod($oLocator, "dispatchEvent", "_CDP_Locator_DispatchEvent")						; todo - Reqs CDP Commands DOM.dispatchEvent
			_AutoItObject_AddMethod($oLocator, "scrollIntoView", "_CDP_Locator_ScrollIntoView")						; done
			_AutoItObject_AddMethod($oLocator, "scrollIntoViewIfNeeded", "_CDP_Locator_ScrollIntoViewIfNeeded")		; todo - Reqs CDP Commands DOM.scrollIntoViewIfNeeded, Runtime.callFunctionOn

			; Add getter methods
			_AutoItObject_AddMethod($oLocator, "textContent", "_CDP_Locator_TextContent")							; done
			_AutoItObject_AddMethod($oLocator, "innerText", "_CDP_Locator_InnerText")								; done
			_AutoItObject_AddMethod($oLocator, "innerTextCRStripped", "_CDP_Locator_InnerTextCRStripped")			; done
			_AutoItObject_AddMethod($oLocator, "innerTextLFStripped", "_CDP_Locator_InnerTextLFStripped")			; done
			_AutoItObject_AddMethod($oLocator, "innerTextReplace", "_CDP_Locator_InnerTextReplace")					; done
			_AutoItObject_AddMethod($oLocator, "innerHTML", "_CDP_Locator_InnerHTML")								; done
			_AutoItObject_AddMethod($oLocator, "inputValue", "_CDP_Locator_InputValue")								; done
			_AutoItObject_AddMethod($oLocator, "getAttribute", "_CDP_Locator_GetAttribute")							; done
			_AutoItObject_AddMethod($oLocator, "boundingBox", "_CDP_Locator_BoundingBox")							; todo - Reqs CDP Commands DOM.getBoxModel
			_AutoItObject_AddMethod($oLocator, "screenshot", "_CDP_Locator_Screenshot")								; todo - Reqs CDP Commands DOM.getBoxModel, Page.captureScreenshot
			_AutoItObject_AddMethod($oLocator, "evaluate", "_CDP_Locator_Evaluate")									; todo - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "evaluateAll", "_CDP_Locator_EvaluateAll")							; todo - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "elementHandle", "_CDP_Locator_ElementHandle")						; todo - Reqs CDP Commands DOM.resolveNode
			_AutoItObject_AddMethod($oLocator, "allInnerTexts", "_CDP_Locator_AllInnerTexts")						; todo - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "allTextContents", "_CDP_Locator_AllTextContents")					; todo - Reqs CDP Commands Runtime.callFunctionOn
			_AutoItObject_AddMethod($oLocator, "count", "_CDP_Locator_Count")										; todo - Reqs CDP Commands DOM.querySelectorAll

			; Add state methods
			_AutoItObject_AddMethod($oLocator, "isVisible", "_CDP_Locator_IsVisible")								; done
			_AutoItObject_AddMethod($oLocator, "isHidden", "_CDP_Locator_IsHidden")									; done
			_AutoItObject_AddMethod($oLocator, "isEnabled", "_CDP_Locator_IsEnabled")								; done
			_AutoItObject_AddMethod($oLocator, "isDisabled", "_CDP_Locator_IsDisabled")								; done
			_AutoItObject_AddMethod($oLocator, "isEditable", "_CDP_Locator_IsEditable")								; done
			_AutoItObject_AddMethod($oLocator, "isChecked", "_CDP_Locator_IsChecked")								; done

			; Add waiting methods
			_AutoItObject_AddMethod($oLocator, "waitFor", "_CDP_Locator_WaitFor")									; todo - Reqs CDP Commands DOM.querySelector, Runtime.callFunctionOn, DOM.getBoxModel
			_AutoItObject_AddMethod($oLocator, "waitForElementState", "_CDP_Locator_WaitForElementState")			; todo - Reqs CDP Commands Runtime.callFunctionOn, DOM.getBoxModel
			_AutoItObject_AddMethod($oLocator, "waitForSelector", "_CDP_Locator_WaitForSelector")					; todo - Reqs CDP Commands DOM.querySelector, DOM.querySelectorAll

			; Add locator-creation methods
			_AutoItObject_AddMethod($oLocator, "locator", "_CDP_Locator_Locator")									; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "filter", "_CDP_Locator_Filter")										; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "nth", "_CDP_Locator_Nth")											; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "first", "_CDP_Locator_First")										; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "last", "_CDP_Locator_Last")											; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "getByRole", "_CDP_Locator_GetByRole")								; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "getByText", "_CDP_Locator_GetByText")								; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "getByLabel", "_CDP_Locator_GetByLabel")								; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "getByPlaceholder", "_CDP_Locator_GetByPlaceholder")					; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "getByAltText", "_CDP_Locator_GetByAltText")							; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "getByTitle", "_CDP_Locator_GetByTitle")								; todo - Reqs CDP Commands No CDP — internal selector logic
			_AutoItObject_AddMethod($oLocator, "getByTestId", "_CDP_Locator_GetByTestId")							; todo - Reqs CDP Commands No CDP — internal selector logic

			; Add properties
			_AutoItObject_AddProperty($oLocator, "type", $ELSCOPE_READONLY, $CDP_PAGE)
			_AutoItObject_AddProperty($oLocator, "wsHandle", $ELSCOPE_PUBLIC, $oSelf.wsHandle)
			_AutoItObject_AddProperty($oLocator, "sessionId", $ELSCOPE_PUBLIC, $oSelf.sessionId)
			_AutoItObject_AddProperty($oLocator, "wsPort", $ELSCOPE_PUBLIC, $oSelf.wsPort)
			_AutoItObject_AddProperty($oLocator, "objectId", $ELSCOPE_PUBLIC, $objectIdVal)
			_AutoItObject_AddProperty($oLocator, "nodeId", $ELSCOPE_PUBLIC, 0)
			_AutoItObject_AddProperty($oLocator, "bboxLeft", $ELSCOPE_PUBLIC, -1)
			_AutoItObject_AddProperty($oLocator, "bboxTop", $ELSCOPE_PUBLIC, -1)
			_AutoItObject_AddProperty($oLocator, "bboxRight", $ELSCOPE_PUBLIC, -1)
			_AutoItObject_AddProperty($oLocator, "bboxBottom", $ELSCOPE_PUBLIC, -1)
			_AutoItObject_AddProperty($oLocator, "bboxWidth", $ELSCOPE_PUBLIC, -1)
			_AutoItObject_AddProperty($oLocator, "bboxHeight", $ELSCOPE_PUBLIC, -1)
			_AutoItObject_AddProperty($oLocator, "bboxCenterX", $ELSCOPE_PUBLIC, -1)
			_AutoItObject_AddProperty($oLocator, "bboxCenterY", $ELSCOPE_PUBLIC, -1)
			_AutoItObject_AddProperty($oLocator, "value", $ELSCOPE_PUBLIC, "")

			Return $oLocator
		EndIf

		;ConsoleWrite("Retrying locator." & @CRLF)
        Sleep(1)
    WEnd

	ConsoleWrite("Timed out." & @CRLF)
	Return Null

EndFunc

Func _CDP_Page_LocatorNow($oSelf, $selector)

    Local $type = ""

    ; Explicit prefixes
    If StringLeft($selector, 6) = "xpath=" Then
        $type = "xpath"
        $selector = StringTrimLeft($selector, 6)

    ElseIf StringLeft($selector, 4) = "css=" Then
        $type = "css"
        $selector = StringTrimLeft($selector, 4)

    ; Auto-detect XPath
    ElseIf StringLeft($selector, 2) = "//" Then
        $type = "xpath"

    ; Auto-detect CSS
    Else
        $type = "css"
    EndIf

    Local $expr = ""

    If $type = "xpath" Then
		$expr = 'document.evaluate("' & $selector & '", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue'
    Else
        $expr = "document.querySelector(`" & $selector & "`)"
    EndIf

	Local $resp = _CDP_Evaluate($oSelf, $expr)

	; Parse objectId
	Local $objectIdObj = _JsonC_Object($resp).get("result").get("result").get("objectId")
	if $objectIdObj = Null Then Return Null
	Local $objectIdVal = $objectIdObj.value()

	; Create the Locator object
	Local $oLocator = _AutoItObject_Create()
	Local $oExpect = _AutoItObject_Create()

	; Add action methods
	_AutoItObject_AddMethod($oLocator, "objectToNode", "_CDP_Locator_ObjectToNode")
	_AutoItObject_AddMethod($oLocator, "click", "_CDP_Locator_Click")
	_AutoItObject_AddMethod($oLocator, "dblClick", "_CDP_Locator_DoubleClick")
	_AutoItObject_AddMethod($oLocator, "hover", "_CDP_Locator_Hover")
	_AutoItObject_AddMethod($oLocator, "tap", "_CDP_Locator_Tap")
	_AutoItObject_AddMethod($oLocator, "fill", "_CDP_Locator_Fill")
	_AutoItObject_AddMethod($oLocator, "sendKeys", "_CDP_Locator_SendKeys")
	_AutoItObject_AddMethod($oLocator, "press", "_CDP_Locator_Press")
	_AutoItObject_AddMethod($oLocator, "check", "_CDP_Locator_Check")
	_AutoItObject_AddMethod($oLocator, "uncheck", "_CDP_Locator_Uncheck")
	_AutoItObject_AddMethod($oLocator, "setChecked", "_CDP_Locator_SetChecked")
	_AutoItObject_AddMethod($oLocator, "selectOption", "_CDP_Locator_SelectOption")
	_AutoItObject_AddMethod($oLocator, "focus", "_CDP_Locator_Focus")
	_AutoItObject_AddMethod($oLocator, "blur", "_CDP_Locator_Blur")
	_AutoItObject_AddMethod($oLocator, "clear", "_CDP_Locator_Clear")
	_AutoItObject_AddMethod($oLocator, "dragTo", "_CDP_Locator_DragTo")
	_AutoItObject_AddMethod($oLocator, "setInputFiles", "_CDP_Locator_SetInputFiles")
	_AutoItObject_AddMethod($oLocator, "dispatchEvent", "_CDP_Locator_DispatchEvent")
	_AutoItObject_AddMethod($oLocator, "scrollIntoViewIfNeeded", "_CDP_Locator_ScrollIntoViewIfNeeded")

	; Add getter methods
	_AutoItObject_AddMethod($oLocator, "textContent", "_CDP_Locator_TextContent")
	_AutoItObject_AddMethod($oLocator, "innerText", "_CDP_Locator_InnerText")
	_AutoItObject_AddMethod($oLocator, "innerTextCRStripped", "_CDP_Locator_InnerTextCRStripped")
	_AutoItObject_AddMethod($oLocator, "innerTextLFStripped", "_CDP_Locator_InnerTextLFStripped")
	_AutoItObject_AddMethod($oLocator, "innerTextReplace", "_CDP_Locator_InnerTextReplace")
	_AutoItObject_AddMethod($oLocator, "innerHTML", "_CDP_Locator_InnerHTML")
	_AutoItObject_AddMethod($oLocator, "inputValue", "_CDP_Locator_InputValue")
	_AutoItObject_AddMethod($oLocator, "getAttribute", "_CDP_Locator_GetAttribute")
	_AutoItObject_AddMethod($oLocator, "boundingBox", "_CDP_Locator_BoundingBox")
	_AutoItObject_AddMethod($oLocator, "screenshot", "_CDP_Locator_Screenshot")
	_AutoItObject_AddMethod($oLocator, "evaluate", "_CDP_Locator_Evaluate")
	_AutoItObject_AddMethod($oLocator, "evaluateAll", "_CDP_Locator_EvaluateAll")
	_AutoItObject_AddMethod($oLocator, "elementHandle", "_CDP_Locator_ElementHandle")
	_AutoItObject_AddMethod($oLocator, "allInnerTexts", "_CDP_Locator_AllInnerTexts")
	_AutoItObject_AddMethod($oLocator, "allTextContents", "_CDP_Locator_AllTextContents")
	_AutoItObject_AddMethod($oLocator, "count", "_CDP_Locator_Count")

	; Add state methods
	_AutoItObject_AddMethod($oLocator, "isVisible", "_CDP_Locator_IsVisible")
	_AutoItObject_AddMethod($oLocator, "isHidden", "_CDP_Locator_IsHidden")
	_AutoItObject_AddMethod($oLocator, "isEnabled", "_CDP_Locator_IsEnabled")
	_AutoItObject_AddMethod($oLocator, "isDisabled", "_CDP_Locator_IsDisabled")
	_AutoItObject_AddMethod($oLocator, "isEditable", "_CDP_Locator_IsEditable")
	_AutoItObject_AddMethod($oLocator, "isChecked", "_CDP_Locator_IsChecked")

	; Add waiting methods
	_AutoItObject_AddMethod($oLocator, "waitFor", "_CDP_Locator_WaitFor")
	_AutoItObject_AddMethod($oLocator, "waitForElementState", "_CDP_Locator_WaitForElementState")
	_AutoItObject_AddMethod($oLocator, "waitForSelector", "_CDP_Locator_WaitForSelector")

	; Add locator-creation methods
	_AutoItObject_AddMethod($oLocator, "locator", "_CDP_Locator_Locator")
	_AutoItObject_AddMethod($oLocator, "filter", "_CDP_Locator_Filter")
	_AutoItObject_AddMethod($oLocator, "nth", "_CDP_Locator_Nth")
	_AutoItObject_AddMethod($oLocator, "first", "_CDP_Locator_First")
	_AutoItObject_AddMethod($oLocator, "last", "_CDP_Locator_Last")
	_AutoItObject_AddMethod($oLocator, "getByRole", "_CDP_Locator_GetByRole")
	_AutoItObject_AddMethod($oLocator, "getByText", "_CDP_Locator_GetByText")
	_AutoItObject_AddMethod($oLocator, "getByLabel", "_CDP_Locator_GetByLabel")
	_AutoItObject_AddMethod($oLocator, "getByPlaceholder", "_CDP_Locator_GetByPlaceholder")
	_AutoItObject_AddMethod($oLocator, "getByAltText", "_CDP_Locator_GetByAltText")
	_AutoItObject_AddMethod($oLocator, "getByTitle", "_CDP_Locator_GetByTitle")
	_AutoItObject_AddMethod($oLocator, "getByTestId", "_CDP_Locator_GetByTestId")

	; Add properties
	_AutoItObject_AddProperty($oLocator, "type", $ELSCOPE_READONLY, $CDP_PAGE)
	_AutoItObject_AddProperty($oLocator, "wsHandle", $ELSCOPE_PUBLIC, $oSelf.wsHandle)
	_AutoItObject_AddProperty($oLocator, "sessionId", $ELSCOPE_PUBLIC, $oSelf.sessionId)
	_AutoItObject_AddProperty($oLocator, "wsPort", $ELSCOPE_PUBLIC, $oSelf.wsPort)
	_AutoItObject_AddProperty($oLocator, "objectId", $ELSCOPE_PUBLIC, $objectIdVal)
	_AutoItObject_AddProperty($oLocator, "nodeId", $ELSCOPE_PUBLIC, 0)
	_AutoItObject_AddProperty($oLocator, "bboxLeft", $ELSCOPE_PUBLIC, -1)
	_AutoItObject_AddProperty($oLocator, "bboxTop", $ELSCOPE_PUBLIC, -1)
	_AutoItObject_AddProperty($oLocator, "bboxRight", $ELSCOPE_PUBLIC, -1)
	_AutoItObject_AddProperty($oLocator, "bboxBottom", $ELSCOPE_PUBLIC, -1)
	_AutoItObject_AddProperty($oLocator, "bboxWidth", $ELSCOPE_PUBLIC, -1)
	_AutoItObject_AddProperty($oLocator, "bboxHeight", $ELSCOPE_PUBLIC, -1)
	_AutoItObject_AddProperty($oLocator, "bboxCenterX", $ELSCOPE_PUBLIC, -1)
	_AutoItObject_AddProperty($oLocator, "bboxCenterY", $ELSCOPE_PUBLIC, -1)
	_AutoItObject_AddProperty($oLocator, "value", $ELSCOPE_PUBLIC, "")

	Return $oLocator

EndFunc

#endregion

#region --- Locator Class ---


Func _CDP_Locator_ObjectToNode($oSelf)

	for $i = 1 to 2

		;Local $hStarttime = TimerInit()
		Local $resp = _CDP_SendSync($oSelf, "DOM.requestNode", _JsonC_Object().add("objectId", $oSelf.objectId))
		;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : TimerDiff($hStarttime) = ' & TimerDiff($hStarttime) & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
		Local $nodeIdVal = _JsonC_Object($resp).get("result").get("nodeId").value()
		if $nodeIdVal <> 0 Then
			$oSelf.nodeId = $nodeIdVal
			Return True
		EndIf
		;Local $hStarttime = TimerInit()
		_CDP_SendSync($oSelf, "DOM.getDocument", _JsonC_Object().add("depth", 0))
		;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : TimerDiff($hStarttime) = ' & TimerDiff($hStarttime) & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

	Next

	Return False
EndFunc

Func _CDP_Locator_Click($oSelf, $waitForLoad = False)

	_CDP_Locator_ScrollIntoView($oSelf)
	_CDP_SendCommand($oSelf, "Input.dispatchMouseEvent", _JsonC_Object().add("type", "mousePressed").add("button", "left").add("clickCount", 1).add("x", $oSelf.bboxCenterX).add("y", $oSelf.bboxCenterY))
	_CDP_SendCommand($oSelf, "Input.dispatchMouseEvent", _JsonC_Object().add("type", "mouseReleased").add("button", "left").add("clickCount", 1).add("x", $oSelf.bboxCenterX).add("y", $oSelf.bboxCenterY))
	if $waitForLoad = True Then _CDP_WaitForLoad($oSelf)
	return $oSelf

EndFunc

Func _CDP_Locator_DoubleClick($oSelf, $waitForLoad = False)

	_CDP_Locator_ScrollIntoView($oSelf)
    _CDP_Locator_BoundingBox($oSelf)
	_CDP_SendCommand($oSelf, "Input.dispatchMouseEvent", _JsonC_Object().add("type", "mousePressed").add("button", "left").add("clickCount", 1).add("x", $oSelf.bboxCenterX).add("y", $oSelf.bboxCenterY))
	_CDP_SendCommand($oSelf, "Input.dispatchMouseEvent", _JsonC_Object().add("type", "mouseReleased").add("button", "left").add("clickCount", 1).add("x", $oSelf.bboxCenterX).add("y", $oSelf.bboxCenterY))
	_CDP_SendCommand($oSelf, "Input.dispatchMouseEvent", _JsonC_Object().add("type", "mousePressed").add("button", "left").add("clickCount", 2).add("x", $oSelf.bboxCenterX).add("y", $oSelf.bboxCenterY))
	_CDP_SendCommand($oSelf, "Input.dispatchMouseEvent", _JsonC_Object().add("type", "mouseReleased").add("button", "left").add("clickCount", 2).add("x", $oSelf.bboxCenterX).add("y", $oSelf.bboxCenterY))
	if $waitForLoad = True Then _CDP_WaitForLoad($oSelf)
	return $oSelf

EndFunc

Func _CDP_Locator_Hover($oSelf)

	_CDP_Locator_ScrollIntoView($oSelf)
    ; Dispatch mouseMoved event
    _CDP_SendCommand($oSelf, "Input.dispatchMouseEvent", _JsonC_Object().add("type", "mouseMoved").add("x", $oSelf.bboxCenterX).add("y", $oSelf.bboxCenterY))
	return $oSelf

EndFunc

Func _CDP_Locator_Tap($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_Fill($oSelf, $value)

    _CDP_SendSync($oSelf, "Runtime.callFunctionOn", _JsonC_Object().add("objectId", $oSelf.objectId).add("functionDeclaration", "function(value) { this.value = value; this.dispatchEvent(new Event('input', { bubbles: true })); this.dispatchEvent(new Event('change', { bubbles: true })); }").add("arguments", _JsonC_Array().add(_JsonC_Object().add("value", $value))))
	return $oSelf

EndFunc

Func _CDP_Locator_SendKeys($oSelf, $sText, $iDelay = 0)

	_CDP_SendCommand($oSelf, "DOM.focus", _JsonC_Object().add("objectId", $oSelf.objectId))
	For $i = 1 To StringLen($sText)
        Local $ch = StringMid($sText, $i, 1)
        Local $keyCode = Asc($ch)
		If StringRegExp($ch, "[A-Za-z0-9]") Then
			; letters and digits → keyDown/keyUp
			_CDP_SendCommand($oSelf, "Input.dispatchKeyEvent", _JsonC_Object().add("type", "keyDown").add("key", $ch).add("text", $ch).add("unmodifiedText", $ch).add("windowsVirtualKeyCode", $keyCode).add("nativeVirtualKeyCode", $keyCode))
			_CDP_SendCommand($oSelf, "Input.dispatchKeyEvent", _JsonC_Object().add("type", "keyUp").add("key", $ch).add("text", $ch).add("windowsVirtualKeyCode", $keyCode).add("nativeVirtualKeyCode", $keyCode))
		Else
			; punctuation, unicode → char
			_CDP_SendCommand($oSelf, "Input.dispatchKeyEvent", _JsonC_Object().add("type", "char").add("text", $ch))
		EndIf
        ; Optional delay
        If $iDelay > 0 Then Sleep($iDelay)
    Next
    Return $oSelf

EndFunc

Func _CDP_Locator_Press($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_Check($oSelf)

	If $oSelf.isChecked() Then Return $oSelf
	$oSelf.click()
	Return $oSelf

EndFunc

Func _CDP_Locator_Uncheck($oSelf)

	If $oSelf.isChecked() = False Then Return $oSelf
	$oSelf.click()
	Return $oSelf

EndFunc

Func _CDP_Locator_SetChecked($oSelf, $bState)

	If $oSelf.isChecked() = $bState Then Return $oSelf
	$oSelf.click()
	Return $oSelf

EndFunc

Func _CDP_Locator_SelectOption($oSelf, $value)

	_CDP_Locator_ScrollIntoView($oSelf)
    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", _JsonC_Object().add("objectId", $oSelf.objectId).add("functionDeclaration", "function(value) { const opt = Array.from(this.options).find(o => o.value === value || o.label === value); if (!opt) return false; this.value = opt.value; this.dispatchEvent(new Event('input', { bubbles: true })); this.dispatchEvent(new Event('change', { bubbles: true })); return true; }").add("arguments", _JsonC_Array().add(_JsonC_Object().add("value", $value))).add("returnByValue", True))
	;Return _JsonC_Object($resp).get("result").get("result").get("value").value()
	Return $oSelf

EndFunc

Func _CDP_Locator_Focus($oSelf)

	if $oSelf.nodeId = 0 Then $oSelf.objectToNode()
	_CDP_SendCommand($oSelf, "DOM.focus", _JsonC_Object().add("nodeId", $oSelf.nodeId))

EndFunc

Func _CDP_Locator_Blur($oSelf)

    _CDP_SendCommand($oSelf, "Runtime.callFunctionOn", _JsonC_Object().add("objectId", $oSelf.objectId).add("functionDeclaration", "function() { this.blur(); }"))

EndFunc

Func _CDP_Locator_Clear($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_DragTo($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_SetInputFiles($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_DispatchEvent($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_ScrollIntoView($oSelf)

    _CDP_SendCommand($oSelf, "Runtime.callFunctionOn", _JsonC_Object().add("objectId", $oSelf.objectId).add("functionDeclaration", "function() { this.scrollIntoView({block: 'center', inline: 'center'}); }").add("awaitPromise", True))
	__CDP_Locator_WaitForStableBox($oSelf)
	return $oSelf

EndFunc

Func __CDP_Locator_WaitForStableBox($oSelf, $timeout = 1000)
    Local $lastLeft = -1, $lastTop = -1

    Local $t = TimerInit()
    While TimerDiff($t) < $timeout
        _CDP_Locator_BoundingBox($oSelf)
        If @error Then ContinueLoop ; Return SetError(1,0,False)

		; If position hasn't changed for 2 consecutive checks → stable
        If $oSelf.bboxLeft = $lastLeft And $oSelf.bboxTop = $lastTop Then Return True

        $lastLeft = $oSelf.bboxLeft
        $lastTop  = $oSelf.bboxTop
        Sleep(20)
    WEnd

    Return SetError(2,0,False)
EndFunc





Func _CDP_Locator_ScrollIntoViewIfNeeded($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_TextContent($oSelf)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", _JsonC_Object().add("objectId", $oSelf.objectId).add("functionDeclaration", "function() { return this.textContent; }").add("returnByValue", True))
	Return _JsonC_Object($resp).get("result").get("result").get("value").value()

EndFunc


Func _CDP_Locator_InnerText($oSelf)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", _JsonC_Object().add("objectId", $oSelf.objectId).add("functionDeclaration", "function() { return this.innerText; }").add("returnByValue", True))
    ; Extract the "result.value"
	Local $valueVal = _JsonC_Object($resp).get("result").get("result").get("value").value()
	$oSelf.value = $valueVal
	Return $valueVal

EndFunc

Func _CDP_Locator_InnerTextCRStripped($oSelf)
	$text = _CDP_Locator_InnerText($oSelf)
	Return StringStripCR($text)
EndFunc

Func _CDP_Locator_InnerTextLFStripped($oSelf)
	$text = _CDP_Locator_InnerText($oSelf)
	Return StringReplace($text, @LF, "")
EndFunc

Func _CDP_Locator_InnerTextReplace($oSelf, $searchString, $replaceString)
	$text = _CDP_Locator_InnerText($oSelf)
	Return StringReplace($text, $searchString, $replaceString)
EndFunc

Func _CDP_Locator_InnerHTML($oSelf)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", _JsonC_Object().add("objectId", $oSelf.objectId).add("functionDeclaration", "function() { return this.innerHTML; }").add("returnByValue", True))
    ; Extract the "result.value"
	Return _JsonC_Object($resp).get("result").get("result").get("value").value()

EndFunc

Func _CDP_Locator_InputValue($oSelf)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", _JsonC_Object().add("objectId", $oSelf.objectId).add("functionDeclaration", "function() { return this.value; }").add("returnByValue", True))
    ; Extract the "result.value"
	Return _JsonC_Object($resp).get("result").get("result").get("value").value()

EndFunc

Func _CDP_Locator_GetAttribute($oSelf, $name)

	if $oSelf.nodeId = 0 Then $oSelf.objectToNode()

    Local $resp = _CDP_SendSync($oSelf, "DOM.getAttributes", _JsonC_Object().add("nodeId", $oSelf.nodeId))
	Local $attributesObj = _JsonC_Object($resp).get("result").get("attributes")

	Local $getNextAttribute = False
	For $i = 0 to $attributesObj.count() - 1
		$attributeVal = $attributesObj.at($i).value()
		;if $getNextAttribute = True Then Return ValueObj($attributeVal)
		if $getNextAttribute = True Then Return $attributeVal
		if $attributeVal = $name Then $getNextAttribute = True
	Next

	Return Null
EndFunc

Func _CDP_Locator_BoundingBox($oSelf)

	if $oSelf.nodeId = 0 Then $oSelf.objectToNode()

    ; 3. Get box model
    Local $resp = _CDP_SendSync($oSelf, "DOM.getBoxModel", _JsonC_Object().add("nodeId", $oSelf.nodeId))
	if $resp = Null Then Return SetError(2, 0, "No box model")
	Local $borderObj = _JsonC_Object($resp).get("result").get("model").get("border")
	if $borderObj = Null or IsObj($borderObj) = False then
		$oSelf.nodeId = 0
		Return SetError(2, 0, "No box model")
	EndIf

	Local $left, $right, $top, $bottom, $loop_num = 0
	For $i = 0 to $borderObj.count() - 1
		$eachVal = $borderObj.at($i).value()
		$loop_num = $loop_num + 1
		Switch $loop_num
			Case 1
				$oSelf.bboxLeft = $eachVal
			Case 2
				$oSelf.bboxTop = $eachVal
			Case 5
				$oSelf.bboxRight = $eachVal
			Case 6
				$oSelf.bboxBottom = $eachVal
		EndSwitch
	Next

	$oSelf.bboxWidth = $oSelf.bboxRight - $oSelf.bboxLeft
	$oSelf.bboxHeight = $oSelf.bboxBottom - $oSelf.bboxTop
	$oSelf.bboxCenterX = ($oSelf.bboxLeft + $oSelf.bboxRight) / 2
	$oSelf.bboxCenterY = ($oSelf.bboxTop + $oSelf.bboxBottom) / 2
EndFunc

Func _CDP_Locator_Screenshot($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_Evaluate($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_EvaluateAll($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_ElementHandle($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_AllInnerTexts($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_AllTextContents($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_Count($oSelf)
	; Todo
EndFunc

Func __CDP_Locator_IsVisibleValue($oSelf)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", _JsonC_Object().add("objectId", $oSelf.objectId).add("functionDeclaration", "function() { const r = this.getBoundingClientRect(); return !!(r.width && r.height); }").add("returnByValue", True))
    ; Extract the "result.value"
	Return _JsonC_Object($resp).get("result").get("result").get("value").value()

EndFunc

Func _CDP_Locator_IsVisible($oSelf)
	$val = __CDP_Locator_IsVisibleValue($oSelf) <> 0
	Return $val
EndFunc

Func _CDP_Locator_IsHidden($oSelf)
	$val = Not ( __CDP_Locator_IsVisibleValue($oSelf) <> 0 )
	Return $val
EndFunc

Func __CDP_Locator_IsDisabledValue($oSelf)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", _JsonC_Object().add("objectId", $oSelf.objectId).add("functionDeclaration", "function() { return this.disabled; }").add("returnByValue", True))
	; Convert numeric 0/1 → AutoIt boolean
    Return (_JsonC_Object($resp).get("result").get("result").get("value").value() <> 0)

EndFunc

Func _CDP_Locator_IsEnabled($oSelf)
	Return Not __CDP_Locator_IsDisabledValue($oSelf)
EndFunc

Func _CDP_Locator_IsDisabled($oSelf)
	Return __CDP_Locator_IsDisabledValue($oSelf)
EndFunc

Func _CDP_Locator_IsEditable($oSelf)

    ; Playwright-equivalent logic:
    ; editable = !disabled && !readOnly
    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", _JsonC_Object().add("objectId", $oSelf.objectId).add("functionDeclaration", "function() { return !this.disabled && !this.readOnly; }").add("returnByValue", True))
    ; Convert numeric 0/1 → AutoIt boolean
    Return (_JsonC_Object($resp).get("result").get("result").get("value").value() <> 0)

EndFunc

Func _CDP_Locator_IsChecked($oSelf)

    Local $resp = _CDP_SendSync($oSelf, "Runtime.callFunctionOn", _JsonC_Object().add("objectId", $oSelf.objectId).add("functionDeclaration", "function() { return this.checked; }").add("returnByValue", True))
	; Convert numeric 0/1 → AutoIt boolean
    Return (_JsonC_Object($resp).get("result").get("result").get("value").value() <> 0)

EndFunc

Func _CDP_Locator_WaitFor($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_WaitForElementState($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_WaitForSelector($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_Locator($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_Filter($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_Nth($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_First($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_Last($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_GetByRole($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_GetByText($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_GetByLabel($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_GetByPlaceholder($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_GetByAltText($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_GetByTitle($oSelf)
	; Todo
EndFunc

Func _CDP_Locator_GetByTestId($oSelf)
	; Todo
EndFunc


#endregion


#region --- Test Class ---

Func test($text)

	__CDP_ConsoleWrite("▶ 🧪 " & $text & @CRLF)

	$cdp.state.indentLevel = $cdp.state.indentLevel + 1

	; get the test environment from a release datapool if it exists
	if FileExists(@ScriptDir & "\Data\Pools\Release.csv") Then $g_CDP_TestEnv = testdata("Release", "Test Environment")

	$testResultsPath = @ScriptDir & "\test-results\" & $text
	if Not FileExists($testResultsPath) Then DirCreate($testResultsPath)
	FileDelete($testResultsPath & "\*.*")

    if $cdp.config.video = $CDPVIDEO_ON Then
		$g_CDP_FfmpegHandle = DllOpen("FFMpegRecorder.dll")
		DllCall($g_CDP_FfmpegHandle, "int", "StartRecorder", "int", 1280, "int", 720, "wstr", $testResultsPath & "\video.webm")
		$g_fChromeStartTime = 0
	EndIf

	Local $test = _AutoItObject_Create()
	_AutoItObject_AddProperty($test, "text", $ELSCOPE_READONLY, $text)
	_AutoItObject_AddProperty($test, "timer", $ELSCOPE_READONLY, TimerInit())
	_AutoItObject_AddProperty($test, "environment", $ELSCOPE_READONLY, $g_CDP_TestEnv)
	_AutoItObject_AddDestructor($test, "_CDP_Test_End")
	Return $test

EndFunc

Func testdata($poolName, $recordKey, $testKey = "") ; $fieldName = Default, $keyColumnName = Default)

	Local $data

	if $poolName = "Environment" then
		_SQLite_XSV_Open(@ScriptDir & "\Data\Pools\" & $g_CDP_TestEnv & " - " & $poolName & ".csv")
		$data = _SQLite_XSV_QueryValue("SELECT ""Parameter Value"" FROM data WHERE ""Parameter Name"" = '" & $recordKey & "'")
	ElseIf $poolName = "Release" then
		_SQLite_XSV_Open(@ScriptDir & "\Data\Pools\" & $poolName & ".csv")
		$data = _SQLite_XSV_QueryValue("SELECT ""Parameter Value"" FROM data WHERE ""Parameter Name"" = '" & $recordKey & "'")
	Else
		_SQLite_XSV_Open(@ScriptDir & "\Data\Pools\" & $g_CDP_TestEnv & " - " & $poolName & ".csv")
		$data = _SQLite_XSV_QueryRecord("SELECT * FROM data WHERE ""Comment 1"" = '" & $recordKey & "' AND ""Assigned to"" = '" & $testKey & "'")
	EndIf

	_SQLite_XSV_Close()
	Return $data

EndFunc

Func _CDP_Test_Data_Get($oSelf, $sFieldName)
ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $sFieldName = ' & $sFieldName & @CRLF & '>Error code: ' & @error & @CRLF)
EndFunc

Func teststep($text)

	__CDP_ConsoleWrite(_StringRepeat("  ", $cdp.state.indentLevel) & "▶ 👣 " & $text & @CRLF)

	$cdp.state.indentLevel = $cdp.state.indentLevel + 1

	Local $teststep = _AutoItObject_Create()
	;_AutoItObject_AddProperty($teststep, "text", $ELSCOPE_READONLY, $text)
	_AutoItObject_AddMethod($teststep, "expect", "_CDP_Test_Step_Expect")
	_AutoItObject_AddDestructor($teststep, "_CDP_Test_Step_End")
	Return $teststep

EndFunc

Func _CDP_Test_Step_End($oSelf)
	$cdp.state.indentLevel = $cdp.state.indentLevel - 1
EndFunc

Func _CDP_Test_End($oSelf)

	__CDP_ConsoleWrite("⏱️ Test finished: " & $oSelf.text & " (" & __CDP__FormatDuration(TimerDiff($oSelf.timer)) & ")" & @CRLF)

    if $cdp.config.video = $CDPVIDEO_ON Then
		$videoPath = @ScriptDir & "\test-results\" & $oSelf.text & "\video.webm"
		if FileExists($videoPath) Then __CDP_ConsoleWrite("🎥 Video: " & $videoPath & @CRLF)
	EndIf

	$cdp.state.indentLevel = $cdp.state.indentLevel - 1
EndFunc

Func _CDP_Test_Step_Expect($oSelf, $subject, $text = "")
    Local $obj = _AutoItObject_Create()
    _AutoItObject_AddProperty($obj, "parent", $ELSCOPE_PUBLIC, $oSelf)
    _AutoItObject_AddProperty($obj, "subject", $ELSCOPE_PUBLIC, $subject)
    _AutoItObject_AddProperty($obj, "text", $ELSCOPE_PUBLIC, $text)

	; Add locator-based expect methods
    _AutoItObject_AddMethod($obj, "toBeVisible", "_CDP_Expect_Locator_ToBeVisible")							; done - Uses isVisible()
    _AutoItObject_AddMethod($obj, "toBeHidden", "_CDP_Expect_Locator_ToBeHidden")							; done - Uses isHidden()
    _AutoItObject_AddMethod($obj, "toBeEnabled", "_CDP_Expect_Locator_ToBeEnabled")							; done - Uses isEnabled()
    _AutoItObject_AddMethod($obj, "toBeDisabled", "_CDP_Expect_Locator_ToBeDisabled")						; done - Uses isDisabled()
    _AutoItObject_AddMethod($obj, "toBeChecked", "_CDP_Expect_Locator_ToBeChecked")							; done - Uses isChecked()
    _AutoItObject_AddMethod($obj, "toHaveText", "_CDP_Expect_Locator_ToHaveText")							; done - Uses textContent()
    _AutoItObject_AddMethod($obj, "toContainText", "_CDP_Expect_Locator_ToContainText")						; done - Uses textContent()
    _AutoItObject_AddMethod($obj, "toHaveAttribute", "_CDP_Expect_Locator_ToHaveAttribute")					; done - Uses getAttribute()
    _AutoItObject_AddMethod($obj, "toHaveClass", "_CDP_Expect_Locator_ToHaveClass")							; todo
    _AutoItObject_AddMethod($obj, "toHaveCount", "_CDP_Expect_Locator_ToHaveCount")							; todo - Uses DOM.querySelectorAll
    _AutoItObject_AddMethod($obj, "toHaveValue", "_CDP_Expect_Locator_ToHaveValue")							; todo
    _AutoItObject_AddMethod($obj, "toHaveJSProperty", "_CDP_Expect_Locator_ToHaveJSProperty")				; todo

	; Add value-based expect methods
	_AutoItObject_AddMethod($obj, "toBe", "_CDP_Expect_Value_ToBe")											; done
	_AutoItObject_AddMethod($obj, "toEqual", "_CDP_Expect_Value_ToEqual")									; todo
	_AutoItObject_AddMethod($obj, "toStrictEqual", "_CDP_Expect_Value_ToStrictEqual")						; todo
	_AutoItObject_AddMethod($obj, "toBeGreaterThan", "_CDP_Expect_Value_ToBeGreaterThan")					; done
	_AutoItObject_AddMethod($obj, "toBeGreaterThanOrEqual", "_CDP_Expect_Value_ToBeGreaterThanOrEqual")		; done
	_AutoItObject_AddMethod($obj, "toBeLessThan", "_CDP_Expect_Value_ToBeLessThan")							; done
	_AutoItObject_AddMethod($obj, "toBeLessThanOrEqual", "_CDP_Expect_Value_ToBeLessThanOrEqual")			; done
	_AutoItObject_AddMethod($obj, "toBeCloseTo", "_CDP_Expect_Value_ToBeCloseTo")							; done - untested
    _AutoItObject_AddMethod($obj, "toContain", "_CDP_Expect_Value_ToContain")								; done
	_AutoItObject_AddMethod($obj, "toMatch", "_CDP_Expect_Value_ToMatch")									; done
	_AutoItObject_AddMethod($obj, "toBeTruthy", "_CDP_Expect_Value_ToBeTruthy")								; done
	_AutoItObject_AddMethod($obj, "toBeFalsy", "_CDP_Expect_Value_ToBeFalsy")								; done
	_AutoItObject_AddMethod($obj, "toBeNull", "_CDP_Expect_Value_ToBeNull")									; done
	_AutoItObject_AddMethod($obj, "toBeDefined", "_CDP_Expect_Value_ToBeDefined")							; done
	_AutoItObject_AddMethod($obj, "toBeUndefined", "_CDP_Expect_Value_ToBeUndefined")						; done - untested
	_AutoItObject_AddMethod($obj, "toContainEqual", "_CDP_Expect_Value_ToContainEqual")						; todo
	_AutoItObject_AddMethod($obj, "toHaveLength", "_CDP_Expect_Value_ToHaveLength")							; done
	_AutoItObject_AddMethod($obj, "toThrow", "_CDP_Expect_Value_ToThrow")									; todo

    ; add more assertion methods here
    Return $obj
EndFunc


Func _CDP_Test_Step_Expect_Msg($indent, $pass, $text, $lineNumber = "")
	$result = "▶ ✓"
	if $pass = False Then $result = "▶ ✗"
	if $lineNumber <> "" Then $lineNumber = " (line " & $lineNumber & ")"

   	__CDP_ConsoleWrite($indent & $result & " Expect " & StringStripWS($text, 1) & $lineNumber & @CRLF)
EndFunc


Func _CDP_Expect_Locator_ToBeVisible($oSelf, $scriptLineNumber = "")

	if $oSelf.text = "" Then $oSelf.text = "object"
	if _CDP_Locator_IsVisible($oSelf.subject) = True Then
		_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), True, $oSelf.text & " [" & $oSelf.subject.objectId & "] to be visible", $scriptLineNumber)
		Return True
    EndIf
	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), False, $oSelf.text & " [" & $oSelf.subject.objectId & "] is not visible", $scriptLineNumber)
    Return False

EndFunc

Func _CDP_Expect_Locator_ToBeHidden($oSelf, $scriptLineNumber = "")

	if $oSelf.text = "" Then $oSelf.text = "object"
	if _CDP_Locator_IsHidden($oSelf.subject) = True Then
		_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), True, $oSelf.text & " [" & $oSelf.subject.objectId & "] to be hidden", $scriptLineNumber)
		Return True
    EndIf
	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), False, $oSelf.text & " [" & $oSelf.subject.objectId & "] to be hidden", $scriptLineNumber)
    Return False

EndFunc

Func _CDP_Expect_Locator_ToBeEnabled($oSelf, $scriptLineNumber = "")

	if $oSelf.text = "" Then $oSelf.text = "object"
	if _CDP_Locator_IsEnabled($oSelf.subject) = True Then
		_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), True, $oSelf.text & " [" & $oSelf.subject.objectId & "] is enabled", $scriptLineNumber)
		Return True
    EndIf
	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), False, $oSelf.text & " [" & $oSelf.subject.objectId & "] is not enabled", $scriptLineNumber)
    Return False

EndFunc

Func _CDP_Expect_Locator_ToBeDisabled($oSelf, $scriptLineNumber = "")

	if $oSelf.text = "" Then $oSelf.text = "object"
	if _CDP_Locator_IsDisabled($oSelf.subject) = True Then
		_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), True, $oSelf.text & " [" & $oSelf.subject.objectId & "] is disabled", $scriptLineNumber)
		Return True
    EndIf
	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), False, $oSelf.text & " [" & $oSelf.subject.objectId & "] is not disabled", $scriptLineNumber)
    Return False

EndFunc

Func _CDP_Expect_Locator_ToBeChecked($oSelf, $scriptLineNumber = "")

	if $oSelf.text = "" Then $oSelf.text = "object"
	if _CDP_Locator_IsChecked($oSelf.subject) = True Then
		_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), True, $oSelf.text & " [" & $oSelf.subject.objectId & "] is checked", $scriptLineNumber)
		Return True
    EndIf
	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), False, $oSelf.text & " [" & $oSelf.subject.objectId & "] is not checked", $scriptLineNumber)
    Return False

EndFunc

Func _CDP_Expect_Locator_ToHaveText($oSelf, $expected, $sLine = "")

	;if $oSelf.text = "" Then $oSelf.text = ""
	Local $actual = _CDP_Locator_TextContent($oSelf.subject)
	If _CDP_NormalizeText($actual) = _CDP_NormalizeText($expected) Then
		_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), True, $oSelf.text & " to have [" & $expected & "]", $sLine)
		Return True
    EndIf
	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), False, $oSelf.text & " to have [" & $expected & "] but got [" & $actual & "]", $sLine)
    Return False
EndFunc

Func _CDP_Expect_Locator_ToContainText($oSelf, $expected, $scriptLineNumber = "")

	;if $oSelf.text = "" Then $oSelf.text = ""
	Local $actual = _CDP_Locator_TextContent($oSelf.subject)
	If StringInStr($actual, $expected) > 0 Then
		_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), True, $oSelf.text & " to contain [" & $expected & "]", $scriptLineNumber)
        Return True
    EndIf
	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), False, $oSelf.text & " to contain [" & $expected & "] but got [" & $actual & "]", $scriptLineNumber)
    Return False
EndFunc

Func _CDP_Expect_Locator_ToHaveAttribute($oSelf, $name, $expectedValue, $scriptLineNumber = "")

	Local $actualValue = _CDP_Locator_GetAttribute($oSelf.subject, $name)
	If $actualValue = $expectedValue Then
		_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), True, $oSelf.text & " to have attribute [" & $name & "] with value [" & $expectedValue & "]", $scriptLineNumber)
        Return True
    EndIf
	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), False, $oSelf.text & " to have attribute [" & $name & "] with value [" & $expectedValue & "]", $scriptLineNumber)
    Return False
EndFunc

Func _CDP_Expect_Locator_ToHaveValue($oSelf, $expected, $scriptLineNumber = "")
	; todo
EndFunc

Func _CDP_Expect_Locator_ToHaveCount($oSelf, $expected, $scriptLineNumber = "")
	; todo
EndFunc

Func _CDP_Expect_Value_ToBe($oSelf, $expected, $line = "")

    Local $actual = $oSelf.subject
	If $actual = $expected Then
    	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), True, $oSelf.text & " to be [" & $expected & "]", $line)
        Return True
    EndIf
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), False, $oSelf.text & " to be [" & $expected & "] but got [" & $actual & "]", $line)
    Return False
EndFunc

Func _CDP_Expect_Value_ToEqual($oSelf, $expected, $scriptLineNumber = "")

	; todo

	;	AutoIt has no deep‑equal, so we should serialize to JSON. for example ...
	;Local $actual = $oSelf.subject
    ;Local $a = Json_Encode($actual)
    ;Local $b = Json_Encode($expected)
    ;Local $pass = ($a = $b)
EndFunc

Func _CDP_Expect_Value_ToStrictEqual($oSelf, $expected, $scriptLineNumber = "")
	; todo - same as _CDP_Expect_Value_ToEqual above
EndFunc

Func _CDP_Expect_Value_ToBeGreaterThan($oSelf, $expected, $line = "")
	;if $oSelf.text = "" Then $oSelf.text = ""
    Local $actual = $oSelf.subject
    Local $pass = (Number($actual) > Number($expected))
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " [" & $actual & "] to be greater than [" & $expected & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeGreaterThanOrEqual($oSelf, $expected, $line = "")
    Local $actual = $oSelf.subject
    Local $pass = (Number($actual) >= Number($expected))
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " [" & $actual & "] to be greater than or equal to [" & $expected & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeLessThan($oSelf, $expected, $line = "")
    Local $actual = $oSelf.subject
    Local $pass = (Number($actual) < Number($expected))
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " [" & $actual & "] to be less than [" & $expected & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeLessThanOrEqual($oSelf, $expected, $line = "")
    Local $actual = $oSelf.subject
    Local $pass = (Number($actual) <= Number($expected))
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " [" & $actual & "] to be less than or equal to [" & $expected & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeCloseTo($oSelf, $expected, $precision = 2, $line = "")
    Local $actual = $oSelf.subject
    Local $delta = Abs($actual - $expected)
    Local $pass = ($delta <= (10 ^ -$precision))
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " [" & $expected & "] to be close to [" & $actual & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToContain($oSelf, $expected, $line = "")
    Local $actual = $oSelf.subject
    Local $pass = False

    If IsString($actual) Then
        $pass = StringInStr($actual, $expected) > 0
    ElseIf IsArray($actual) Then
        For $i = 0 To UBound($actual) - 1
            If $actual[$i] = $expected Then
                $pass = True
                ExitLoop
            EndIf
        Next
    EndIf

	if $pass Then
    	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " to contain [" & $expected & "]", $line)
	Else
    	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " [" & $actual & "] to contain [" & $expected & "]", $line)
	EndIf

    Return $pass
EndFunc

Func _CDP_Expect_Value_ToMatch($oSelf, $pattern, $line = "")
    Local $actual = $oSelf.subject
    Local $pass = StringRegExp($actual, $pattern)
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " [" & $actual & "] to match regex [" & $pattern & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeTruthy($oSelf, $line = "")
    Local $actual = $oSelf.subject
    ; AutoIt truthiness: anything non-zero is True
    Local $pass = ($actual <> 0)

	if $pass Then
    	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " to be truthy", $line)
	Else
    	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " to be truthy and got [" & $actual & "]", $line)
	EndIf

    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeFalsy($oSelf, $line = "")
    Local $actual = $oSelf.subject
    ; AutoIt falsiness: only 0 is False
    Local $pass = ($actual = 0)

	if $pass Then
	    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " to be falsy", $line)
	Else
	    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " to be falsy and got [" & $actual & "]", $line)
	EndIf

    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeNull($oSelf, $line = "")
    Local $actual = $oSelf.subject
    Local $pass = ($actual = Null)
	if $actual = Null then $actual = "Null"

	if $pass Then
    	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " to be Null", $line)
	Else
    	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " to be Null but got [" & $actual & "]", $line)
	EndIf

    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeDefined($oSelf, $line = "?")
    Local $actual = $oSelf.subject
    Local $pass = Not ($actual = Default)
	$actual = "defined"
	if $pass = False then $actual = "undefined"

	if $pass Then
    	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " to be defined", $line)
	Else
    	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " to be defined and got [" & $actual & "]", $line)
	EndIf

    Return $pass
EndFunc

Func _CDP_Expect_Value_ToBeUndefined($oSelf, $line = "?")
    Local $actual = $oSelf.subject
    Local $pass = ($actual = Default)
	$actual = "undefined"
	if $pass = False then $actual = "defined"
    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " to be undefined and got [" & $actual & "]", $line)
    Return $pass
EndFunc

Func _CDP_Expect_Value_ToContainEqual($oSelf, $expected, $scriptLineNumber = "")

	; todo
	#cs
    Local $actual = $oSelf.subject
    Local $pass = False

    If IsArray($actual) Then
        Local $expectedJson = Json_Encode($expected)
        For $i = 0 To UBound($actual) - 1
            If Json_Encode($actual[$i]) = $expectedJson Then
                $pass = True
                ExitLoop
            EndIf
        Next
    EndIf

    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, "expected array to contain deep-equal [" & Json_Encode($expected) & "]", $line)

    Return $pass
	#ce
EndFunc

Func _CDP_Expect_Value_ToHaveLength($oSelf, $expected, $line = "")
    Local $actual = $oSelf.subject
    Local $len = 0

    If IsString($actual) Then
        $len = StringLen($actual)
    ElseIf IsArray($actual) Then
        $len = UBound($actual)
    EndIf

    Local $pass = ($len = $expected)

	if $pass Then
    	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " to have length [" & $expected & "]", $line)
	Else
    	_CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, $oSelf.text & " to have length [" & $expected & "] but got [" & $len & "]", $line)
	EndIf

    Return $pass
EndFunc

Func _CDP_Expect_Value_ToThrow($oSelf, $expected, $scriptLineNumber = "")

	; todo

	#cs
    Local $fn = $oSelf.subject
    Local $pass = False

    If IsFunc($fn) Then
        Local $err = 0
        Local $result = ""
        $result = Execute("TryReturn(" & $fn & "())")
        $err = @error
        $pass = ($err <> 0)
    EndIf

    _CDP_Test_Step_Expect_Msg(_StringRepeat("  ", $cdp.state.indentLevel), $pass, _
        "expected function to throw", $line)

    Return $pass
	#ce

EndFunc


#endregion



#region --- Utilities ---

; String helpers
; JSON helpers
; Debug helpers

Func _CDP_NormalizeText($s)
    ; Normalize line endings
    $s = StringReplace($s, @CRLF, @LF)
    $s = StringReplace($s, @CR, @LF)

    ; Normalize NBSP to space
    $s = StringReplace($s, Chr(0xA0), " ")

    ; Remove zero-width characters
    $s = StringRegExpReplace($s, "[\x{200B}\x{200C}\x{200D}\x{FEFF}]", "")

    ; Trim trailing LF
    While StringRight($s, 1) = @LF
        $s = StringTrimRight($s, 1)
    WEnd

    Return $s
EndFunc

Func _CDP_Downloads_DeleteFile($fileMask)
	FileDelete(@UserProfileDir & "\Downloads\" & $fileMask)
EndFunc

Func _CDP_Downloads_WaitForFile($filename, $timeoutMs = 10000)
    Local $end = TimerInit()
    While Not FileExists(@UserProfileDir & "\Downloads\" & $filename)
        Sleep(50)
        If TimerDiff($end) > $timeoutMs Then Return False
    WEnd
    Return True
EndFunc

Func WaitForFile($path, $timeoutMs = 5000)
    Local $end = TimerInit()
    While Not FileExists($path)
        Sleep(50)
        If TimerDiff($end) > $timeoutMs Then Return False
    WEnd
    Return True
EndFunc

Func __CDP_ResolveBrowserSpecifier($browser)

    ; Split "chrome@119" into ["chrome", "119"]
    Local $arr = StringSplit($browser, "@", $STR_NOCOUNT)
    If @error Or UBound($arr) < 2 Then
        Return SetError(1, 0, $browser)
    EndIf

    Local $browserType = $arr[0]
    Local $browserVersion = $arr[1]

    ; Build Selenium Manager command
    Local $cmd = 'selenium-manager.exe --browser ' & $browserType & ' --browser-version ' & $browserVersion & ' --cache-path .'

    ; Run Selenium Manager and capture output
	ConsoleWrite(_StringRepeat("  ", $cdp.state.indentLevel) & '▶ 🔧 Locating ' & $browserType & ' version ' & $browserVersion & ' (this may take a moment if it needs to download)' & @CRLF)

    if $cdp.config.infoPopups = True Then ControlSetText("AutoIt CDP", "", "Static1", 'Locating ' & $browserType & ' version ' & $browserVersion & ' ...' & @CRLF & '(this may take a moment if it needs to download)')
	Local $output = __CDP_RunCmdCapture($cmd)
    If @error Then Return SetError(2, 0, "")

    ; Extract the "Browser path:" line
    Local $browserPath = __CDP_ExtractBrowserPath($output)
    If @error Then Return SetError(3, 0, "")

    Return $browserPath
EndFunc


; Helper: run a command and capture stdout
Func __CDP_RunCmdCapture($cmd)
    Local $pid = Run(@ComSpec & " /c " & $cmd, "", @SW_HIDE, $RUN_CREATE_NEW_CONSOLE + $STDERR_MERGED + $STDOUT_CHILD)
    If $pid = 0 Then Return SetError(1, 0, "")
	ProcessWaitClose($pid)
	Return StdoutRead($pid)
EndFunc


; Helper: extract the browser path from Selenium Manager output
Func __CDP_ExtractBrowserPath($text)
    Local $lines = StringSplit($text, @LF, $STR_ENTIRESPLIT)
    For $i = 1 To $lines[0]
        If StringInStr($lines[$i], "Browser path:") Then
            ; Extract everything after the colon
            Local $path = StringStripWS(StringTrimLeft($lines[$i], StringInStr($lines[$i], ":") ), $STR_STRIPALL)
            Return $path
        EndIf
    Next

    Return SetError(1, 0, "")
EndFunc

Func ErrFunc($oError)
	ConsoleWrite("!>COM Error !"&@CRLF&"!>"&@TAB&"Number: "&Hex($oError.Number,8)&@CRLF&"!>"&@TAB&"Windescription: "&StringRegExpReplace($oError.windescription,"\R$","")&@CRLF&"!>"&@TAB&"Source: "&$oError.source&@CRLF&"!>"&@TAB&"Description: "&$oError.description&@CRLF&"!>"&@TAB&"Helpfile: "&$oError.helpfile&@CRLF&"!>"&@TAB&"Helpcontext: "&$oError.helpcontext&@CRLF&"!>"&@TAB&"Lastdllerror: "&$oError.lastdllerror&@CRLF&"!>"&@TAB&"Scriptline: "&$oError.scriptline&@CRLF)
EndFunc   ;==>ErrFunc

Func __CDP_Base64Decode($input_string)

    Local $struct = DllStructCreate("int")

    Local $a_Call = DllCall("Crypt32.dll", "int", "CryptStringToBinary", _
            "str", $input_string, _
            "int", 0, _
            "int", 1, _
            "ptr", 0, _
            "ptr", DllStructGetPtr($struct, 1), _
            "ptr", 0, _
            "ptr", 0)

    If @error Or Not $a_Call[0] Then
        Return SetError(1, 0, "") ; error calculating the length of the buffer needed
    EndIf

    Local $a = DllStructCreate("byte[" & DllStructGetData($struct, 1) & "]")

    $a_Call = DllCall("Crypt32.dll", "int", "CryptStringToBinary", _
            "str", $input_string, _
            "int", 0, _
            "int", 1, _
            "ptr", DllStructGetPtr($a), _
            "ptr", DllStructGetPtr($struct, 1), _
            "ptr", 0, _
            "ptr", 0)

    If @error Or Not $a_Call[0] Then
        Return SetError(2, 0, ""); error decoding
    EndIf

    Return DllStructGetData($a, 1)

EndFunc

Func __CDP_ConsoleWrite($sText)
    if $cdp.config.enterpriseMode = False Then
		__CDP_ConsoleWriteUTF8($sText)
	Else
		__CDP_ConsoleWriteUTF8Enterprise($sText)
	EndIf
EndFunc

Func __CDP_ConsoleWriteUTF8($sText)
	; ChrW(0x200B) enforces unicode fallback fonts in windows console
	ConsoleWrite(BinaryToString(StringToBinary(ChrW(0x200B) & $sText, 4), 1))
EndFunc

Func __CDP_ConsoleWriteUTF8Enterprise($sText)
	if $cdp.config.enterpriseMode = True Then __CDP_ConsoleWriteUTF8(StringFormat("[%i-%02i-%02i %02i꞉%02i꞉%02i.%03i] %s", @YEAR, @MON, @MDAY, @HOUR, @MIN, @SEC, @MSEC, $sText))
EndFunc

Func __CDP__FormatDuration($ms)
    If $ms < 1000 Then Return $ms & " ms"

    Local $sec = $ms / 1000
    If $sec < 60 Then Return Round($sec, 1) & " s"

    Local $min = Int($sec / 60)
    Local $rem = Round(Mod($sec, 60), 1)
    If $min < 60 Then Return $min & "m " & $rem & "s"

    Local $hr = Int($min / 60)
    Local $minRem = Mod($min, 60)
    Return $hr & "h " & $minRem & "m " & Int($rem) & "s"
EndFunc

; Override for __Au3Obj_FunctionProxy from AutoItObject.au3
Func __Au3Obj_FunctionProxy($FuncName, $oSelf) ; allows binary code to call autoit functions
	Local $arg = $oSelf.__params__ ; fetch params

	Local $testLogIndex = _ArraySearch($arg, " called <AutoItObject $FuncName> ", 0, 0, 1, 1)
	if $testLogIndex > -1 Then
		__CDP_ConsoleWriteUTF8Enterprise(_StringRepeat("  ", $cdp.state.indentLevel) & "▶ 🔧 " & StringReplace($arg[$testLogIndex], "<AutoItObject $FuncName>", $FuncName) & @CRLF)
		_ArrayDelete($arg, $testLogIndex)
	EndIf

	If IsArray($arg) Then
		Local $ret = Call($FuncName, $arg) ; Call
		If @error = 0xDEAD And @extended = 0xBEEF Then Return 0
		$oSelf.__error__ = @error ; set error
		$oSelf.__result__ = $ret ; set result
		Return 1
	EndIf
	; return error when params-array could not be created
EndFunc   ;==>__Au3Obj_FunctionProxy

#endregion

