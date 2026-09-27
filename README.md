# 数字华容道 (Number Klotski)

> 一款用 **Godot 4** 制作、面向 **中小学生** 的数字推盘（15-Puzzle）游戏。
> 友好的引导、正向鼓励、无障碍选项与多种玩法，让第一次接触拼图的孩子也能轻松上手。

[![Engine](https://img.shields.io/badge/Godot-4.7%2B-478cbf?logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![Language](https://img.shields.io/badge/language-GDScript-355570)](https://docs.godotengine.org/)
[![License](https://img.shields.io/badge/license-MIT-green)](./LICENSE)

> A kid-friendly number sliding puzzle built with Godot 4. See the
> [English section](#english) below.

---

## ✨ 特性

- **6 种玩法**：自由拼图、限时闯关、限步闯关、记忆挑战、每日一题、闯关模式。
- **4 档棋盘**：3×3 入门 / 4×4 经典 / 5×5 进阶 / 6×6 大师，自动生成保证可解。
- **新手引导**：首次进入自动讲解玩法，并高亮演示第一步；随时可点「玩法」重看。
- **正向反馈**：完成度进度条 + 每跨过 25% 的鼓励提示，不催促、只鼓励。
- **键盘友好**：支持方向键滑动方块，方便用电脑的孩子。
- **无障碍选项**：浅色 / 深色 / 高对比三套主题，数字 / 汉字 / 符号三种方块样式，字体缩放，减少动画，计时器可隐藏。
- **成长系统**：星级评价、最佳记录、统计面板、10 个成就。
- **每日一题**：基于日期的确定性题目，全球同一天同一题。
- **零外部素材**：音效全部由代码实时合成，仓库不含任何第三方资源。

## 🎮 玩法与操作

目标：把数字按 `1 → N` 的顺序排好，空位留在右下角。

| 操作 | 说明 |
| --- | --- |
| 鼠标 / 触屏 | 点击空格旁边的方块，方块滑入空位 |
| 方向键 | 按方向键，让方块朝该方向滑动 |
| ↩ 撤销 | 回退上一步 |
| 💡 提示 | 给出下一步建议（3×3 为最优解） |
| ❓ 玩法 | 重新查看新手引导 |
| 🔄 重开 | 重新打乱当前棋盘 |

## 🚀 运行

1. 安装 [Godot 4.7 或更高版本](https://godotengine.org/download)（标准版即可，无需 .NET）。
2. 克隆仓库：

   ```bash
   git clone <你的仓库地址>.git
   cd new-15puzzle-steam
   ```

3. 用 Godot 打开本目录下的 `project.godot`，按 <kbd>F5</kbd> 运行。

也可以在命令行直接运行：

```bash
godot --path . # 需要 godot 在 PATH 中
```

导出到 Windows / Linux / macOS / Web 时，请在 Godot 编辑器中配置 `export_presets.cfg`
（该文件因可能包含本地路径/签名信息而已被 `.gitignore` 忽略）。

## 🗂 项目结构

```
.
├── project.godot            # 工程配置（窗口、自动加载、渲染器）
├── autoload/                # 全局单例（自动加载）
│   ├── constants.gd         # 模式、尺寸、星级等常量
│   ├── event_bus.gd         # 全局信号总线，模块间解耦
│   ├── save_manager.gd      # JSON 存档读写 + 备份
│   ├── settings_manager.gd  # 设置项
│   ├── theme_manager.gd     # 主题配色与方块配色
│   ├── audio_manager.gd     # 程序化音效合成
│   ├── stats_manager.gd     # 统计与最佳记录
│   ├── achievement_manager.gd
│   ├── puzzle_solver.gd     # IDA* 求解（3×3 最优解 / 大棋盘启发式）
│   ├── game_session.gd      # 单局状态与存档恢复
│   ├── toast_manager.gd     # 屏幕提示
│   └── transition_manager.gd# 场景切换与淡入淡出
├── core/                    # 与渲染无关的纯逻辑
│   ├── puzzle_board.gd      # 棋盘数据结构与移动规则
│   └── puzzle_generator.gd  # 逆向打乱（保证可解）
├── scenes/                  # 场景入口（脚本挂载于根节点）
└── ui/                      # 各界面脚本与 UIFactory 控件工厂
```

### 架构要点

- **单一数据源**：跨系统通信统一走 `EventBus`，模块之间不直接互相引用。
- **逻辑与表现分离**：`core/` 不依赖任何节点，可独立单元测试。
- **性能友好**：移动时只为真正变化的方块创建补间；求解器有节点/时间预算，避免卡住主线程。
- **存档安全**：写入前自动备份，JSON 损坏时回退到备份。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request：

1. Fork 本仓库并新建分支：`git checkout -b feature/your-idea`
2. 保持代码风格一致（GDScript，Tab 缩进，中文注释）。
3. 提交前请确保在 Godot 中可正常运行、无报错。
4. 提交 PR 并说明改动动机与验证方式。

特别欢迎：更多儿童友好的引导、无障碍改进、翻译与本地化。

## 📄 许可证

本项目基于 [MIT License](./LICENSE) 开源，可自由使用、修改与分发（含商业用途），
请保留版权声明。

---

## English

**Number Klotski** is a kid-friendly number sliding puzzle game built with
**Godot 4** and GDScript.

- 6 game modes, 4 board sizes (3×3 – 6×6), daily challenge.
- Built-in onboarding tutorial, progress bar and encouraging feedback.
- Keyboard (arrow keys) and pointer support.
- Light / Dark / High-contrast themes, tile styles, font scaling, reduced motion.
- All sound effects are generated procedurally — no third-party assets in the repo.

### Run

Install [Godot 4.7+](https://godotengine.org/download), clone the repo, open
`project.godot`, and press <kbd>F5</kbd>. Or run `godot --path .` from a terminal.

### License

Released under the [MIT License](./LICENSE).
