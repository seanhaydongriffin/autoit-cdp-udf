#include-once

; #INDEX# =======================================================================================================================
; Title .........: CDPReport
; Description ...: Standalone, self-contained HTML test report for the CDP UDF.
;                 One file per test in test-results\<test name>\report.html. Left panel = nested accordion of test step
;                 names (built by JS from flat records); right panel = the selected step's end-of-step screenshot.
;                 Written realtime in append mode; tolerant of an abruptly-terminated (unclosed) HTML file.
; Author(s) .....: Sean Griffin
; ===============================================================================================================================

; #VARIABLES# ===================================================================================================================
Global $g_CDP_ReportFile = -1                  ; open file handle, or -1 when no report is active
Global $g_CDP_ReportStepId = 0                 ; monotonic step id
Global $g_CDP_ReportStack[256]                 ; stack of currently-open step ids (for parent resolution)
Global $g_CDP_ReportSnap[256]                  ; per-open-step pending screenshot (base64), set by teststepshot()
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

    Local $sPath = $sDir & "\report.html"
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

; Called when a test step ends. Appends one flat record, including any image attached via teststepshot().
Func __CDP_Report_StepEnd($iId, $iParent, $sName)
    If $g_CDP_ReportFile = -1 Then Return

    ; Use only an image explicitly attached via teststepshot() during the step. No automatic
    ; screenshot: steps the author didn't annotate simply have no image in the report.
    Local $sB64 = ""
    If $g_CDP_ReportStackTop >= 0 Then $sB64 = $g_CDP_ReportSnap[$g_CDP_ReportStackTop]

    Local $sImgPayload = ""
    If $sB64 <> "" Then
        If $g_CDP_ReportEmbedImages Then
            $sImgPayload = $sB64                                  ; base64 goes inline in <i>
        Else
            Local $sRel = "steps\" & $iId & ".png"
            Local $hPng = FileOpen($g_CDP_ReportDir & "\" & $sRel, 18) ; 18 = binary+erase
            If $hPng <> -1 Then
                FileWrite($hPng, __CDP_Base64Decode($sB64))
                FileClose($hPng)
                $sImgPayload = StringReplace($sRel, "\", "/")     ; <i> holds a relative path instead
            EndIf
        EndIf
    EndIf

    ; One self-contained record. data-embed tells the JS whether <i> is base64 or a src path.
    FileWrite($g_CDP_ReportFile, _
        '<div class="step" data-id="' & $iId & '" data-parent="' & $iParent & _
        '" data-embed="' & ($g_CDP_ReportEmbedImages ? "1" : "0") & '">' & _
        '<b>' & __CDP_Report_HtmlEscape($sName) & '</b><i>' & $sImgPayload & '</i></div>' & @CRLF)
    FileFlush($g_CDP_ReportFile)

    If $g_CDP_ReportStackTop >= 0 Then
        $g_CDP_ReportSnap[$g_CDP_ReportStackTop] = ""   ; clear the slot as the step unwinds
        $g_CDP_ReportStackTop -= 1
    EndIf
EndFunc

; Attach an image to the current step (last successful call wins). If $sB64 is supplied it is used
; as-is (an element screenshot or a pre-captured base64 PNG); otherwise the active page is captured now.
; Called by the public teststepshot() function; works from any call depth inside a teststep block.
Func __CDP_Report_Snap($sB64 = Default)
    If $g_CDP_ReportFile = -1 Or $g_CDP_ReportStackTop < 0 Then Return
    If $sB64 = Default Then $sB64 = __CDP_Report_CaptureBase64()
    If $sB64 <> "" Then $g_CDP_ReportSnap[$g_CDP_ReportStackTop] = $sB64
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
        '#detail{flex:1;min-width:0;overflow:auto;background:#fff;display:flex;align-items:flex-start;justify-content:center;padding:10px}' & _
        '#shot{max-width:100%;height:auto;box-shadow:0 0 8px rgba(0,0,0,.5)}' & _
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
        'byId[id]={id:id,pid:el.getAttribute("data-parent"),embed:el.getAttribute("data-embed")!=="0",' & _
        'name:(el.querySelector("b")||{}).textContent||"",shotEl:el.querySelector("i"),kids:[]};});' & _
        'steps.forEach(function(el){var id=el.getAttribute("data-id"),n=byId[id];' & _
        'if(n.pid&&n.pid!=="0"&&byId[n.pid])byId[n.pid].kids.push(n);else roots.push(n);});' & _
        'var nav=document.getElementById("nav"),img=document.getElementById("shot"),cur=null;' & _
        'function expanded(n){return n.kids.length&&n.__kids.style.display!=="none";}' & _
        'function expand(n){if(n.kids.length){n.__kids.style.display="block";n.__tog.textContent="▼";}}' & _
        'function collapse(n){if(n.kids.length){n.__kids.style.display="none";n.__tog.textContent="▶";}}' & _
        'function select(n){cur=n;' & _
        'document.querySelectorAll("#nav .row.sel").forEach(function(r){r.classList.remove("sel")});' & _
        'n.__row.classList.add("sel");' & _
        'var v=n.shotEl?n.shotEl.textContent:"";' & _   ; read base64/path lazily, only on select
        'if(!v)img.removeAttribute("src");else img.src=n.embed?("data:image/png;base64,"+v):v;' & _
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
        '});</script>'
    $s &= '</head><body>'
    $s &= '<div id="hdr">' & $sTitle & '</div>'
    $s &= '<div id="main"><div id="nav" tabindex="0"></div><div id="split"></div><div id="detail"><img id="shot"></div></div>'
    $s &= '<div id="data" style="display:none">' & @CRLF
    Return $s
EndFunc
