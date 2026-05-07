#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y

#include "CDP.au3"

$hTimer = TimerInit()

$chrome = $browser.launch(Default, 9299, Default, Default, "1280,800")
$page = $chrome.page()

BasicWebPageTest($chrome, $page)

$fDiff = TimerDiff($hTimer)
ConsoleWrite(@CRLF & "> BasicWebPageWithStandardBrowser() took " & $fDiff & " ms." & @CRLF & @CRLF)

Func BasicWebPageTest($chrome, $page)

	$test("Basic web page test")

	$test.step("Navigate to evil tester test pages")
	$page.goto("https://testpages.eviltester.com")

	$test.step("Verify the main page")
	$title = $page.locator("//head/title")
	$test.expect($title).toHaveText("Software Testing Practice Pages, Apps, and Challenges", @ScriptLineNumber)
	$test.expect($title.innerText()).toBe("Software Testing Practice Pages, Apps, and Challenges", @ScriptLineNumber)
	$test.expect($title).toBeHidden(@ScriptLineNumber)
	$test.expect($title.isVisible()).toBe(False, @ScriptLineNumber)
	$test.expect($title.isHidden()).toBe(True, @ScriptLineNumber)

	$pages_link = $page.locator("xpath=//a[@href='/pages/']")
	$test.expect($pages_link.textContent()).toBe("Pages", @ScriptLineNumber)
	$test.expect($pages_link).toBeVisible(@ScriptLineNumber)
	$test.expect($pages_link.isVisible()).toBe(True, @ScriptLineNumber)
	$test.expect($pages_link.isHidden()).toBe(False, @ScriptLineNumber)
	$pages_link.click(True)

	$test.expect($page.locator("//a[@href='/pages/basics/']/span").innerHTML()).toBe("Basics", @ScriptLineNumber)
	$page.locator("//a[@href='/pages/basics/']").click(True)
	$page.locator("//a[@href='/pages/basics/basic-web-page/']").click(True)

	$test.expect($page.locator("css=header.article-meta")).toContainText("Elements", @ScriptLineNumber)
	$test.expect($page.locator("css=header.article-meta").innerText()).toContain("Elements", @ScriptLineNumber)
	$test.expect($page.locator("//p[@id='para1']").innerText()).toBe("A paragraph of text", @ScriptLineNumber)
	$test.expect($page.locator("//p[@id='para2']").innerText()).toBe("Another paragraph of text", @ScriptLineNumber)

	$page.locator("//button[@id='button1']").click()
	$test.expect($page.locator("//p[@id='click-message']").innerText()).toBe("You clicked the button!", @ScriptLineNumber)

	$chrome.close()

EndFunc
