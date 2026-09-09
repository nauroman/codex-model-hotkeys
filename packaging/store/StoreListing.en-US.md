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
composer. ReasonKey supports the current unified model/Power picker and the
earlier compact/Advanced picker in both Codex and ChatGPT Chat, uses
keyboard-accessible Windows UI Automation controls, and verifies the final
selected value.

In a ChatGPT Chat composer, the same shortcuts select 5.6 Sol with Instant,
Medium, High, and Pro Power. Older combined-label pickers display the endpoints
as Light and Max; that compatibility is retained. Availability
still depends on the user's ChatGPT plan.

Default presets in Codex and ChatGPT Work:

- F16: GPT-6 Astra, Light
- F17: GPT-6 Astra, Medium
- F18: GPT-6 Astra, High
- F19: GPT-6 Astra, Extra High

Ordinary Chat has a separate model catalog. The tested 26.903 app offers
Latest, GPT-5.6 Sol and GPT-5.5 there, without Astra. Use Codex or ChatGPT Work
for Astra; ReasonKey cannot unlock an unavailable model.

Upgrades preserve existing presets. To adopt Astra after upgrading, open
presets.ini from the running ReasonKey tray icon, set the first four Model
values to Astra and Effort to Light, Medium, High, Extra High, then reload.
Store and direct EXE installations keep separate configuration files.

Shortcuts and presets can be edited in a documented `presets.ini` file from the
tray menu. The utility acts only while the Codex/ChatGPT desktop app window is
active. It does not read conversations, use an OpenAI API key, modify app files,
or send telemetry. The Store package contacts only Microsoft Store to check for
ReasonKey updates; the direct EXE does not make network requests.

Requires the Codex/ChatGPT Windows desktop app with English picker labels.

ReasonKey is open source and is an unofficial community utility. It
is not made, endorsed, or supported by OpenAI.

## Features

1. Select a model and reasoning effort with one shortcut
2. Supports current unified and legacy compact/Advanced picker layouts
3. Configurable presets and AutoHotkey hotkey syntax
4. Local diagnostic log and no telemetry
5. Optional startup controlled through Windows Startup Apps
6. Open-source implementation and build instructions
7. Checks Microsoft Store for updates on every Store launch and restarts after
   a permitted update

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

Copyright 2026 ReasonKey contributors. Codex, ChatGPT, and OpenAI are the
property of their respective owners. This product is not affiliated with or
endorsed by OpenAI.

## What's new in 1.0.10

- Recognize the updated 26.903 picker, including its open Select effort Button.
- Astra Light, Medium, High, and Extra High on F16-F19 in Codex and ChatGPT Work.
- Keep ordinary Chat's separate Sol Instant, Medium, High, and Pro presets.
- Keep picker discovery inside the focused popup and active app window.
- Clarify how to update preserved presets in the active Store or EXE installation.
