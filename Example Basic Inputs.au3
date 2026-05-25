#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "CDP.au3"

$chrome = $browser.launch(Default, 9299, Default, Default, "1280,800")
$page = $chrome.newPage()

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

		$page.locator("//input[@id='button-input']").scrollIntoView().hover()

		With teststep("State after hover")
			.expect($page.locator("//span[@id='button-input-event-value']")).toHaveText("mousemove", @ScriptLineNumber)
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

		$page.locator("//input[@id='checkbox-input']").scrollIntoView().hover()

		With teststep("State after hover")
			.expect($page.locator("//span[@id='checkbox-input-event-value']")).toHaveText("mousemove", @ScriptLineNumber)
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

	With teststep("Verify the radio buttons")

		With teststep("Radio button 1")

			With teststep("Initial state")
				.expect($page.locator("//span[@id='radio-input-1-type-value']")).toHaveText("radio", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-1-value-value']")).toHaveText("One", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-1-id-value']")).toHaveText("radio-input-1", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-1-event-value']")).toHaveText("initiated", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-1-key-value']")).toHaveText("", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-1-checked-value']")).toHaveText("false", @ScriptLineNumber)
			EndWith

			$page.locator("//input[@id='radio-input-1']").scrollIntoView().hover()

			With teststep("State after hover")
				.expect($page.locator("//span[@id='radio-input-1-event-value']")).toHaveText("mousemove", @ScriptLineNumber)
			EndWith

			$page.locator("//input[@id='radio-input-1']").click()

			With teststep("State after click")
				.expect($page.locator("//span[@id='radio-input-1-type-value']")).toHaveText("radio", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-1-value-value']")).toHaveText("One", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-1-id-value']")).toHaveText("radio-input-1", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-1-event-value']")).toHaveText("change", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-1-key-value']")).toHaveText("", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-1-checked-value']")).toHaveText("true", @ScriptLineNumber)
			EndWith

		EndWith

		With teststep("Radio button 2")

			With teststep("Initial state")
				.expect($page.locator("//span[@id='radio-input-2-type-value']")).toHaveText("radio", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-2-value-value']")).toHaveText("Two", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-2-id-value']")).toHaveText("radio-input-2", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-2-event-value']")).toHaveText("initiated", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-2-key-value']")).toHaveText("", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-2-checked-value']")).toHaveText("false", @ScriptLineNumber)
			EndWith

			$page.locator("//input[@id='radio-input-2']").scrollIntoView().hover()

			With teststep("State after hover")
				.expect($page.locator("//span[@id='radio-input-2-event-value']")).toHaveText("mousemove", @ScriptLineNumber)
			EndWith

			$page.locator("//input[@id='radio-input-2']").click()

			With teststep("State after click")
				.expect($page.locator("//span[@id='radio-input-2-type-value']")).toHaveText("radio", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-2-value-value']")).toHaveText("Two", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-2-id-value']")).toHaveText("radio-input-2", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-2-event-value']")).toHaveText("change", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-2-key-value']")).toHaveText("", @ScriptLineNumber)
				.expect($page.locator("//span[@id='radio-input-2-checked-value']")).toHaveText("true", @ScriptLineNumber)
			EndWith

		EndWith

	EndWith

	With teststep("Verify the hidden")

		With teststep("Initial state")
			.expect($page.locator("//span[@id='hidden-input-type-value']")).toHaveText("hidden", @ScriptLineNumber)
			.expect($page.locator("//span[@id='hidden-input-value-value']")).toHaveText("bob", @ScriptLineNumber)
			.expect($page.locator("//span[@id='hidden-input-id-value']")).toHaveText("hidden-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='hidden-input-event-value']")).toHaveText("initiated", @ScriptLineNumber)
			.expect($page.locator("//span[@id='hidden-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

	EndWith

EndWith

$chrome.close()
