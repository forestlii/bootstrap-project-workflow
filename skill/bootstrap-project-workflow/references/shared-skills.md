# Codex 项目 Skill 薄入口

`.claude/skills` 维护正文，`.agents/skills` 提供 Codex 原生发现。项目已有设计文档保持原位置，两者引用同一份内容。根目录 `AGENTS.md` 引导读取共同工作流，始终适用的规则不能只依赖 Skill 自动匹配。

## 模板

假设原文为 `.claude/skills/module-ai/SKILL.md`，入口为 `.agents/skills/module-ai/SKILL.md`。`module-ai` 仅用于演示，实际保留有效的既有名称和描述。

```markdown
---
name: module-ai
description: 开发、修改或审查本项目 AI 模块时使用。
---

本文件是 Codex 发现入口，共用规范在：

[共用 Skill](../../../.claude/skills/module-ai/SKILL.md)

使用本 Skill 时：
1. 完整读取共用 Skill，再执行任务。
2. 原文中的相对引用，以原文所在目录为基准解析。
3. 更新知识时修改原文或其引用文档，不在本入口维护业务规则。
4. 原文不存在、引用失效或内容冲突时明确报告，不凭空补全。
```

## 生成与维护

- 提取原文的 YAML name／description，用合法 YAML 序列化；含冒号、引号或多行描述时正确转义，不能简单拼接。
- 从入口所在目录到原文生成相对路径，不能硬编码示例名、当前盘符或用户目录。
- 只生成转接正文。Claude 专用的工具权限、hooks、执行上下文等元数据没有自然映射，不照抄成 Codex 配置；依赖这些行为时报告适配缺口。
- 一般无需 `agents/openai.yaml`；确实需要 Codex 专用展示或调用设置时单独维护，它不承载业务规范。
- 不必接入所有全局工具 Skill，只处理当前仓库范围。插件和游戏仓分别使用自己的根目录与权威知识，不把嵌套的另一仓正文复制进来。
- 已有完整 Codex Skill、链接目录或名字冲突时报告差异，不能把它当作可覆盖模板。
- 正文更新不需要改入口；元数据、名称或源路径变更时同步入口，重命名后检查旧入口，避免重复匹配。

## 验证示例

在临时项目目录建立模板中的两个路径，并在原文引用 `references/example.md`。从入口解析后应读取原文目录下的引用，不应去 `.agents/skills/module-ai/references` 查找。

把整个项目复制到另一个普通目录再验证路径；删除临时源文件应得到缺失报告，不能回退到另一机器的路径。实际客户端发现验证使用新会话，仅进行只读任务，不启动业务构建或写入。

## 官方依据

- [Codex Skills](https://learn.chatgpt.com/docs/build-skills)：项目发现目录、name／description、按需加载。
- [Claude Code Skills](https://code.claude.com/docs/en/skills)：Claude 项目 Skill 与支持文件。

此入口是普通 Skill 指令，通过要求 Agent 打开原文来转接，并非两种客户端共享内存或运行时配置的机制。
