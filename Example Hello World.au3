#AutoIt3Wrapper_UseX64=y
#include "CDP.au3"

$chrome = $browser.launch()
$page = $chrome.newPage()

$page.goto("https://example.com")
$page.screenshot("example.png")

$chrome.close()
