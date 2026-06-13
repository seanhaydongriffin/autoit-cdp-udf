#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "CDP.au3"

$chrome = $browser.launch(Default, 9299, Default, Default, "1280,800")
$page = $chrome.newPage()

With test("Text Inputs test")

	$page.goto("https://testpages.eviltester.com/pages/input-elements/text-inputs/")

	With teststep("Verify the text input")

		With teststep("Initial state")
			.expect($page.locator("//span[@id='text-input-type-value']")).toHaveText("text", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-input-value-value']")).toHaveText("", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-input-id-value']")).toHaveText("text-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-input-event-value']")).toHaveText("initiated", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

		$page.locator("//input[@id='text-input']").sendKeys("Hello world")

		With teststep("After typing")
			.expect($page.locator("//span[@id='text-input-type-value']")).toHaveText("text", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-input-value-value']")).toHaveText("Hello world", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-input-id-value']")).toHaveText("text-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-input-event-value']").textContent()).toMatch("keyup|selectionchange", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-input-key-value']")).toHaveText("d", @ScriptLineNumber)
		EndWith

	EndWith

	With teststep("Verify the search input")

		With teststep("Initial state")
			.expect($page.locator("//span[@id='search-input-type-value']")).toHaveText("search", @ScriptLineNumber)
			.expect($page.locator("//span[@id='search-input-value-value']")).toHaveText("", @ScriptLineNumber)
			.expect($page.locator("//span[@id='search-input-id-value']")).toHaveText("search-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='search-input-event-value']")).toHaveText("initiated", @ScriptLineNumber)
			.expect($page.locator("//span[@id='search-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

		$page.locator("//input[@id='search-input']").sendKeys("weather tomorrow")

		With teststep("After typing")
			.expect($page.locator("//span[@id='search-input-type-value']")).toHaveText("search", @ScriptLineNumber)
			.expect($page.locator("//span[@id='search-input-value-value']")).toHaveText("weather tomorrow", @ScriptLineNumber)
			.expect($page.locator("//span[@id='search-input-id-value']")).toHaveText("search-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='search-input-event-value']").textContent()).toMatch("keyup|selectionchange", @ScriptLineNumber)
			.expect($page.locator("//span[@id='search-input-key-value']")).toHaveText("w", @ScriptLineNumber)
		EndWith

	EndWith

	With teststep("Verify the password input")

		With teststep("Initial state")
			.expect($page.locator("//span[@id='password-input-type-value']")).toHaveText("password", @ScriptLineNumber)
			.expect($page.locator("//span[@id='password-input-value-value']")).toHaveText("", @ScriptLineNumber)
			.expect($page.locator("//span[@id='password-input-id-value']")).toHaveText("password-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='password-input-event-value']")).toHaveText("initiated", @ScriptLineNumber)
			.expect($page.locator("//span[@id='password-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

		$page.locator("//input[@id='password-input']").sendKeys("P@ssw0rd123")

		With teststep("After typing")
			.expect($page.locator("//span[@id='password-input-type-value']")).toHaveText("password", @ScriptLineNumber)
			.expect($page.locator("//span[@id='password-input-value-value']")).toHaveText("P@ssw0rd123", @ScriptLineNumber)
			.expect($page.locator("//span[@id='password-input-id-value']")).toHaveText("password-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='password-input-event-value']").textContent()).toMatch("keyup|selectionchange", @ScriptLineNumber)
			.expect($page.locator("//span[@id='password-input-key-value']")).toHaveText("3", @ScriptLineNumber)
		EndWith

	EndWith

	With teststep("Verify the email input")

		With teststep("Initial state")
			.expect($page.locator("//span[@id='email-input-type-value']")).toHaveText("email", @ScriptLineNumber)
			.expect($page.locator("//span[@id='email-input-value-value']")).toHaveText("", @ScriptLineNumber)
			.expect($page.locator("//span[@id='email-input-id-value']")).toHaveText("email-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='email-input-event-value']")).toHaveText("initiated", @ScriptLineNumber)
			.expect($page.locator("//span[@id='email-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

		$page.locator("//input[@id='email-input']").sendKeys("user123@demo.net")

		With teststep("After typing")
			.expect($page.locator("//span[@id='email-input-type-value']")).toHaveText("email", @ScriptLineNumber)
			.expect($page.locator("//span[@id='email-input-value-value']")).toHaveText("user123@demo.net", @ScriptLineNumber)
			.expect($page.locator("//span[@id='email-input-id-value']")).toHaveText("email-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='email-input-event-value']").textContent()).toMatch("keyup|selectionchange", @ScriptLineNumber)
			.expect($page.locator("//span[@id='email-input-key-value']")).toHaveText("t", @ScriptLineNumber)
		EndWith

	EndWith

	With teststep("Verify the url input")

		With teststep("Initial state")
			.expect($page.locator("//span[@id='url-input-type-value']")).toHaveText("url", @ScriptLineNumber)
			.expect($page.locator("//span[@id='url-input-value-value']")).toHaveText("", @ScriptLineNumber)
			.expect($page.locator("//span[@id='url-input-id-value']")).toHaveText("url-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='url-input-event-value']")).toHaveText("initiated", @ScriptLineNumber)
			.expect($page.locator("//span[@id='url-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

		$page.locator("//input[@id='url-input']").sendKeys("https://testsite.dev/login")

		With teststep("After typing")
			.expect($page.locator("//span[@id='url-input-type-value']")).toHaveText("url", @ScriptLineNumber)
			.expect($page.locator("//span[@id='url-input-value-value']")).toHaveText("https://testsite.dev/login", @ScriptLineNumber)
			.expect($page.locator("//span[@id='url-input-id-value']")).toHaveText("url-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='url-input-event-value']").textContent()).toMatch("keyup|selectionchange", @ScriptLineNumber)
			.expect($page.locator("//span[@id='url-input-key-value']")).toHaveText("n", @ScriptLineNumber)
		EndWith

	EndWith

	With teststep("Verify the tel input")

		With teststep("Initial state")
			.expect($page.locator("//span[@id='tel-input-type-value']")).toHaveText("tel", @ScriptLineNumber)
			.expect($page.locator("//span[@id='tel-input-value-value']")).toHaveText("", @ScriptLineNumber)
			.expect($page.locator("//span[@id='tel-input-id-value']")).toHaveText("tel-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='tel-input-event-value']")).toHaveText("initiated", @ScriptLineNumber)
			.expect($page.locator("//span[@id='tel-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

		$page.locator("//input[@id='tel-input']").sendKeys("0412 345 678")

		With teststep("After typing")
			.expect($page.locator("//span[@id='tel-input-type-value']")).toHaveText("tel", @ScriptLineNumber)
			.expect($page.locator("//span[@id='tel-input-value-value']")).toHaveText("0412 345 678", @ScriptLineNumber)
			.expect($page.locator("//span[@id='tel-input-id-value']")).toHaveText("tel-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='tel-input-event-value']").textContent()).toMatch("keyup|selectionchange", @ScriptLineNumber)
			.expect($page.locator("//span[@id='tel-input-key-value']")).toHaveText("8", @ScriptLineNumber)
		EndWith

	EndWith

	With teststep("Verify the text input of no set length")

		With teststep("Initial state")
			.expect($page.locator("//span[@id='text-default-input-type-value']")).toHaveText("text", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-default-input-value-value']")).toHaveText("", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-default-input-id-value']")).toHaveText("text-default-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-default-input-event-value']")).toHaveText("initiated", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-default-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

		$page.locator("//input[@id='text-default-input']").sendKeys("Sample input")

		With teststep("After typing")
			.expect($page.locator("//span[@id='text-default-input-type-value']")).toHaveText("text", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-default-input-value-value']")).toHaveText("Sample input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-default-input-id-value']")).toHaveText("text-default-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-default-input-event-value']").textContent()).toMatch("keyup|selectionchange", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-default-input-key-value']")).toHaveText("t", @ScriptLineNumber)
		EndWith

	EndWith

	With teststep("Verify the text input of max length 20")

		With teststep("Initial state")
			.expect($page.locator("//span[@id='text-max-input-type-value']")).toHaveText("text", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-max-input-value-value']")).toHaveText("", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-max-input-id-value']")).toHaveText("text-max-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-max-input-event-value']")).toHaveText("initiated", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-max-input-key-value']")).toHaveText("", @ScriptLineNumber)
		EndWith

		$page.locator("//input[@id='text-max-input']").sendKeys("Short message")

		With teststep("After typing")
			.expect($page.locator("//span[@id='text-max-input-type-value']")).toHaveText("text", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-max-input-value-value']")).toHaveText("Short message", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-max-input-id-value']")).toHaveText("text-max-input", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-max-input-event-value']").textContent()).toMatch("keyup|selectionchange", @ScriptLineNumber)
			.expect($page.locator("//span[@id='text-max-input-key-value']")).toHaveText("e", @ScriptLineNumber)
		EndWith

	EndWith

EndWith

$chrome.close()
