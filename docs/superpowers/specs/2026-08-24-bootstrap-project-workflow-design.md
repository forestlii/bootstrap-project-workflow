# bootstrap-project-workflow 设计规格

## 0. 状态

- 日期：2026-08-24
- 状态：待用户书面审核
- 首版平台：Windows
- 发布目标：`forestlii/bootstrap-project-workflow` 私有 GitHub 仓库；成熟后由仓库所有者决定是否公开
- 许可证：MIT
- 首个试点：`C:\workspace\ai_project\codex\card-hero-skin-studio-windows`

在本规格获批前，只允许修改本规格，不进入实现。

## 1. 产品目标

`bootstrap-project-workflow` 是一个可同时安装到 Claude Code 与 Codex 的项目脚手架生成 Skill。

它解决两个问题：

1. 任何 Windows 用户都能从同一 GitHub 仓库安装适合自己 Agent 的 Skill。
2. 项目维护者安装 Skill、在业务仓库完成一次引导、审核项目专属工作流并提交脚手架后，其他协作者只需 clone 或 pull 业务仓库，即可让 Claude Code 或 Codex 自动发现并使用同等语义的项目工作流，不需要再次安装 bootstrap Skill。

这里的“clone 或 pull 即用”是脚手架已经写入并提交业务仓库后的消费状态，不是无人编写工作流的自动承诺。首次接入时，宿主 Agent 根据仓库证据和维护者确认起草项目工作流，项目维护者对内容负责并批准提交；PowerShell 生成器只负责检查、渲染和校验，不凭空决定项目规则。

“同等效果”指两种 Agent 遵守相同的项目约束、使用相同的功能开发/调试/评审/验证/接力流程、读取相同的项目状态，并执行相同的确定性验证脚本；不要求两个运行时的内部文件格式、工具名称或回复文字完全相同。

## 2. 非目标

首版不做以下事项：

- 不逐文件复制 Card 的 `.claude` 目录。
- 不生成几十个未经目标项目验证的领域 Skill。
- 不依赖符号链接作为业务仓库脚手架的正确性基础。
- 不要求 Claude 与 Codex 的 subagent、hook、命令语法完全一致。
- 不在 bootstrap 时擅自修改业务代码、安装依赖、运行破坏性命令或清理工作树。
- 不支持 macOS、Linux、WSL 或非 PowerShell 安装器。
- 不承诺一次扫描就能得到完美项目知识；脚手架必须支持后续校正和重新生成。

## 3. 总体架构

系统分为三层：

```text
GitHub Skill 源码
  ├─ Claude 安装入口
  ├─ Codex 安装入口
  └─ 通用生成器、适配器、模板与测试
                  ↓
目标项目的 .agent-workflow（唯一维护源）
                  ↓ 编译
  ├─ Claude 原生入口：CLAUDE.md + .claude/skills
  └─ Codex 原生入口：AGENTS.md + .agents/skills
```

### 3.1 GitHub Skill 仓库

```text
bootstrap-project-workflow/
├─ README.md
├─ LICENSE
├─ install-claude.ps1
├─ install-codex.ps1
├─ update.ps1
├─ uninstall.ps1
├─ skill/
│  └─ bootstrap-project-workflow/
│     ├─ SKILL.md
│     ├─ agents/openai.yaml
│     ├─ references/
│     │  ├─ workflow-core.md
│     │  ├─ scaffold-contract.md
│     │  ├─ migration-rules.md
│     │  ├─ unity.md
│     │  ├─ unreal.md
│     │  └─ generic-tool.md
│     ├─ scripts/
│     │  ├─ inspect-project.ps1
│     │  ├─ render-scaffolds.ps1
│     │  ├─ check-scaffolds.ps1
│     │  └─ test-project-workflow.ps1
│     └─ assets/scaffold/
│        ├─ source/
│        ├─ claude/
│        └─ codex/
├─ tests/
│  ├─ fixtures/
│  └─ BootstrapProjectWorkflow.Tests.ps1
└─ .github/workflows/windows-test.yml
```

`skill/bootstrap-project-workflow/SKILL.md` 使用 Claude Code 与 Codex 都能识别的 Agent Skills 公共子集：只依赖 `name`、`description` 和 Markdown 正文。Codex 专属的 UI 元数据放在可选的 `agents/openai.yaml`；Claude Code忽略它。

### 3.2 项目脚手架

```text
<project>/
├─ .agent-workflow/
│  ├─ source/
│  │  ├─ project.md
│  │  ├─ architecture.md
│  │  ├─ component-catalog.md
│  │  ├─ build-test.md
│  │  └─ skills/
│  │     ├─ feature.md
│  │     ├─ debug.md
│  │     ├─ review.md
│  │     ├─ verify.md
│  │     └─ continue-work.md
│  ├─ systems/INDEX.md
│  ├─ memory.md
│  ├─ decisions.md
│  ├─ scaffold.lock.json
│  └─ scripts/
│     ├─ sync-scaffolds.ps1
│     ├─ check-scaffolds.ps1
│     └─ verify-project.ps1
├─ CLAUDE.md
├─ AGENTS.md
├─ .claude/skills/*/SKILL.md
└─ .agents/skills/*/SKILL.md
```

`.agent-workflow` 是唯一允许手工维护的工作流信息源。`CLAUDE.md`、`AGENTS.md`、`.claude/skills`、`.agents/skills` 是生成产物，必须提交 Git，以保证协作者 clone 后无需额外安装即可使用。

### 3.3 角色与产物生命周期

工作流不会由脚本凭空产生。首版明确区分以下角色：

| 角色 | 责任 | 不负责 |
|---|---|---|
| Skill 作者 | 在本 GitHub 仓库维护通用模板、检查器、渲染器、适配器和测试 | 替未知业务项目预先编写项目规则 |
| 项目维护者 | 安装并启动一次 bootstrap，回答不能从仓库安全推断的问题，审核 `.agent-workflow/source`，提交统一源和双运行时产物 | 要求协作者逐台安装 bootstrap Skill |
| 宿主 Agent | 运行 Skill 时读取目标仓库的源码、文档、Git 状态和既有规则，基于证据起草项目专属统一源，并把不确定项交给维护者确认 | 在没有证据或确认时发明项目事实 |
| 确定性渲染器 | 把已审核的 `.agent-workflow/source` 编译成 Claude Code 与 Codex 的原生入口，记录哈希并检查漂移 | 理解业务、替维护者做语义决策 |
| 项目协作者 | clone 或 pull 已提交脚手架的业务仓库，直接消费运行时原生入口；需要修改规则时只改统一源并重新同步 | 为日常使用再次安装 bootstrap Skill |

产物生命周期如下：

1. Skill 作者发布或更新通用 bootstrap Skill。
2. 一名项目维护者在目标业务仓库安装并调用 Skill。
3. 承载本次调用的 Claude Code 或 Codex 充当宿主 Agent，先形成证据报告，再在维护者确认后起草 `.agent-workflow/source`。
4. 项目维护者审核统一源；渲染器随后生成 `CLAUDE.md`、`AGENTS.md`、`.claude/skills` 和 `.agents/skills`。
5. 项目维护者提交统一源、生成产物、同步脚本和锁文件。
6. 从此其他协作者 clone 或 pull 即用。日常规则修改在 `.agent-workflow/source` 完成；bootstrap Skill 仅在首次接入、升级模板或重新审计项目时需要。

若第 5 步尚未完成，任何文档或命令都不得声称该业务仓库已经达到“clone 或 pull 即用”。

## 4. 安装设计

### 4.1 本机安装位置

用户先把 GitHub 仓库克隆到固定目录：

```text
%LOCALAPPDATA%\AgentSkills\bootstrap-project-workflow
```

Claude 安装器创建目录联接：

```text
%USERPROFILE%\.claude\skills\bootstrap-project-workflow
  -> <clone>\skill\bootstrap-project-workflow
```

Codex 安装器创建目录联接：

```text
%USERPROFILE%\.agents\skills\bootstrap-project-workflow
  -> <clone>\skill\bootstrap-project-workflow
```

两个入口可以同时存在并指向同一个本机 Git clone。安装器必须幂等：重复运行不破坏正确联接；遇到已有普通目录、错误联接或未提交本地改动时停止并给出可操作说明，不自动删除。

### 4.2 更新与卸载

- `update.ps1` 只在工作树干净时执行 fast-forward `git pull`，否则停止。
- `uninstall.ps1` 只移除所选运行时的联接，不删除 Git clone，不修改任何已经生成的业务项目。
- README 不提供未经审阅的远程脚本管道执行方式。

## 5. Bootstrap 工作流

Skill 按以下阶段运行，每个阶段有明确输入、输出和停止条件。

### 5.0 作者责任与生成边界

首次项目工作流由“宿主 Agent 起草、项目维护者审核”共同完成。宿主 Agent 可以归纳已有事实、提出候选规则和生成初稿，但所有缺少仓库证据的约束必须标记为待确认；项目维护者确认前，不能把它们写成已生效规则。

生成过程分为两类，不能混为一谈：

- 语义创作：宿主 Agent 依据项目事实和维护者答复编写 `.agent-workflow/source`。
- 确定性生成：PowerShell 渲染器只把统一源转换成两种运行时能够自动发现的文件，并验证两边语义映射和哈希。

因此，单独运行渲染器不能为一个从未接入过的项目创造可用工作流；它必须接收已经过门禁的统一源。

### 5.1 只读体检

输入：用户明确给出的目标工程根目录。

检查内容：

- Git 根、当前分支、工作树状态和忽略规则。
- 现有 `CLAUDE.md`、`AGENTS.md`、`.claude`、`.agents`、项目文档和活记忆。
- 技术栈：Unity、Unreal 或通用工具。
- 源码模块、入口、代表性实现、测试与构建候选命令。
- 机器路径、凭据、商业资源和不应进入 Git 的内容。

输出：只在对话中给出体检报告、拟生成文件、冲突与未验证假设。该阶段不得写项目。

### 5.2 方案门禁

用户必须确认：

- 项目类型和适配器。
- 将吸收的现有规则。
- 将创建或修改的文件。
- 自动验证边界与人肉验收边界。
- 不能安全推断的构建命令或项目事实。

未确认前不得进入生成阶段。

### 5.3 统一源生成

生成器先写 `.agent-workflow`，再从统一源渲染两个运行时的原生入口。生成产物包含固定声明：

```text
GENERATED by bootstrap-project-workflow.
Edit .agent-workflow/source, then run sync-scaffolds.ps1.
```

`scaffold.lock.json` 记录生成器版本、适配器、源到产物映射、SHA-256、生成时间和迁移来源。

### 5.4 现有文件迁移

- 已有单一 `AGENTS.md` 或 `CLAUDE.md`：提取为 `.agent-workflow/source/project.md` 的“既有项目规则”，展示差异后再生成双入口。
- 两者同时存在且语义不一致：生成冲突报告并停止，禁止擅自选边。
- 已有 `.claude` 或 `.agents`：分类为可迁移通用知识、运行时专属能力、项目过时信息；只迁移有源码或用户确认支撑的内容。
- 已跟踪文件依赖 Git 历史恢复，不额外制造长期 `.bak` 文件。
- 未跟踪且将被覆盖的文件必须停止并请求用户处理，不覆盖。
- 用户工作树中的无关修改全部保留。

### 5.5 同步与漂移检查

`sync-scaffolds.ps1` 从 `.agent-workflow/source` 重建两套入口；`check-scaffolds.ps1` 只读比较锁文件和当前 SHA-256。

任何人直接修改生成文件后，检查必须失败，并指出应修改的统一源文件。

## 6. 首版通用工作流

首版只生成五个经过验证的工作流：

| 工作流 | 触发目标 | 核心输出 |
|---|---|---|
| `feature` | 新功能或行为修改 | 需求澄清、组件清单、源码锚点、方案门禁、实现与验证 |
| `debug` | Bug、异常或测试失败 | 可复现证据、根因链、回归验证 |
| `review` | 审查修改 | 正确性、架构边界、回归风险和验证缺口 |
| `verify` | 声称完成前 | 编译、测试、静态检查、测试数量和原始证据 |
| `continue-work` | 新会话或交接 | 当前状态、未完成项、下一最小动作和阻塞 |

复杂项目以后可以新增领域 Skill，但 bootstrap 不凭空生成 Card 的 45 个领域 Skill。

## 7. 技术栈适配器

### 7.1 Unity

检测 `ProjectSettings/ProjectVersion.txt`、`Assets`、`Packages`，提取 Unity 版本、asmdef、Editor/Runtime 边界、batchmode/ExecuteMethod 验证入口、资源与 `.meta` 约束。

### 7.2 Unreal

检测 `.uproject`、`Source`、`Config`、模块和 `Build.cs`，关注 UHT/反射、UObject 生命周期、Game Thread、Blueprint/C++ 边界、Cook/Package 和 Automation Test。

### 7.3 通用工具

检测常见项目清单和入口，关注输入输出契约、退出码、stdout/stderr、幂等性、文件系统副作用、平台约束、打包与端到端测试。

检测只能生成候选结论。没有源码、配置、实际命令输出或用户确认支撑的事实必须标为“待确认”。

## 8. 验证设计

### 8.1 PowerShell/Pester 自动测试

至少覆盖：

- 两个安装器的首次安装、重复安装、错误联接和普通目录冲突。
- 空项目、已有 Claude、已有 Codex、已有双脚手架。
- 脏工作树与未跟踪冲突文件。
- 含空格、中文和长路径的工程。
- UTF-8/BOM、CRLF 和路径转义。
- 生成幂等性：连续生成两次，第二次零 diff。
- 漂移检测：修改任一生成文件必须失败。
- 源修改后同步：两个运行时产物同时变化且锁文件更新。

### 8.2 Skill 行为测试

按照 RED-GREEN-REFACTOR：

1. 在没有 Skill 的相同工程夹具上记录基线行为。
2. 安装 Skill 后重跑相同请求。
3. 验证 Agent 是否先只读体检、是否保留现有文件、是否经过方案门禁、是否生成双入口、是否运行漂移检查。
4. Claude 与 Codex 使用相同任务和结构化验收契约比较，不比较自然语言逐字一致。

真实调用 Claude/Codex 可能产生费用或外部调用，执行前单独获得用户许可。

### 8.3 试点工程验收

首个试点是 `card-hero-skin-studio-windows`。当前事实：

- Unity 2022.3 Windows 工具。
- 已有 `AGENTS.md`、本地交接文档、技术规则、协议、黄金样例、devlog 和多组验证入口。
- 没有 Claude 项目入口或两种运行时的项目 Skill。
- 工作树当前有用户未提交的发布产物和 devlog 修改。

验收步骤：

1. dry-run 报告正确识别现状和工作树边界。
2. 生成前后的业务代码、发布产物和用户改动保持不变。
3. 现有 `AGENTS.md` 规则被吸收且语义保留。
4. Claude 新会话能报告其项目规则和五个工作流。
5. Codex 新会话能报告相同的项目规则和五个工作流。
6. 两者面对同一“只诊断、不修改”的任务，都先读取交接资料、保持 Card 商业工程只读，并给出相同结构的证据链。
7. `check-scaffolds.ps1` 通过；故意改生成文件后失败；同步后恢复通过。

## 9. 安全与错误处理

- 默认只读，写入必须在用户批准的文件清单内。
- 禁止保存 token、密码、个人绝对路径或商业资源内容到公开模板。
- 所有破坏性操作、覆盖、删除、重置、清理和依赖安装都需要独立授权。
- 所有 PowerShell 文件操作使用 `-LiteralPath`，递归移动/删除前验证解析后的绝对路径。
- 任何阶段失败都保留原工程状态，输出具体失败点和恢复方法。
- 安装器不接管用户已有同名普通目录。
- 生成器不把“命令退出码 0”单独当成测试成功；必须同时检查测试数量、失败数量和预期证据。

## 10. 版本与发布

- GitHub 仓库初始为 private。
- 使用 MIT 许可证发布生成器和模板；试点工程自己的公司专有许可不受影响。
- 首次可用版本保持 `0.y.z`。
- 公开前完成：清理公司路径/凭据/商业内容、两种运行时黑盒验证、安装/卸载测试、全新 Windows 用户路径测试和 README 审核。
- GitHub Actions 只运行不依赖公司工程的通用夹具测试。

## 11. 完成定义

第一版只有同时满足以下条件才算完成：

- Claude/Codex 安装器从同一 Git 源安装同一个 Skill。
- 全部 Pester 测试通过且证明测试确实执行。
- 试点工程由宿主 Agent 基于证据起草统一源，经项目维护者审核后生成双原生入口，不破坏现有改动。
- 统一源和双原生入口提交业务仓库后，新 clone 中 Claude 与 Codex 均无需 bootstrap Skill 即可自动读取项目约束并发现五个工作流。
- 未提交脚手架的业务仓库不能通过验收，也不得标记为“clone 或 pull 即用”。
- 同一诊断任务通过结构化语义一致性验收。
- 漂移检查能抓住手改产物。
- README、MIT LICENSE、私有 GitHub 仓库与版本说明齐备。
