# Microsoft Store listing - en-US

## Product name

ReasonKey

## Short description

Keyboard presets for switching model and reasoning effort in the Codex and
ChatGPT Windows desktop app.

## Description

ReasonKey is an unofficial, lightweight Windows tray utility for people who
switch frequently between complete model presets in the Codex and ChatGPT
desktop app.

Press one shortcut to select the configured model and effort for the active
composer. ReasonKey supports the compact Power picker and expanded Advanced
picker in both Codex and ChatGPT Chat, uses keyboard-accessible Windows UI
Automation controls, and verifies the final selected value.

In a ChatGPT Chat composer, the same shortcuts select 5.6 Sol and map the configured
effort to Chat's labels: Light to Instant, Medium to Medium, High to High,
Extra High to Extra High, and Max or Ultra to Pro. Availability still depends
on the user's ChatGPT plan.

Default presets:

- F16: GPT-5.6 Luna, High
- F17: GPT-5.6 Sol, Light
- F18: GPT-5.6 Sol, Extra High
- F19: GPT-5.6 Sol, Max

Shortcuts and presets can be edited in a documented `presets.ini` file from the
tray menu. The utility acts only while the Codex/ChatGPT desktop app window is
active. It does not read conversations, use an OpenAI API key, modify app files, send
telemetry, or make network requests.

Requires the Codex/ChatGPT Windows desktop app with English picker labels.

ReasonKey is open source and is an unofficial community utility. It
is not made, endorsed, or supported by OpenAI.

## Features

1. Select a model and reasoning effort with one shortcut
2. Supports compact and Advanced picker layouts in Codex and ChatGPT Chat
3. Configurable presets and AutoHotkey hotkey syntax
4. Local diagnostic log and no telemetry
5. Optional startup controlled through Windows Startup Apps
6. Open-source implementation and build instructions

## System requirements

- Windows 10 version 2004 or later, or Windows 11
- x64 processor
- Codex/ChatGPT Windows desktop app
- English Codex and ChatGPT picker labels

## Category

Productivity

## Search terms

AI model hotkeys, model presets, reasoning effort, keyboard shortcuts, model switcher, desktop AI, productivity

## Privacy policy URL

https://github.com/nauroman/codex-model-hotkeys/blob/main/PRIVACY.md

## Website and support URL

https://github.com/nauroman/codex-model-hotkeys

## Copyright and trademark note

Copyright 2026 ReasonKey contributors. Codex and OpenAI are the
property of their respective owners. This product is not affiliated with or
endorsed by OpenAI.

## What's new in 1.0.4

- Prevent the Store and direct-installer versions from running two ReasonKey
  instances in the same Windows session.
- Use the same current Quick Start content for both installation channels.
- Replace and migrate the older Codex Model Hotkeys 1.0.3 runtime.
