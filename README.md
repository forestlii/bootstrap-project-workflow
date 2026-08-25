# bootstrap-project-workflow

一个仅支持 Windows 的 Agent Skill，用于给现有项目建立 Claude Code 与 Codex 共用的最小项目工作流。

它在负责人审核后只生成两个项目入口：

- `.claude/CLAUDE.md`：项目工作流和未来项目 Skill 的唯一信息源；
- `AGENTS.md`：Codex 的薄适配入口，读取并遵守同一份 `.claude` 信息源。

随着项目发展，代码框架知识按 `.claude/skills/<name>/SKILL.md` 拆分。Claude 原生使用这些 Skill，Codex 通过 `AGENTS.md` 使用，不维护第二份正文。

## 安装

先克隆仓库：

```powershell
git clone https://github.com/forestlii/bootstrap-project-workflow.git
Set-Location .\bootstrap-project-workflow
```

为 Claude Code 安装：

```powershell
.\install-claude.ps1
```

为 Codex 安装：

```powershell
.\install-codex.ps1
```

两个安装器复制同一份 Skill。目标目录已经存在时会停止，不会覆盖或自动更新。

## 使用

在目标项目中要求 Agent 使用 `$bootstrap-project-workflow` 初始化项目工作流。

Skill 会先只读了解项目、询问无法确认的信息，然后展示 `.claude/CLAUDE.md` 和 `AGENTS.md` 的完整草稿。只有负责人明确批准草稿后才会写入文件。

如果任一目标文件已经存在，Skill 会停止并报告冲突，不覆盖、不合并、不备份。

## 第一版边界

- 只生成 `.claude/CLAUDE.md` 和 `AGENTS.md`；
- 不预生成业务 Skill；
- 不提供编译、同步、漂移检测或自动迁移；
- 不自动运行项目构建、测试、提交或推送；
- 不提供自动升级安装器。

设计见 [docs/design.md](docs/design.md)。

当前状态：最小实现已通过 Skill 格式验证和两个临时安装测试，尚未在真实项目中运行。

本项目采用 [MIT License](LICENSE)。
