#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "CDP.au3"

$chrome = $browser.launch(Default, 9299, Default, Default, "1280,800")
$page = $chrome.page()

With test("Multiple Elements test")

	teststep("Navigate to the page")
	$page.goto("https://testpages.eviltester.com/pages/basics/multiple-elements-example/")
	$submitBtn = $page.locator("//button[@id='submitBtn']")

	With teststep("Verify the submit button is disabled")
		.expect($submitBtn.isDisabled()).toBe(True, @ScriptLineNumber)
		.expect($submitBtn.isEnabled()).toBe(False, @ScriptLineNumber)
		.expect($submitBtn).toBeDisabled(@ScriptLineNumber)
	EndWith

	With teststep("Verify the manager radio button state change")
		$manager = $page.locator("//input[@id='manager']")
		.expect($manager.isChecked()).toBe(False, @ScriptLineNumber)
		$manager.click()
		.expect($manager.isChecked()).toBe(True, @ScriptLineNumber)
		.expect($manager).toBeChecked(@ScriptLineNumber)
	EndWith

	With teststep("Verify the submit button is now enabled")
		.expect($submitBtn.isDisabled()).toBe(False, @ScriptLineNumber)
		.expect($submitBtn.isEnabled()).toBe(True, @ScriptLineNumber)
		.expect($submitBtn).toBeEnabled(@ScriptLineNumber)
	EndWith

EndWith

$chrome.close()
