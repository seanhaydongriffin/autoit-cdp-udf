#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "CDP.au3"

$cdp.config.debug = True
$chrome = $browser.launch(Default, 9299, Default, Default, "1280,800")
$page = $chrome.newPage()

With test("Element Attributes test")

	$page.goto("https://testpages.eviltester.com/pages/basics/element-attribute-examples/")

	With teststep("Verify attributes")
		.expect($page.locator("//p[@id='domattributes']").textContent()).toBe("This paragraph has attributes")
		.expect($page.locator("//p[@id='jsattributes']").textContent()).toBe("This paragraph has dynamic attributes")
		.expect($page.locator("//p[@id='jsattributes']").getAttribute("nextid")).toBe(1)
		.expect($page.locator("//p[@id='jsattributes']")).toHaveAttribute("nextid", 1)
		.expect($page.locator("//p[@id='jsattributes']").getAttribute("nextid")).toBeLessThan(2)
		.expect($page.locator("//p[@id='jsattributes']").getAttribute("nextid")).toBeLessThanOrEqual(1)
		.expect($page.locator("//p[@id='jsattributes']").getAttribute("nextid")).toBeLessThanOrEqual(2)
		$page.locator("//button[@id='add-attribute-button']").click()
		.expect($page.locator("//p[@id='jsattributes']").getAttribute("nextid")).toBe(2)
		.expect($page.locator("//p[@id='jsattributes']")).toHaveAttribute("nextid", 2)
		.expect($page.locator("//p[@id='jsattributes']").getAttribute("nextid")).toBeGreaterThan(1)
		.expect($page.locator("//p[@id='jsattributes']").getAttribute("nextid")).toBeGreaterThanOrEqual(1)
		.expect($page.locator("//p[@id='jsattributes']").getAttribute("nextid")).toBeGreaterThanOrEqual(2)
	EndWith
EndWith

$chrome.close()
