#AutoIt3Wrapper_UseX64=y
#include-once
#include <SQLite.au3>
#include <FileConstants.au3>

; #INDEX# =======================================================================================================================
; Title .........: SQLite-XSV
; AutoIt Version : 3.3.16.0
; Language ......: English
; Description ...: A collection of functions for CSV manipulation using sqlite-xsv (https://github.com/asg017/sqlite-xsv).
; Author(s) .....: Sean Griffin
; Dll ...........: sqlite-xsv.dll
; ===============================================================================================================================

; #VARIABLES# ===================================================================================================================
Global $__g_hDb_CSV
; ===============================================================================================================================

; #CURRENT# =====================================================================================================================
; _SQLite_XSV_Startup
; _SQLite_XSV_Shutdown

; _SQLite_XSV_Open
; _SQLite_XSV_Close

; _SQLite_XSV_Exec
; _SQLite_XSV_QueryRecords
; _SQLite_XSV_QueryRecord
; _SQLite_XSV_QueryValue

; _SQLite_XSV_DisplayArrayResult
; _SQLite_XSV_GetRecordCount

; _SQLite_XSV_SaveAs
; ===============================================================================================================================

Global Const $__CSV_ScriptDir = @ScriptDir



; #FUNCTION# ;===============================================================================
; Name...........:	_SQLite_XSV_Startup()
; Description ...:	Initialises Sqlite3 with the sqlite-xsv extension.
; Syntax.........:	_SQLite_XSV_Startup()
; Parameters ....:
; Return values .:
; Author ........:	seangriffin
; Modified.......:
; Remarks .......:	Must be executed prior to any other SQLite_XSV functions.
; Related .......:
; Link ..........:
; Example .......:	Yes
; ;==========================================================================================
func _SQLite_XSV_Startup()

	Local $sDll_Filename = "sqlite3_xsv.dll"
	Local $iExtended = 0

	Local $hDll = DllOpen($__CSV_ScriptDir & "\" & $sDll_Filename)
	If $hDll = -1 Then
		$__g_hDll_SQLite = 0
		Return SetError(1, $iExtended, "")
	EndIf
	$__g_hDll_SQLite = $hDll

	$__g_hDb_CSV = _SQLite_Open()
	DllCall($__g_hDll_SQLite, "int:cdecl", "sqlite3_enable_load_extension", "ptr", $__g_hDB_SQLite, "int", 1)
	_SQLite_Exec($__g_hDb_CSV, "SELECT load_extension('sqlite3_xsv.dll');")

	Return SetExtended(0)
EndFunc

; #FUNCTION# ;===============================================================================
; Name...........:	_SQLite_XSV_Shutdown()
; Description ...:	Cleans up the SQLite_XSV UDF.
; Syntax.........:	_SQLite_XSV_Shutdown()
; Parameters ....:
; Return values .:
; Author ........:	seangriffin
; Modified.......:
; Remarks .......:	A prerequisite is that _SQLite_XSV_Startup() has been executed.
; Related .......:
; Link ..........:
; Example .......:	Yes
; ;==========================================================================================
func _SQLite_XSV_Shutdown()
	_SQLite_Close($__g_hDb_CSV)
	_SQLite_Shutdown()
EndFunc

; #FUNCTION# ;===============================================================================
; Name...........:	_SQLite_XSV_Open()
; Description ...:	Opens a CSV file and returns a handle to it.
; Syntax.........:	_SQLite_XSV_Open($csv_file)
; Parameters ....:	$csv_file			- the CSV file.
; Return values .: 	On Success			- Returns a handle to the CSV file.
;                 	On Failure			- Returns nothing.
; Author ........:	seangriffin
; Modified.......:
; Remarks .......:	A prerequisite is that _SQLite_XSV_Startup() has been executed.
; Related .......:
; Link ..........:
; Example .......:	Yes
; ;==========================================================================================
Func _SQLite_XSV_Open($csv_file)
	; Self-healing: a crashed previous run can leave 'data' behind, which would
	; otherwise make the CREATE fail silently and leave a stale table in place
	_SQLite_Exec($__g_hDb_CSV, 'DROP TABLE IF EXISTS data;')
	Return _SQLite_Exec($__g_hDb_CSV, 'create virtual table data using csv(filename="' & $csv_file & '");')
EndFunc

; #FUNCTION# ;===============================================================================
; Name...........:	_SQLite_XSV_Close()
; Description ...:	Opens a CSV file and returns a handle to it.
; Syntax.........:	_SQLite_XSV_Close($csv_file)
; Parameters ....:	$csv_file			- the CSV file.
; Return values .: 	On Success			- Returns a handle to the CSV file.
;                 	On Failure			- Returns nothing.
; Author ........:	seangriffin
; Modified.......:
; Remarks .......:	A prerequisite is that _CSV_Initialise() has been executed.
; Related .......:
; Link ..........:
; Example .......:	Yes
; ;==========================================================================================
Func _SQLite_XSV_Close()
	Return _SQLite_Exec($__g_hDb_CSV, 'DROP TABLE data;')
EndFunc

; #FUNCTION# ;===============================================================================
; Name...........:	_SQLite_XSV_Exec()
; Description ...:	Executes a SQLite query, does not handle results.
; Syntax.........:	_SQLite_XSV_Exec($csv_handle, $csv_query)
; Parameters ....:	$csv_handle			- the handle of the CSV file you are querying.
;					$csv_query			- the SQLite query.
; Return values .: 	On Success			- the 2Dimensional array of results.
;                 	On Failure			- Returns nothing.
; Author ........:	seangriffin
; Modified.......:
; Remarks .......:	A prerequisite is that _CSV_Open() has been executed.
; Related .......:
; Link ..........:
; Example .......:	Yes
; ;==========================================================================================
Func _SQLite_XSV_Exec($csv_query)
	Return _SQLite_Exec($__g_hDb_CSV, $csv_query)
EndFunc

; #FUNCTION# ;===============================================================================
; Name...........:	_CSV_GetRecords()
; Description ...:	Get a 2D array of records from the CSV file.
; Syntax.........:	_CSV_GetRecords($row_number_or_query = "", $include_header = False)
; Parameters ....:	$csv_handle				- the handle of the CSV file.
;					$query					- Optional: a specific query to filter the records.
;												"" = get all CSV records (default)
;												SQLite query = get all records matching a query
;					$include_header			- Optional: include the header in the output
;												True = include the header
;												False = do not include the header (default)
; Return values .: 	On Success				- a 2D array of CSV record(s).
;                 	On Failure				- Returns Null.
; Author ........:	seangriffin
; Modified.......:
; Remarks .......:	A prerequisite is that _CSV_Open() has been executed.
; Related .......:
; Link ..........:
; Example .......:	Yes
; ;==========================================================================================
Func _SQLite_XSV_QueryRecords($query = Default, $include_header = False)
	Local $aResult, $iRows, $iColumns
	if $query = Default Then
		$query = "SELECT * FROM data;"
	EndIf
	If _SQLite_GetTable2d($__g_hDb_CSV, $query, $aResult, $iRows, $iColumns) <> $SQLITE_OK Then Return SetError(@error, 0, _SQLite_ErrMsg())
	if $include_header = False Then
		_ArrayDelete($aResult, 0)
	EndIf
	Return $aResult
EndFunc

; #FUNCTION# ;===============================================================================
; Name...........:	_SQLite_XSV_QueryRecord()
; Description ...:	Get a 1D or 2D array of records in the CSV file.
; Syntax.........:	_SQLite_XSV_QueryRecord($csv_handle, $row_number_or_query = "", $include_header = False)
; Parameters ....:	$csv_handle				- the handle of the CSV file.
;					$row_number_or_query	- Optional: a specific query to filter the records.
;												"" = get all CSV records (default)
;												row number = get a record by it's row number
;												SQLite query = get all records matching a query
;					$include_header			- Optional: include the header in the output
;												True = include the header
;												False = do not include the header (default)
; Return values .: 	On Success				- an array of CSV record(s).
;                 	On Failure				- Returns nothing.
; Author ........:	seangriffin
; Modified.......:
; Remarks .......:	A prerequisite is that _CSV_Open() has been executed.
; Related .......:
; Link ..........:
; Example .......:	Yes
; ;==========================================================================================
#cs
Func _SQLite_XSV_QueryRecord($sQuery)
	Local $hQuery, $aNames, $aRow
	If _SQLite_Query($__g_hDb_CSV, $sQuery, $hQuery) <> $SQLITE_OK then Return SetError(1, 0, Null)
	If _SQLite_FetchNames($hQuery, $aNames) <> $SQLITE_OK then Return SetError(1, 0, Null)
	If _SQLite_FetchData($hQuery, $aRow) <> $SQLITE_OK then Return SetError(1, 0, Null)
	Global $oData = ObjCreate("Scripting.Dictionary")
	for $i = 0 to UBound($aNames) - 1
		$oData.Add($aNames[$i], $aRow[$i])
	Next
	If _SQLite_QueryFinalize($hQuery) <> $SQLITE_OK then Return SetError(1, 0, Null)
	Return $oData
EndFunc
#ce

Func _SQLite_XSV_QueryRecord($sQuery)
    Local $hQuery, $aNames, $aRow
    ; Inject rowid capture into "SELECT * FROM ..." queries so updates can target the exact row
    $sQuery = StringRegExpReplace($sQuery, "(?i)^\s*SELECT\s+\*", "SELECT rowid AS __rowid, *")
    If _SQLite_Query($__g_hDb_CSV, $sQuery, $hQuery) <> $SQLITE_OK Then Return SetError(1, 0, Null)
    If _SQLite_FetchNames($hQuery, $aNames) <> $SQLITE_OK Then Return SetError(1, 0, Null)
    If _SQLite_FetchData($hQuery, $aRow) <> $SQLITE_OK Then Return SetError(1, 0, Null)
    Local $oData = ObjCreate("Scripting.Dictionary")
    For $i = 0 To UBound($aNames) - 1
        $oData.Add($aNames[$i], $aRow[$i])
    Next
    _SQLite_QueryFinalize($hQuery)
    Return $oData
EndFunc


; #FUNCTION# ;===============================================================================
; Name...........:	_SQLite_XSV_QueryValue()
; Description ...:	Get a 1D or 2D array of records in the CSV file.
; Syntax.........:	_SQLite_XSV_QueryValue($csv_handle, $row_number_or_query = "", $include_header = False)
; Parameters ....:	$csv_handle				- the handle of the CSV file.
;					$row_number_or_query	- Optional: a specific query to filter the records.
;												"" = get all CSV records (default)
;												row number = get a record by it's row number
;												SQLite query = get all records matching a query
;					$include_header			- Optional: include the header in the output
;												True = include the header
;												False = do not include the header (default)
; Return values .: 	On Success				- an array of CSV record(s).
;                 	On Failure				- Returns nothing.
; Author ........:	seangriffin
; Modified.......:
; Remarks .......:	A prerequisite is that _CSV_Open() has been executed.
; Related .......:
; Link ..........:
; Example .......:	Yes
; ;==========================================================================================
Func _SQLite_XSV_QueryValue($sQuery)
	Local $hQuery, $aRow
	If _SQLite_Query($__g_hDb_CSV, $sQuery, $hQuery) <> $SQLITE_OK then Return SetError(1, 0, Null)
	If _SQLite_FetchData($hQuery, $aRow) <> $SQLITE_OK then Return SetError(1, 0, Null)
	If _SQLite_QueryFinalize($hQuery) <> $SQLITE_OK then Return SetError(1, 0, Null)
	Return $aRow[0]
EndFunc

; #FUNCTION# ;===============================================================================
; Name...........:	_SQLite_XSV_DisplayArrayResult()
; Description ...:	Prints to Console a formated display of a result array.
; Syntax.........:	_SQLite_XSV_DisplayArrayResult($csv_result)
; Parameters ....:	$csv_result			- the results of a query (see _CSV_GetRecordArray()).
; Return values .: 	On Success			- Returns nothing.
;                 	On Failure			- Returns nothing.
; Author ........:	seangriffin
; Modified.......:
; Remarks .......:	A prerequisite is that _CSV_GetTableArray() has been executed.
; Related .......:
; Link ..........:
; Example .......:	Yes
; ;==========================================================================================
Func _SQLite_XSV_DisplayArrayResult($csv_result)
	_SQLite_Display2DResult($csv_result)
EndFunc

; #FUNCTION# ;===============================================================================
; Name...........:	_SQLite_XSV_GetRecordCount()
; Description ...:	Get the number of records in a CSV file.
; Syntax.........:	_SQLite_XSV_GetRecordCount($csv_handle)
; Parameters ....:	$csv_handle			- the handle of the CSV file.
; Return values .: 	On Success			- the number of records in the CSV file.
;                 	On Failure			- Returns nothing.
; Author ........:	seangriffin
; Modified.......:
; Remarks .......:	A prerequisite is that _CSV_Open() has been executed.
; Related .......:
; Link ..........:
; Example .......:	Yes
; ;==========================================================================================
Func _SQLite_XSV_GetRecordCount($csv_handle)
	Local $csv_result = _SQLite_XSV_QueryRecords($csv_handle, "SELECT count(*) FROM csv;")
	Return $csv_result[0][0]
EndFunc

; #FUNCTION# ;===============================================================================
;
; Name...........:	_SQLite_XSV_SaveAs()
; Description ...:	Saves a CSV file ($csv_handle) to another CSV file.
; Syntax.........:	_SQLite_XSV_SaveAs($csv_handle, $csv_file, $csv_query = "SELECT * FROM csv;")
; Parameters ....:	$csv_handle			- the handle of the CSV file to save.
;					$csv_file			- the name of the CSV file to save to.
;					$csv_query			- Optional: a SQLite query of data to save.
;											By default all data will be saved.
; Return values .: 	On Success			- True
;                 	On Failure			- False
; Author ........:	seangriffin
; Modified.......:
; Remarks .......:	A prerequisite is that _CSV_Open() has been executed.
; Related .......:
; Link ..........:
; Example .......:	Yes
;
; ;==========================================================================================
; Save the current CSV (the 'data' table) to another CSV file, in-process.
Func _SQLite_XSV_SaveAs($csv_file)
    _SQLite_Exec($__g_hDb_CSV, "DROP TABLE IF EXISTS export; CREATE TABLE export AS SELECT * FROM data;")
    Return __XSV_ExportTableToCsv("export", $csv_file)
EndFunc


#cs
Func _SQLite_XSV_UpdateRecordAndSave($oData, $csv_file)

    If Not IsObj($oData) Or Not $oData.Exists("__rowid") Then Return SetError(1, 0, False)

	_SQLite_Exec($__g_hDb_CSV, "DROP TABLE IF EXISTS export; CREATE TABLE export AS SELECT * FROM data;")

    Local $sSet = ""
    For $sKey In $oData.Keys()
        If $sKey = "__rowid" Then ContinueLoop
        If $sSet <> "" Then $sSet &= ", "
        $sSet &= '"' & $sKey & '" = ' & _SQLite_FastEscape($oData.Item($sKey))
    Next
    Local $sQuery = 'UPDATE export SET ' & $sSet & ' WHERE rowid = ' & $oData.Item("__rowid") & ';'
    If _SQLite_Exec($__g_hDb_CSV, $sQuery) <> $SQLITE_OK Then Return SetError(2, 0, False)

	Local $sSqlite = @ScriptDir & '\sqlite3.exe'
	Local $sCmd = '"' & $sSqlite & '" -cmd ".headers on" -cmd ".mode csv" "' & $__XSV_dbFile & '" "SELECT * FROM export;"'

	Local $iPID = Run($sCmd, @ScriptDir, @SW_HIDE, $STDOUT_CHILD)
	Local $sOutput = ""
	While 1
		$sOutput &= StdoutRead($iPID)
		If @error Then ExitLoop ; pipe closed = process finished writing
	WEnd

	FileDelete($csv_file)
	FileWrite($csv_file, $sOutput)
    Return True

EndFunc
#ce



Func _SQLite_XSV_UpdateRecordAndSave($oData, $csv_file)
    If Not IsObj($oData) Or Not $oData.Exists("__rowid") Then Return SetError(1, 0, False)

    Local $sSet = ""
    For $sKey In $oData.Keys()
        If $sKey = "__rowid" Then ContinueLoop
        If $sSet <> "" Then $sSet &= ", "
        $sSet &= '"' & StringReplace($sKey, '"', '""') & '" = ' & _SQLite_FastEscape($oData.Item($sKey))
    Next

    _SQLite_Exec($__g_hDb_CSV, "DROP TABLE IF EXISTS export; CREATE TABLE export AS SELECT * FROM data;")
    If _SQLite_Exec($__g_hDb_CSV, 'UPDATE export SET ' & $sSet & ' WHERE rowid = ' & $oData.Item("__rowid") & ';') <> $SQLITE_OK Then Return SetError(2, 0, False)

    Return __XSV_ExportTableToCsv("export", $csv_file)
EndFunc


; Export a table to a CSV file. SQLite assembles each row into a ready-quoted CSV
; line natively, so AutoIt loops once per ROW rather than once per CELL - this
; matters for pools with 1000+ columns. Quoting matches sqlite3.exe's .mode csv:
; a field is quoted only if it contains a comma, double quote, CR or LF.
Func __XSV_ExportTableToCsv($sTable, $csv_file)
    Local $iTimer = TimerInit()
    Local $hQuery, $aNames, $aRow

    ; Column names
    If _SQLite_Query($__g_hDb_CSV, 'SELECT * FROM "' & $sTable & '" LIMIT 0;', $hQuery) <> $SQLITE_OK Then Return SetError(3, 0, False)
    _SQLite_FetchNames($hQuery, $aNames)
    _SQLite_QueryFinalize($hQuery)

    ; Build a SELECT in which SQLite itself quotes and joins the fields of a row.
    ; Columns are chunked into groups (one result column per group) because a
    ; single 1000-column expression exceeds SQLite's max expression tree depth.
    Local Const $iChunkSize = 50
    Local $iCols = UBound($aNames)
    Local $iChunks = Ceiling($iCols / $iChunkSize)
    Local $sSelect = ""
    For $i = 0 To $iCols - 1
        Local $c = 'ifnull("' & StringReplace($aNames[$i], '"', '""') & '",'''')'
        If $i > 0 Then $sSelect &= (Mod($i, $iChunkSize) = 0 ? ", " : " || ',' || ")
        $sSelect &= "CASE WHEN instr(" & $c & ",',') + instr(" & $c & ",'""') + instr(" & $c & ",char(10)) + instr(" & $c & ",char(13))" & _
            " THEN '""' || replace(" & $c & ",'""','""""') || '""' ELSE " & $c & " END"
    Next

    If _SQLite_Query($__g_hDb_CSV, "SELECT " & $sSelect & ' FROM "' & $sTable & '";', $hQuery) <> $SQLITE_OK Then Return SetError(4, 0, False)

    Local $sCsv = __XSV_CsvLine($aNames), $iRows = 0
    While _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
        Local $sLine = $aRow[0]
        For $i = 1 To $iChunks - 1
            $sLine &= "," & $aRow[$i]
        Next
        $sCsv &= $sLine & @CRLF
        $iRows += 1
    WEnd
    _SQLite_QueryFinalize($hQuery)

    Local $hFile = FileOpen($csv_file, $FO_OVERWRITE + $FO_UTF8_NOBOM)
    If $hFile = -1 Then Return SetError(5, 0, False)
    FileWrite($hFile, $sCsv)
    FileClose($hFile)

    ;ConsoleWrite("SQLite-XSV: saved " & $iRows & " rows x " & UBound($aNames) & " cols to " & $csv_file & " in " & Round(TimerDiff($iTimer)) & "ms" & @CRLF)
    Return True
EndFunc

; Quote fields the same way sqlite3's .mode csv does (RFC 4180). Used for the header line.
Func __XSV_CsvLine($aFields)
    Local $sLine = ""
    For $i = 0 To UBound($aFields) - 1
        Local $v = $aFields[$i]
        If StringRegExp($v, '[",' & @CR & @LF & ']') Then $v = '"' & StringReplace($v, '"', '""') & '"'
        $sLine &= ($i > 0 ? "," : "") & $v
    Next
    Return $sLine & @CRLF
EndFunc

