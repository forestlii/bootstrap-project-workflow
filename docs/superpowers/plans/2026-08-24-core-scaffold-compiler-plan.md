# Core Skill and Scaffold Compiler Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the cross-runtime Skill, read-only project inspector, canonical source contract, deterministic Claude Code/Codex scaffold compiler, and drift checker.

**Architecture:** The host Agent inspects evidence and authors `.agent-workflow/source`; PowerShell never invents project semantics. A deterministic compiler validates that source, renders byte-equivalent project rules and skills into each runtime's native discovery paths, vendors its own sync/check implementation into the project, and records SHA-256 mappings in a lock file.

**Tech Stack:** Windows PowerShell 5.1-compatible PowerShell, PowerShell 7.x, Pester 5.7.1, JSON, Markdown, Git.

**Spec:** `docs/superpowers/specs/2026-08-24-bootstrap-project-workflow-design.md`

## Global Constraints

- Platform is Windows only; reject non-Windows hosts with a clear nonzero exit.
- The inspector is read-only and writes its report only to stdout.
- `.agent-workflow/source` is the only hand-maintained workflow source.
- `CLAUDE.md`, `AGENTS.md`, `.claude/skills`, and `.agents/skills` are generated and committed.
- Existing tracked content and unrelated working-tree changes are never cleaned, reset, deleted, or silently overwritten.
- All file operations use `-LiteralPath`; recursive delete and move are absent from the compiler.
- Missing evidence remains `待确认`; scripts do not elevate candidates into confirmed project facts.
- Generated text uses UTF-8 with BOM and CRLF so Windows PowerShell 5.1 preserves Chinese content.
- Production scripts use syntax supported by Windows PowerShell 5.1 and PowerShell 7.x.
- Real Claude Code or Codex calls are outside this plan.

---

## File Map

- `skill/bootstrap-project-workflow/SKILL.md`: cross-runtime orchestration and approval gates.
- `skill/bootstrap-project-workflow/agents/openai.yaml`: optional Codex display metadata only.
- `skill/bootstrap-project-workflow/references/*.md`: authoring contract, migration rules, and adapter evidence rules.
- `skill/bootstrap-project-workflow/scripts/ProjectInspection.psm1`: read-only fact collection and conflict classification.
- `skill/bootstrap-project-workflow/scripts/inspect-project.ps1`: CLI wrapper that emits JSON.
- `skill/bootstrap-project-workflow/scripts/ProjectWorkflow.Compiler.psm1`: canonical validation, rendering, hashing, lock creation, and drift comparison.
- `skill/bootstrap-project-workflow/scripts/render-scaffolds.ps1`: bootstrap-time compiler CLI.
- `skill/bootstrap-project-workflow/scripts/check-scaffolds.ps1`: bootstrap-time read-only drift CLI.
- `skill/bootstrap-project-workflow/scripts/test-project-workflow.ps1`: combined contract check for a target project.
- `skill/bootstrap-project-workflow/assets/scaffold/source/*`: authoring skeletons copied only after the approval gate.
- `skill/bootstrap-project-workflow/assets/scaffold/runtime/*`: self-contained project-local sync/check/verify wrappers.
- `tests/TestHelpers.ps1`: temporary project and encoding helpers.
- `tests/*.Tests.ps1`: focused Pester suites.

### Task 1: Cross-runtime Skill contract and test harness

**Files:**
- Create: `tests/TestHelpers.ps1`
- Create: `tests/SkillContract.Tests.ps1`
- Create: `skill/bootstrap-project-workflow/SKILL.md`
- Create: `skill/bootstrap-project-workflow/agents/openai.yaml`
- Create: `skill/bootstrap-project-workflow/references/workflow-core.md`
- Create: `skill/bootstrap-project-workflow/references/scaffold-contract.md`
- Create: `skill/bootstrap-project-workflow/references/migration-rules.md`

**Interfaces:**
- Consumes: approved design spec.
- Produces: a discoverable Skill named `bootstrap-project-workflow`; `New-TestProject -Name [string]` and `Get-Utf8Text -LiteralPath [string]` test helpers.

- [ ] **Step 1: Install the test runner only after user approval**

Run:

```powershell
Install-Module Pester -MinimumVersion 5.7.1 -Scope CurrentUser -Force
```

Expected: `Get-Module -ListAvailable Pester` reports version `5.7.1` or newer. If installation is not authorized, run this task in the Windows CI environment and record that local execution is pending instead of claiming local passage.

- [ ] **Step 2: Write the failing Skill contract test**

```powershell
BeforeAll {
    . "$PSScriptRoot/TestHelpers.ps1"
    $repo = Split-Path -Parent $PSScriptRoot
    $skillRoot = Join-Path $repo 'skill/bootstrap-project-workflow'
}

Describe 'bootstrap-project-workflow Skill contract' {
    It 'uses portable frontmatter and ships every referenced file' {
        $text = Get-Content -LiteralPath (Join-Path $skillRoot 'SKILL.md') -Raw
        $text | Should -Match '(?ms)^---\r?\nname: bootstrap-project-workflow\r?\ndescription: .+?\r?\n---'
        $text | Should -Not -Match 'allowed-tools:|hooks:|context: fork'
        @('workflow-core.md', 'scaffold-contract.md', 'migration-rules.md') | ForEach-Object {
            Test-Path -LiteralPath (Join-Path $skillRoot "references/$_") | Should -BeTrue
        }
    }

    It 'states the authoring and approval boundary' {
        $text = Get-Content -LiteralPath (Join-Path $skillRoot 'SKILL.md') -Raw
        $text | Should -Match '宿主 Agent 起草'
        $text | Should -Match '项目维护者审核'
        $text | Should -Match '未确认前不得写入目标项目'
    }
}
```

- [ ] **Step 3: Run the test and observe the missing-file failure**

Run:

```powershell
Invoke-Pester -Path tests/SkillContract.Tests.ps1 -Output Detailed
```

Expected: FAIL because `skill/bootstrap-project-workflow/SKILL.md` does not exist.

- [ ] **Step 4: Add the final Skill orchestration contract**

Use this frontmatter and workflow body in `SKILL.md`:

```markdown
---
name: bootstrap-project-workflow
description: Bootstrap or re-audit a Windows project so Claude Code and Codex share one project workflow source and committed native discovery files. Use when a maintainer wants to inspect a project, migrate existing CLAUDE.md or AGENTS.md rules, create .agent-workflow, or synchronize dual-runtime scaffolds.
---

# Bootstrap Project Workflow

Only operate on a Windows project root explicitly supplied by the user.

1. Read `references/workflow-core.md`, `references/scaffold-contract.md`, and `references/migration-rules.md` completely.
2. Select exactly one adapter reference from repository evidence: `unity.md`, `unreal.md`, or `generic-tool.md`.
3. Run `scripts/inspect-project.ps1 -ProjectRoot $projectRoot` with the user-supplied absolute path and present its evidence, conflicts, proposed source files, and unverified assumptions. This phase is read-only.
4. Stop for maintainer approval of the adapter, migrated rules, write set, verification boundary, and every unverified project fact. 未确认前不得写入目标项目。
5. After approval, act as the semantic author: write `.agent-workflow/source` from repository evidence and maintainer answers. Mark unsupported claims as `待确认`; do not invent project facts.
6. Run `scripts/render-scaffolds.ps1` only after the canonical source and migration acknowledgements are complete.
7. Run the generated `.agent-workflow/scripts/check-scaffolds.ps1` and report the exact test count, failures, hashes, and remaining manual checks.

The authoring responsibility is 宿主 Agent 起草、项目维护者审核. PowerShell validates and compiles; it does not decide project semantics. A repository is clone/pull-ready only after the maintainer commits the canonical source and all generated artifacts.
```

In `agents/openai.yaml`, add only UI metadata:

```yaml
interface:
  display_name: "Bootstrap Project Workflow"
  short_description: "Create one Windows project workflow for Claude Code and Codex"
  default_prompt: "Use $bootstrap-project-workflow to inspect this project and propose a dual-runtime workflow scaffold without writing before approval."
```

Write the three reference files with these non-overlapping responsibilities:

- `workflow-core.md`: seven lifecycle phases, stop conditions, evidence classes, and the rule that a host Agent authors semantics.
- `scaffold-contract.md`: exact canonical/generated paths, JSON schemas, encoding, ordering, generated notice, and commit requirements.
- `migration-rules.md`: tracked/untracked behavior, accepted SHA-256 records, dual-entry conflict handling, and no automatic backups.

- [ ] **Step 5: Run the Skill contract test**

Run:

```powershell
Invoke-Pester -Path tests/SkillContract.Tests.ps1 -Output Detailed
```

Expected: PASS with `2 tests completed, 0 failed`.

- [ ] **Step 6: Commit the Skill contract**

```powershell
git add tests/TestHelpers.ps1 tests/SkillContract.Tests.ps1 skill/bootstrap-project-workflow/SKILL.md skill/bootstrap-project-workflow/agents/openai.yaml skill/bootstrap-project-workflow/references/workflow-core.md skill/bootstrap-project-workflow/references/scaffold-contract.md skill/bootstrap-project-workflow/references/migration-rules.md
git commit -m "feat: define cross-runtime bootstrap skill contract"
```

### Task 2: Read-only project inspector and adapters

**Files:**
- Create: `tests/ProjectInspection.Tests.ps1`
- Create: `skill/bootstrap-project-workflow/scripts/ProjectInspection.psm1`
- Create: `skill/bootstrap-project-workflow/scripts/inspect-project.ps1`
- Create: `skill/bootstrap-project-workflow/references/unity.md`
- Create: `skill/bootstrap-project-workflow/references/unreal.md`
- Create: `skill/bootstrap-project-workflow/references/generic-tool.md`

**Interfaces:**
- Consumes: absolute project root.
- Produces: `Get-BpwProjectInspection -ProjectRoot [string] -> PSCustomObject`; CLI JSON with `schemaVersion`, `projectRoot`, `git`, `adapter`, `existingEntrypoints`, `workflowSources`, `verificationCandidates`, `conflicts`, and `unverifiedFacts`.

- [ ] **Step 1: Write failing inspector tests**

Create isolated fixture directories inside Pester `TestDrive:` and assert all three adapters plus no-write behavior:

```powershell
BeforeAll {
    Import-Module "$PSScriptRoot/../skill/bootstrap-project-workflow/scripts/ProjectInspection.psm1" -Force
}

Describe 'Get-BpwProjectInspection' {
    It 'detects Unity from evidence and does not mutate the project' {
        $root = Join-Path $TestDrive 'Unity 工具'
        New-Item -ItemType Directory -Path (Join-Path $root 'ProjectSettings') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'ProjectSettings/ProjectVersion.txt') -Value 'm_EditorVersion: 2022.3.62f2c1'
        New-Item -ItemType Directory -Path (Join-Path $root 'Assets') -Force | Out-Null
        $before = Get-ChildItem -LiteralPath $root -Recurse | Select-Object -ExpandProperty FullName

        $result = Get-BpwProjectInspection -ProjectRoot $root

        $result.adapter.kind | Should -Be 'unity'
        $result.adapter.evidence | Should -Contain 'ProjectSettings/ProjectVersion.txt'
        $after = Get-ChildItem -LiteralPath $root -Recurse | Select-Object -ExpandProperty FullName
        Compare-Object $before $after | Should -BeNullOrEmpty
    }

    It 'detects Unreal only from a uproject and Source or Config' {
        $root = Join-Path $TestDrive 'UnrealGame'
        New-Item -ItemType Directory -Path (Join-Path $root 'Source') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'UnrealGame.uproject') -Value '{"FileVersion":3}'
        $result = Get-BpwProjectInspection -ProjectRoot $root
        $result.adapter.kind | Should -Be 'unreal'
        $result.adapter.evidence | Should -Contain 'UnrealGame.uproject'
    }

    It 'falls back to generic-tool and marks build commands unverified' {
        $root = Join-Path $TestDrive 'GenericTool'
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'tool.ps1') -Value 'param()'
        $result = Get-BpwProjectInspection -ProjectRoot $root
        $result.adapter.kind | Should -Be 'generic-tool'
        @($result.verificationCandidates | Where-Object { -not $_.confirmed }).Count | Should -BeGreaterThan 0
    }

    It 'reports existing generated and hand-maintained entrypoints separately' {
        $root = Join-Path $TestDrive 'ExistingRules'
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'AGENTS.md') -Value '# Hand maintained'
        Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value "GENERATED by bootstrap-project-workflow.`r`nEdit .agent-workflow/source"
        $result = Get-BpwProjectInspection -ProjectRoot $root
        ($result.existingEntrypoints | Where-Object path -eq 'AGENTS.md').generated | Should -BeFalse
        ($result.existingEntrypoints | Where-Object path -eq 'CLAUDE.md').generated | Should -BeTrue
    }
}
```

- [ ] **Step 2: Run the inspector test and observe import failure**

Run:

```powershell
Invoke-Pester -Path tests/ProjectInspection.Tests.ps1 -Output Detailed
```

Expected: FAIL because `ProjectInspection.psm1` is absent.

- [ ] **Step 3: Implement the inspector without write APIs**

Export exactly this function:

```powershell
function Get-BpwProjectInspection {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)
    # Resolve and validate the root; collect only file existence, text evidence,
    # git read commands, hashes, and candidate commands; return a PSCustomObject.
}

Export-ModuleMember -Function Get-BpwProjectInspection
```

Implementation requirements:

- Resolve with `[System.IO.Path]::GetFullPath()` and require an existing directory.
- Invoke only read-only Git commands: `rev-parse --show-toplevel`, `branch --show-current`, `status --porcelain=v1 -uall`, and `ls-files --error-unmatch -- $relativePath` with an argument array.
- Classify an entrypoint as generated only when it contains both `GENERATED by bootstrap-project-workflow.` and `Edit .agent-workflow/source`.
- Detect Unity from `ProjectSettings/ProjectVersion.txt` plus `Assets` or `Packages`; Unreal from one `.uproject` plus `Source` or `Config`; otherwise `generic-tool`.
- Return build and test commands as candidates with `confirmed = $false`; never execute them.
- Exclude file bodies, credentials, URL values, and machine setting values from JSON; evidence records contain relative paths and reason strings.
- Do not call `Set-Content`, `Out-File`, `New-Item`, `Remove-Item`, `Move-Item`, or `Copy-Item` from the production module.

The wrapper accepts `-ProjectRoot` and `-Depth 8`, imports the module, converts with `ConvertTo-Json -Depth $Depth`, writes stdout, and exits `2` for invalid input.

- [ ] **Step 4: Write the three adapter references**

Each reference lists exact evidence and review questions:

- `unity.md`: version file, asmdef boundaries, Editor/Runtime split, `.meta`, batch `-executeMethod`, Player/manual evidence, and commercial resource exclusions.
- `unreal.md`: `.uproject`, `Build.cs`, modules, UHT/reflection, UObject lifetime, Game Thread, Blueprint/C++ boundary, Automation Test, Cook/Package.
- `generic-tool.md`: manifests, CLI/GUI entrypoints, input/output contracts, exit codes, stdout/stderr, idempotence, filesystem effects, packaging, and end-to-end checks.

Every candidate derived from naming alone is labeled `待确认`.

- [ ] **Step 5: Run inspector and Skill contract tests**

Run:

```powershell
Invoke-Pester -Path tests/ProjectInspection.Tests.ps1,tests/SkillContract.Tests.ps1 -Output Detailed
```

Expected: all tests PASS and the output count is at least `6`.

- [ ] **Step 6: Commit the inspector**

```powershell
git add tests/ProjectInspection.Tests.ps1 skill/bootstrap-project-workflow/scripts/ProjectInspection.psm1 skill/bootstrap-project-workflow/scripts/inspect-project.ps1 skill/bootstrap-project-workflow/references/unity.md skill/bootstrap-project-workflow/references/unreal.md skill/bootstrap-project-workflow/references/generic-tool.md skill/bootstrap-project-workflow/SKILL.md
git commit -m "feat: inspect Windows projects without mutation"
```

### Task 3: Canonical source schema and five workflow skills

**Files:**
- Create: `tests/CanonicalSource.Tests.ps1`
- Create: `skill/bootstrap-project-workflow/assets/scaffold/source/project.json`
- Create: `skill/bootstrap-project-workflow/assets/scaffold/source/project.md`
- Create: `skill/bootstrap-project-workflow/assets/scaffold/source/architecture.md`
- Create: `skill/bootstrap-project-workflow/assets/scaffold/source/component-catalog.md`
- Create: `skill/bootstrap-project-workflow/assets/scaffold/source/build-test.md`
- Create: `skill/bootstrap-project-workflow/assets/scaffold/source/skills/feature.md`
- Create: `skill/bootstrap-project-workflow/assets/scaffold/source/skills/debug.md`
- Create: `skill/bootstrap-project-workflow/assets/scaffold/source/skills/review.md`
- Create: `skill/bootstrap-project-workflow/assets/scaffold/source/skills/verify.md`
- Create: `skill/bootstrap-project-workflow/assets/scaffold/source/skills/continue-work.md`
- Create: `skill/bootstrap-project-workflow/assets/scaffold/systems/INDEX.md`
- Create: `skill/bootstrap-project-workflow/assets/scaffold/memory.md`
- Create: `skill/bootstrap-project-workflow/assets/scaffold/decisions.md`

**Interfaces:**
- Consumes: host-Agent-authored Markdown and maintainer-confirmed `project.json`.
- Produces: schema version `1` canonical source with adapter enum `unity|unreal|generic-tool`, migration acknowledgements, verification command records, and five portable Skill sources.

- [ ] **Step 1: Write the failing source contract test**

```powershell
Describe 'canonical scaffold assets' {
    BeforeAll { $assets = "$PSScriptRoot/../skill/bootstrap-project-workflow/assets/scaffold" }

    It 'defines project schema version 1 and no enabled unconfirmed command' {
        $config = Get-Content -LiteralPath (Join-Path $assets 'source/project.json') -Raw | ConvertFrom-Json
        $config.schemaVersion | Should -Be 1
        $config.adapter | Should -BeIn @('unity', 'unreal', 'generic-tool')
        @($config.verification.commands | Where-Object { $_.enabled -and -not $_.confirmed }).Count | Should -Be 0
    }

    It 'ships exactly five portable workflow sources' {
        $names = Get-ChildItem -LiteralPath (Join-Path $assets 'source/skills') -Filter '*.md' |
            ForEach-Object { $_.BaseName } | Sort-Object
        $names | Should -Be @('continue-work', 'debug', 'feature', 'review', 'verify')
        foreach ($name in $names) {
            $text = Get-Content -LiteralPath (Join-Path $assets "source/skills/$name.md") -Raw
            $text | Should -Match "(?m)^name: $([regex]::Escape($name))$"
            $text | Should -Match '(?m)^description: .+$'
        }
    }
}
```

- [ ] **Step 2: Run the source test and observe missing assets**

Run:

```powershell
Invoke-Pester -Path tests/CanonicalSource.Tests.ps1 -Output Detailed
```

Expected: FAIL because the asset tree is absent.

- [ ] **Step 3: Define the machine-readable source contract**

Use this complete shape for the authoring skeleton; empty arrays mean “no maintainer-confirmed value”, not inferred approval:

```json
{
  "schemaVersion": 1,
  "projectName": "unconfirmed-project",
  "adapter": "generic-tool",
  "generatorVersion": "0.1.0-dev",
  "migration": {
    "acceptedInputs": [],
    "conflictsResolved": false,
    "approvedByMaintainer": false
  },
  "verification": {
    "commands": []
  }
}
```

An accepted input has `path`, lowercase `sha256`, and `classification` (`existing-rule`, `runtime-specific`, or `obsolete`). A verification command has `name`, exactly one of `executable` or `executableEnv`, `arguments` as an array, `workingDirectory`, `expectedExitCode`, `requiredMarkers` as an array, `confirmed`, and `enabled`. `executableEnv` stores an environment-variable name such as `UNITY_EDITOR_PATH`, never its machine-specific value. The compiler rejects enabled commands unless `confirmed` is true.

- [ ] **Step 4: Write the authoring skeleton and five final workflow contracts**

The four root Markdown files contain required section headings and authoring rules, not invented facts. Each workflow source uses portable frontmatter and these mandatory outputs:

| Source | Mandatory sequence and output |
|---|---|
| `feature.md` | confirm behavior and exclusions; locate components and source anchors; present options and gate; implement; verify; update memory/devlog |
| `debug.md` | reproduce; collect raw evidence; trace root-cause chain; create regression check; fix only when authorized; rerun original symptom |
| `review.md` | inspect diff and surrounding code; report correctness, architecture, regression, and verification findings with file/line evidence; do not mutate |
| `verify.md` | enumerate claims; map each to command and expected markers; run; report exact exit, test count, failures, and manual gaps |
| `continue-work.md` | read root rules, memory, decisions, system index, local handoff, and Git status; report completed, pending, next smallest action, blockers |

Use the following frontmatter pattern in every file:

```markdown
---
name: feature
description: Use for a new feature or behavior change in this project; requires evidence, an approved design gate, implementation, and claim-matched verification.
---
```

Change `name` and `description` for the other four workflows. Do not include Claude-only tool lists, Codex-only metadata, hooks, or subagent syntax.

- [ ] **Step 5: Run canonical source tests**

Run:

```powershell
Invoke-Pester -Path tests/CanonicalSource.Tests.ps1 -Output Detailed
```

Expected: PASS with exactly `2 tests completed, 0 failed`.

- [ ] **Step 6: Commit the canonical source contract**

```powershell
git add tests/CanonicalSource.Tests.ps1 skill/bootstrap-project-workflow/assets/scaffold
git commit -m "feat: define canonical project workflow source"
```

### Task 4: Deterministic dual-runtime compiler

**Files:**
- Create: `tests/ScaffoldCompiler.Tests.ps1`
- Create: `skill/bootstrap-project-workflow/scripts/ProjectWorkflow.Compiler.psm1`
- Create: `skill/bootstrap-project-workflow/scripts/render-scaffolds.ps1`
- Create: `skill/bootstrap-project-workflow/assets/scaffold/runtime/sync-scaffolds.ps1`
- Create: `skill/bootstrap-project-workflow/assets/scaffold/runtime/check-scaffolds.ps1`
- Create: `skill/bootstrap-project-workflow/assets/scaffold/runtime/verify-project.ps1`

**Interfaces:**
- Consumes: `.agent-workflow/source/project.json` under the supplied project root, four ordered root Markdown files, and five `source/skills/*.md` files.
- Produces: `Invoke-BpwRender -ProjectRoot [string] -GeneratorVersion [string] -> PSCustomObject`; root entrypoints, ten native Skill files, three project-local wrappers, vendored compiler module, and `scaffold.lock.json`.

- [ ] **Step 1: Write failing render and idempotence tests**

```powershell
BeforeAll {
    Import-Module "$PSScriptRoot/../skill/bootstrap-project-workflow/scripts/ProjectWorkflow.Compiler.psm1" -Force
}

Describe 'Invoke-BpwRender' {
    It 'renders equal semantics into both native discovery trees' {
        $root = New-TestProject -Name '双 Agent 工具'
        Install-TestCanonicalSource -ProjectRoot $root -Adapter 'generic-tool' -Approved

        $result = Invoke-BpwRender -ProjectRoot $root -GeneratorVersion '0.1.0-dev'

        $result.changed | Should -BeTrue
        Get-Content -LiteralPath (Join-Path $root 'AGENTS.md') -Raw |
            Should -Be (Get-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Raw)
        foreach ($name in 'feature','debug','review','verify','continue-work') {
            Get-Content -LiteralPath (Join-Path $root ".agents/skills/$name/SKILL.md") -Raw |
                Should -Be (Get-Content -LiteralPath (Join-Path $root ".claude/skills/$name/SKILL.md") -Raw)
        }
    }

    It 'produces zero byte changes on the second render' {
        $root = New-TestProject -Name 'idempotent'
        Install-TestCanonicalSource -ProjectRoot $root -Adapter 'generic-tool' -Approved
        Invoke-BpwRender -ProjectRoot $root -GeneratorVersion '0.1.0-dev'
        $before = Get-TestTreeHash -LiteralPath $root
        $second = Invoke-BpwRender -ProjectRoot $root -GeneratorVersion '0.1.0-dev'
        $after = Get-TestTreeHash -LiteralPath $root
        $second.changed | Should -BeFalse
        $after | Should -Be $before
    }
}
```

Add complete helpers `Install-TestCanonicalSource` and `Get-TestTreeHash` to `tests/TestHelpers.ps1`; copy the committed asset source, set `projectName`, `adapter`, and `migration.approvedByMaintainer = true`, then hash relative paths plus bytes in ordinal path order.

- [ ] **Step 2: Run the compiler tests and observe module import failure**

Run:

```powershell
Invoke-Pester -Path tests/ScaffoldCompiler.Tests.ps1 -Output Detailed
```

Expected: FAIL because `ProjectWorkflow.Compiler.psm1` is absent.

- [ ] **Step 3: Implement canonical validation and byte-stable rendering**

Export exactly:

```powershell
Export-ModuleMember -Function @(
    'Get-BpwSha256',
    'Test-BpwCanonicalSource',
    'Invoke-BpwRender',
    'Test-BpwScaffoldDrift',
    'Invoke-BpwProjectVerification'
)
```

Compiler rules:

1. Validate schema `1`, allowed adapter, maintainer approval, all required root sources, exactly five required Skill names, portable frontmatter, and no enabled unconfirmed command.
2. Compose root text in fixed order: generated notice, canonical-source instruction, `project.md`, `architecture.md`, `component-catalog.md`, `build-test.md`, then links to `.agent-workflow/memory.md`, `decisions.md`, and `systems/INDEX.md`.
3. Write identical bytes to `AGENTS.md` and `CLAUDE.md`.
4. Insert the generated notice immediately after Skill frontmatter and write identical bytes to the corresponding Claude and Codex Skill paths.
5. Copy the compiler module to `.agent-workflow/scripts/ProjectWorkflow.Compiler.psm1` and copy the three runtime wrappers.
6. Store paths with `/`, ordinal sort order, lowercase SHA-256, adapter, schema version, generator version, and `generatedAtUtc` in `scaffold.lock.json`.
7. If all would-be output bytes and source mappings equal the existing lock, preserve the old `generatedAtUtc`, perform no write, and return `changed = $false`.
8. Write each changed file to a same-directory temporary path, flush, then use `[System.IO.File]::Replace` when a destination exists and `[System.IO.File]::Move` when it does not. On unsupported replace, use a single validated `MoveFileExW` replacement; never use delete-then-move.

The fixed notice is:

```text
GENERATED by bootstrap-project-workflow.
Edit .agent-workflow/source, then run .agent-workflow/scripts/sync-scaffolds.ps1.
```

- [ ] **Step 4: Implement bootstrap and project-local wrappers**

`render-scaffolds.ps1` imports its sibling compiler module and calls `Invoke-BpwRender`. The vendored `sync-scaffolds.ps1` resolves the project root as two parents above `$PSScriptRoot`, imports the vendored compiler, reads generator version from the lock, and calls the same function. `check-scaffolds.ps1` calls only `Test-BpwScaffoldDrift` and exits `1` on any mismatch. `verify-project.ps1` lists commands by default and requires `-Execute -Name 'configured-name'` before invoking that exact maintainer-confirmed command.

- [ ] **Step 5: Run render tests under both PowerShell hosts**

Run:

```powershell
Invoke-Pester -Path tests/ScaffoldCompiler.Tests.ps1 -Output Detailed
powershell.exe -NoProfile -Command "Invoke-Pester -Path tests/ScaffoldCompiler.Tests.ps1 -Output Detailed"
```

Expected: both commands PASS with the same test count and zero failures.

- [ ] **Step 6: Commit the compiler**

```powershell
git add tests/TestHelpers.ps1 tests/ScaffoldCompiler.Tests.ps1 skill/bootstrap-project-workflow/scripts/ProjectWorkflow.Compiler.psm1 skill/bootstrap-project-workflow/scripts/render-scaffolds.ps1 skill/bootstrap-project-workflow/assets/scaffold/runtime
git commit -m "feat: compile canonical workflow for Claude and Codex"
```

### Task 5: Drift detection, command evidence, and encoding/path matrix

**Files:**
- Create: `tests/ScaffoldDrift.Tests.ps1`
- Create: `tests/EncodingAndPaths.Tests.ps1`
- Create: `skill/bootstrap-project-workflow/scripts/check-scaffolds.ps1`
- Create: `skill/bootstrap-project-workflow/scripts/test-project-workflow.ps1`
- Modify: `skill/bootstrap-project-workflow/scripts/ProjectWorkflow.Compiler.psm1`

**Interfaces:**
- Consumes: lock file and current artifact bytes; confirmed verification record.
- Produces: `Test-BpwScaffoldDrift` result with `isValid`, `checkedCount`, and `mismatches[]`; `Invoke-BpwProjectVerification` result with command, exit code, markers, and success.

- [ ] **Step 1: Write failing drift and verification evidence tests**

Cover these exact cases:

```powershell
It 'reports the edited artifact and canonical repair instruction' {
    $root = New-RenderedTestProject
    Add-Content -LiteralPath (Join-Path $root 'AGENTS.md') -Value 'manual edit'
    $result = Test-BpwScaffoldDrift -ProjectRoot $root
    $result.isValid | Should -BeFalse
    $result.mismatches.output | Should -Contain 'AGENTS.md'
    $result.repair | Should -Be 'Edit .agent-workflow/source, then run .agent-workflow/scripts/sync-scaffolds.ps1.'
}

It 'does not accept exit zero without every required marker' {
    $root = New-RenderedTestProject -VerificationCommand (New-TestCommand -ExitCode 0 -Output 'one marker')
    $result = Invoke-BpwProjectVerification -ProjectRoot $root -Name 'fixture' -Execute
    $result.exitCode | Should -Be 0
    $result.success | Should -BeFalse
    $result.missingMarkers.Count | Should -Be 1
}
```

The encoding suite renders a project named `含 空格-中文`, adds CRLF Chinese content to every source, checks UTF-8 BOM bytes `EF BB BF`, and renders from a path longer than 180 characters without using wildcard paths.

- [ ] **Step 2: Run the suites and observe failures**

Run:

```powershell
Invoke-Pester -Path tests/ScaffoldDrift.Tests.ps1,tests/EncodingAndPaths.Tests.ps1 -Output Detailed
```

Expected: FAIL because drift details and marker-aware command execution are incomplete.

- [ ] **Step 3: Implement drift and evidence rules**

- Hash every lock artifact and report missing, unexpected-hash, and invalid-lock separately.
- Count actual checked artifacts; the CLI emits JSON integer fields `checked` and `mismatches`, then exits nonzero when `mismatches` is greater than zero.
- Verification resolves only the exact configured executable or the named environment variable and the exact argument array; it never evaluates a command string with `Invoke-Expression`.
- Capture stdout and stderr separately, require the expected exit code and every literal marker, and return both raw streams.
- Refuse unknown, disabled, or unconfirmed command names before process creation.
- Keep script output free of credential values; when `executableEnv` is used, report the variable name but do not echo its value.

- [ ] **Step 4: Run focused and full core tests**

Run:

```powershell
Invoke-Pester -Path tests/ScaffoldDrift.Tests.ps1,tests/EncodingAndPaths.Tests.ps1 -Output Detailed
Invoke-Pester -Path tests -Output Detailed
```

Expected: both runs PASS; the full run reports at least `12 tests completed, 0 failed`.

- [ ] **Step 5: Commit drift and evidence checks**

```powershell
git add tests/ScaffoldDrift.Tests.ps1 tests/EncodingAndPaths.Tests.ps1 skill/bootstrap-project-workflow/scripts/ProjectWorkflow.Compiler.psm1 skill/bootstrap-project-workflow/scripts/check-scaffolds.ps1 skill/bootstrap-project-workflow/scripts/test-project-workflow.ps1
git commit -m "feat: detect scaffold drift and verify evidence"
```

### Task 6: Safe migration gates for existing project entrypoints

**Files:**
- Create: `tests/MigrationSafety.Tests.ps1`
- Modify: `skill/bootstrap-project-workflow/scripts/ProjectInspection.psm1`
- Modify: `skill/bootstrap-project-workflow/scripts/ProjectWorkflow.Compiler.psm1`
- Modify: `skill/bootstrap-project-workflow/references/migration-rules.md`

**Interfaces:**
- Consumes: inspector entrypoint records and `project.json.migration` acknowledgements.
- Produces: conflict records with path/hash/tracking/classification and compiler refusal codes `UnacceptedExistingEntrypoint`, `UnresolvedEntrypointConflict`, or `UntrackedOutputCollision`.

- [ ] **Step 1: Write the migration safety matrix**

Add one Pester `It` case for each row:

| Fixture | Expected result |
|---|---|
| existing tracked `AGENTS.md`, hash absent from `acceptedInputs` | render refuses and file bytes remain unchanged |
| existing untracked `CLAUDE.md` | render refuses with `UntrackedOutputCollision` |
| tracked `AGENTS.md` and `CLAUDE.md` with different normalized bodies | inspector reports conflict; render refuses while `conflictsResolved=false` |
| accepted exact hash and approved migration | render succeeds and canonical `project.md` contains the migrated rule |
| changed existing file after acceptance | render refuses because current hash differs |
| generated outputs with matching lock | render treats them as managed artifacts and may synchronize |
| unrelated modified tracked file plus unrelated untracked file | render changes only declared scaffold paths and preserves both unrelated hashes |

- [ ] **Step 2: Run the matrix and observe unsafe cases failing**

Run:

```powershell
Invoke-Pester -Path tests/MigrationSafety.Tests.ps1 -Output Detailed
```

Expected: at least the unaccepted and dual-conflict cases FAIL before production guards exist.

- [ ] **Step 3: Implement exact-hash migration acknowledgements**

- Inspector records relative path, lowercase SHA-256, Git-tracked boolean, generated boolean, and normalized semantic SHA-256.
- Semantic normalization removes only the known generated notice and normalizes CRLF/LF; it does not reorder or paraphrase content.
- Compiler accepts a hand-maintained output path only when `acceptedInputs` contains its current exact file hash and `migration.approvedByMaintainer=true`.
- When both native root files exist with different semantic hashes, require `migration.conflictsResolved=true` in addition to both accepted hashes.
- Before overwrite, require the canonical `project.md` to contain a `## Migrated project rules` section and every accepted path name. This is a traceability check, not an automated claim that prose is semantically complete.
- Never create persistent `.bak` files; tracked history remains the recovery mechanism.

- [ ] **Step 4: Run migration and full tests**

Run:

```powershell
Invoke-Pester -Path tests/MigrationSafety.Tests.ps1 -Output Detailed
Invoke-Pester -Path tests -Output Detailed
```

Expected: migration suite and full suite PASS with zero failures.

- [ ] **Step 5: Commit migration gates**

```powershell
git add tests/MigrationSafety.Tests.ps1 skill/bootstrap-project-workflow/scripts/ProjectInspection.psm1 skill/bootstrap-project-workflow/scripts/ProjectWorkflow.Compiler.psm1 skill/bootstrap-project-workflow/references/migration-rules.md
git commit -m "feat: gate migration with exact source acknowledgements"
```

### Task 7: Core acceptance fixture and developer documentation

**Files:**
- Create: `tests/fixtures/unity-minimal/ProjectSettings/ProjectVersion.txt`
- Create: `tests/fixtures/unity-minimal/Assets/Fixture.Runtime.asmdef`
- Create: `tests/CoreAcceptance.Tests.ps1`
- Create: `docs/core-contract.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: all core modules and fixture.
- Produces: one end-to-end offline acceptance test and documented local commands; version state `0.1.0-dev`.

- [ ] **Step 1: Write the failing end-to-end acceptance test**

The test copies `unity-minimal` to `TestDrive:`, runs the inspector CLI, writes a maintainer-approved canonical source using the committed skeleton, renders twice, checks both native trees, deliberately changes one generated Skill, observes check failure, synchronizes, and observes check success. Assert the inspector report says `unity` and contains no absolute credential or file body values.

- [ ] **Step 2: Run acceptance before documentation changes**

Run:

```powershell
Invoke-Pester -Path tests/CoreAcceptance.Tests.ps1 -Output Detailed
```

Expected: FAIL until every CLI path and fixture assumption is connected.

- [ ] **Step 3: Connect the end-to-end CLI and document the contract**

`docs/core-contract.md` documents:

- host Agent versus maintainer versus compiler responsibilities;
- `project.json` schema with a complete example;
- artifact ordering and hash behavior;
- migration refusal codes and recovery actions;
- exact inspect, render, sync, check, and verification commands;
- statement that the core phase does not yet provide global installation.

Update README status to `Core compiler implemented; Windows installers are the next release gate.` only after the acceptance command passes.

- [ ] **Step 4: Run all tests in both hosts and prove count**

Run:

```powershell
Invoke-Pester -Path tests -Output Detailed -PassThru
powershell.exe -NoProfile -Command "Invoke-Pester -Path tests -Output Detailed -PassThru"
```

Expected: each run returns `FailedCount = 0`, `PassedCount` greater than or equal to `20`, and process exit `0`.

- [ ] **Step 5: Check repository hygiene**

Run:

```powershell
git diff --check
rg -n "C:\\workspace|E:\\WorkSpace|xcards-svn|password|token" skill tests docs/core-contract.md README.md
git status --short
```

Expected: `git diff --check` exits `0`; the sensitive/path scan has no findings except a clearly documented generic word such as “token” if one is intentionally part of safety guidance; status lists only files from this task.

- [ ] **Step 6: Commit the core acceptance milestone**

```powershell
git add tests/fixtures tests/CoreAcceptance.Tests.ps1 docs/core-contract.md README.md
git commit -m "test: prove core scaffold compiler workflow"
```

## Plan 1 Completion Gate

Do not begin the Windows distribution plan until fresh output proves:

- both PowerShell hosts report zero Pester failures and at least 20 passed tests;
- inspection does not mutate fixtures;
- two renders produce byte-identical trees;
- Claude/Codex root and Skill counterparts are byte-equal;
- drift, missing marker, unconfirmed command, untracked collision, and entrypoint conflict tests fail safely;
- repository path/credential scan has no private project leakage.
