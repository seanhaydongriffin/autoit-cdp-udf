#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "CDP.au3"

$hTimer = TimerInit()

;$cdp.config.debug = True
$chrome = $browser.launch(Default, 9299, Default, Default, "1280,800")
$page = $chrome.page()

With test("Multiple Elements test")

	teststep("Navigate to the page")
	$page.goto("https://testpages.eviltester.com/pages/basics/multiple-elements-example/")

	With teststep("Verify the submit button is disabled")
		.expect($page.locator("//button[@id='submitBtn']").isDisabled()).toBe(True, @ScriptLineNumber)
	EndWith

	With teststep("Verify the manager radio button state change")
		$manager = $page.locator("//input[@id='manager']")
		.expect($manager.isChecked()).toBe(False, @ScriptLineNumber)
		$manager.click()
		.expect($manager.isChecked()).toBe(True, @ScriptLineNumber)
	EndWith

	With teststep("Verify the submit button is now enabled")
		.expect($page.locator("//button[@id='submitBtn']").isEnabled()).toBe(True, @ScriptLineNumber)
	EndWith

EndWith

