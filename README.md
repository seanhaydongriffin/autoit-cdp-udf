<p align="center">
  <img src="images/icon.png" width="176" alt="CDP UDF logo">
</p>
<h3 align="center">AutoIT CDP UDF</h3>
<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-ff69b4.svg?style=flat-square&logo=spdx">
  <img src="https://img.shields.io/github/contributors/seanhaydongriffin/autoit-cdp-udf?style=flat-square&logo=github">
  <img src="https://img.shields.io/github/last-commit/seanhaydongriffin/autoit-cdp-udf?style=flat-square&logo=github">
  <img src="https://img.shields.io/badge/os-windows-yellow?style=flat-square&logo=windows">
  <img src="https://img.shields.io/github/stars/seanhaydongriffin/autoit-cdp-udf?color=blueviolet&logo=reverbnation&logoColor=white&style=flat-square">
</p>

<p align="center">
  <a href="#description">Description</a> •
  <a href="#features">Features</a> •
  <a href="#requirements">Requirements</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#license">License</a> •
  <a href="#acknowledgements">Acknowledgements</a>
</p>

## Description

A modern, high‑performance AutoIt UDF for browser automation using the **Chrome DevTools Protocol (CDP)**.  
This library provides a Playwright‑style API for controlling Chromium‑based browsers directly over CDP — **no WebDriver required**.

The goal of this project is to bring a clean, fluent, reliable automation experience to AutoIt, with first‑class support for:

- Locators  
- Assertions  
- Page interactions
- Test framework
- Network interception ¹ 
- JavaScript evaluation ¹ 
- Event handling ¹ 

¹ not developed

If you’ve used Playwright or Puppeteer, the API will feel instantly familiar.

## Features

- Direct CDP communication (no WebDriver, no Selenium) via WebSockets
- Playwright‑inspired Locator API
- Auto‑waiting for elements and conditions ¹
- Built‑in assertion system (`expect()`)
- Support for:
  - navigation
  - clicking
  - typing
  - filling
  - evaluating JavaScript ¹
  - retrieving attributes, text, values
  - checking visibility, enabled/disabled, checked state
- Network request/response interception ¹
- Event‑driven architecture
- Works with Chrome, Edge, Brave, Chromium ²
- Automatic browser download via Selenium Manager
- Scripts compiled into standalone executables for users to simply run

¹ not developed<br>
² currently only chrome supported

### Comparing CDP UDF to Playwright

    ✔️ = supported
    ❌ = not supported    

### Test Runner & Assertions

| Feature name | CDP UDF | Playwright |
| --- | --- | --- |
| **Test runner included** | ✔️ | ✔️ |
| ``test`` object | ✔️ | ✔️ |
| ``test.step()`` | ✔️ | ✔️ |
| ``test.expect()`` | ✔️ | ✔️ |
| ``test.describe()`` | ❌ | ✔️ |
| ``test.beforeEach()`` | ❌ | ✔️ |
| ``test.afterEach()`` | ❌ | ✔️ |
| **Parallel test execution** | ❌ | ✔️ |
| **Automatic trace viewer** | ❌ | ✔️ |
| **Automatic HTML report** | ❌ | ✔️ |    

### Locator‑Creation Methods

| Feature name | CDP UDF | Playwright | CDP Commands |
| --- | --- | --- | --- |
| ``locator(selector)`` | ✔️ | ✔️ | No CDP — internal selector logic |
| ``filter`` | ❌ | ✔️ | No CDP — internal selector logic |
| ``nth()`` | ❌ | ✔️ | No CDP — internal selector logic |
| ``first()`` | ❌ | ✔️ | No CDP — internal selector logic |
| ``last()`` | ❌ | ✔️ | No CDP — internal selector logic |
| ``getByRole()`` | ❌ | ✔️ | No CDP — internal selector logic |
| ``getByText()`` | ❌ | ✔️ | No CDP — internal selector logic |
| ``getByLabel()`` | ❌ | ✔️ | No CDP — internal selector logic |
| ``getByPlaceholder()`` | ❌ | ✔️ | No CDP — internal selector logic |
| ``getByAltText()`` | ❌ | ✔️ | No CDP — internal selector logic |
| ``getByTitle()`` | ❌ | ✔️ | No CDP — internal selector logic |
| ``getByTestId()`` | ❌ | ✔️ | No CDP — internal selector logic |

### Locator Action Methods

| Feature name | CDP UDF | Playwright | CDP Commands |
| --- | --- | --- | --- |
| ``click()`` | ✔️¹ | ✔️ | DOM.getBoxModel<br>Input.dispatchMouseEvent<br>Runtime.callFunctionOn |
| ``dblclick()`` | ❌ | ✔️ | same as click (twice) |
| ``hover()`` | ❌ | ✔️ | DOM.getBoxModel<br>Input.dispatchMouseEvent |
| ``tap()`` | ❌ | ✔️ | Input.dispatchTouchEvent |
| ``fill()`` | ✔️ | ✔️ | DOM.focus<br>Input.insertText<br>Runtime.callFunctionOn |
| ``type()`` | ❌ | ✔️ | Input.dispatchKeyEvent |
| ``press()`` | ❌ | ✔️ | Input.dispatchKeyEvent |
| ``check()`` | ❌ | ✔️ | Runtime.callFunctionOn<br>Input.dispatchMouseEvent |
| ``uncheck()`` | ❌ | ✔️ | Runtime.callFunctionOn<br>Input.dispatchMouseEvent |
| ``setChecked()`` | ❌ | ✔️ | ?
| ``selectOption()`` | ❌ | ✔️ | Runtime.callFunctionOn<br>DOM.dispatchEvent |
| ``focus()`` | ❌ | ✔️ | DOM.focus |
| ``blur()`` | ❌ | ✔️ | Runtime.callFunctionOn |
| ``clear()`` | ❌ | ✔️ | Runtime.callFunctionOn |
| ``dragTo()`` | ❌ | ✔️ | DOM.getBoxModel<br>Input.dispatchMouseEvent |
| ``setInputFiles()`` | ❌ | ✔️ | DOM.setFileInputFiles |
| ``dispatchEvent()`` | ❌ | ✔️ | DOM.dispatchEvent |
| ``scrollIntoViewIfNeeded()`` | ❌ | ✔️ | DOM.scrollIntoViewIfNeeded<br>Runtime.callFunctionOn |

¹ partially done

### Locator Getter Methods

| Feature name | CDP UDF | Playwright | CDP Commands |
| --- | --- | --- | --- |
| ``textContent()`` | ✔️ | ✔️ | Runtime.callFunctionOn |
| ``innerText()`` | ✔️ | ✔️ | Runtime.callFunctionOn |
| ``innerTextCRStripped()`` | ✔️ | ❌ | Runtime.callFunctionOn |
| ``innerTextLFStripped()`` | ✔️ | ❌ | Runtime.callFunctionOn |
| ``innerTextReplace()`` | ✔️ | ❌ | Runtime.callFunctionOn |
| ``innerHTML()`` | ✔️ | ✔️ | Runtime.callFunctionOn |
| ``inputValue()`` | ✔️ | ✔️ | Runtime.callFunctionOn |
| ``getAttribute()`` | ✔️ | ✔️ | Runtime.callFunctionOn |
| ``boundingBox()`` | ❌ | ✔️ | DOM.getBoxModel |
| ``screenshot()`` | ❌ | ✔️ | DOM.getBoxModel<br>Page.captureScreenshot |
| ``evaluate()`` | ❌ | ✔️ | Runtime.callFunctionOn |
| ``evaluateAll()`` | ❌ | ✔️ | Runtime.callFunctionOn |
| ``elementHandle()`` | ❌ | ✔️ | DOM.resolveNode |
| ``allInnerTexts()`` | ❌ | ✔️ | Runtime.callFunctionOn |
| ``allTextContents()`` | ❌ | ✔️ | Runtime.callFunctionOn |
| ``count()`` | ❌ | ✔️ | DOM.querySelectorAll |

### Locator State Methods

| Feature name | CDP UDF | Playwright | CDP Commands |
| --- | --- | --- | --- |
| ``isVisible()`` | ✔️ | ✔️ | Runtime.callFunctionOn, DOM.getBoxModel |
| ``isHidden()`` | ✔️ | ✔️ | same as isVisible |
| ``isEnabled()`` | ✔️ | ✔️ | Runtime.callFunctionOn |
| ``isDisabled()`` | ✔️ | ✔️ | Runtime.callFunctionOn |
| ``isEditable()`` | ✔️ | ✔️ | Runtime.callFunctionOn |
| ``isChecked()`` | ✔️ | ✔️ | Runtime.callFunctionOn |

### Locator Waiting Methods

| Feature name | CDP UDF | Playwright | CDP Commands |
| --- | --- | --- | --- |
| ``waitFor()`` | ❌ | ✔️ | DOM.querySelector<br>Runtime.callFunctionOn<br>DOM.getBoxModel
| ``waitForElementState()`` | ❌ | ✔️ | Runtime.callFunctionOn<br>DOM.getBoxModel
| ``waitForSelector()`` | ❌ | ✔️ | DOM.querySelector<br>DOM.querySelectorAll

### Locator‑Based Expect Methods

| Feature name | CDP UDF | Playwright | Uses |
| --- | --- | --- | --- |
| ``expect(locator).toBeVisible()`` | ✔️ | ✔️ | isVisible() |
| ``expect(locator).toBeHidden()`` | ✔️ | ✔️ | isHidden() |
| ``expect(locator).toBeEnabled()`` | ✔️ | ✔️ | isEnabled() |
| ``expect(locator).toBeDisabled()`` | ✔️ | ✔️ | isDisabled() |
| ``expect(locator).toBeChecked()`` | ✔️ | ✔️ | isChecked() |
| ``expect(locator).toHaveText()`` | ✔️ | ✔️ | textContent() |
| ``expect(locator).toContainText()`` | ✔️ | ✔️ | textContent() |
| ``expect(locator).toHaveAttribute()`` | ✔️ | ✔️ | getAttribute() |
| ``expect(locator).toHaveClass()`` | ❌ | ✔️ | |
| ``expect(locator).toHaveCount()`` | ❌ | ✔️ | |
| ``expect(locator).toHaveValue()`` | ❌ | ✔️ | |
| ``expect(locator).toHaveJSProperty()`` | ❌ | ✔️ | |

### Value‑Based Expect Methods

| Feature name | CDP UDF | Playwright |
| --- | --- | --- |
| ``expect(value).toBe()`` | ✔️ | ✔️ |
| ``expect(value).toEqual()`` | ❌ | ✔️ |
| ``expect(value).toStrictEqual()`` | ❌ | ✔️ |
| ``expect(value).toBeGreaterThan()`` | ✔️ | ✔️ |
| ``expect(value).toBeGreaterThanOrEqual()`` | ✔️ | ✔️ |
| ``expect(value).toBeLessThan()`` | ✔️ | ✔️ |
| ``expect(value).toBeLessThanOrEqual()`` | ✔️ | ✔️ |
| ``expect(value).toBeCloseTo()`` | ✔️¹ | ✔️ |
| ``expect(value).toContain()`` | ✔️ | ✔️ |
| ``expect(value).toMatch()`` | ✔️ | ✔️ |
| ``expect(value).toBeTruthy()`` | ✔️ | ✔️ |
| ``expect(value).toBeFalsy()`` | ✔️ | ✔️ |
| ``expect(value).toBeNull()`` | ✔️ | ✔️ |
| ``expect(value).toBeDefined()`` | ✔️ | ✔️ |
| ``expect(value).toBeUndefined()`` | ✔️¹ | ✔️ |
| ``expect(value).toContainEqual()`` | ❌ | ✔️ |
| ``expect(value).toHaveLength()`` | ✔️ | ✔️ |
| ``expect(value).toThrow()`` | ❌ | ✔️ |

¹ untested

### Browser / Page Features

| Feature name | CDP UDF | Playwright |
| --- | --- | --- |
| **Launch Chromium** | ✔️ | ✔️ |
| **Connect to existing browser** | ✔️ | ✔️ |
| **Multiple contexts** | ❌ | ✔️ |
| **Multiple pages** | ✔️ | ✔️ |
| **Tracing** | ❌ | ✔️ |
| **HAR recording** | ❌ | ✔️ |
| **Network interception** | ✔️ | ✔️ |
| **Console event capture** | ✔️ | ✔️ |
| **Dialog handling** | ✔️ | ✔️ |
| **Screenshot** | ✔️ | ✔️ |
| **PDF generation** | ❌ | ✔️ |
| **Video recording** | ❌ | ✔️ |

## Requirements

- AutoIt v3.3.16.0 or later  
- AutoItObject UDF  
- JSON UDF (JsonC recommended)  
- Chromium‑based browser with remote debugging enabled

## Getting Started

Try the following examples from the main folder that demonstrate the UDF functions.

| Script | Features Included |
| --- | --- |
| Example Chrome Default.au3 | Test of a basic web page using default "pre-installed" Chrome browser |
| Example Chrome Default Headless.au3 | Test of a basic web page using default "pre-installed" Chrome browser & headless mode |
| Example Chrome v119.au3 | Test of a basic web page using an "auto-installed" Chrome browser v119 |
| Example Playwright Chrome.au3 | Test of a basic web page using optionally installed Playwright Chromium browser |
| Example Playwright Headless Chrome.au3 | Basic Web Page test using optionally installed Playwright Chromium Headless Shell |
| Example Element Attributes.au3 | Test of web element attributes |
| Example Element Attributes Debug.au3 | Test of web element attributes with debugging enabled |
| Example Multiple Elements.au3 | Test of multiple web elements |
| Example Basic Inputs.au3 | Test of basic HTML input elements |
| Example Number Inputs.au3 | Test of numeric HTML input elements |

### Example output 

The Basic Web Page test should output the following:

```text
▶ Test: Basic web page test
  ▶ Step: Verify Basic Web Page navigation
    ▶ Step: Navigate to evil tester test pages
    ▶ Step: Verify the main page
        ✓ Expect: expected [Software Testing Practice Pages, Apps, and Challenges] and got [Software Testing Practice Pages, Apps, and Challenges] (line 29)
        ✓ Expect: expected [Software Testing Practice Pages, Apps, and Challenges] and got [Software Testing Practice Pages, Apps, and Challenges] (line 31)
        ✓ Expect: object [-5136690175131552945.1.1] is hidden (line 32)
        ✓ Expect: expected [False] and got [False] (line 33)
        ✓ Expect: expected [True] and got [True] (line 34)
    ▶ Step: Verify navigation to Pages
        ✓ Expect: expected [Pages] and got [Pages] (line 39)
        ✓ Expect: object [-5136690175131552945.1.2] is visible (line 40)
        ✓ Expect: expected truthy and got [True] (line 41)
        ✓ Expect: expected falsy and got [False] (line 42)
    ▶ Step: Navigate to Pages
    ▶ Step: Verify navigation to Basics
        ✓ Expect: expected [Basics] and got [Basics] (line 50)
    ▶ Step: Navigate to Basic Web Page
  ▶ Step: Verify Basic Web Page
    ▶ Step: Page elements
        ✓ Expect: actual text contains [Elements] (line 63)
        ✓ Expect: expected [Tags:

 Elements Locators

Categories:

 Basics] to contain [Elements] (line 64)
        ✓ Expect: expected [Tags:

 Elements Locators

Categories:

 Basics] to match regex [.*Categor.*] (line 65)
        ✓ Expect: expected [A paragraph of text] and got [A paragraph of text] (line 66)
        ✓ Expect: expected [Another paragraph of text] and got [Another paragraph of text] (line 67)
    ▶ Step: Click Me functionality
        ✓ Expect: expected [You clicked the button!] and got [You clicked the button!] (line 72)
        ✓ Expect: expected defined value and got [defined] (line 73)
        ✓ Expect: expected length [23] and got [23] (line 74)
  ▶ Step: Verify invalid locator
      ✓ Expect: expected Null and got [Null] (line 80)

> BasicWebPageWithStandardBrowser() took n ms.
```



## Configuration

The AutoIT SciTE script editor does not have UTF8 / Unicode support enabled by default.  This is required to display the unicode characters (like ▶✓) in the test output (see the "Example output" above).

To enable this in the AutoIT editor add the following line to your **SciTEUser.properties** file (via menu **Options > Open User Options File**) :

<code>output.code.page=65001</code>

## License

Distributed under the MIT License. See [LICENSE] for more information.

## Acknowledgements

- Opportunity by [GitHub](https://github.com)
- Badges by [Shields](https://shields.io)
- Thanks to the authors of the Third-Party UDFs
  - *AutoItObject* by the AutoItObject-Team (monoceres, trancexx, Kip and progandy)
  - *JsonC* by Sean Griffin
  - *Curl* by Ward and modified by Beege and Sean Griffin
- Thanks to Microsoft Copilot for being my every-optimistic coding-buddy 24/7

