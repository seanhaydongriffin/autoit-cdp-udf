#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "CDP.au3"

$hTimer = TimerInit()

$chrome = $browser.launch(Default, 9299, "--headless=new")
$page = $chrome.newPage()
BasicWebPageTest($chrome, $page)
$chrome.close()

$fDiff = TimerDiff($hTimer)
ConsoleWrite(@CRLF & "> BasicWebPageWithStandardBrowser() took " & $fDiff & " ms." & @CRLF & @CRLF)

Func BasicWebPageTest($chrome, $page)

	With test("Basic web page test")

		With teststep("Verify Basic Web Page navigation")

			teststep("Navigate to evil tester test pages")
			$page.goto("https://testpages.eviltester.com")

			With teststep("Verify the main page")
				$title = $page.locator("//head/title")
				.expect($title).toHaveText("Software Testing Practice Pages, Apps, and Challenges", @ScriptLineNumber)

				.expect($title.innerText()).toBe("Software Testing Practice Pages, Apps, and Challenges", @ScriptLineNumber)
				.expect($title).toBeHidden(@ScriptLineNumber)
				.expect($title.isVisible()).toBe(False, @ScriptLineNumber)
				.expect($title.isHidden()).toBe(True, @ScriptLineNumber)
			EndWith

			With teststep("Verify navigation to Pages")
				$pages_link = $page.locator("xpath=//a[@href='/pages/']")
				.expect($pages_link.textContent()).toBe("Pages", @ScriptLineNumber)
				.expect($pages_link).toBeVisible(@ScriptLineNumber)
				.expect($pages_link.isVisible()).toBeTruthy(@ScriptLineNumber)
				.expect($pages_link.isHidden()).toBeFalsy(@ScriptLineNumber)
			EndWith

			With teststep("Navigate to Pages")
				$pages_link.click(True)
			EndWith

			With teststep("Verify navigation to Basics")
				.expect($page.locator("//a[@href='/pages/basics/']/span").innerHTML()).toBe("Basics", @ScriptLineNumber)
			EndWith

			With teststep("Navigate to Basic Web Page")
				$page.locator("//a[@href='/pages/basics/']").click(True)
				$page.locator("//a[@href='/pages/basics/basic-web-page/']").click(True)
			EndWith

		EndWith

		With teststep("Verify Basic Web Page")

			With teststep("Page elements")
				.expect($page.locator("css=header.article-meta")).toContainText("Elements", @ScriptLineNumber)
				.expect($page.locator("css=header.article-meta").innerText()).toContain("Elements", @ScriptLineNumber)
				.expect($page.locator("css=header.article-meta").innerText()).toMatch(".*Categor.*", @ScriptLineNumber)
				.expect($page.locator("//p[@id='para1']").innerText()).toBe("A paragraph of text", @ScriptLineNumber)
				.expect($page.locator("//p[@id='para2']").innerText()).toBe("Another paragraph of text", @ScriptLineNumber)
			EndWith

			With teststep("Click Me functionality")
				$page.locator("//button[@id='button1']").click()
				.expect($page.locator("//p[@id='click-message']").innerText()).toBe("You clicked the button!", @ScriptLineNumber)
				.expect($page.locator("//p[@id='click-message']").innerText()).toBeDefined(@ScriptLineNumber)
				.expect($page.locator("//p[@id='click-message']").innerText()).toHaveLength(StringLen("You clicked the button!"), @ScriptLineNumber)
			EndWith

		EndWith

		With teststep("Verify invalid locator")
			.expect($page.locatorNow("//button[@id='invalid']")).toBeNull(@ScriptLineNumber)
		EndWith

	EndWith

EndFunc
