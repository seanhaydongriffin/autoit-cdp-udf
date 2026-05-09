<p align="center">
    <img src="images/icon.png" width="176" />
    <h2 align="center"The AutoIT CDP UDF</h2>
</p>

[![license](https://img.shields.io/badge/license-MIT-ff69b4.svg?style=flat-square&logo=spdx)][license]
[![contributors](https://img.shields.io/github/contributors/Danp2/au3WebDriver.svg?style=flat-square&logo=github)][Contributors]
![repo size](https://img.shields.io/github/repo-size/Danp2/au3WebDriver.svg?style=flat-square&logo=github)
[![last commit](https://img.shields.io/github/last-commit/Danp2/au3WebDriver.svg?style=flat-square&logo=github)](https://github.com/Danp2/au3WebDriver/commits/master)
[![release](https://img.shields.io/github/release/Danp2/au3WebDriver.svg?style=flat-square&logo=github)](https://github.com/Danp2/au3WebDriver/releases/latest)
![os](https://img.shields.io/badge/os-windows-yellow.svg?style=flat-square&logo=windows)
![stars](https://img.shields.io/github/stars/Danp2/au3WebDriver?color=blueviolet&logo=reverbnation&logoColor=white&style=flat-square)

[Description](#description) | [Documentation](#documentation) | [Features](#features) | [Getting started](#getting-started) | [Configuration](#configuration) | [Contributing](#contributing) | [License](#license) | [Acknowledgements](#acknowledgements)

## Description

A modern, high‑performance AutoIt UDF for browser automation using the **Chrome DevTools Protocol (CDP)**.  
This library provides a Playwright‑style API for controlling Chromium‑based browsers directly over CDP — **no WebDriver required**.

The goal of this project is to bring a clean, fluent, reliable automation experience to AutoIt, with first‑class support for:

- Locators  
- Assertions  
- Page interactions  
- Network interception  
- JavaScript evaluation  
- Event handling  

If you’ve used Playwright or Puppeteer, the API will feel instantly familiar.

---

## Features

- Direct CDP communication (no WebDriver, no Selenium)
- Playwright‑inspired Locator API
- Auto‑waiting for elements and conditions
- Built‑in assertion system (`expect()`)
- Support for:
  - navigation
  - clicking
  - typing
  - filling
  - evaluating JavaScript
  - retrieving attributes, text, values
  - checking visibility, enabled/disabled, checked state
- Network request/response interception
- Event‑driven architecture
- Works with Chrome, Edge, Brave, Chromium

---

## Requirements

- AutoIt v3.3.16.0 or later  
- AutoItObject UDF  
- JSON UDF (JsonC recommended)  
- Chromium‑based browser with remote debugging enabled

Example launch:

