#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "CDP.au3"

$chrome = $browser.launch(Default, 9299, Default, Default, "1280,800")
$page = $chrome.newPage()

With test("Other Text Inputs test")

	$page.goto("https://testpages.eviltester.com/pages/input-elements/other-text/")

	With teststep("Verify the text area")

		With teststep("Initial state")
			.expect($page.locator("//span[@id='text-area-input-type-value']")).toHaveText("textarea", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-area-input-value-value']")).toHaveText("", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-area-input-id-value']")).toHaveText("text-area-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-area-input-event-value']")).toHaveText("initiated", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-area-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

		$page.locator("//textarea[@id='text-area-input']").sendKeys("Hello world!" & @CRLF & "Good to see you.")

		With teststep("After typing")
			.expect($page.locator("//span[@id='text-area-input-type-value']")).toHaveText("textarea", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-area-input-value-value']")).toHaveText("Hello world!" & @CRLF & "Good to see you.", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-area-input-id-value']")).toHaveText("text-area-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-area-input-event-value']").textContent()).toMatch("keyup|selectionchange", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-area-input-key-value']")).toHaveText("u", @ScriptLineNumber)
		EndWith

	EndWith

	With teststep("Verify the text area of max len 40")

		With teststep("Initial state")
			.expect($page.locator("//span[@id='text-area-input-max-type-value']")).toHaveText("textarea", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-area-input-max-value-value']")).toHaveText("", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-area-input-max-id-value']")).toHaveText("text-area-input-max", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-area-input-max-event-value']")).toHaveText("initiated", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-area-input-max-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

		$page.locator("//textarea[@id='text-area-input-max']").sendKeys("Line one" & @CRLF & "Second line" & @CRLF & "Final line for test")

		With teststep("After typing")
			.expect($page.locator("//span[@id='text-area-input-max-type-value']")).toHaveText("textarea", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-area-input-max-value-value']")).toHaveText("Line one" & @CRLF & "Second line" & @CRLF & "Final line for test", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-area-input-max-id-value']")).toHaveText("text-area-input-max", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-area-input-max-event-value']").textContent()).toMatch("keyup|selectionchange", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-area-input-max-key-value']")).toHaveText("t", @ScriptLineNumber)
		EndWith

	EndWith

	With teststep("Verify the multiple select")

		With teststep("Initial state")
			.expect($page.locator("//span[@id='multi-select-input-type-value']")).toHaveText("select-multiple", @ScriptLineNumber)
			.expect($page.locator("//span[@id='multi-select-input-value-value']")).toHaveText("ms4", @ScriptLineNumber)
			.expect($page.locator("//span[@id='multi-select-input-id-value']")).toHaveText("multi-select-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='multi-select-input-event-value']")).toHaveText("initiated", @ScriptLineNumber)
			.expect($page.locator("//span[@id='multi-select-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

		$page.locator("//select[@id='multi-select-input']").selectOption("ms1")

		With teststep("After select")
			.expect($page.locator("//span[@id='multi-select-input-type-value']")).toHaveText("select-multiple", @ScriptLineNumber)
			.expect($page.locator("//span[@id='multi-select-input-value-value']")).toHaveText("ms1", @ScriptLineNumber)
			.expect($page.locator("//span[@id='multi-select-input-id-value']")).toHaveText("multi-select-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='multi-select-input-event-value']")).toHaveText("change", @ScriptLineNumber)
			.expect($page.locator("//span[@id='multi-select-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

	EndWith

	With teststep("Verify the select")

		With teststep("Initial state")
			.expect($page.locator("//span[@id='select-input-type-value']")).toHaveText("select-one", @ScriptLineNumber)
			.expect($page.locator("//span[@id='select-input-value-value']")).toHaveText("dd3", @ScriptLineNumber)
			.expect($page.locator("//span[@id='select-input-id-value']")).toHaveText("select-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='select-input-event-value']")).toHaveText("initiated", @ScriptLineNumber)
			.expect($page.locator("//span[@id='select-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

		$page.locator("//select[@id='select-input']").selectOption("dd1")

		With teststep("After select")
			.expect($page.locator("//span[@id='select-input-type-value']")).toHaveText("select-one", @ScriptLineNumber)
			.expect($page.locator("//span[@id='select-input-value-value']")).toHaveText("dd1", @ScriptLineNumber)
			.expect($page.locator("//span[@id='select-input-id-value']")).toHaveText("select-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='select-input-event-value']")).toHaveText("change", @ScriptLineNumber)
			.expect($page.locator("//span[@id='select-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

	EndWith

EndWith

$chrome.close()
