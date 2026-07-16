#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "CDP.au3"

$chrome = $browser.launch(Default, 9299, Default, Default, "1280,800")
$page = $chrome.newPage()
BasicWebPageTest($chrome, $page)
$chrome.close()

Func BasicWebPageTest($chrome, $page)

	With test("Basic web page test")

		With teststep("Verify Basic Web Page navigation")

			teststep("Navigate to evil tester test pages")
			$page.goto("https://testpages.eviltester.com", False)

			With teststep("Verify the main page")
				$title = $page.locator("//head/title")
				.expect($title, "title").toHaveText("Software Testing Practice Pages, Apps, and Challenges", @ScriptLineNumber)
				.expect($title.innerText(), "title innerText").toBe("Software Testing Practice Pages, Apps, and Challenges", @ScriptLineNumber)
				.expect($title, "title").toBeHidden(@ScriptLineNumber)
				.expect($title.isVisible(), "title visible state").toBe(False, @ScriptLineNumber)
				.expect($title.isHidden(), "title hidden state").toBe(True, @ScriptLineNumber)
			EndWith

			With teststep("Verify navigation to Pages")
				$pages_link = $page.locator("xpath=//a[@href='/pages/']")
				.expect($pages_link.textContent(), "Pages link text").toBe("Pages", @ScriptLineNumber)
				.expect($pages_link, "Pages link").toBeVisible(@ScriptLineNumber)
				.expect($pages_link.isVisible(), "Pages link visible state").toBeTruthy(@ScriptLineNumber)
				.expect($pages_link.isHidden(), "Pages link hidden state").toBeFalsy(@ScriptLineNumber)
			EndWith

			With teststep("Navigate to Pages")
				$pages_link.click(True)
			EndWith

			With teststep("Verify navigation to Basics")
				.expect($page.locator("//a[@href='/pages/basics/']/span").innerHTML(), "the Basics link innerHTML").toBe("Basics", @ScriptLineNumber)
			EndWith

			With teststep("Navigate to Basic Web Page")
				$page.locator("//a[@href='/pages/basics/']").click(True)
				$page.locator("//a[@href='/pages/basics/basic-web-page/']").click(True)
			EndWith

		EndWith

		With teststep("Verify Basic Web Page")

			With teststep("Page elements")
				.expect($page.locator("css=header.article-meta"), "Header article meta").toContainText("Elements", @ScriptLineNumber)
				.expect($page.locator("css=header.article-meta").innerText(), "Header article meta innerText").toContain("Elements", @ScriptLineNumber)
				.expect($page.locator("css=header.article-meta").innerText(), "Header article meta innerText").toMatch(".*Categor.*", @ScriptLineNumber)
				.expect($page.locator("//p[@id='para1']").innerText(), "Paragraph 1 innerText").toBe("A paragraph of text", @ScriptLineNumber)
				.expect($page.locator("//p[@id='para2']").innerText(), "Paragraph 1 innerText").toBe("Another paragraph of text", @ScriptLineNumber)
			EndWith

			With teststep("Click Me functionality")
				$page.locator("//button[@id='button1']").click()
				.expect($page.locator("//p[@id='click-message']").innerText(), "click message").toBe("You clicked the button!", @ScriptLineNumber)
				.expect($page.locator("//p[@id='click-message']").innerText(), "click message").toBeDefined(@ScriptLineNumber)
				.expect($page.locator("//p[@id='click-message']").innerText(), "click message").toHaveLength(StringLen("You clicked the button!"), @ScriptLineNumber)
			EndWith

		EndWith

		With teststep("Verify invalid locator")
			.expect($page.locator("//button[@id='invalid']")._locate(), "invalid locator").toBeNull(@ScriptLineNumber)
		EndWith

	EndWith

EndFunc
