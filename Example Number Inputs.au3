#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include "CDP.au3"

$chrome = $browser.launch($CDPBROWSER_CHROME, _JsonC_Object().add("port", 9299).add("windowSize", "1280,800"))
$page = $chrome.newPage()

With test("Number Inputs test")

	teststep("Navigate to the page")
	$page.goto("https://testpages.eviltester.com/pages/input-elements/number-inputs/")

	With teststep("Verify the number with defaults")

		With teststep("Initial state")
			.expect($page.locator("//span[@id='number-input-type-value']")).toHaveText("number", @ScriptLineNumber)
			.expect($page.locator("//span[@id='number-input-value-value']")).toHaveText("", @ScriptLineNumber)
			.expect($page.locator("//span[@id='number-input-id-value']")).toHaveText("number-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='number-input-event-value']")).toHaveText("initiated", @ScriptLineNumber)
			.expect($page.locator("//span[@id='number-input-key-value']")).toHaveText("", @ScriptLineNumber)
			.expect($page.locator("//input[@id='number-input']").isEditable()).toBe(True, @ScriptLineNumber)
		EndWith

		$page.locator("//input[@id='number-input']").click()

		With teststep("State after click")
			.expect($page.locator("//span[@id='number-input-type-value']")).toHaveText("number", @ScriptLineNumber)
			.expect($page.locator("//span[@id='number-input-value-value']")).toHaveText("", @ScriptLineNumber)
			.expect($page.locator("//span[@id='number-input-id-value']")).toHaveText("number-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='number-input-event-value']").textContent()).toMatch("click|selectionchange", @ScriptLineNumber)
			.expect($page.locator("//span[@id='number-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

		$page.locator("//input[@id='number-input']").fill("123")

		With teststep("State after typing")
			.expect($page.locator("//span[@id='number-input-type-value']")).toHaveText("number", @ScriptLineNumber)
			.expect($page.locator("//span[@id='number-input-value-value']")).toHaveText("123", @ScriptLineNumber)
			.expect($page.locator("//span[@id='number-input-id-value']")).toHaveText("number-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='number-input-event-value']")).toHaveText("selectionchange", @ScriptLineNumber)
			.expect($page.locator("//span[@id='number-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

	EndWith

EndWith

$chrome.close()
