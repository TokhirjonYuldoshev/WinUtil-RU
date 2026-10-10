<div align="center">

# WinUtil RU

**The original WinUtil features, with a Russian interface.**

[![Stable release](https://img.shields.io/github/v/release/TokhirjonYuldoshev/WinUtil-RU?label=stable&color=2563eb)](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/latest)
[![Backend parity](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/workflows/russian-parity-check.yaml/badge.svg?branch=russian)](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/workflows/russian-parity-check.yaml)
[![License: MIT](https://img.shields.io/badge/license-MIT-22c55e.svg)](LICENSE)
![Languages](https://img.shields.io/badge/interface-RU%20%2F%20EN-7c3aed.svg)

[**Download**](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/latest) · [**Russian guide**](docs/README-RU.md) · [**Русский**](README.md)

</div>

---

**WinUtil RU** is an independent Russian localization of [Chris Titus Tech's Windows Utility](https://github.com/ChrisTitusTech/winutil). Application management, Windows settings and system tools retain the behavior of the selected official release. Translation and language selection apply to the interface.

Published stable release: **[26.10.07-RU.1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.10.07-RU.1)**. Based on official **WinUtil 26.10.07**. Localization version: **1.2.1**.

**Release versus source branch:** stable tag `26.10.07-RU.1` points to merge commit `1be881f8690aed8e9e4c230d4a0818fd8f311a95`. The owner-tested RC was built from `f1f684ab43f75f075a9947fec2552cd0c615af45`. The published stable `winutil-RU.ps1` is **byte-identical** to the tested prerelease (SHA256: `7399dd337f1194374ee5fb79e89ad32178626bfc939d8df7bdc551fa09cd48f8`). The bootstrap follows the current `russian` branch, which can advance independently; download the release asset for a pinned version.

## Quick start

Open **PowerShell as Administrator** and run:

```powershell
irm https://raw.githubusercontent.com/TokhirjonYuldoshev/WinUtil-RU/russian/bootstrap.ps1 | iex
```

The bootstrap checks the local build and refreshes it from the `russian` branch when needed. Its source is available in [bootstrap.ps1](bootstrap.ps1).

To run the published stable version, download [winutil-RU.ps1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/download/26.10.07-RU.1/winutil-RU.ps1), open an administrator PowerShell in that folder and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\winutil-RU.ps1
```

## Features

| Area | Available features |
| --- | --- |
| Applications | Search, install, update and uninstall using the original WinUtil tools |
| Tweaks | Windows settings and the rollback supported by the original utility |
| DNS and AppX | DNS selection and Windows application management |
| Windows Update | Update modes from the official release |
| Windows 11 | ISO and installation-image tools |
| Interface | Russian and English, translated descriptions, status messages and About |

Choose **Русский / English** in the gear menu, then restart the utility.

## Verified foundation

Operational files are compared against the **exact official release tag**. Interface and launcher differences are reviewed separately. Stable publication requires CI, Windows QA and owner approval.

The `26.10.07-RU.1` release passed the [RC pipeline and Windows validation](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38020610471), [owner QA](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/14#issuecomment-6093518281), and the [protected stable promotion](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/38022376836). PowerShell 7 RC checks reported **1040 passed, 0 failed**; the PowerShell 5.1, WPF RU → EN → RU, compile, and strict backend-parity gates also passed. GitHub confirms the executable SHA256 matches between prerelease and stable. See the [technical audit](docs/AUDIT-RU.md).

Future RC creation is automated as described in the [release pipeline guide](docs/AUTOMATION-RU.md). **Stable releases are never published automatically:** owner Windows QA and a separate protected manual workflow remain mandatory.

## Documentation and contributions

- [Russian user guide](docs/README-RU.md) — launch, language, logs and updates.
- [Technical audit in Russian](docs/AUDIT-RU.md) — release baseline, checks and branch protection.
- [Contributing](.github/CONTRIBUTING.md) — change and pull-request rules.
- [Original WinUtil documentation](https://winutil.christitus.com/) — upstream features.

## Credits and license

Original WinUtil: **Chris Titus Tech and project contributors**. Russian localization: **[Tokhirjon Yuldoshev](https://github.com/TokhirjonYuldoshev)**.

Distributed under the original [MIT License](LICENSE), retaining **Copyright (c) 2022 CT Tech Group LLC**. WinUtil RU is an independent fork that preserves upstream attribution.
