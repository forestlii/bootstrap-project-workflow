# Windows Installation and Distribution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the same Git checkout safely installable, updateable, and removable for Claude Code and Codex on Windows, with repeatable CI and user documentation.

**Architecture:** Public wrapper scripts delegate to one PowerShell module that resolves runtime targets, classifies existing filesystem objects, and manages only directory junctions whose target is the repository's Skill directory. Updates use `git pull --ff-only` only from a clean checkout; uninstall removes verified junctions but never deletes the checkout or generated business-project files.

**Tech Stack:** Windows PowerShell 5.1, PowerShell 7.x, Pester 5.7.1, Git for Windows, GitHub Actions `windows-latest`.

**Spec:** `docs/superpowers/specs/2026-08-24-bootstrap-project-workflow-design.md`

## Global Constraints

- Plan 1 completion gate must already pass.
- Platform is Windows only.
- The repository is private during initial validation and remains MIT licensed.
- Installation creates directory junctions only; it does not copy divergent Skill sources.
- Claude target is `%USERPROFILE%\.claude\skills\bootstrap-project-workflow`.
- Codex target is `%USERPROFILE%\.agents\skills\bootstrap-project-workflow`.
- Both targets point to `$RepositoryRoot\skill\bootstrap-project-workflow`, where `$RepositoryRoot` is the resolved Git checkout.
- Existing ordinary directories, files, unexpected reparse points, and wrong-target junctions are never removed or replaced automatically.
- Update refuses a dirty checkout and uses fast-forward-only pull.
- Uninstall never removes the Git checkout or any business-project scaffold.
- README does not recommend piping a downloaded script directly into PowerShell.

---

## File Map

- `scripts/InstallSupport.psm1`: junction classification, installation, update, and uninstall implementation.
- `install-claude.ps1`: Claude Code entrypoint.
- `install-codex.ps1`: Codex entrypoint.
- `update.ps1`: clean-tree fast-forward updater.
- `uninstall.ps1`: selected-runtime junction removal.
- `tests/InstallSupport.Tests.ps1`: first install, repeat, conflict, wrong target, and path cases.
- `tests/UpdateAndUninstall.Tests.ps1`: Git update safety and recoverable uninstall behavior.
- `.github/workflows/windows-test.yml`: Windows PowerShell and PowerShell 7 test matrix.
- `VERSION`: release version consumed by tests and lock generation.
- `docs/install-windows.md`: clone, install, update, uninstall, and troubleshooting.

### Task 1: Junction state classifier and idempotent installer

**Files:**
- Create: `scripts/InstallSupport.psm1`
- Create: `tests/InstallSupport.Tests.ps1`
- Create: `install-claude.ps1`
- Create: `install-codex.ps1`

**Interfaces:**
- Consumes: repository root, runtime enum, and user profile root.
- Produces: `Get-BpwRuntimeTarget`, `Get-BpwLinkState`, and `Install-BpwRuntime`; wrapper exit `0` for installed/already-correct and `2` for conflicts.

- [ ] **Step 1: Write failing installation tests**

```powershell
BeforeAll {
    Import-Module "$PSScriptRoot/../scripts/InstallSupport.psm1" -Force
}

Describe 'Install-BpwRuntime' -Tag 'Windows' {
    It 'creates the Claude junction and is idempotent' {
        $profile = Join-Path $TestDrive 'Profile With 空格'
        $repo = New-TestDistributionRepository -Root (Join-Path $TestDrive 'Repo')
        $first = Install-BpwRuntime -Runtime Claude -RepositoryRoot $repo -UserProfileRoot $profile
        $second = Install-BpwRuntime -Runtime Claude -RepositoryRoot $repo -UserProfileRoot $profile
        $first.state | Should -Be 'Installed'
        $second.state | Should -Be 'AlreadyInstalled'
        (Get-Item -LiteralPath (Join-Path $profile '.claude/skills/bootstrap-project-workflow')).Attributes |
            Should -Match 'ReparsePoint'
    }

    It 'creates the Codex junction to the identical Skill source' {
        $profile = Join-Path $TestDrive 'Profile'
        $repo = New-TestDistributionRepository -Root (Join-Path $TestDrive 'Repo')
        Install-BpwRuntime -Runtime Claude -RepositoryRoot $repo -UserProfileRoot $profile | Out-Null
        Install-BpwRuntime -Runtime Codex -RepositoryRoot $repo -UserProfileRoot $profile | Out-Null
        (Get-BpwLinkState -LiteralPath (Join-Path $profile '.claude/skills/bootstrap-project-workflow') -ExpectedTarget (Join-Path $repo 'skill/bootstrap-project-workflow')).state | Should -Be 'CorrectJunction'
        (Get-BpwLinkState -LiteralPath (Join-Path $profile '.agents/skills/bootstrap-project-workflow') -ExpectedTarget (Join-Path $repo 'skill/bootstrap-project-workflow')).state | Should -Be 'CorrectJunction'
    }

    It 'refuses an ordinary directory without changing its sentinel' {
        $profile = Join-Path $TestDrive 'Profile'
        $repo = New-TestDistributionRepository -Root (Join-Path $TestDrive 'Repo')
        $target = Join-Path $profile '.agents/skills/bootstrap-project-workflow'
        New-Item -ItemType Directory -Path $target -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $target 'sentinel.txt') -Value 'keep'
        { Install-BpwRuntime -Runtime Codex -RepositoryRoot $repo -UserProfileRoot $profile -ErrorAction Stop } | Should -Throw '*OrdinaryDirectory*'
        Get-Content -LiteralPath (Join-Path $target 'sentinel.txt') | Should -Be 'keep'
    }

    It 'refuses a junction that points to another checkout' {
        $profile = Join-Path $TestDrive 'Profile'
        $repo = New-TestDistributionRepository -Root (Join-Path $TestDrive 'Repo')
        $other = New-TestDistributionRepository -Root (Join-Path $TestDrive 'OtherRepo')
        $target = Join-Path $profile '.claude/skills/bootstrap-project-workflow'
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        New-Item -ItemType Junction -Path $target -Target (Join-Path $other 'skill/bootstrap-project-workflow') | Out-Null
        { Install-BpwRuntime -Runtime Claude -RepositoryRoot $repo -UserProfileRoot $profile -ErrorAction Stop } | Should -Throw '*WrongTargetJunction*'
    }
}
```

Add `New-TestDistributionRepository` to `tests/TestHelpers.ps1`; it creates `skill/bootstrap-project-workflow/SKILL.md` under the supplied root and returns the full root path.

- [ ] **Step 2: Run and observe module import failure**

Run:

```powershell
Invoke-Pester -Path tests/InstallSupport.Tests.ps1 -Output Detailed
```

Expected: FAIL because `scripts/InstallSupport.psm1` is absent.

- [ ] **Step 3: Implement target resolution and junction classification**

Export these exact functions:

```powershell
function Get-BpwRuntimeTarget {
    param(
        [ValidateSet('Claude','Codex')][string]$Runtime,
        [string]$UserProfileRoot = $env:USERPROFILE
    )
}

function Get-BpwLinkState {
    param([string]$LiteralPath, [string]$ExpectedTarget)
}

function Install-BpwRuntime {
    [CmdletBinding()]
    param(
        [ValidateSet('Claude','Codex')][string]$Runtime,
        [string]$RepositoryRoot,
        [string]$UserProfileRoot = $env:USERPROFILE
    )
}
```

`Get-BpwLinkState` returns one of `Missing`, `CorrectJunction`, `WrongTargetJunction`, `OrdinaryDirectory`, `OrdinaryFile`, or `UnexpectedReparsePoint`. Resolve both expected and actual targets to absolute normalized paths and compare with `OrdinalIgnoreCase`. `Install-BpwRuntime` validates Windows, repository root, and Skill source before creating parent directories and one junction with `New-Item -ItemType Junction`. It catches no conflict by deleting; it throws a terminating error whose message includes the state, exact target path, and manual recovery instruction.

- [ ] **Step 4: Implement thin public wrappers**

Each install script uses:

```powershell
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'scripts/InstallSupport.psm1') -Force
$result = Install-BpwRuntime -Runtime Claude -RepositoryRoot $PSScriptRoot
$result | ConvertTo-Json -Depth 4
```

Use `Codex` in `install-codex.ps1`. Neither wrapper downloads files, changes execution policy, or requests elevation.

- [ ] **Step 5: Run installer tests under both hosts**

Run:

```powershell
Invoke-Pester -Path tests/InstallSupport.Tests.ps1 -Output Detailed
powershell.exe -NoProfile -Command "Invoke-Pester -Path tests/InstallSupport.Tests.ps1 -Output Detailed"
```

Expected: both PASS with `4 tests completed, 0 failed`.

- [ ] **Step 6: Commit installers**

```powershell
git add scripts/InstallSupport.psm1 tests/TestHelpers.ps1 tests/InstallSupport.Tests.ps1 install-claude.ps1 install-codex.ps1
git commit -m "feat: install shared skill for Claude and Codex"
```

### Task 2: Safe update and selected-runtime uninstall

**Files:**
- Create: `tests/UpdateAndUninstall.Tests.ps1`
- Create: `update.ps1`
- Create: `uninstall.ps1`
- Modify: `scripts/InstallSupport.psm1`

**Interfaces:**
- Consumes: a Git checkout and runtime selection.
- Produces: `Update-BpwRepository` with before/after hashes; `Uninstall-BpwRuntime` with `Removed|NotInstalled`; public exit `2` for dirty tree or junction conflict.

- [ ] **Step 1: Write failing update and uninstall tests**

Create a local bare remote plus two working clones inside `TestDrive:` so no network is used. Assert:

```powershell
It 'refuses update when the checkout is dirty' {
    $repo = New-TestGitDistribution -Root (Join-Path $TestDrive 'git-fixture')
    Add-Content -LiteralPath (Join-Path $repo.checkout 'README.md') -Value 'dirty'
    { Update-BpwRepository -RepositoryRoot $repo.checkout -ErrorAction Stop } | Should -Throw '*DirtyWorkingTree*'
    (git -C $repo.checkout rev-parse HEAD) | Should -Be $repo.initialCommit
}

It 'fast-forwards a clean checkout' {
    $repo = New-TestGitDistribution -Root (Join-Path $TestDrive 'git-fixture')
    $next = Add-TestRemoteCommit -Fixture $repo
    $result = Update-BpwRepository -RepositoryRoot $repo.checkout
    $result.before | Should -Be $repo.initialCommit
    $result.after | Should -Be $next
}

It 'removes only the verified junction and preserves its target' {
    $profile = Join-Path $TestDrive 'Profile'
    $repo = New-TestDistributionRepository -Root (Join-Path $TestDrive 'Repo')
    Install-BpwRuntime -Runtime Claude -RepositoryRoot $repo -UserProfileRoot $profile | Out-Null
    $result = Uninstall-BpwRuntime -Runtime Claude -RepositoryRoot $repo -UserProfileRoot $profile
    $result.state | Should -Be 'Removed'
    Test-Path -LiteralPath (Join-Path $repo 'skill/bootstrap-project-workflow/SKILL.md') | Should -BeTrue
}
```

Also assert uninstall refuses an ordinary directory and a wrong-target junction while preserving both targets.

- [ ] **Step 2: Run and observe missing function failures**

Run:

```powershell
Invoke-Pester -Path tests/UpdateAndUninstall.Tests.ps1 -Output Detailed
```

Expected: FAIL because update/uninstall functions are not exported.

- [ ] **Step 3: Implement update without shell string evaluation**

`Update-BpwRepository`:

1. validates `.git` and `origin`;
2. runs `git -C $RepositoryRoot status --porcelain=v1 -uall` with an argument array and refuses any output;
3. records `git rev-parse HEAD`;
4. runs `git pull --ff-only` with an argument array;
5. requires Git exit `0`, records the new hash, and returns stdout/stderr plus hashes;
6. never runs checkout, reset, clean, stash, merge, or rebase.

- [ ] **Step 4: Implement verified-link uninstall**

`Uninstall-BpwRuntime` calls `Get-BpwLinkState`. It returns `NotInstalled` for missing; calls `Remove-Item -LiteralPath $targetPath -Force` only for `CorrectJunction`; refuses every other state. Immediately after removal, assert the Skill target directory still exists. `uninstall.ps1` accepts:

```powershell
[ValidateSet('Claude','Codex','All')]
[string]$Runtime = 'All'
```

`update.ps1` imports the module and calls `Update-BpwRepository -RepositoryRoot $PSScriptRoot`.

- [ ] **Step 5: Run update/uninstall and full tests**

Run:

```powershell
Invoke-Pester -Path tests/UpdateAndUninstall.Tests.ps1 -Output Detailed
Invoke-Pester -Path tests -Output Detailed
```

Expected: all PASS; update/uninstall suite reports at least `5` passed tests.

- [ ] **Step 6: Commit lifecycle scripts**

```powershell
git add scripts/InstallSupport.psm1 tests/TestHelpers.ps1 tests/UpdateAndUninstall.Tests.ps1 update.ps1 uninstall.ps1
git commit -m "feat: update and uninstall skill safely"
```

### Task 3: Windows CI and release version contract

**Files:**
- Create: `.github/workflows/windows-test.yml`
- Create: `VERSION`
- Create: `tests/ReleaseContract.Tests.ps1`
- Modify: `skill/bootstrap-project-workflow/assets/scaffold/source/project.json`
- Modify: `README.md`

**Interfaces:**
- Consumes: repository at any commit.
- Produces: version `0.1.0-rc.1`; CI status for both PowerShell hosts; generator reads version from `VERSION` rather than a duplicated constant.

- [ ] **Step 1: Write failing release contract tests**

```powershell
Describe 'release contract' {
    It 'has one valid prerelease version source' {
        $version = (Get-Content -LiteralPath "$PSScriptRoot/../VERSION" -Raw).Trim()
        $version | Should -Match '^0\.1\.0-rc\.1$'
        $project = Get-Content -LiteralPath "$PSScriptRoot/../skill/bootstrap-project-workflow/assets/scaffold/source/project.json" -Raw
        $project | Should -Not -Match '0\.1\.0-dev'
    }

    It 'runs tests in Windows PowerShell and PowerShell 7' {
        $workflow = Get-Content -LiteralPath "$PSScriptRoot/../.github/workflows/windows-test.yml" -Raw
        $workflow | Should -Match 'powershell'
        $workflow | Should -Match 'pwsh'
        $workflow | Should -Match 'Invoke-Pester.*-CI'
    }
}
```

- [ ] **Step 2: Run and observe missing release files**

Run:

```powershell
Invoke-Pester -Path tests/ReleaseContract.Tests.ps1 -Output Detailed
```

Expected: FAIL because `VERSION` and the workflow do not exist.

- [ ] **Step 3: Add version and Windows-only CI**

`VERSION` contains exactly `0.1.0-rc.1` plus one newline. The compiler loads it at bootstrap time and writes it into the generated source/lock; the asset `project.json` no longer carries a fixed generator version.

The workflow has one job on `windows-latest` with two explicit test steps:

```yaml
name: windows-test
on:
  push:
  pull_request:
jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test with PowerShell 7
        shell: pwsh
        run: |
          Install-Module Pester -MinimumVersion 5.7.1 -Scope CurrentUser -Force
          Invoke-Pester -Path tests -CI -Output Detailed
      - name: Test with Windows PowerShell 5.1
        shell: powershell
        run: |
          Install-Module Pester -MinimumVersion 5.7.1 -Scope CurrentUser -Force
          Import-Module Pester -MinimumVersion 5.7.1
          Invoke-Pester -Path tests -CI -Output Detailed
```

- [ ] **Step 4: Run the release suite and local full suite**

Run:

```powershell
Invoke-Pester -Path tests/ReleaseContract.Tests.ps1 -Output Detailed
Invoke-Pester -Path tests -Output Detailed
```

Expected: all PASS and full suite has zero failures.

- [ ] **Step 5: Commit CI and release contract**

```powershell
git add .github/workflows/windows-test.yml VERSION tests/ReleaseContract.Tests.ps1 skill/bootstrap-project-workflow/assets/scaffold/source/project.json skill/bootstrap-project-workflow/scripts/ProjectWorkflow.Compiler.psm1 README.md
git commit -m "ci: test Windows distribution in both PowerShell hosts"
```

### Task 4: Windows installation guide and distribution acceptance

**Files:**
- Create: `docs/install-windows.md`
- Create: `tests/DistributionAcceptance.Tests.ps1`
- Modify: `README.md`

**Interfaces:**
- Consumes: a fresh authenticated clone of the private GitHub repository.
- Produces: complete clone/install/update/uninstall instructions and an offline acceptance test proving both runtime links share one source.

- [ ] **Step 1: Write the failing documentation/acceptance test**

Assert README and the guide contain these literal commands and safety statements:

```powershell
git clone https://github.com/forestlii/bootstrap-project-workflow.git "$env:LOCALAPPDATA\AgentSkills\bootstrap-project-workflow"
Set-Location -LiteralPath "$env:LOCALAPPDATA\AgentSkills\bootstrap-project-workflow"
.\install-claude.ps1
.\install-codex.ps1
.\update.ps1
.\uninstall.ps1 -Runtime All
```

The test also creates an isolated fake profile, installs both links, edits the source `SKILL.md`, observes the same edit through both links, uninstalls both, and asserts the source remains.

- [ ] **Step 2: Run and observe missing documentation failure**

Run:

```powershell
Invoke-Pester -Path tests/DistributionAcceptance.Tests.ps1 -Output Detailed
```

Expected: FAIL because `docs/install-windows.md` is absent.

- [ ] **Step 3: Write the Windows guide and finalize README**

Document prerequisites (Windows, Git for Windows, Claude Code and/or Codex), private-repository GitHub authentication, the fixed clone directory, both installers, restart/new-session discovery, clean-tree update, selected uninstall, every conflict state, and manual recovery. State explicitly:

- bootstrap installation is required only for maintainers who create, upgrade, or re-audit scaffolds;
- generated business-project scaffolds must be committed;
- coworkers consuming a committed scaffold do not install the bootstrap Skill;
- the scripts never change execution policy and the README does not use `iex`, `Invoke-Expression`, or a download-to-pipeline command.

Set README status to `0.1.0-rc.1: Windows distribution ready for pilot validation.` only after the acceptance suite passes.

- [ ] **Step 4: Run the complete distribution gate**

Run:

```powershell
Invoke-Pester -Path tests -Output Detailed -PassThru
powershell.exe -NoProfile -Command "Import-Module Pester -MinimumVersion 5.7.1; Invoke-Pester -Path tests -Output Detailed -PassThru"
git diff --check
git status --short
```

Expected: both hosts have `FailedCount = 0`; `git diff --check` exits `0`; status contains only the guide, acceptance test, and README change.

- [ ] **Step 5: Commit the release candidate documentation**

```powershell
git add docs/install-windows.md tests/DistributionAcceptance.Tests.ps1 README.md
git commit -m "docs: publish Windows installation workflow"
```

### Task 5: Claude Code and Codex bootstrap behavior acceptance

**Files:**
- Create: `tests/fixtures/generic-behavior/README.md`
- Create: `tests/fixtures/generic-behavior/tool.ps1`
- Create: `tests/agent-behavior-contract.json`
- Create after execution: `docs/agent-behavior-acceptance.md`

**Interfaces:**
- Consumes: a disposable copy of the generic fixture, one fresh Claude Code session, one fresh Codex session, and separate user permission for external calls.
- Produces: baseline-versus-installed evidence that the Skill causes read-only inspection, generic-tool detection, an explicit maintainer gate, safe generation after approval, and dual-output drift validation.

- [ ] **Step 1: Define the fixture and machine-readable acceptance contract**

`generic-behavior/README.md` identifies a Windows command-line text normalizer whose entrypoint is `tool.ps1`; it states that input is one UTF-8 text file, output is normalized text on stdout, exit `0` is success, exit `2` is invalid input, and tests/build commands are not yet documented. `tool.ps1` accepts one literal input path, validates it, normalizes CRLF, and writes stdout without modifying files.

`agent-behavior-contract.json` contains:

```json
{
  "schemaVersion": 1,
  "dryRun": {
    "requiredAdapter": "generic-tool",
    "writesMustEqual": [],
    "requiresMaintainerApproval": true,
    "requiredReportFields": ["evidence", "conflicts", "proposedWrites", "unverifiedFacts"]
  },
  "afterApproval": {
    "requiredRootFiles": ["AGENTS.md", "CLAUDE.md"],
    "requiredWorkflowNames": ["feature", "debug", "review", "verify", "continue-work"],
    "driftCheckExitCode": 0
  }
}
```

- [ ] **Step 2: Add a static fixture-contract test and observe failure first**

The Pester test loads the JSON, checks schema `1`, exactly five workflow names, an empty dry-run write array, and the fixture's absence of `.agent-workflow`, `AGENTS.md`, `CLAUDE.md`, `.claude`, and `.agents`. Run it before creating the fixture and require missing-file failure; then add the files above and require the test to pass.

- [ ] **Step 3: Obtain permission for four external Agent runs**

Ask the user to authorize one baseline and one installed-Skill run for Claude Code, plus one baseline and one installed-Skill run for Codex. State that calls may use account quota. If permission is denied, keep release status at `0.1.0-rc.1 behavior validation pending` and do not enter the pilot plan.

- [ ] **Step 4: Record the no-Skill baseline without changing the fixture**

For each runtime, remove only a verified bootstrap junction if present, create a fresh disposable copy of `generic-behavior`, capture its complete tree hash, and use this exact prompt:

```text
请为这个 Windows 工具建立一套 Claude Code 与 Codex 共享的项目工作流。第一轮只做体检，不要写文件。请只输出 JSON：adapter、evidence、conflicts、proposedWrites、unverifiedFacts、requiresMaintainerApproval、writes。
```

Record the response and post-run tree hash. The baseline is observational: do not require it to fail, and do not reinterpret a coincidental match as proof that the Skill was discovered.

- [ ] **Step 5: Install the Skill and run the same dry-run in fresh sessions**

Install each runtime junction from the same checkout, prove both states are `CorrectJunction`, then rerun the identical prompt in a new disposable fixture copy. Validate JSON against `dryRun` and require the before/after tree hashes to match. The response must identify repository-relative evidence and must not contain machine credential or environment-variable values.

- [ ] **Step 6: Approve fixture generation and validate outputs**

In each installed-Skill session, provide the same approval: adapter `generic-tool`; absorb README facts; create only the proposed scaffold paths; keep build/test commands unconfirmed; generate five workflows. After completion, run the project-local drift check, compare Claude/Codex root hashes and all five Skill-pair hashes, and run sync twice to prove the second run creates zero diff.

- [ ] **Step 7: Record the behavior matrix**

`docs/agent-behavior-acceptance.md` records date, exact `claude --version`, exact Codex version command output, bootstrap commit, four run identifiers, pre/post tree hashes, dry-run contract fields, generated artifact count, drift result, and deviations. Do not include full credentials, local profile paths, or account identifiers.

- [ ] **Step 8: Run final tests and commit behavior evidence**

```powershell
Invoke-Pester -Path tests -Output Detailed -PassThru
git diff --check
git add -- tests/fixtures/generic-behavior tests/agent-behavior-contract.json docs/agent-behavior-acceptance.md
git commit -m "test: validate bootstrap behavior in Claude and Codex"
```

Expected: full suite has zero failures; the evidence matrix shows both installed-Skill dry runs passed and both approved generations passed.

## Plan 2 Completion Gate

Do not begin the pilot plan until fresh evidence proves:

- first install and repeat install pass for Claude and Codex;
- ordinary directories, wrong-target junctions, and unexpected reparse points remain untouched;
- both links expose the identical source bytes;
- clean update fast-forwards and dirty update refuses;
- uninstall removes only verified junctions and preserves the checkout;
- Windows PowerShell 5.1 and PowerShell 7.x full suites both have zero failures;
- GitHub Actions on `main` is green for the pushed commit.
- baseline and installed-Skill behavior are recorded separately for both Agents;
- installed-Skill dry runs make zero writes, stop for approval, and approved runs generate both native scaffolds with passing drift checks.
