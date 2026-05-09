<p align="center">
  <img src="images/icon.png" width="176" alt="CDP UDF logo">
</p>

<h3 align="center">AutoIt CDP UDF</h3>


<p align="center">
  <img src="https://img.shields.io/github/license/seanhaydongriffin/autoit-cdp-udf?style=flat-square&logo=spdx">
  <img src="https://img.shields.io/github/contributors/seanhaydongriffin/autoit-cdp-udf?style=flat-square&logo=github">
  <img src="https://img.shields.io/github/last-commit/seanhaydonggriffin/autoit-cdp-udf?style=flat-square&logo=github">
  <img src="https://img.shields.io/badge/os-windows-yellow?style=flat-square&logo=windows">
  <img src="https://img.shields.io/github/stars/seanhaydongriffin/autoit-cdp-udf?color=blueviolet&logo=reverbnation&logoColor=white&style=flat-square">
</p>

[Description](#description) | [Documentation](#documentation) | [Features](#features) | [Getting started](#getting-started) | [Configuration](#configuration) | [Contributing](#contributing) | [License](#license) | [Acknowledgements](#acknowledgements)

<p align="center">
  <a href="#description">Description</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#features">Features</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#contributing">Contributing</a> •
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

