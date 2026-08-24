# bootstrap-project-workflow 实施路线

> 本路线把已批准规格拆成三个可独立验收的实施计划。必须按顺序执行；每份计划完成后保留测试证据和独立提交，再进入下一份。

## 顺序与完成门禁

1. [核心 Skill 与脚手架编译器](2026-08-24-core-scaffold-compiler-plan.md)
   - 交付只读项目检查器、统一源契约、五个项目 Skill、双运行时渲染、同步与漂移检查。
   - 门禁：Pester 核心测试全通过；连续渲染零 diff；手改任一生成文件可被检测。
2. [Windows 安装、更新与发布](2026-08-24-windows-install-distribution-plan.md)
   - 交付 Claude Code/Codex 两个安装入口、幂等联接、更新/卸载、Windows CI 和安装文档。
   - 门禁：Windows PowerShell 5.1 与 PowerShell 7.x 安装测试全通过；冲突目录不被覆盖。
3. [皮肤工具试点接入与双 Agent 验收](2026-08-24-card-hero-skin-studio-pilot-plan.md)
   - 在 `C:\workspace\ai_project\codex\card-hero-skin-studio-windows` 生成并审核统一源，提交 Claude Code/Codex 原生脚手架，验证新 clone 无需 bootstrap Skill。
   - 门禁：业务代码和执行时已有用户改动不变；Claude Code 与 Codex 对同一诊断任务满足同一结构化契约。

## 共同质量规则

- Windows-only；不加入 macOS、Linux、WSL 分支。
- 使用 PowerShell 5.1 兼容语法，并在 PowerShell 7.x 重跑相同测试。
- Pester 最低测试版本为 `5.7.1`；本机当前只有 `3.4.0`，实际执行前需获得用户许可后安装到 `CurrentUser`，或在隔离 CI 中运行。
- 所有实现按 RED-GREEN-REFACTOR：先观察目标测试失败，再写最小实现，再运行完整相关测试。
- 业务仓库中的 `.agent-workflow` 是唯一维护源；`CLAUDE.md`、`AGENTS.md`、`.claude/skills`、`.agents/skills` 只由编译器生成。
- 真实 Claude Code/Codex 黑盒调用可能产生外部调用或费用，必须在计划 2 的 Skill 行为验收和计划 3 的零安装验收开始前分别询问用户。
- 每个任务只提交任务列出的文件；不清理、不重置、不覆盖无关工作树变化。

## 版本节点

- `0.1.0-dev`：计划 1 完成，核心编译器可在夹具工程运行。
- `0.1.0-rc.1`：计划 2 完成，可从 Git clone 安装到两个运行时。
- `0.1.0`：计划 3 完成，试点和新 clone 双运行时验收通过。

## 规格覆盖索引

| 已批准规格 | 实施位置 |
|---|---|
| 产品目标、同等语义、作者责任链 | 计划 1 Task 1/3/4；计划 3 Task 1/2/5 |
| 非目标与 Windows-only 边界 | 三份计划的 Global Constraints |
| GitHub Skill、统一源、双原生产物 | 计划 1 Task 1/3/4 |
| Claude/Codex 安装、更新、卸载 | 计划 2 Task 1/2/4 |
| 只读体检、方案门禁、语义创作边界 | 计划 1 Task 1/2；计划 2 Task 5；计划 3 Task 1/2 |
| 现有入口迁移和用户改动保护 | 计划 1 Task 6；计划 3 Task 1/3 |
| 同步、幂等与漂移检查 | 计划 1 Task 4/5/7；计划 3 Task 3 |
| 五个通用工作流 | 计划 1 Task 3；计划 3 Task 2 |
| Unity、Unreal、通用工具适配器 | 计划 1 Task 2；计划 2 Task 5；计划 3 Task 1/2 |
| Pester、中文/空格/长路径、双 PowerShell | 计划 1 Task 2/4/5/7；计划 2 Task 1/2/3/4 |
| Skill 安装前后行为测试 | 计划 2 Task 5 |
| 皮肤工具试点和相同诊断契约 | 计划 3 Task 1 至 Task 5 |
| 安全、错误处理、凭据和商业资源边界 | 计划 1 Task 2/5/6/7；计划 2 Task 1/2/4；计划 3 全部任务 |
| 私有发布、MIT、版本与完成定义 | 计划 2 Task 3/4/5；计划 3 Task 6；三份 Completion Gate |
