# Card Hero Skin Studio Pilot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bootstrap, review, commit, and validate one canonical project workflow for `card-hero-skin-studio-windows` that Claude Code and Codex can consume from a fresh clone without the global bootstrap Skill.

**Architecture:** Run the completed Skill's inspector against the pilot without writes, then let the active host Agent author canonical project rules from repository evidence and maintainer answers. After an explicit review gate, compile the canonical source to identical native Claude/Codex content, commit it in the pilot repository, and verify static discovery plus same-prompt Agent behavior from an isolated clone with the global bootstrap Skill absent.

**Tech Stack:** Unity 2022.3.62f2c1, Windows PowerShell, Git, Claude Code, Codex, the completed `bootstrap-project-workflow` release candidate.

**Spec:** `docs/superpowers/specs/2026-08-24-bootstrap-project-workflow-design.md`

## Global Constraints

- Plans 1 and 2 completion gates must already pass, including green Windows CI.
- Target root is exactly `C:\workspace\ai_project\codex\card-hero-skin-studio-windows`.
- The project is a Windows Unity tool; it is not treated as a completed replacement for the existing commercial editor.
- The commercial Card project is read-only unless the user separately authorizes a specific modification.
- `doc/` is local and untracked; read available handoff documents before implementation but do not add them to Git.
- Continue recording project development in `log/devlog.md`, while preserving any execution-time user edits.
- Never store local art paths, SVN credentials, passwords, commercial assets, or Card source content in the generated scaffold.
- Existing `AGENTS.md` is hand-maintained input until its exact hash is accepted and its rules appear under `## Migrated project rules`.
- No generated file is written before the maintainer approves the dry-run report and exact write set.
- Real Claude Code/Codex calls and any Unity process launch require separate user permission immediately before execution.
- Pushing the pilot repository requires explicit user authorization after local acceptance.

---

## File Map

The pilot generation creates or replaces only these tracked paths:

- `.agent-workflow/source/project.json`: adapter, migration hashes, and confirmed verification commands.
- `.agent-workflow/source/project.md`: purpose, stage, collaboration rules, safety, and migrated `AGENTS.md` content.
- `.agent-workflow/source/architecture.md`: App/protocol/importer boundaries.
- `.agent-workflow/source/component-catalog.md`: code, package, document, and verification anchors.
- `.agent-workflow/source/build-test.md`: exact evidence hierarchy and Unity command contracts.
- `.agent-workflow/source/skills/{feature,debug,review,verify,continue-work}.md`: project workflow sources.
- `.agent-workflow/systems/INDEX.md`: system-to-source routing index.
- `.agent-workflow/memory.md`: current factual state and next work boundary.
- `.agent-workflow/decisions.md`: durable decisions with evidence links.
- `.agent-workflow/scripts/*`: self-contained generated compiler, sync, check, and verification scripts.
- `.agent-workflow/scaffold.lock.json`: generated mapping and hashes.
- `CLAUDE.md`, `AGENTS.md`: identical generated root instructions.
- `.claude/skills/*/SKILL.md`, `.agents/skills/*/SKILL.md`: identical generated workflow skills in native discovery paths.
- `log/devlog.md`: one appended entry describing scaffold generation and evidence; no prior entry is rewritten.

### Task 1: Fresh read-only preflight and maintainer gate

**Files:**
- Read only: target repository and completed Skill checkout.
- Do not create or modify target files in this task.

**Interfaces:**
- Consumes: current pilot worktree and `inspect-project.ps1`.
- Produces: conversation-only JSON inspection, baseline Git status, existing-entrypoint hash, proposed write set, and maintainer decision.

- [ ] **Step 1: Capture a fresh Git and file baseline**

Run as separate read-only commands from the target root:

```powershell
git status --porcelain=v1 -uall
git branch --show-current
git rev-parse HEAD
(Get-FileHash -LiteralPath 'AGENTS.md' -Algorithm SHA256).Hash.ToLowerInvariant()
git ls-files --error-unmatch -- AGENTS.md
```

Record stdout in the task transcript. At planning time on 2026-08-24 the worktree was clean, but execution must use the fresh output and treat every listed path as user-owned.

- [ ] **Step 2: Run the completed inspector and prove no write**

Capture `git status --porcelain=v1 -uall` immediately before and after:

```powershell
& 'C:\workspace\ai_project\bootstrap-project-workflow\skill\bootstrap-project-workflow\scripts\inspect-project.ps1' -ProjectRoot 'C:\workspace\ai_project\codex\card-hero-skin-studio-windows'
```

Expected report facts:

- adapter `unity`;
- Unity evidence `ProjectSettings/ProjectVersion.txt` with `2022.3.62f2c1`;
- existing tracked, hand-maintained `AGENTS.md`;
- no generated `CLAUDE.md`, `.claude/skills`, `.agents/skills`, or `.agent-workflow`;
- local handoff candidates `doc/WINDOWS_APP_HANDOFF.md` and `doc/HERO_SKIN_WINDOWS_APP_ALIGNMENT_AUDIT_2026-08-21.md` without their contents in JSON;
- verification candidates remain unconfirmed and are not executed;
- before/after Git status is byte-identical.

- [ ] **Step 3: Read the authoritative project evidence**

Read completely:

```text
AGENTS.md
README.md
TECHNICAL_RULES.md
SKIN_PACKAGE_PROTOCOL.md
GOLDEN_SAMPLES.md
USER_GUIDE.md
doc/WINDOWS_APP_HANDOFF.md (when present)
doc/HERO_SKIN_WINDOWS_APP_ALIGNMENT_AUDIT_2026-08-21.md (when present)
the current tail and relevant verification sections of log/devlog.md
```

Inspect the four asmdef boundaries and the named `*Verification.cs` entrypoints before drafting architecture or commands.

- [ ] **Step 4: Present and stop at the maintainer gate**

Present exactly:

1. project type and Unity adapter evidence;
2. current Git baseline and paths that must remain unchanged;
3. `AGENTS.md` hash and the three rules proposed for migration;
4. the complete File Map above;
5. automatic verification candidates versus manual Player/Card visual checks;
6. facts marked `待确认`.

Do not proceed until the maintainer approves this report and write set in the conversation.

### Task 2: Author the pilot canonical source

**Files:**
- Create: all `.agent-workflow/source/*` files listed in File Map.
- Create: `.agent-workflow/systems/INDEX.md`
- Create: `.agent-workflow/memory.md`
- Create: `.agent-workflow/decisions.md`
- Do not modify: generated runtime paths in this task.

**Interfaces:**
- Consumes: approved preflight, repository evidence, exact existing `AGENTS.md` hash.
- Produces: maintainer-reviewable canonical source; `project.json.migration.approvedByMaintainer=true` only after the Task 1 approval.

- [ ] **Step 1: Copy the canonical skeleton after approval**

Copy only the source/system/memory/decision authoring assets from the release-candidate Skill into `.agent-workflow`; do not copy runtime output directories yet. Confirm `git status --short` lists only `.agent-workflow/` additions.

- [ ] **Step 2: Write `project.json` with exact migration and command records**

Use schema `1`, project name `card-hero-skin-studio-windows`, adapter `unity`, the current generator version, and this structure. The planning-time `AGENTS.md` SHA-256 is `acc51d0a474208ee409a5ad2faa26744a19526871034a81f47ff45bb9b1d7b18`; Task 1 must produce the same value. If it differs, stop, review the new rules, and revise the migration record through the maintainer gate before writing.

```json
{
  "schemaVersion": 1,
  "projectName": "card-hero-skin-studio-windows",
  "adapter": "unity",
  "migration": {
    "acceptedInputs": [
      {
        "path": "AGENTS.md",
        "sha256": "acc51d0a474208ee409a5ad2faa26744a19526871034a81f47ff45bb9b1d7b18",
        "classification": "existing-rule"
      }
    ],
    "conflictsResolved": false,
    "approvedByMaintainer": true
  },
  "verification": {
    "commands": [
      {
        "name": "protocol-golden",
        "executableEnv": "UNITY_EDITOR_PATH",
        "arguments": ["-batchmode", "-quit", "-projectPath", ".", "-executeMethod", "Giant.CardHeroSkin.Importer.Editor.SkinPackageProtocolVerification.RunBatch", "-logFile", "Logs/AgentWorkflow-ProtocolGolden.log"],
        "workingDirectory": ".",
        "expectedExitCode": 0,
        "requiredMarkers": ["HERO_SKIN_PROTOCOL_GOLDEN_OK"],
        "confirmed": true,
        "enabled": true
      },
      {
        "name": "card-importer",
        "executableEnv": "UNITY_EDITOR_PATH",
        "arguments": ["-batchmode", "-quit", "-projectPath", ".", "-executeMethod", "Giant.CardHeroSkin.Importer.Editor.CardHeroSkinImporterVerification.RunBatch", "-logFile", "Logs/AgentWorkflow-CardImporter.log"],
        "workingDirectory": ".",
        "expectedExitCode": 0,
        "requiredMarkers": ["HERO_SKIN_CARD_IMPORTER_OK"],
        "confirmed": true,
        "enabled": true
      },
      {
        "name": "authoring-infrastructure",
        "executableEnv": "UNITY_EDITOR_PATH",
        "arguments": ["-batchmode", "-quit", "-projectPath", ".", "-executeMethod", "Giant.CardHeroSkinStudio.Editor.HeroSkinAuthoringInfrastructureVerification.RunBatch", "-logFile", "Logs/AgentWorkflow-AuthoringInfrastructure.log"],
        "workingDirectory": ".",
        "expectedExitCode": 0,
        "requiredMarkers": ["HERO_SKIN_AUTHORING_INFRASTRUCTURE_OK"],
        "confirmed": true,
        "enabled": true
      },
      {
        "name": "svn-on-demand",
        "executableEnv": "UNITY_EDITOR_PATH",
        "arguments": ["-batchmode", "-quit", "-projectPath", ".", "-executeMethod", "Giant.CardHeroSkinStudio.Editor.HeroSkinSvnOnDemandVerification.RunBatch", "-logFile", "Logs/AgentWorkflow-SvnOnDemand.log"],
        "workingDirectory": ".",
        "expectedExitCode": 0,
        "requiredMarkers": ["HERO_SKIN_SVN_ON_DEMAND_OK"],
        "confirmed": true,
        "enabled": true
      }
    ]
  }
}
```

Before retaining a fully qualified class name, verify it from the corresponding source namespace. A mismatch is corrected in `project.json` before review; no runtime guessing is allowed.

- [ ] **Step 3: Write exact project and architecture semantics**

`project.md` must contain:

- purpose: Windows interactive skin authoring/import tool for artists;
- current stage: schema v2 technical validation, with `Appearance`, composite timing editing, collection Slot overrides, commercial Card adapter, real Prefab generation, and full visual comparison explicitly incomplete where README says so;
- before-work sequence: root rules, available local `doc/`, relevant system index, current memory/decisions, Git status;
- development log: append meaningful progress to `log/devlog.md`;
- data safety: machine paths/credentials remain local, no full SVN update, no overwrite of artist changes;
- Card boundary: commercial Card is read-only without explicit authorization;
- claim boundary: an exit code alone is insufficient; required marker, test count/evidence, Player/manual gap must be reported;
- `## Migrated project rules`: name `AGENTS.md` and preserve all three existing rules without weakening them.

`architecture.md` separates:

1. Windows App runtime/editor authoring under `Assets/CardHeroSkinStudio`;
2. shared schema v2 protocol under `Packages/com.giant.card-hero-skin/Runtime`;
3. Editor importer plan and adapter gate under `Packages/com.giant.card-hero-skin/Editor`;
4. commercial Card as an external read-only fact source;
5. seven prefab types and five stable virtual slots as protocol semantics, not physical Prefab-node promises.

- [ ] **Step 4: Write component, evidence, state, and decision indexes**

`component-catalog.md` maps the two project asmdefs, package runtime/editor asmdefs, all nine named verification classes, and the five authoritative root documents to their responsibilities. `build-test.md` records `UNITY_EDITOR_PATH`, exact command records from `project.json`, required markers, real-art/Player/Card manual boundaries, and the rule that shared Unity process ownership must be checked before launch.

`systems/INDEX.md` routes App UI/authoring, SVN/resources, schema/protocol, importer/adapter, verification, packaging, and user documentation to exact repository paths. `memory.md` records only current verified status and next smallest work boundary. `decisions.md` records the one-source/two-native-output workflow decision and links to local repository evidence, not to commercial source content.

- [ ] **Step 5: Tailor the five workflow sources without runtime-specific syntax**

Start from the five release-candidate sources. Add only pilot-specific evidence order and safety gates:

- `feature`: require protocol/adapter impact classification and devlog update;
- `debug`: distinguish pure model, Unity Editor, Windows Player, SVN, and commercial Card evidence;
- `review`: flag reflection/`SerializedProperty`, destructive SVN behavior, absolute paths, credential persistence, and false Prefab-success claims;
- `verify`: require exit, markers, log path, executed test set, and manual gaps;
- `continue-work`: read local `doc/` when present, memory/decisions, devlog tail, and fresh Git status.

- [ ] **Step 6: Run canonical validation and stop for content review**

Run the compiler's canonical validation without rendering. Present the complete canonical diff and a table mapping each claim to its source file. The maintainer must approve the content before Task 3.

### Task 3: Render native scaffolds and prove deterministic safety

**Files:**
- Create: generated `.agent-workflow/scripts/*` and `scaffold.lock.json`.
- Create: `CLAUDE.md`, `.claude/skills/*/SKILL.md`, `.agents/skills/*/SKILL.md`.
- Replace: `AGENTS.md` only after exact-hash migration passes.
- Append: `log/devlog.md` after generated output verification.

**Interfaces:**
- Consumes: maintainer-approved canonical source.
- Produces: byte-equivalent Claude/Codex native files, passing drift check, zero-diff second sync, and a reviewable Git diff.

- [ ] **Step 1: Recheck migration hash and worktree baseline**

Run `(Get-FileHash -LiteralPath 'AGENTS.md' -Algorithm SHA256).Hash.ToLowerInvariant()` and compare it with `project.json.migration.acceptedInputs[0].sha256`. Run `git status --porcelain=v1 -uall` and compare it with Task 1. If either differs, stop and return to the maintainer gate; do not update the accepted hash silently.

- [ ] **Step 2: Render once and inspect the exact write set**

Run:

```powershell
& 'C:\workspace\ai_project\bootstrap-project-workflow\skill\bootstrap-project-workflow\scripts\render-scaffolds.ps1' -ProjectRoot 'C:\workspace\ai_project\codex\card-hero-skin-studio-windows'
git status --short
git diff -- AGENTS.md CLAUDE.md .agent-workflow .claude .agents
```

Expected: only File Map paths change; the renderer reports the accepted `AGENTS.md` hash; no business source, package, asset, distribution, or existing devlog bytes change yet.

- [ ] **Step 3: Prove Claude/Codex byte parity and drift validity**

Run:

```powershell
if ((Get-FileHash -LiteralPath 'AGENTS.md' -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath 'CLAUDE.md' -Algorithm SHA256).Hash) { throw 'RootParityFailed' }
& '.\.agent-workflow\scripts\check-scaffolds.ps1'
```

For each name in `feature`, `debug`, `review`, `verify`, and `continue-work`, compare `.agents/skills/{name}/SKILL.md` and `.claude/skills/{name}/SKILL.md` SHA-256. Expected: all five pairs and the root pair match; check reports zero mismatches.

- [ ] **Step 4: Prove idempotence and drift repair with a recoverable test file**

Record `git diff --binary` and tree hashes, run `sync-scaffolds.ps1`, and assert zero new diff. Then append `drift probe` only to `.agents/skills/verify/SKILL.md`; run check and require nonzero exit naming that path. Run sync again and require check exit `0` plus the exact original hash. Do not use Git reset or checkout for repair.

- [ ] **Step 5: Append the devlog evidence**

Append one dated section recording:

- canonical source and dual native paths generated;
- existing `AGENTS.md` rules migrated by exact hash;
- check artifact count and zero mismatches;
- second sync zero diff;
- deliberate drift detection and sync repair;
- Unity and external Agent calls not yet run in this task.

- [ ] **Step 6: Review and commit the pilot scaffold locally**

Run `git diff --check`, inspect `git diff --stat`, and scan generated files for `C:\workspace`, `E:\WorkSpace`, SVN credential values, and absolute art paths. After user approval of the final diff:

```powershell
git add -- .agent-workflow CLAUDE.md AGENTS.md .claude .agents log/devlog.md
git commit -m "feat: add shared Claude and Codex project workflow"
```

Do not push in this task.

### Task 4: Run project verification with claim-matched evidence

**Files:**
- Modify only logs already declared by the pilot project's verification commands; do not commit Unity caches or logs unless existing repository policy explicitly tracks them.
- Append: `log/devlog.md` with actual results.

**Interfaces:**
- Consumes: `project.json.verification.commands`, `UNITY_EDITOR_PATH`, and explicit user permission to launch Unity.
- Produces: command-by-command exit codes, required-marker results, log paths, and an honest manual-gap list.

- [ ] **Step 1: List without executing**

Run:

```powershell
& '.\.agent-workflow\scripts\verify-project.ps1'
```

Expected: four enabled command names, environment-variable name `UNITY_EDITOR_PATH`, expected exit `0`, and their markers; no Unity process starts and the environment variable value is not printed.

- [ ] **Step 2: Obtain permission and check Unity ownership**

Ask the user before launching Unity. Check for an existing Unity process and project lock. If another owner is using the project, stop and report the conflict; do not kill the process or delete a lock.

- [ ] **Step 3: Execute each authorized command separately**

For each name the user authorizes, run the corresponding literal command:

```powershell
& '.\.agent-workflow\scripts\verify-project.ps1' -Execute -Name 'protocol-golden'
& '.\.agent-workflow\scripts\verify-project.ps1' -Execute -Name 'card-importer'
& '.\.agent-workflow\scripts\verify-project.ps1' -Execute -Name 'authoring-infrastructure'
& '.\.agent-workflow\scripts\verify-project.ps1' -Execute -Name 'svn-on-demand'
```

Do not run a line the user did not authorize. No unlisted name is accepted. After each run, record exit code, marker presence, stderr, and log path before starting the next.

- [ ] **Step 4: Report automatic and manual evidence separately**

Automatic success requires exit `0` and every required marker. Continue to list real Windows Player interaction, native save-dialog behavior, production art visual comparison, and isolated commercial Card Prefab generation as manual or external-environment evidence unless freshly executed. Do not upgrade a partial result into a complete-product claim.

- [ ] **Step 5: Append results and commit evidence wording**

Append exact results to `log/devlog.md`, run `git diff --check`, then commit only the devlog change:

```powershell
git add -- log/devlog.md
git commit -m "test: record project workflow verification evidence"
```

### Task 5: Prove clone/pull-only discovery in both Agents

**Files:**
- No source changes expected.
- Temporary acceptance clone under a newly created child of `$env:TEMP\bootstrap-project-workflow-acceptance`.

**Interfaces:**
- Consumes: committed pilot scaffold, Claude Code, Codex, and permission for external Agent calls plus temporary uninstall/reinstall of global bootstrap links.
- Produces: two structured responses satisfying one semantic contract while the bootstrap Skill is absent.

- [ ] **Step 1: Obtain the external-call and link-change permission**

Ask permission to:

1. remove only the verified Claude/Codex global bootstrap junctions;
2. run one read-only Claude Code prompt and one read-only Codex prompt;
3. reinstall the same two junctions after validation.

Do not proceed without this permission.

- [ ] **Step 2: Create a clean clone of the committed local pilot**

Create a GUID-named path under `$env:TEMP\bootstrap-project-workflow-acceptance`, resolve its full path, assert its parent equals that exact temp base, and run:

```powershell
$acceptanceBase = [System.IO.Path]::GetFullPath((Join-Path $env:TEMP 'bootstrap-project-workflow-acceptance'))
New-Item -ItemType Directory -Path $acceptanceBase -Force | Out-Null
$cloneRoot = [System.IO.Path]::GetFullPath((Join-Path $acceptanceBase ([Guid]::NewGuid().ToString('N'))))
if ([System.IO.Path]::GetDirectoryName($cloneRoot) -ne $acceptanceBase) { throw 'UnsafeAcceptanceClonePath' }
git clone --no-hardlinks 'C:\workspace\ai_project\codex\card-hero-skin-studio-windows' $cloneRoot
```

Expected: clone HEAD equals the original local HEAD; `git status --porcelain=v1 -uall` is empty; no `.claude` or `.agents` path is a reparse point.

- [ ] **Step 3: Remove the global bootstrap Skill and prove absence**

From the bootstrap repository run `uninstall.ps1 -Runtime All`. Verify both expected global bootstrap paths are missing while the Git checkout remains. Do not remove unrelated skills.

- [ ] **Step 4: Run the same read-only prompt in fresh Claude Code and Codex sessions**

Use this exact prompt in the temp clone:

```text
只读诊断，不修改文件，不启动 Unity，不访问商业 Card 工程。请依据你自动发现的项目规则，仅输出 JSON：projectPurpose、requiredPreRead、readOnlyBoundaries、workflows、currentLimitations、evidenceSources。workflows 必须列出你能使用的项目工作流名称；每个结论给出仓库相对路径证据。
```

Each response must satisfy:

- `projectPurpose` identifies the Windows skin authoring/import tool;
- `requiredPreRead` includes available local `doc/`, `.agent-workflow/memory.md`, `.agent-workflow/decisions.md`, system index, devlog, and Git status;
- `readOnlyBoundaries` says commercial Card is read-only without authorization;
- `workflows` is exactly the set `feature`, `debug`, `review`, `verify`, `continue-work`;
- `currentLimitations` does not claim complete commercial Prefab generation or complete replacement of the old editor;
- `evidenceSources` uses repository-relative paths and contains no machine credential/path value.

Natural-language wording and JSON property order may differ; semantic values above may not.

- [ ] **Step 5: Reinstall global links and verify restoration**

Run both installers from the bootstrap checkout and verify each link state is `CorrectJunction`. If either Agent run or restoration fails, report the actual state and keep the acceptance clone for diagnosis.

- [ ] **Step 6: Clean only a successful disposable clone**

Only after both responses pass and global links are restored, resolve `$cloneRoot` again, assert it is a strict child of `$acceptanceBase` and is not the base itself, then remove that one clone with `Remove-Item -LiteralPath $cloneRoot -Recurse -Force`. Preserve failed-run evidence until the user decides how to handle it.

### Task 6: Push the pilot and promote bootstrap version 0.1.0

**Files in pilot repository:**
- No new changes beyond accepted verification fixes and devlog evidence.

**Files in bootstrap repository:**
- Modify: `VERSION`
- Modify: `README.md`
- Create: `CHANGELOG.md`

**Interfaces:**
- Consumes: successful Task 5 evidence and user permission to push the pilot.
- Produces: pilot remote commit available to coworkers and bootstrap version `0.1.0` in the private GitHub repository.

- [ ] **Step 1: Verify the pilot branch and request push authorization**

Run fresh `git status --short`, `git log -2 --oneline`, and the project-local drift check. Show the target remote and branch. Push only after the user approves that remote operation.

- [ ] **Step 2: Push and verify the remote pilot commit**

After showing `git remote -v` and `git branch --show-current`, assign the user-approved values to `$pilotRemote` and `$pilotBranch`; run `git push $pilotRemote $pilotBranch`, fetch the corresponding remote tracking ref, and require its hash to equal local HEAD. If branch policy requires a pull request, create a branch using the repository's policy and present the PR instead of bypassing protection.

- [ ] **Step 3: Add the bootstrap release record**

Set `VERSION` to `0.1.0`. `CHANGELOG.md` records Windows-only support, dual installers, one canonical project source, generated native paths, migration gates, five workflows, drift/idempotence tests, and the pilot acceptance commit. README status becomes `0.1.0 validated on card-hero-skin-studio-windows; repository remains private pending owner decision.`

- [ ] **Step 4: Run final bootstrap verification**

Run both PowerShell full suites, `git diff --check`, the private-path/credential scan, and Git status. Expected: zero test failures, no private pilot path or content in reusable templates, and only release files modified.

- [ ] **Step 5: Commit and push bootstrap 0.1.0**

```powershell
git add -- VERSION README.md CHANGELOG.md
git commit -m "chore: release bootstrap project workflow 0.1.0"
git push origin main
```

Verify local HEAD equals `refs/remotes/origin/main` and the GitHub repository remains private.

## Plan 3 Completion Gate

Version `0.1.0` is complete only when fresh evidence proves:

- the pilot preflight was read-only and the maintainer approved the authored canonical source;
- the old `AGENTS.md` exact hash was accepted and all three rules were preserved;
- generated Claude/Codex counterparts are byte-equal and project-local drift check passes;
- second sync is zero diff and deliberate drift is detected then repaired from canonical source;
- project verification reports exit codes and required markers without overstating manual evidence;
- global bootstrap Skill was absent during both fresh-clone Agent sessions;
- both Agents discovered the same five workflows and project safety boundaries from committed files;
- the pilot remote contains the accepted scaffold and the bootstrap private repository contains verified version `0.1.0`.
