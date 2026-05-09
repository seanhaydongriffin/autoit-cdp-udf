#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "CDP.au3"

$hTimer = TimerInit()

;$cdp.config.debug = True
$chrome = $browser.launch(Default, 9299, Default, Default, "1280,800")
$page = $chrome.page()

With test("Basic Inputs test")

	teststep("Navigate to the page")
	$page.goto("https://testpages.eviltester.com/pages/input-elements/basic-inputs/")

	With teststep("Verify the button")

		With teststep("Initial state")
			.expect($page.locator("//span[@id='button-input-type-value']")).toHaveText("button", @ScriptLineNumber)
			.expect($page.locator("//span[@id='button-input-value-value']")).toHaveText("A Button", @ScriptLineNumber)
			.expect($page.locator("//span[@id='button-input-id-value']")).toHaveText("button-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='button-input-event-value']")).toHaveText("initiated", @ScriptLineNumber)
			.expect($page.locator("//span[@id='button-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

		$page.locator("//input[@id='button-input']").click()

		With teststep("State after click")
			.expect($page.locator("//span[@id='button-input-type-value']")).toHaveText("button", @ScriptLineNumber)
			.expect($page.locator("//span[@id='button-input-value-value']")).toHaveText("A Button", @ScriptLineNumber)
			.expect($page.locator("//span[@id='button-input-id-value']")).toHaveText("button-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='button-input-event-value']")).toHaveText("click", @ScriptLineNumber)
			.expect($page.locator("//span[@id='button-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

	EndWith

	With teststep("Verify the checkbox")

		With teststep("Initial state")
			.expect($page.locator("//span[@id='checkbox-input-type-value']")).toHaveText("checkbox", @ScriptLineNumber)
			.expect($page.locator("//span[@id='checkbox-input-value-value']")).toHaveText("on", @ScriptLineNumber)
			.expect($page.locator("//span[@id='checkbox-input-id-value']")).toHaveText("checkbox-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='checkbox-input-event-value']")).toHaveText("initiated", @ScriptLineNumber)
			.expect($page.locator("//span[@id='checkbox-input-key-value']")).toHaveText("", @ScriptLineNumber)
			.expect($page.locator("//span[@id='checkbox-input-checked-value']")).toHaveText("false", @ScriptLineNumber)
		EndWith

		$page.locator("//input[@id='checkbox-input']").click()

		With teststep("State after click")
			.expect($page.locator("//span[@id='checkbox-input-type-value']")).toHaveText("checkbox", @ScriptLineNumber)
			.expect($page.locator("//span[@id='checkbox-input-value-value']")).toHaveText("on", @ScriptLineNumber)
			.expect($page.locator("//span[@id='checkbox-input-id-value']")).toHaveText("checkbox-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='checkbox-input-event-value']")).toHaveText("change", @ScriptLineNumber)
			.expect($page.locator("//span[@id='checkbox-input-key-value']")).toHaveText("", @ScriptLineNumber)
			.expect($page.locator("//span[@id='checkbox-input-checked-value']")).toHaveText("true", @ScriptLineNumber)
		EndWith

	EndWith


EndWith

