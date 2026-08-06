# AI4EDA SystemVerilog 标准化数据集

[English](README.md) | [简体中文](README_zh-CN.md)

这是一个强调来源可追溯性的 HDL 数据集。项目选取 OpenCores IP，将其向
可综合 SystemVerilog 规范化重构，并通过可自检仿真进行验证。

## 项目目标

本仓库面向未来 AI4EDA 研究和工程应用，目标是逐步建设标准化、可追溯、
可执行验证的 SystemVerilog 数据集。IP 原始素材来源于 OpenCores；仓库以
统一形式组织规范化后的 RTL、修改补丁、元数据、来源信息和可复现验证资产，
同时保留原始版权声明和许可证信息。

数据集可用于：

- RTL 代码生成与自动修复；
- 时序逻辑、并发语义和可综合编码能力训练；
- 多层次 RTL hierarchy 与接口理解；
- IP 检索、组合与复用；
- testbench、断言和验证代码生成；
- AI4EDA 模型训练、评测和回归测试。

这里的“标准化”指本仓库的数据结构、来源记录、SystemVerilog 规范化目标和
验证流程，不代表 IEEE、Accellera 或其他组织的官方认证。

## 当前范围

- 共收录 14 个经过验证的项目；其中 4 个项目的许可证信息尚不完整或待确认；
- 保留上游源文件中的原始版权和许可证声明；
- 每个项目包含 `ORIGIN.yml`、重构元数据或补丁、RTL 和测试资产；
- 许可证存在歧义的项目按数据集维护者要求收录，并进行醒目标记；
- 当前验证结果不代表形式等价、综合签核、时序收敛或量产认证。

## 目录结构

```text
projects/<功能分类>/<项目名称>/
LICENSES/
NOTICE.md
manifest.json
EXCLUDED_PROJECTS.json
```

每个项目通常包含：

```text
ORIGIN.yml                 # 上游来源和许可证状态
metadata.json              # 重构范围、语言和验证元数据
refactor.patch             # 原始代码到规范化代码的修改证据
rtl/                       # RTL 代码
tb/ 或 tbench/             # 测试平台
scripts/run.sh 或 run.sh   # 独立回归脚本
validation/                # 基线验证结果
```

## 运行验证

安装 Icarus Verilog 和 Verilator，然后执行：

```bash
python3 tools/run_all.py
```

也可以指定工具路径：

```bash
IVERILOG=/path/iverilog \\
VVP=/path/vvp \\
VERILATOR=/path/verilator \\
python3 tools/run_all.py
```

当前发布快照中 14/14 个项目通过编译、自检仿真和 lint 回归。详细信息见
[`VALIDATION.md`](VALIDATION.md)。

## 版权与许可证

这是一个多许可证仓库。顶层 `LICENSE` 仅说明仓库内材料的许可证划分，
不会将第三方 HDL 重新授权为统一许可证。复用任何项目之前，请同时查看：

- [`NOTICE.md`](NOTICE.md)；
- [`LICENSES/`](LICENSES/)；
- 项目自己的 `ORIGIN.yml`；
- RTL 文件中保留的原始版权和许可证头。

`LicenseRef-Unknown` 表示在本地上游材料中没有找到明确的再分发许可证；
`LicenseRef-LGPL-Unspecified-Version` 表示发现了 LGPL 声明，但没有确认具体版本。
收录代码不等同于获得授权。

## 公开发布提示

当前有 4 个项目使用 `LicenseRef-Unknown` 或
`LicenseRef-LGPL-Unspecified-Version`。公开传播或用于商业场景之前，应进一步
核对 OpenCores 上游发布信息、联系权利人，并进行必要的版权或法律审查。
仓库设为私有也不会自动消除版权义务。
