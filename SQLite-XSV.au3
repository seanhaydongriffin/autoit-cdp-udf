#AutoIt3Wrapper_UseX64=y
#include-once
#include <SQLite.au3>

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

	Local $hDll = DllOpen($sDll_Filename)
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
