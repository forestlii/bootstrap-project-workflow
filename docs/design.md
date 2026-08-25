# bootstrap-project-workflow 最小设计

## 目标

提供一个可通过 GitHub 安装的 `bootstrap-project-workflow` Skill。负责人在现有项目中运行它，由 Agent 读取工程、询问必要信息并起草项目工作流；负责人审核后，Skill 才把工作流写入业务仓库。

业务仓库提交脚手架后，其他协作者只需 clone 或 pull，即可让 Claude Code 与 Codex 使用相同的项目语义，不需要再次安装 Bootstrap Skill。

## 边界

- 只支持 Windows。
- 仓库使用 MIT 协议。
- Skill 逻辑只维护一份。
- Claude Code 与 Codex 各有一个小型 PowerShell 安装器。
- 项目工作流和项目 Skill 只维护一份正文。
- 第一版只建立入口和共同工作流，不预生成业务 Skill。

## 分发结构

```text
bootstrap-project-workflow/
├─ README.md
├─ LICENSE
├─ install-claude.ps1
├─ install-codex.ps1
└─ skill/
   └─ bootstrap-project-workflow/
      ├─ SKILL.md
      └─ agents/
         └─ openai.yaml
```

两个安装器复制同一个 `skill/bootstrap-project-workflow`：

- Claude Code：`%USERPROFILE%\.claude\skills\bootstrap-project-workflow`
- Codex：`%USERPROFILE%\.agents\skills\bootstrap-project-workflow`

安装器只执行复制，不安装依赖，不修改系统配置，也不修改其他 Skill。目标目录已经存在时立即停止，不覆盖、不更新、不删除。

## 项目输出

第一版 Bootstrap 成功后，业务项目只新增：

```text
项目根目录/
├─ AGENTS.md
└─ .claude/
   └─ CLAUDE.md
```

`.claude` 是 Claude Code 与 Codex 共用的唯一项目知识源。`AGENTS.md` 只负责让 Codex 读取 `.claude/CLAUDE.md`，并按任务使用未来位于 `.claude/skills` 的项目 Skill；不得复制项目知识正文。

## 共同工作流内容

`.claude/CLAUDE.md` 记录：

1. 项目用途、技术类型和主要运行环境；
2. 主要目录和顶层代码框架；
3. 负责人确认过的启动、构建和验证命令；
4. 理解需求、读取代码、提交方案、等待审核、实施和验证的开发流程；
5. 禁止修改区域、代码规范和项目特有红线；
6. 项目 Skill 的拆分、触发和维护规则。

无法从项目中可靠确认的信息必须询问负责人，不得猜测。

## 项目 Skill 的演进

初次 Bootstrap 不创建空白业务 Skill。随着项目发展，独立且可复用的代码框架知识必须从共同工作流中拆出，例如：

```text
.claude/skills/<skill-name>/
├─ SKILL.md
├─ examples.md       # 只有需要时才创建
└─ checklist.md      # 只有需要时才创建
```

每个 `SKILL.md` 用 `description` 声明触发条件。Agent 根据当前任务只读取匹配的 Skill，不一次加载全部项目知识。新增或修改项目 Skill 前必须先提交拆分范围给负责人审核。

Codex 通过根目录 `AGENTS.md` 把 `.claude/skills/*/SKILL.md` 当作项目 Skill 使用；不创建或维护重复的 `.agents/skills` 正文。

## Bootstrap 工作流

1. 检查项目根目录是否已经存在 `.claude/CLAUDE.md` 或 `AGENTS.md`。
2. 若存在任一目标文件，立即停止并报告冲突；不覆盖、不合并、不备份。
3. 只读扫描项目结构和已有文档。
4. 识别项目类型、主要目录、顶层代码框架和可能的构建命令。
5. 对无法确认的信息逐项询问负责人。
6. 在聊天中展示两个目标文件的完整草稿和文件清单。
7. 等负责人明确审核。
8. 审核通过后只写入 `.claude/CLAUDE.md` 和 `AGENTS.md`。
9. 不自动运行项目构建、测试或其他验证。

## 验证边界

第一版只允许三项验证：

1. 对 Skill 运行一次官方 `quick_validate.py`；
2. 在临时用户目录运行一次 Claude 安装器，确认只安装该 Skill；
3. 在另一个临时用户目录运行一次 Codex 安装器，确认只安装该 Skill。

不启动子代理，不执行压力测试、安全攻击测试或 PowerShell 版本兼容矩阵，也不写入真实用户 Skill 目录。

在 `card-hero-skin-studio-windows` 中实际运行 Bootstrap 属于后续独立阶段，必须重新提交负责人审核。

## 明确不做

- 编译器、锁文件、哈希清单或漂移检测；
- 自动迁移、自动合并、自动覆盖或备份；
- Unity、Unreal 或工具项目的预置业务知识；
- 预生成 `.claude/skills` 业务 Skill 集；
- 自动升级安装器；
- 多代理实现、审查或验证循环；
- 未经负责人审核的实施、验证、提交或推送。
