#include-once

; #INDEX# =======================================================================================================================
; Title .........: CDPReport
; Description ...: Standalone, self-contained HTML test report for the CDP UDF.
;                 One file per test in test-results\<test name>\report.html. Left panel = nested accordion of test step
;                 names (built by JS from flat records); right panel = the selected step's ordered detail
;                 (text lines + images, appended in call order via teststepinfo()..teststepfail() / teststepimage()).
;                 Written realtime in append mode; tolerant of an abruptly-terminated (unclosed) HTML file.
; Author(s) .....: Sean Griffin
; ===============================================================================================================================

; #VARIABLES# ===================================================================================================================
Global $g_CDP_ReportFile = -1                  ; open file handle, or -1 when no report is active
Global $g_CDP_ReportStepId = 0                 ; monotonic step id
Global $g_CDP_ReportStack[256]                 ; stack of currently-open step ids (for parent resolution)
Global $g_CDP_ReportDetail[256]                ; per-open-step ordered detail HTML (text + image items, in call order)
Global $g_CDP_ReportImgSeq = 0                 ; monotonic image counter (external-image filenames)
Global $g_CDP_ReportStackTop = -1
Global $g_CDP_ReportActivePage = Null          ; most-recently-created page object; source for step-end screenshots
Global $g_CDP_ReportDir = ""                   ; the test-results\<test name> folder
Global $g_CDP_ReportEmbedImages = True         ; True = base64 in the HTML (single portable file);
                                               ; False = external PNGs in <dir>\steps\ (scales to huge step counts)
; ===============================================================================================================================

; Begin a report for a test. Opens (erasing) <dir>\report.html and writes the head + panel scaffold.
Func __CDP_Report_Begin($sDir, $sName)
    $g_CDP_ReportDir = $sDir
    $g_CDP_ReportStepId = 0
    $g_CDP_ReportStackTop = -1

    Local $sPath = $sDir & "\" & $sName & " test run.html"
    ; mode 2 = erase+write, 128 = UTF8 no BOM. Handle kept open; later FileWrite calls append.
    $g_CDP_ReportFile = FileOpen($sPath, 2 + 128)
    If $g_CDP_ReportFile = -1 Then Return SetError(1, 0, False)

    If Not $g_CDP_ReportEmbedImages Then DirCreate($sDir & "\steps")

    FileWrite($g_CDP_ReportFile, __CDP_Report_HtmlHead(__CDP_Report_HtmlEscape($sName)))
    FileFlush($g_CDP_ReportFile)
    Return True
EndFunc

; Called when a test step begins. Assigns an id, records its parent (current top of stack), pushes it.
; Returns a 2-element array [id, parentId] so the step object can carry them to step-end.
Func __CDP_Report_StepBegin($sName)
    #forceref $sName
    Local $aRet[2] = [0, 0]
    If $g_CDP_ReportFile = -1 Then Return $aRet

    $g_CDP_ReportStepId += 1
    $aRet[0] = $g_CDP_ReportStepId
    $aRet[1] = ($g_CDP_ReportStackTop >= 0) ? $g_CDP_ReportStack[$g_CDP_ReportStackTop] : 0

    $g_CDP_ReportStackTop += 1
    If $g_CDP_ReportStackTop <= UBound($g_CDP_ReportStack) - 1 Then $g_CDP_ReportStack[$g_CDP_ReportStackTop] = $aRet[0]
    Return $aRet
EndFunc

; Called when a test step ends. Appends one flat record carrying the step's ordered detail
; (the text + image items appended during the step via teststepinfo()..teststepfail() / teststepimage()).
Func __CDP_Report_StepEnd($iId, $iParent, $sName)
    If $g_CDP_ReportFile = -1 Then Return

    Local $sDetail = ""
    If $g_CDP_ReportStackTop >= 0 Then $sDetail = $g_CDP_ReportDetail[$g_CDP_ReportStackTop]

    ; One self-contained record. <div class="d"> holds the ordered detail items, shown in the
    ; detail panel when the step is selected.
    FileWrite($g_CDP_ReportFile, _
        '<div class="step" data-id="' & $iId & '" data-parent="' & $iParent & '">' & _
        '<b>' & __CDP_Report_HtmlEscape($sName) & '</b>' & _
        '<div class="d">' & $sDetail & '</div></div>' & @CRLF)
    FileFlush($g_CDP_ReportFile)

    If $g_CDP_ReportStackTop >= 0 Then
        $g_CDP_ReportDetail[$g_CDP_ReportStackTop] = ""   ; clear the buffer as the step unwinds
        $g_CDP_ReportStackTop -= 1
    EndIf
EndFunc

; Append an IMAGE item to the current step's ordered detail. $vB64 = Default captures the active
; page now (full-page PNG); otherwise it's a pre-captured base64 image (element screenshot or any
; format). The format is auto-detected so the data URI / file extension is correct. Multiple calls
; append in order. Called by the public teststepimage(); works from any depth inside a teststep block.
Func __CDP_Report_Image($vB64 = Default)
    If $g_CDP_ReportFile = -1 Or $g_CDP_ReportStackTop < 0 Then Return
    If $vB64 = Default Then $vB64 = __CDP_Report_CaptureBase64()
    If $vB64 = "" Then Return

    Local $sMime = __CDP_Report_ImageMime($vB64)
    Local $sSrc
    If $g_CDP_ReportEmbedImages Then
        $sSrc = "data:" & $sMime & ";base64," & $vB64          ; inline (single portable file)
    Else
        $g_CDP_ReportImgSeq += 1
        Local $sRel = "steps\img_" & $g_CDP_ReportImgSeq & "." & __CDP_Report_ImageExt($sMime)
        Local $hImg = FileOpen($g_CDP_ReportDir & "\" & $sRel, 18) ; 18 = binary+erase
        If $hImg = -1 Then Return
        FileWrite($hImg, __CDP_Base64Decode($vB64))
        FileClose($hImg)
        $sSrc = StringReplace($sRel, "\", "/")                 ; external file reference
    EndIf

    ; data-src (not src) so images in the hidden #data block don't all load at once; the JS
    ; hydrates only the selected step's images on select.
    $g_CDP_ReportDetail[$g_CDP_ReportStackTop] &= '<img class="shot" data-src="' & $sSrc & '">'
EndFunc

; Append a TEXT item to the current step's ordered detail. $sLevel = info|warn|error|pass|fail
; (default info) drives the colour. Multiple calls append in order. Called by the teststep<level>() functions.
Func __CDP_Report_Text($sMessage, $sLevel = "info")
    If $g_CDP_ReportFile = -1 Or $g_CDP_ReportStackTop < 0 Then Return
    Switch StringLower($sLevel)
        Case "info", "warn", "error", "pass", "fail"
            $sLevel = StringLower($sLevel)
        Case Else
            $sLevel = "info"
    EndSwitch
    $g_CDP_ReportDetail[$g_CDP_ReportStackTop] &= '<div class="msg lvl-' & $sLevel & '">' & __CDP_Report_HtmlEscape($sMessage) & '</div>'
EndFunc

; Detect an image's MIME type from the leading base64 characters (magic bytes). Defaults to PNG
; (CDP screenshots are PNG). Handles PNG/JPEG/GIF/ICO/WEBP/BMP.
Func __CDP_Report_ImageMime($sB64)
    If StringLeft($sB64, 11) = "iVBORw0KGgo" Then Return "image/png"
    If StringLeft($sB64, 4)  = "/9j/"        Then Return "image/jpeg"
    If StringLeft($sB64, 6)  = "R0lGOD"      Then Return "image/gif"
    If StringLeft($sB64, 6)  = "AAABAA"      Then Return "image/x-icon"
    If StringLeft($sB64, 5)  = "UklGR"       Then Return "image/webp"
    If StringLeft($sB64, 2)  = "Qk"          Then Return "image/bmp"
    Return "image/png"
EndFunc

Func __CDP_Report_ImageExt($sMime)
    Switch $sMime
        Case "image/jpeg"
            Return "jpg"
        Case "image/gif"
            Return "gif"
        Case "image/x-icon"
            Return "ico"
        Case "image/webp"
            Return "webp"
        Case "image/bmp"
            Return "bmp"
        Case Else
            Return "png"
    EndSwitch
EndFunc

; End the report (writes the closing tags and closes the handle). Safe to never be called (browser tolerates it).
Func __CDP_Report_End()
    If $g_CDP_ReportFile = -1 Then Return
    FileWrite($g_CDP_ReportFile, '</div></body></html>')
    FileClose($g_CDP_ReportFile)
    $g_CDP_ReportFile = -1
EndFunc

; Capture the active page as a base64 PNG, directly from CDP (no file round-trip). Returns "" on failure.
Func __CDP_Report_CaptureBase64()
    If Not IsObj($g_CDP_ReportActivePage) Then Return ""
    Local $resp = _CDP_SendSync($g_CDP_ReportActivePage, "Page.captureScreenshot", _
        _JsonC_Object().add("format", "png").add("captureBeyondViewport", True))
    If @error Then Return ""
    Local $data = _JsonC_Object($resp).get("result").get("data").value()
    If @error Then Return ""
    Return $data
EndFunc

Func __CDP_Report_HtmlEscape($s)
    $s = StringReplace($s, "&", "&amp;")
    $s = StringReplace($s, "<", "&lt;")
    $s = StringReplace($s, ">", "&gt;")
    Return $s
EndFunc

; The document head: CSS + tree-building JS (runs on DOMContentLoaded so an unclosed file still renders),
; then the two panels and the (display:none) data container that records are appended into.
Func __CDP_Report_HtmlHead($sTitle)
    Local $s = '<!doctype html><html><head><meta charset="utf-8"><title>' & $sTitle & '</title>'
    $s &= '<style>' & _
        '*{box-sizing:border-box}' & _
        'body{margin:0;font-family:Segoe UI,Arial,sans-serif;font-size:13px;display:flex;flex-direction:column;height:100vh;color:#222}' & _
        '#hdr{flex:none;padding:5px 10px;font-size:14px;font-weight:600;background:#f5f5f5;border-bottom:1px solid #ccc;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}' & _
        '#main{flex:1;display:flex;min-height:0;min-width:0}' & _
        '#nav{flex:none;width:320px;min-width:120px;overflow:auto;padding:6px;outline:none}' & _
        '#split{flex:none;width:6px;cursor:col-resize;background:#ddd}' & _
        '#split:hover{background:#bbb}' & _
        '#detail{flex:1;min-width:0;overflow:auto;background:#fff;padding:10px}' & _
        '#detail img{max-width:100%;height:auto;box-shadow:0 0 8px rgba(0,0,0,.5);display:block;margin:6px 0}' & _
        '.msg{position:relative;padding:3px 8px 3px 30px;margin:2px 0;white-space:pre-wrap;font-family:Consolas,Courier New,monospace;font-size:12px}' & _
        '.msg::before{position:absolute;left:7px;top:3px;width:16px;height:16px;border-radius:50%;color:#fff;font-size:11px;font-weight:bold;line-height:16px;text-align:center;font-family:Arial,sans-serif}' & _
        '.lvl-info::before{content:"i";background:#5b9bd5}' & _
        '.lvl-warn::before{content:"!";background:#e0a000}' & _
        '.lvl-error::before{content:"\002715";background:#c0392b}' & _
        '.lvl-pass::before{content:"\002713";background:#2e7d32}' & _
        '.lvl-fail::before{content:"\002715";background:#c0392b}' & _
        '.node{margin:1px 0}' & _
        '.row{display:flex;align-items:center;gap:4px;padding:2px 4px;border-radius:3px;cursor:pointer;white-space:nowrap}' & _
        '.row:hover{background:#eef}' & _
        '.row.sel{background:#3a6ea5;color:#fff}' & _
        '.tog{width:14px;text-align:center;color:#888;font-size:10px;flex:none}' & _
        '.row.sel .tog{color:#dde}' & _
        '.kids{margin-left:14px;border-left:1px dotted #ccc;padding-left:4px}' & _
        '</style>'
    $s &= '<script>document.addEventListener("DOMContentLoaded",function(){' & _
        'var steps=[].slice.call(document.querySelectorAll("#data .step"));' & _
        'var byId={},roots=[];' & _
        'steps.forEach(function(el){var id=el.getAttribute("data-id");' & _
        'byId[id]={id:id,pid:el.getAttribute("data-parent"),' & _
        'name:(el.querySelector("b")||{}).textContent||"",detailEl:el.querySelector(".d"),kids:[]};});' & _
        'steps.forEach(function(el){var id=el.getAttribute("data-id"),n=byId[id];' & _
        'if(n.pid&&n.pid!=="0"&&byId[n.pid])byId[n.pid].kids.push(n);else roots.push(n);});' & _
        'var nav=document.getElementById("nav"),detail=document.getElementById("detail"),cur=null;' & _
        'function expanded(n){return n.kids.length&&n.__kids.style.display!=="none";}' & _
        'function expand(n){if(n.kids.length){n.__kids.style.display="block";n.__tog.textContent="▼";}}' & _
        'function collapse(n){if(n.kids.length){n.__kids.style.display="none";n.__tog.textContent="▶";}}' & _
        'function select(n){cur=n;' & _
        'document.querySelectorAll("#nav .row.sel").forEach(function(r){r.classList.remove("sel")});' & _
        'n.__row.classList.add("sel");' & _
        'detail.innerHTML=n.detailEl?n.detailEl.innerHTML:"";' & _
        '[].forEach.call(detail.querySelectorAll("img[data-src]"),function(im){im.src=im.getAttribute("data-src");});' & _
        'n.__row.scrollIntoView({block:"nearest"});}' & _
        'function vis(){return [].slice.call(nav.querySelectorAll(".row")).filter(function(r){return r.offsetParent!==null;});}' & _
        'function moveVisible(dir){var rows=vis(),i=rows.indexOf(cur.__row),j=i+dir;if(j>=0&&j<rows.length)select(rows[j].__node);}' & _
        'function render(n,box,parent){var d=document.createElement("div");d.className="node";' & _
        'var row=document.createElement("div");row.className="row";n.__row=row;row.__node=n;n.__parent=parent;' & _
        'var tog=document.createElement("span");tog.className="tog";tog.textContent=n.kids.length?"▶":"•";n.__tog=tog;' & _
        'var nm=document.createElement("span");nm.className="nm";nm.textContent=n.name;' & _
        'row.appendChild(tog);row.appendChild(nm);d.appendChild(row);' & _
        'var kb=document.createElement("div");kb.className="kids";kb.style.display="none";n.__kids=kb;' & _
        'n.kids.forEach(function(k){render(k,kb,n)});d.appendChild(kb);' & _
        'if(n.kids.length)tog.onclick=function(e){e.stopPropagation();expanded(n)?collapse(n):expand(n);};' & _
        'row.onclick=function(){select(n);};box.appendChild(d);}' & _
        'roots.forEach(function(r){render(r,nav,null)});' & _
        'nav.addEventListener("keydown",function(e){if(!cur)return;var k=e.key;' & _
        'if(k==="ArrowDown"){e.preventDefault();moveVisible(1);}' & _
        'else if(k==="ArrowUp"){e.preventDefault();moveVisible(-1);}' & _
        'else if(k==="ArrowRight"){e.preventDefault();if(cur.kids.length){if(!expanded(cur))expand(cur);else select(cur.kids[0]);}}' & _
        'else if(k==="ArrowLeft"){e.preventDefault();if(cur.kids.length&&expanded(cur))collapse(cur);else if(cur.__parent)select(cur.__parent);}' & _
        'else if(k==="Home"){e.preventDefault();var r=vis();if(r.length)select(r[0].__node);}' & _
        'else if(k==="End"){e.preventDefault();var r=vis();if(r.length)select(r[r.length-1].__node);}});' & _
        'var split=document.getElementById("split"),drag=false;' & _
        'split.addEventListener("mousedown",function(e){drag=true;e.preventDefault();document.body.style.userSelect="none";});' & _
        'document.addEventListener("mousemove",function(e){if(!drag)return;var w=e.clientX,mx=window.innerWidth-200;if(w<150)w=150;if(w>mx)w=mx;nav.style.width=w+"px";});' & _
        'document.addEventListener("mouseup",function(){if(drag){drag=false;document.body.style.userSelect="";}});' & _
        'if(roots.length){select(roots[0]);nav.focus();}' & _
        '(function(){var ks=[].slice.call(nav.querySelectorAll(".kids"));' & _
        'ks.forEach(function(k){k.style.display="block";});' & _
        'var w=nav.scrollWidth+20;' & _
        'ks.forEach(function(k){k.style.display="none";});' & _
        'var mx=Math.min(window.innerWidth-200,Math.round(window.innerWidth*0.6));' & _
        'if(w>mx)w=mx;if(w<120)w=120;nav.style.width=w+"px";})();' & _
        '});</script>'
    $s &= '</head><body>'
    $s &= '<div id="hdr">' & $sTitle & '</div>'
    $s &= '<div id="main"><div id="nav" tabindex="0"></div><div id="split"></div><div id="detail"></div></div>'
    $s &= '<div id="data" style="display:none">' & @CRLF
    Return $s
EndFunc
