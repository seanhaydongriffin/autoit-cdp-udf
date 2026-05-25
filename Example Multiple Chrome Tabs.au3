#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "CDP.au3"

Local $chrome1, $chrome2

With test("Multiple Chrome Tabs test")

	With teststep("Chrome browser opens a second tab")
		$chrome = $browser.launch(Default, 9299, Default, @ScriptDir & "\chrome1profile", "1280,800")
		$chromepage1 = $chrome.newPage()
		$chromepage1.goto("https://testpages.eviltester.com/pages/navigation/windows-names/")
		$chromepage1.locator("//a[@id='gobasicajax']").click()
		$chromepage2 = $chrome.getNewPage()
		$windowNameButton = $chromepage2.waitForLoad().locator("//button[@id='window-name-button']")
		$windowNameButton.click()
		.expect($windowNameButton).toHaveText("window-with-name", @ScriptLineNumber)
		$chrome.close()
	EndWith

	With teststep("Launch first Chrome browser and first tab")
		$chrome1 = $browser.launch(Default, 9299, Default, @ScriptDir & "\chrome1profile", "1280,800")
		$chrome1page1 = $chrome1.newPage()
		$chrome1page1.goto("https://testpages.eviltester.com/pages/basics/element-attribute-examples/")
		MsgBox(0, "Example Multiple Chrome Tabs", "Chrome #1 launched and new page (tab) #1", 2)
	EndWith

	With teststep("Launch second Chrome browser and first tab")
		$chrome2 = $browser.launch(Default, 9298, Default, @ScriptDir & "\chrome2profile", "1280,800")
		$chrome2page1 = $chrome2.newPage()
		$chrome2page1.goto("https://testpages.eviltester.com/pages/basics/element-attribute-examples/")
		MsgBox(0, "Example Multiple Chrome Tabs", "Chrome #2 launched and new page (tab) #1", 2)
	EndWith

	With teststep("Add a second tab to the first Chrome browser")
		$chrome1page2 = $chrome1.newPage()
		$chrome1page2.goto("https://testpages.eviltester.com/pages/basics/element-attribute-examples/")
		MsgBox(0, "Example Multiple Chrome Tabs", "New page (tab) #2 added to Chrome #1", 2)
	EndWith

	With teststep("Add a second tab to the second Chrome browser")
		$chrome2page2 = $chrome2.newPage()
		$chrome2page2.goto("https://testpages.eviltester.com/pages/basics/element-attribute-examples/")
		MsgBox(0, "Example Multiple Chrome Tabs", "New page (tab) #2 added to Chrome #2", 2)
	EndWith

	With teststep("Close the first Chrome browser")
		$chrome1.close()
		MsgBox(0, "Example Multiple Chrome Tabs", "Chrome #1 closed", 2)
	EndWith

	With teststep("Close the second Chrome browser")
		$chrome2.close()
		MsgBox(0, "Example Multiple Chrome Tabs", "Chrome #2 closed", 2)
	EndWith

EndWith
