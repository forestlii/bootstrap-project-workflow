# bootstrap-project-workflow

Windows 项目的 Claude Code／Codex 共用研发工作流 Skill。项目规范只维护一份，两种 Agent 通过各自入口读取。

## 三种用途

| 模式 | 用途 | 输出 |
|---|---|---|
| 初始化 | 项目没有共同工作流 | 仅 `.claude/CLAUDE.md`、`AGENTS.md` |
| 拆解 | 按现有代码框架整理可复用知识 | `.claude/skills/<name>/SKILL.md` 及必要引用、对应 Codex 薄入口 |
| 接入与维护 | 已有 Claude Skill，接入 Codex 或更新共同规范 | `.agents/skills/<name>/SKILL.md`，按范围增量更新已有规则 |

`.claude/CLAUDE.md` 维护工作方法；`.claude/skills` 维护模块知识和制作方式；既有项目文档保持原位置。`AGENTS.md` 和 `.agents/skills` 只转接，不复制业务正文。接入使用普通文件和相对路径，适合 Git／P4 与独立工作区。

每次实质修改都留下记录：具体修改与验证进入任务记录／devlog，模块知识变化同步到 Skill 或引用文档，新模块才考虑新 Skill。不是每次修改都新增 Skill。

## 安装

```powershell
git clone https://github.com/forestlii/bootstrap-project-workflow.git
Set-Location .\bootstrap-project-workflow
.\install-claude.ps1
.\install-codex.ps1
```

两个安装器复制同一份 `skill/bootstrap-project-workflow`（包括 references）。Claude 安装到 `%USERPROFILE%\.claude\skills`；Codex 安装到 `%USERPROFILE%\.agents\skills`。

目标已存在时安装器停止，不覆盖或自动升级。**仓库 `git pull` 不会更新已安装副本。**升级时让本机 Agent 比较仓库源与安装目录，确认并保留本机定制后，按你的更新授权同步这个 Skill；不要删除整个 skills 目录。新会话再核对加载内容。

## 使用示例

```text
使用 $bootstrap-project-workflow 初始化当前项目的共同研发规范。

使用 $bootstrap-project-workflow 拆解当前项目已有的模块知识。

使用 $bootstrap-project-workflow 为当前项目已有的 .claude/skills
建立 Codex 薄入口，保留正文和现有定制；将知识回写规则补入共同工作流。
```

初始化仍不覆盖已有文件；明确请求改造已有工作流则进入接入与维护模式。范围不明时先展示差异与方案，已有明确授权不逐文件重复询问。此 Skill 不自动授权业务代码修改、构建、提交或推送。

入口模板见 [shared-skills.md](skill/bootstrap-project-workflow/references/shared-skills.md)，整体设计见 [docs/design.md](docs/design.md)。

## 验证边界

格式／相对路径／安装验证与真实客户端发现分开报告。通过格式检查不代表 Claude 与 Codex 已实际加载，也不代表 UE 或业务验收完成。当前迭代验证记录见 [2026-09-20 devlog](docs/devlog/2026-09-20.md)。

本项目采用 [MIT License](LICENSE)。
