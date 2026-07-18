#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "CDP.au3"

$edge = $browser.launch($CDPBROWSER_EDGE, _JsonC_Object().add("port", 9299).add("windowSize", "1280,800"))
$page = $edge.newPage()
BasicWebPageTest($edge, $page)
$edge.close()

Func BasicWebPageTest($edge, $page)

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

		EndWith

	EndWith

EndFunc
