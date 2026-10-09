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

Published stable release: **[26.09.29-RU.1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/tag/26.09.29-RU.1)**. Based on official **WinUtil 26.09.29**. Localization version: **1.2.1**.

**Published release versus source branch:** the downloadable `26.09.29-RU.1` `winutil-RU.ps1` was built from commit `0f2739e7d7bc74939a8b196a4cbacd9f045dd7ef`. The bootstrap below follows `russian` (as of 2026-10-09: `9f85c63d8c23ba707a120f060dfba5b957176981`), which already includes [PR #11](https://github.com/TokhirjonYuldoshev/WinUtil-RU/pull/11) fixing startup errors. **That fix has not been republished in a release asset.**

## Quick start

Open **PowerShell as Administrator** and run:

```powershell
irm https://raw.githubusercontent.com/TokhirjonYuldoshev/WinUtil-RU/russian/bootstrap.ps1 | iex
```

The bootstrap checks the local build and refreshes it from the `russian` branch when needed. Its source is available in [bootstrap.ps1](bootstrap.ps1).

To run the published stable version, download [winutil-RU.ps1](https://github.com/TokhirjonYuldoshev/WinUtil-RU/releases/download/26.09.29-RU.1/winutil-RU.ps1), open an administrator PowerShell in that folder and run:

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

For `26.09.29-RU.1`, **1021 PowerShell 7 tests and 153 Windows PowerShell 5.1 tests**, strict backend parity and WPF interface loading in **RU → EN → RU** passed. Evidence and verification limits are recorded in the [technical audit in Russian](docs/AUDIT-RU.md).

Separately, the newer `russian` merge commit (`9f85c63d`) passed [1031 PowerShell 7 tests and 163 Windows PowerShell 5.1 tests](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37943543891) with zero failed/skipped, [Compile & Check](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37943543781), and [strict backend parity](https://github.com/TokhirjonYuldoshev/WinUtil-RU/actions/runs/37943543870). **These results validate the branch, not the previously published release asset.**

## Documentation and contributions

- [Russian user guide](docs/README-RU.md) — launch, language, logs and updates.
- [Technical audit in Russian](docs/AUDIT-RU.md) — release baseline, checks and branch protection.
- [Contributing](.github/CONTRIBUTING.md) — change and pull-request rules.
- [Original WinUtil documentation](https://winutil.christitus.com/) — upstream features.

## Credits and license

Original WinUtil: **Chris Titus Tech and project contributors**. Russian localization: **[Tokhirjon Yuldoshev](https://github.com/TokhirjonYuldoshev)**.

Distributed under the original [MIT License](LICENSE), retaining **Copyright (c) 2022 CT Tech Group LLC**. WinUtil RU is an independent fork that preserves upstream attribution.
