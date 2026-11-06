# Unlimited Stacks Customizer (Minecraft ~26.2)

<div align="center">

[![Minecraft](https://img.shields.io/badge/Minecraft-~26.2-brightgreen.svg?logo=minecraft)](https://www.minecraft.net/)
[![Fabric](https://img.shields.io/badge/Modloader-Fabric-blue.svg?logo=fabric)](https://fabricmc.net/)
[![PowerShell](https://img.shields.io/badge/Platform-PowerShell_5.1%2B-5391FE.svg?logo=powershell)](https://learn.microsoft.com/powershell/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**无需 Java 编译环境，一键自由定制 Minecraft 物品与容器的最大堆叠上限。**  
*A lightweight, zero-dependency bytecode patcher for the Minecraft "Unlimited Stacks Mod".*

[English](#english-documentation) | [简体中文](#简体中文说明)

</div>

---

<a name="简体中文说明"></a>
## 📖 简介

在原版 Minecraft（包括 ~26.2 及更新版本）中，物品组件系统的默认堆叠上限最大被限制在 **99**。虽然优秀的开源模组 **[Unlimited Stacks](https://modrinth.com/mod/unlimited-stacks)**（由 HarryTheeWizard 开发）将堆叠上限提升到了 21 亿（`Integer.MAX_VALUE`），但由于其数值直接**硬编码在类字节码中**且未提供配置文件，玩家和整合包作者无法自由设定想要的堆叠上限（例如设定为常见的 999、1000、65535 或 1,000,000）。

**Unlimited Stacks Customizer** 是一个专为该模组打造的轻量级自动化修补工具。它直接在二进制级别解析 Jar 包中的常量池（Constant Pool），安全无损地将堆叠上限替换为您所指定的任何正整数，并自动完成文件备份与版本重命名。

---

> [!WARNING]
> ### ⚠️ 重要安全警告：调低堆叠上限会导致超出部分的物品消失！
> **实测证实**：若现有存档中已存在超过新上限的大堆叠物品（例如箱子里堆叠了 3000 个物品），**直接调低模组上限（例如降为 1000）并进入游戏，超出新上限的物品将会直接被系统截断丢弃并永久消失！**
>
> **安全降级操作流程：**
> 1. **第一步（必须）**：在修改模组前，完整备份你的世界存档（`saves/你的存档`）。
> 2. **第二步**：进入游戏，将所有超过目标新上限的大堆叠物品**提前手动分摊到多个空箱子/背包格子中**，确保没有单格数量超过新上限。
> 3. **第三步**：保存并完全退出游戏后，再运行本脚本降低模组上限。

---

## 📥 前置准备：获取原版模组

> [!NOTE]
> **关于原模组的分发说明**：  
> 出于对原作者版权、劳动成果与下载量统计的尊重，**本仓库仅提供补丁与定制工具，不直接附带或分发原模组的二进制 Jar 文件**。

在运行本修补工具前，请先前往官方渠道下载原版模组：
1. **前往 Modrinth 官方页面下载原版 Mod**：  
   👉 **[Unlimited Stacks Mod on Modrinth (by HarryTheeWizard)](https://modrinth.com/mod/unlimited-stacks)**
2. 将下载到的模组文件（如 `unlimited-stacks-mod-1.0.3.jar`）直接放置在**本工具同级目录**下（脚本运行时会自动检测该文件）。
3. 如需指定其他目录下的模组，也可在执行命令时使用 `-JarPath` 参数。

---

## ✨ 核心特性

- 🎯 **自由定制上限**：突破原版 99 限制，可设定为任意正整数（如 `500`、`999`、`1000`、`65535`、`1,000,000` 等）。
- 🛡️ **安全双向标注与备份**：
  - 修改前自动备份原文件，并在备份文件名中明确标注原上限数值（如 `...-limit-2147483647.jar.bak`）。
  - 修改后自动重命名为带上限标记的新文件名（如 `...-limit-1000.jar`），方便归档与多版本管理。
  - 防重复追加命名，多次修改依然保持文件名简洁。
- ⚡ **零环境依赖**：纯 Windows 原生 PowerShell + .NET 驱动，无需安装 JDK、Fabric Loom、Gradle 或任何编译工具链。
- 📝 **元数据同步更新**：同步更新 Jar 内 `fabric.mod.json` 中的模组描述文本，游戏内 Mod 菜单正确显示你设定的具体上限。
- 🛡️ **耐久物品原生保护**：模组内部保留了耐久度检测逻辑，武器、工具、防具等装备不会被修改堆叠，依然保持 1 个/堆。

---

## 🚀 快速上手

### 1. 查看当前模组的堆叠上限
确保原版模组 Jar 已放在当前目录下，运行：
```powershell
.\Modify-StackLimit.ps1
```
*输出示例：*
```text
=== Unlimited Stacks Mod: 读取当前设置 ===
模组文件: unlimited-stacks-mod-1.0.3.jar
  [ContainerMixin.class] -> 2,147,483,647 (0x7FFFFFFF)
  [ExtraCodecsMixin.class] -> 2,147,483,647 (0x7FFFFFFF)
  [ItemStackMixin.class] -> 2,147,483,647 (0x7FFFFFFF)
  [UnlimitedStacksMod.class] -> 2,147,483,647 (0x7FFFFFFF)
```

### 2. 修改上限为目标数值（例如 1000）
```powershell
.\Modify-StackLimit.ps1 1000
```
*输出示例：*
```text
=== Unlimited Stacks Mod: 开始修改堆叠上限 ===
当前文件: unlimited-stacks-mod-1.0.3.jar
新上限值: 1,000 (0x000003E8)
已创建备份: unlimited-stacks-mod-1.0.3-limit-2147483647.jar.bak (标注原上限: 2147483647)
  [已修改] ContainerMixin.class: 2,147,483,647 -> 1,000
  [已修改] ExtraCodecsMixin.class: 2,147,483,647 -> 1,000
  [已修改] ItemStackMixin.class: 2,147,483,647 -> 1,000
  [已修改] UnlimitedStacksMod.class: 2,147,483,647 -> 1,000
  [已更新] fabric.mod.json 模组信息描述
已更新名称: unlimited-stacks-mod-1.0.3-limit-1000.jar (标注新上限: 1000)

[SUCCESS] 修改完成！
  - 最终模组文件: unlimited-stacks-mod-1.0.3-limit-1000.jar
  - 备份原始文件: unlimited-stacks-mod-1.0.3-limit-2147483647.jar.bak
```

### 3. 高级用法
- **指定外部 Jar 路径修改**：
  ```powershell
  .\Modify-StackLimit.ps1 -NewLimit 999 -JarPath "C:\mc\mods\unlimited-stacks-mod-1.0.3.jar"
  ```
- **不生成备份文件**：
  ```powershell
  .\Modify-StackLimit.ps1 999 -NoBackup
  ```

---

## 🔍 技术原理 (How It Works)

本工具无需源码重新编译，通过直接解析并重写 Java Class 常量池（Constant Pool）中的 4 字节大端整数完成修补：

1. **`UnlimitedStacksMod.class` (CP[44])**：
   在 Fabric `DefaultItemComponentEvents.MODIFY` 事件中，为所有非耐久物品设置默认组件 `DataComponents.MAX_STACK_SIZE`。
2. **`ContainerMixin.class` (CP[3])**：
   通过 SpongePowered Mixin 重写 `Container.getMaxStackSize()` 容器容量上限。
3. **`ItemStackMixin.class` (CP[3])**：
   重写 `ItemStack.getMaxStackSize()` 单个物品堆叠上限。
4. **`ExtraCodecsMixin.class` (CP[9])**：
   拦截 `ExtraCodecs.intRange(min, max)`，当 `max == 99`（原版默认数据组件校验上限）时，将合法范围边界扩展为你设定的数值。
5. **`ItemCountDisplayMixin.class`**：
   客户端渲染 Mixin。当数量 `< 1000` 时正常展示全数字；当数量 `≥ 1000` 时自动缩写为 `1.0K`、`1.0M`、`1.0B` 等。

---

## ❓ 常见问题 (FAQ)

#### Q1: 如果游戏里已经有堆叠了 3000 个的物品，此时将上限降低为 1000，多出的物品会消失吗？
**是的，多出的物品会被直接截断丢失！**  
实测证明：在 Minecraft 26.2 中，当背包或箱子等容器加载与客户端同步时，若检测到格内物品数量超过了当前模组允许的最大堆叠上限，超出部分将会被系统**直接截断丢弃**（即 3000 个会变成 1000 个，多出的 2000 个无法找回）。  
⚠️ **请务必注意**：切勿在有大堆叠存档的情况下直接调低上限！请务必先备份存档，在游戏内将大堆叠分摊到多个格子中（确保每格不超过新上限），然后再退出游戏调低模组上限。

#### Q2: 上限数值建议设置多少？
* **上限理论极值**：Java 有符号 32 位整型上限为 `2,147,483,647`。为了防止两个大堆叠相加时发生整数溢出，建议的理论安全极值为 **`1,073,741,823`**（即 `Integer.MAX_VALUE / 2`）。
* **常规推荐数值**：`999`、`1000`、`9999`、`65535`、`1,000,000` 均为日常生存与服务器使用中最推荐的稳定数值。

---

<a name="english-documentation"></a>
## 🌐 English Documentation

### Overview
Minecraft ~26.2 (Fabric) natively caps item stack sizes at 99 in its data component codecs. While **[Unlimited Stacks Mod](https://modrinth.com/mod/unlimited-stacks)** (by HarryTheeWizard) lifts this ceiling up to 2.14 billion (`Integer.MAX_VALUE`), it hardcodes the limit in bytecode without providing a config file.

**Unlimited Stacks Customizer** is a zero-dependency PowerShell patcher that inspects and modifies the Constant Pool integers directly inside the compiled `.jar`, giving you full control over the exact stack size cap.

> [!WARNING]
> **Warning on Lowering Stack Limits**:
> Actual in-game testing confirms that if an existing world contains item stacks exceeding the new lower limit (e.g., a stack of 3,000 items when lowering the limit to 1,000), **the excess items WILL BE DISCARDED / CLAMPED upon loading**!  
> **Always backup your world save** and manually split your large stacks across multiple slots before decreasing the stack limit.

### 📥 Prerequisites: Download the Original Mod
> [!NOTE]
> **Distribution Notice**:  
> To respect the original author's copyright, labor, and download metrics, **this repository provides the patcher tool only and does NOT distribute the original mod binary `.jar` file**.

1. Download the original mod from the official Modrinth page:  
   👉 **[Unlimited Stacks Mod on Modrinth (by HarryTheeWizard)](https://modrinth.com/mod/unlimited-stacks)**
2. Place the downloaded `.jar` file (e.g., `unlimited-stacks-mod-1.0.3.jar`) into the same directory as this script.
3. You can also specify an external file path using the `-JarPath` parameter.

### Quick Commands
```powershell
# View current stack size cap
.\Modify-StackLimit.ps1

# Change stack size cap to 1000
.\Modify-StackLimit.ps1 1000

# Specify custom file and skip backup
.\Modify-StackLimit.ps1 -NewLimit 999 -JarPath "path/to/mod.jar" -NoBackup
```

---

## 🤝 致谢与开源协议 (Credits & License)

- **原模组开发 (Original Mod)**：[HarryTheeWizard](https://modrinth.com/user/HarryTheeWizard) - [Unlimited Stacks on Modrinth](https://modrinth.com/mod/unlimited-stacks)
- **开源协议 (License)**：本项目根据 [MIT License](LICENSE) 开源发布。
