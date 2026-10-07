# SPEC.md

Project contract for WinUtil — what the project is, how it's built, and how it runs. Written for anyone, human or AI, who needs to understand the project itself.

`AGENTS.md` in the repository root points here for these facts, and separately covers how an agent should behave while working in this repo. This file does not change based on who's reading it.

## Project Context

WinUtil is a Windows PowerShell utility with a WPF interface. The repository is maintained as modular source, but the distributed artifact is one compiled PowerShell script.

### Stack

- Language: Windows PowerShell / PowerShell.
- UI: WPF via `xaml/inputXML.xaml`.
- Configuration: JSON files under `config/`.
- Tests: Pester tests under `pester/`.
- Lint: PowerShell Script Analyzer with settings in `lint/PSScriptAnalyser.ps1`.
- Docs: Astro + Starlight site under `docs/`, built independently of `Compile.ps1` (its own `package.json`/`node_modules`).
- Release artifact: generated root `winutil.ps1`.

### Repository Layout

- `Compile.ps1`: build script that creates `winutil.ps1`.
- `scripts/start.ps1`: startup/bootstrap segment used at the beginning of the compiled script.
- `scripts/main.ps1`: main entrypoint appended at the end of the compiled script.
- `functions/public/`: public/UI-facing PowerShell functions.
- `functions/private/`: internal helper PowerShell functions.
- `config/`: JSON configuration consumed at compile time and embedded into `$sync.configs`.
- `xaml/inputXML.xaml`: WPF UI markup embedded into the compiled script.
- `tools/autounattend.xml`: unattended setup XML embedded for Windows ISO workflows.
- `pester/`: Pester tests for config and function checks.
- `lint/PSScriptAnalyser.ps1`: PowerShell Script Analyzer settings.
- `tools/title-screen/`: uv project that captures WinUtil's Light and Dark themes and generates the title-screen composite.
- `docs/`: Astro + Starlight documentation site, with its own `package.json` and build independent of `Compile.ps1`.
- `winutil.ps1`: ignored generated build artifact.

## Goals

- Provide a single-script Windows utility that can be launched from PowerShell.
- Keep development modular enough for contributors to work on functions, config, UI, docs, and tooling independently.
- Make install, tweak, feature, repair, update, and ISO workflows discoverable from the WPF UI.
- Keep common lists and options declarative in JSON config where possible.
- Preserve a repeatable compile process so local builds and GitHub Actions builds produce the distributable script from the same inputs.

## Non-Goals

- `winutil.ps1` is not hand-maintained.
- The project is not structured as a PowerShell module at runtime.
- The GUI is not a separate packaged desktop application in this repository's normal release path.
- Generated files should not be reviewed as source changes.

## Build Model

`Compile.ps1` combines the repository sources into `winutil.ps1` in this order:

1. Read `scripts/start.ps1` and replace `#{replaceme}` with `Meta.Version` from `config/localization_ru.json`.
2. Append every file under `functions/` recursively.
3. Convert each `config/*.json` file into embedded `$sync.configs` objects.
4. Special-case `config/applications.json` so keys receive the `WPFInstall` prefix in compiled config.
5. Embed `xaml/inputXML.xaml` into `$inputXML`.
6. Embed `tools/autounattend.xml` into `$WinUtilAutounattendXml`.
7. Append `scripts/main.ps1`.
8. Write the result to root `winutil.ps1`.

Because the final script is concatenated, code cannot rely on runtime module imports or source-relative dot-sourcing unless the compiled script will also contain the required code/data.

## Runtime Model

- WinUtil runs in PowerShell on Windows and uses WPF for the UI. Startup sets the shared console output encoding to UTF-8 before runspaces start, preserving readable native WinGet output and the existing session transcript.
- Shared mutable state is stored in `$sync`, including configs, UI element references, runspace state, selections, and progress.
- Long-running operations use runspaces or existing async patterns so the UI remains responsive.
- UI updates from background work are dispatched back to the WPF UI thread.
- Declarative features such as apps, tweaks, presets, DNS providers, and navigation stay in `config/*.json` unless code is required.

## UI And Event Contract

- UI layout lives in `xaml/inputXML.xaml`.
- Named WPF controls are discovered and stored in `$sync`.
- Button/action wiring follows a naming convention: an element named like `WPFThingButton` maps to a function named like `Invoke-WPFThingButton`.

## Configuration Contract

- Config files must remain valid JSON and compile cleanly through `ConvertFrom-Json`.
- `config/dns.json` opts unfiltered providers into Fastest selection with `BenchmarkEligible: true`; missing or false values exclude a provider from the TCP latency benchmark.
- `config/applications.json` defines installable applications; each entry includes the fields expected by tests and UI code, such as package manager IDs, category, display content, description, and link.
- `config/tweaks.json` defines Windows tweaks; registry and service changes include original values or original states when applicable so undo workflows can restore user systems.
- Preset and navigation files reference valid config keys. Renaming a config key requires updating all presets, UI references, docs, and code paths together.

## Safety Requirements

- Registry, service, package manager, Windows Update, AppX removal, and ISO operations affect the host system and are treated as high-risk.
- Tweak changes include undo metadata when the schema supports it, so changes stay reversible.
- ISO workflows never modify the user's original ISO file; they work on copied/mounted content.

## Docs Site (Astro)

- `docs/` is an Astro + Starlight site, independent of `Compile.ps1`'s build (its own `package.json`/`node_modules`, deployed via the `docs.yaml` GitHub Actions workflow to GitHub Pages).
- Pages live under `docs/src/content/docs/` (`.mdx`), organized into `guides/`, `code-reference/`, plus top-level pages like `faq.mdx`, `knownissues.mdx`, `contributing.mdx`, `index.mdx`.
- `docs/src/content/docs/code-reference/tweaks/` and `.../features/` are auto-generated by `tools/devdocs-generator.ps1` from `config/tweaks.json`/`config/feature.json` and the relevant PowerShell function files. Other pages under `code-reference/` (e.g. `architecture.mdx`) are hand-written and untouched by the generator.
- Sidebar entries in `docs/astro.config.mjs` must match actual page slugs under `docs/src/content/docs/`.
- `docs/public/` is tracked source for static assets (favicons, etc.), not generated output. Generated/ignored paths are listed in `docs/.gitignore` (`dist/`, `.astro/`, `node_modules/`, local env files).
- `docs/src/assets/branding/title-screen.png` is a tracked generated image used by the repository README and docs homepage. Its raw Light and Dark captures are temporary.
- `docs/Dockerfile` and `docs/docker-compose.yml` (service `winutil-astro`) containerize the site's npm tooling; see AGENTS.md's Dependency Installs, Builds, And Dev Servers for why and how agents must use them instead of running npm on the host.

## Testing And CI

- `.\Compile.ps1` verifies the compiler can generate `winutil.ps1`.
- `.\Compile.ps1 -Run` compiles and launches the generated utility for manual GUI verification.
- Pester 5.8.0 runs the suite under `pester/*.Tests.ps1`. GitHub Actions (`unittests.yaml`) installs Pester 5.8.0 fresh and runs with `-CI`, which produces `testResults.xml` and exits non-zero on failure.
- Launcher/cache and release/workflow guard tests also run under Windows PowerShell 5.1, using the same installed Pester 5.8.0 module to check the supported `irm | iex` host.
- GitHub Actions also runs PowerShell Script Analyzer with `lint/PSScriptAnalyser.ps1` on every push. Severity Error diagnostics fail the job; accepted convention warnings remain visible.
- `tools/Test-WinUtilRussianEdition.ps1` is the strict RU release preflight. It verifies that the version maps to a published non-draft/non-prerelease upstream tag, resolves that tag to its exact commit, requires the candidate to descend from that commit, and enforces Git-blob parity across protected runtime/config paths except for an explicit reviewed UI/launcher allowlist.
- Compile & Check validates a Russian standalone artifact for every PR targeting `russian` and every push to `russian`/`update/*`, independently of the PR head branch name. It also explicitly parses compiled output.
- Windows RU builds validate the embedded RU→EN→RU XAML with `tools/Test-WinUtilRussianXaml.ps1` using WPF's `XamlReader.Load` before uploading an artifact. This loads the window without showing it or running system operations; manual GUI QA remains required.
- `.github/workflows/russian-parity-check.yaml` runs that strict parity gate on pushes and pull requests targeting `russian`; any new protected mismatch, missing upstream file, or unapproved addition fails the check.
- The generated `winutil.ps1` may appear locally after compile. It remains ignored build output (see root `.gitignore`) and must not be committed.
- The manually triggered title-screen workflow compiles WinUtil from `main` and opens an image-only pull request when the generated composite changes. These pull requests require manual review. Failed runs retain diagnostics for 14 days.

## Release Artifact

For WinUtil RU, `tools/Build-WinUtilRussianRelease.ps1` first verifies that every runtime/config/compiler/license input in the working tree matches committed HEAD, including ignored and untracked files. It runs the strict parity preflight, compiles repository sources, rechecks the inputs and source commit and produces `dist/winutil-RU.ps1`, `dist/release.json`, and `dist/LICENSE`. The stable release workflow is manual-only; publishing additionally requires `publish_stable=true`. A release is not valid merely because it compiles: strict parity must pass and Windows QA plus explicit owner approval remain required before stable publication.

`tools/Publish-WinUtilRussianRelease.ps1` verifies manifest/artifact integrity and the remote Git tag independently of GitHub Release metadata. Annotated tags are peeled to their commit. An absent tag is created at the exact source SHA with a non-forced push; publication uses `--verify-tag` and checks the tag again before and after publishing. Existing releases and tags are never automatically replaced. Remote/API errors fail the publication.

## Source Launcher and Cache

`bootstrap.ps1` resolves the requested branch once and downloads `run-russian.ps1` by exact commit. The launcher downloads the same commit archive, compiles, parses the generated script and validates actual WPF via Windows PowerShell STA before starting it. ZIP launch does not perform Git ancestry/parity; that remains a CI/release check.

The launcher elevates the application before running its temporary script when needed and waits for the elevated process tree before publishing or removing temporary sources. Restart capability is explicitly passed into the elevated process. Bootstrap uses the same waiting behavior for cached builds. UAC cancellation (Win32 error 1223, including wrapped exceptions) stops bootstrap without falling back to another elevated launch. Other update failures retain the verified-cache fallback. Failed child exit codes propagate as application launch failures.

After successful application exit, the launcher publishes a content-addressed script under `%LocalAppData%/YTY/WindowManager/Stable/versions/<commit>-<hash>/`. `release.json` is an atomically replaced pointer; `release.previous.json` retains only a verified previous pointer. Replacing a corrupt active pointer preserves the existing recovery pointer. Old artifact paths are not overwritten. A cache-only failure after successful application exit produces a warning and does not reopen the old application. Bootstrap verifies script hashes, supports the legacy flat cache and uses only a verified cache when source commit lookup or updating fails.

The fork maintains its own CODEOWNERS and security routing. Upstream publishing, auto-merge, sponsors, title-screen, Pages and issue/discussion-maintenance workflows are repository-guarded. `fork-automation-safety.yaml` also disables those seven workflows at repository level, covering unguarded versions retained on other branches and tags. Pull requests only inspect settings with read permissions; applying the fixed allowlist requires a push or manual run from the trusted `russian` branch and verifies each workflow's `disabled_manually` state. Fork CI and the manual Russian release workflow remain enabled. Original upstream refs and isolated bug-fix work are preserved.
