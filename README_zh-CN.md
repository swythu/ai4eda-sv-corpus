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

- 共收录 21 个经过验证的项目；其中 6 个项目的许可证信息尚不完整或待确认；
- 保留上游源文件中的原始版权和许可证声明；
- 每个项目包含 `ORIGIN.yml`、重构元数据或补丁、RTL 和测试资产；
- 许可证存在歧义的项目按数据集维护者要求收录，并进行醒目标记；
- 当前验证结果不代表形式等价、综合签核、时序收敛或量产认证。

## IP 列表

| IP | 分类 | 功能说明 | 当前验证 | 许可证 |
|---|---|---|---|---|
| [binary_to_bcd](projects/arithmetic/binary_to_bcd) | 算术 | 参数化二进制转 BCD 转换器。 | 边界向量功能检查 | `LGPL-2.1-or-later` |
| [fixed_point_arithmetic_parameterized](projects/arithmetic/fixed_point_arithmetic_parameterized) | 算术 | 参数化定点加法、乘法和迭代除法单元。 | 数学参考模型检查 | `LicenseRef-Unknown` |
| [ima_adpcm_enc_dec](projects/arithmetic/ima_adpcm_enc_dec) | 算术 | 带预测值和索引状态的 IMA ADPCM 音频编解码器。 | 64 组样本逐周期等价检查 | `LicenseRef-OpenCores-Permissive` |
| [pid_controller](projects/arithmetic/pid_controller) | 算术 | 带有符号 P/I/D 状态和溢出报告的 Wishbone PID 控制器。 | 连续采样数学参考检查 | `LicenseRef-Unknown` |
| [tiny_spi](projects/communication/tiny_spi) | 通信 | 紧凑型 Wishbone 控制 SPI 主机。 | Wishbone 与 4 字节 SPI 环回 | `LGPL-2.1-or-later` |
| [rtfsimpleuart](projects/communication/rtfsimpleuart) | 通信 | 带 8N1 收发、波特率生成、缓冲和中断的 Wishbone UART。 | 双字节 8N1 协议环回 | `BSD-3-Clause` |
| [xge_mac](projects/communication/xge_mac) | 通信 | 带 XGMII 接口的 10 Gigabit Ethernet MAC 数据通路。 | 18 个数据包 XGMII 环回 | `LGPL-2.1-or-later` |
| [pit](projects/control/pit) | 控制 | 包含预分频器、计数器和标志的可编程间隔定时器。 | 寄存器、预分频和定时检查 | `BSD-3-Clause` |
| [simple_gpio](projects/control/simple_gpio) | 控制 | 支持可编程引脚方向的 Wishbone GPIO 控制器。 | Wishbone 与双向 GPIO 检查 | `LicenseRef-OpenCores-Permissive` |
| [simple_pic](projects/control/simple_pic) | 控制 | 支持屏蔽和电平/边沿模式的可编程中断控制器。 | 寄存器与中断模式检查 | `LicenseRef-OpenCores-Permissive` |
| [scalable_arbiter](projects/control/scalable_arbiter) | 控制 | 输出独热授权和二进制选择的参数化轮询仲裁器。 | 独热、屏蔽与公平性检查 | `ISC` |
| [cdc_ufifo](projects/interconnect/cdc_ufifo) | 互连/CDC | 用于有序跨时钟域传输的双时钟异步 FIFO。 | 双时钟域有序传输检查 | `Apache-2.0` |
| [dma_axi32](projects/interconnect/dma_axi32) | 互连/CDC | 32 位数据通路的多通道 AXI DMA 集成顶层。 | 展开与复位/空闲冒烟检查 | `LicenseRef-LGPL-Unspecified-Version` |
| [dma_axi64](projects/interconnect/dma_axi64) | 互连/CDC | 64 位数据通路的多通道 AXI DMA 集成顶层。 | 展开与复位/空闲冒烟检查 | `LicenseRef-LGPL-Unspecified-Version` |
| [versatile_fifo](projects/interconnect/versatile_fifo) | 互连/CDC | 采用 Gray 指针两级同步的双向异步 FIFO。 | 双向异步时钟传输检查 | `LGPL-2.1-or-later` |
| [wb_flash](projects/memory/wb_flash) | 存储 | 支持字节通道和等待周期应答的 Wishbone-to-Flash 接口。 | 字节通道与等待周期检查 | `LGPL-2.1-or-later` |
| [configurable_crc_core](projects/security/configurable_crc_core) | 安全 | 参数化串行 CRC 生成与校验核心。 | 逐位 CRC-7 参考计分板 | `LicenseRef-Unknown` |
| [apbtoaes128](projects/security/apbtoaes128) | 安全 | 支持 ECB、CBC 和 CTR 模式的 APB AES-128 加速器。 | 已知答案、暂停恢复与 DMA 测试 | `LGPL-2.1-or-later` |
| [sha_core](projects/security/sha_core) | 安全 | SHA-1 与 SHA-256 哈希核心。 | SHA-1/SHA-256 已知答案测试 | `LicenseRef-OpenCores-Permissive` |
| [logicprobe](projects/verification/logicprobe) | 验证 | 包含采样捕获、读出复用和 UART 输出的嵌入式逻辑分析仪。 | 捕获、读出复用与 UART 检查 | `BSD-2-Clause` |
| [oc_axi_bfm](projects/verification/oc_axi_bfm) | 验证 | 用于生成读写事务的 AXI4-Lite 总线功能主机模型。 | AXI4-Lite 握手场景检查 | `LicenseRef-Unknown` |

“当前验证”列只表示仓库已经自动执行的检查。例如“复位/空闲冒烟检查”不代表
DMA 搬运功能已经完整验证，也不代表综合、CDC、时序或量产签核。

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
IVERILOG=/path/iverilog \
VVP=/path/vvp \
VERILATOR=/path/verilator \
python3 tools/run_all.py
```

当前发布快照中 21/21 个项目通过编译、自检仿真和 lint 回归。详细信息见
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

当前有 6 个项目使用 `LicenseRef-Unknown` 或
`LicenseRef-LGPL-Unspecified-Version`。公开传播或用于商业场景之前，应进一步
核对 OpenCores 上游发布信息、联系权利人，并进行必要的版权或法律审查。
仓库设为私有也不会自动消除版权义务。
