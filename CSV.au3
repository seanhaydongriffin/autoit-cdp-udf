#include-once
#include <SQLite.au3>
#include <SQLite.dll.au3>
#Region Header
#cs
	Title:   		CSV UDF Library for AutoIt3
	Filename:  		CSV.au3
	Description: 	A collection of functions for CSV manipulation
	Author:   		seangriffin
	Version:  		V0.1
	Last Update: 	24/02/19
	Requirements: 	AutoIt3 3.3 or higher,
					sqlite.exe.
	Changelog:		---------24/02/19---------- v0.1
					Initial release.

#ce
#EndRegion Header
#Region Global Variables and Constants
#EndRegion Global Variables and Constants
#Region Core functions
; #FUNCTION# ;===============================================================================
;
; Name...........:	_CSV_Initialise()
; Description ...:	Initialises CSV.
; Syntax.........:	_CSV_Initialise()
; Parameters ....:
; Return values .:
; Author ........:	seangriffin
; Modified.......:
; Remarks .......:	Must be executed prior to any other CSV functions.
; Related .......:
; Link ..........:
; Example .......:	Yes
;
; ;==========================================================================================
func _CSV_Initialise()

	; Load and initialize sqlite
	$ret = _SQLite_Startup("sqlite3_x64.dll", False, 1)
EndFunc

; #FUNCTION# ;===============================================================================
;
; Name...........:	_CSV_Open()
; Description ...:	Opens a CSV file and returns a handle to it.
; Syntax.........:	_CSV_Open($csv_file)
; Parameters ....:	$csv_file			- the CSV file.
; Return values .: 	On Success			- Returns a handle to the CSV file.
;                 	On Failure			- Returns nothing.
; Author ........:	seangriffin
; Modified.......:
; Remarks .......:	A prerequisite is that _CSV_Initialise() has been executed.
; Related .......:
; Link ..........:
; Example .......:	Yes
;
; ;==========================================================================================
Func _CSV_Open($csv_file)
	Local $sOut, $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
	_PathSplit($csv_file, $sDrive, $sDir, $sFileName, $sExtension)
	Local $csv_handle = @TempDir & "\" & $sFileName & ".db"
	FileDelete($csv_handle)
	Local $csv_file_fwd = StringReplace($csv_file, "\", "/")
	Local $sqlite = @ScriptDir & "\sqlite3.exe"
	Local $cmd = '"' & $sqlite & '" "' & $csv_handle & '" -cmd ".mode csv" -cmd ".import ''' & $csv_file_fwd & ''' csv"'
	Local $pid = Run($cmd, @ScriptDir, @SW_HIDE, $STDOUT_CHILD + $STDERR_MERGED)
	ProcessWaitClose($pid)
	Local $output = StdoutRead($pid)
	Return $csv_handle
EndFunc

; #FUNCTION# ;===============================================================================
;
; Name...........:	_CSV_Exec()
; Description ...:	Executes a SQLite query, does not handle results.
; Syntax.........:	_CSV_Exec($csv_handle, $csv_query)
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
;
; ;==========================================================================================
Func _CSV_Exec($csv_handle, $csv_query)

	Local $aResult, $iRows, $iColumns, $iRval
	$conn = _SQLite_Open ($csv_handle) ; open :memory: Database
	_SQLite_Exec($conn, $csv_query)
	_SQLite_Close($conn)
	Return $aResult
EndFunc


Func _CSV_QuerySingleValue($csv_handle, $sQuery = "")

	Local $hQuery, $aRow
	$conn = _SQLite_Open ($csv_handle)
	_SQLite_Query(-1, $sQuery, $hQuery)
	_SQLite_FetchData($hQuery, $aRow)
	_SQLite_QueryFinalize($hQuery)
	_SQLite_Close($conn)
	Return $aRow[0]
EndFunc


Func _CSV_Query($csv_handle, $sQuery = "")

	Local $hQuery, $aNames, $aRow
	Global $oData = ObjCreate("Scripting.Dictionary")

	$conn = _SQLite_Open ($csv_handle)
	_SQLite_Query(-1, $sQuery, $hQuery)

	_SQLite_FetchNames($hQuery, $aNames) ; Read out Column Names
	_SQLite_FetchData($hQuery, $aRow)

	for $i = 0 to UBound($aNames) - 1
		$oData.Add($aNames[$i], $aRow[$i])
	Next

	_SQLite_QueryFinalize($hQuery)
	_SQLite_Close($conn)
	Return $oData
EndFunc




; #FUNCTION# ;===============================================================================
;
; Name...........:	_CSV_GetRecordArray()
; Description ...:	Get a 1D or 2D array of records in the CSV file.
; Syntax.........:	_CSV_GetRecordArray($csv_handle, $row_number_or_query = "", $include_header = False)
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
;
; ;==========================================================================================
Func _CSV_GetRecordArray($csv_handle, $row_number_or_query = "", $include_header = False)

	Local $aResult, $iRows, $iColumns, $iRval
	$conn = _SQLite_Open ($csv_handle)

	if StringLen($row_number_or_query) = 0 Then

		$row_number_or_query = "SELECT * FROM csv;"
	EndIf

	if IsInt($row_number_or_query) = True Then

		_SQLite_GetTable2d($conn, "SELECT * FROM csv WHERE rowid = " & $row_number_or_query & ";", $aResult, $iRows, $iColumns)
		_SQLite_Close($conn)

		if $include_header = True Then

			Return $aResult
		Else

			Local $csv_result = _ArrayExtract($aResult, 1, 1)
			Return $csv_result
		EndIf
	Else

		_SQLite_GetTable2d($conn, $row_number_or_query, $aResult, $iRows, $iColumns)
		_SQLite_Close($conn)

		if $include_header = False Then

			_ArrayDelete($aResult, 0)
		EndIf

		Return $aResult
	EndIf

	_SQLite_Close($conn)
	Return False
EndFunc


; #FUNCTION# ;===============================================================================
;
; Name...........:	_CSV_DisplayArrayResult()
; Description ...:	Prints to Console a formated display of a result array.
; Syntax.........:	_CSV_DisplayArrayResult($csv_result)
; Parameters ....:	$csv_result			- the results of a query (see _CSV_GetRecordArray()).
; Return values .: 	On Success			- Returns nothing.
;                 	On Failure			- Returns nothing.
; Author ........:	seangriffin
; Modified.......:
; Remarks .......:	A prerequisite is that _CSV_GetTableArray() has been executed.
; Related .......:
; Link ..........:
; Example .......:	Yes
;
; ;==========================================================================================
Func _CSV_DisplayArrayResult($csv_result)

	_SQLite_Display2DResult($csv_result)
EndFunc

; #FUNCTION# ;===============================================================================
;
; Name...........:	_CSV_GetRecordCount()
; Description ...:	Get the number of records in a CSV file.
; Syntax.........:	_CSV_GetRecordCount($csv_handle)
; Parameters ....:	$csv_handle			- the handle of the CSV file.
; Return values .: 	On Success			- the number of records in the CSV file.
;                 	On Failure			- Returns nothing.
; Author ........:	seangriffin
; Modified.......:
; Remarks .......:	A prerequisite is that _CSV_Open() has been executed.
; Related .......:
; Link ..........:
; Example .......:	Yes
;
; ;==========================================================================================
Func _CSV_GetRecordCount($csv_handle)

	Local $csv_result = _CSV_GetRecordArray($csv_handle, "SELECT count(*) FROM csv;")
	Return $csv_result[0][0]
EndFunc

; #FUNCTION# ;===============================================================================
;
; Name...........:	_CSV_SaveAs()
; Description ...:	Saves a CSV file ($csv_handle) to another CSV file.
; Syntax.........:	_CSV_SaveAs($csv_handle, $csv_file, $csv_query = "SELECT * FROM csv;")
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
Func _CSV_SaveAs($csv_handle, $csv_file, $csv_query = "SELECT * FROM csv;")

	Local $sOut
	FileDelete($csv_file)
	_SQLite_SQLiteExe($csv_handle, ".headers on" & @CRLF & ".mode ascii" & @CRLF & ".output '" & $csv_file & "'" & @CRLF & $csv_query, $sOut, -1, True)
	Local $csv_str = FileRead($csv_file)

	; Each of the embedded double-quote characters must be represented by a pair of double-quote characters.
	$csv_str = StringReplace($csv_str, '"', '""')

	; Fields with embedded commas or double-quote characters must be quoted.
	$csv_str = StringRegExpReplace($csv_str, "(?U)([\x1E\x1F])([^\x1E\x1F]*[,""][^\x1E\x1F]*)([\x1E\x1F])", '${1}"${2}"${3}')

	; In CSV implementations that do trim leading or trailing spaces, fields with such spaces as meaningful data must be quoted.
	$csv_str = StringRegExpReplace($csv_str, "(?U)([\x1E\x1F])([^\x1E\x1F]* )([\x1E\x1F])", '${1}"${2}"${3}')
	$csv_str = StringRegExpReplace($csv_str, "(?U)([\x1E\x1F])( [^\x1E\x1F]*)([\x1E\x1F])", '${1}"${2}"${3}')
	$csv_str = StringRegExpReplace($csv_str, "(?U)([\x1E\x1F])( [^\x1E\x1F]* )([\x1E\x1F])", '${1}"${2}"${3}')

	; Convert ascii field and record separators to csv
	$csv_str = StringReplace($csv_str, "", @CRLF)
	$csv_str = StringReplace($csv_str, "", ",")

	FileDelete($csv_file)
	FileWrite($csv_file, $csv_str)
EndFunc

; #FUNCTION# ;===============================================================================
;
; Name...........:	_CSV_Cleanup()
; Description ...:	Cleans up the CSV UDF.
; Syntax.........:	_CSV_Cleanup()
; Parameters ....:
; Return values .:
; Author ........:	seangriffin
; Modified.......:
; Remarks .......:	A prerequisite is that _CSV_Initialise() has been executed.
; Related .......:
; Link ..........:
; Example .......:	Yes
;
; ;==========================================================================================
func _CSV_Cleanup()

	_SQLite_Shutdown()
EndFunc

