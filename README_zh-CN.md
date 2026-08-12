# AI4EDA SystemVerilog 标准化数据集

[English](README.md) | [简体中文](README_zh-CN.md)

这是一个强调来源可追溯性的 HDL 数据集。初始语料来自 OpenCores，并补充
固定版本的 OpenTitan 衍生工程与仓库自研能力 IP；所有项目均以可综合
SystemVerilog 组织，并通过可自检仿真进行验证。

本仓库同时作为项目级 IP 工程任务图谱（IP-ETG）的唯一事实源。每个图谱连接
RTL 层次、接口、时钟/复位候选、验证义务、工具证据和公开工程任务。详细定义见
[数据集卡片](DATASET_CARD.md)与[图谱规范](docs/schema.md)。

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

- 共收录 40 个至少达到 Q2 的项目，均有编译、lint 与自检仿真证据；
- 包含 40 个可重复生成的 IP-ETG 与 389 条不含答案的候选任务；
- 28 个项目可发布源码，另有 12 个仅发布元数据或等待许可证审核；
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
| [pipelined_fft_64](projects/arithmetic/pipelined_fft_64) | 算术 | 64 点全流水复数 FFT，含两级归一化。 | 逐位黄金结果与频谱峰值检查 | `LicenseRef-OpenCores-Permissive` |
| [pipelined_mac](projects/arithmetic/pipelined_mac) | 算术 | 带 ready/valid 的有符号乘累加流水线。 | 延迟、停顿、清零和有符号运算检查 | `Apache-2.0` |
| [fir_filter](projects/arithmetic/fir_filter) | 算术 | 参数化四抽头流式 FIR 滤波器。 | 冲激与样本序列参考检查 | `Apache-2.0` |
| [tiny_spi](projects/communication/tiny_spi) | 通信 | 紧凑型 Wishbone 控制 SPI 主机。 | Wishbone 与 4 字节 SPI 环回 | `LGPL-2.1-or-later` |
| [rtfsimpleuart](projects/communication/rtfsimpleuart) | 通信 | 带 8N1 收发、波特率生成、缓冲和中断的 Wishbone UART。 | 双字节 8N1 协议环回 | `BSD-3-Clause` |
| [xge_mac](projects/communication/xge_mac) | 通信 | 带 XGMII 接口的 10 Gigabit Ethernet MAC 数据通路。 | 18 个数据包 XGMII 环回 | `LGPL-2.1-or-later` |
| [i2c](projects/communication/i2c) | 通信 | 符合 WISHBONE revB.2 的多主 I2C 主机，含字节/位控制器。 | 寄存器、从机写入/读回与 NACK 检查 | `LicenseRef-OpenCores-Permissive` |
| [uart2bus](projects/communication/uart2bus) | 通信 | 带 ASCII 与二进制命令解析器的 UART 转内部总线桥。 | 8N1 串口 ASCII 写入/读回 | `BSD-2-Clause` |
| [pit](projects/control/pit) | 控制 | 包含预分频器、计数器和标志的可编程间隔定时器。 | 寄存器、预分频和定时检查 | `BSD-3-Clause` |
| [simple_gpio](projects/control/simple_gpio) | 控制 | 支持可编程引脚方向的 Wishbone GPIO 控制器。 | Wishbone 与双向 GPIO 检查 | `LicenseRef-OpenCores-Permissive` |
| [simple_pic](projects/control/simple_pic) | 控制 | 支持屏蔽和电平/边沿模式的可编程中断控制器。 | 寄存器与中断模式检查 | `LicenseRef-OpenCores-Permissive` |
| [scalable_arbiter](projects/control/scalable_arbiter) | 控制 | 输出独热授权和二进制选择的参数化轮询仲裁器。 | 独热、屏蔽与公平性检查 | `ISC` |
| [reset_synchronizer](projects/cdc/reset_synchronizer) | CDC | 异步置位、同步释放的复位同步器。 | 异步置位与分级释放检查 | `Apache-2.0` |
| [cdc_handshake](projects/cdc/cdc_handshake) | CDC | 两相捆绑数据 CDC 握手。 | 有序传输与背压检查 | `Apache-2.0` |
| [apb_register_bank](projects/interconnect/apb_register_bank) | 互连 | 支持字节写使能和译码错误的 APB4 寄存器组。 | APB 读写与错误检查 | `Apache-2.0` |
| [axi_lite_slice](projects/interconnect/axi_lite_slice) | 互连 | AXI-Lite 五通道弹性寄存器切片。 | 停顿稳定性与响应检查 | `Apache-2.0` |
| [cdc_ufifo](projects/interconnect/cdc_ufifo) | 互连/CDC | 用于有序跨时钟域传输的双时钟异步 FIFO。 | 双时钟域有序传输检查 | `Apache-2.0` |
| [dma_axi32](projects/interconnect/dma_axi32) | 互连/CDC | 32 位数据通路的多通道 AXI DMA 集成顶层。 | APB 控制面与 AXI 空闲不变量检查 | `LicenseRef-LGPL-Unspecified-Version` |
| [dma_axi64](projects/interconnect/dma_axi64) | 互连/CDC | 64 位数据通路的多通道 AXI DMA 集成顶层。 | APB 控制面与 AXI 空闲不变量检查 | `LicenseRef-LGPL-Unspecified-Version` |
| [ready_valid_fifo](projects/interconnect/ready_valid_fifo) | 互连 | 参数化 ready/valid FIFO。 | 满空、顺序、稳定性和流式传输检查 | `Apache-2.0` |
| [skid_buffer](projects/interconnect/skid_buffer) | 互连 | 两项弹性 skid buffer。 | 背压与无损有序检查 | `Apache-2.0` |
| [versatile_fifo](projects/interconnect/versatile_fifo) | 互连/CDC | 采用 Gray 指针两级同步的双向异步 FIFO。 | 双向异步时钟传输检查 | `LGPL-2.1-or-later` |
| [wishbone_apb_bridge](projects/interconnect/wishbone_apb_bridge) | 互连 | 单未决事务 Wishbone-to-APB 桥。 | 读写、等待周期与错误检查 | `Apache-2.0` |
| [ot_sram_1p](projects/memory/ot_sram_1p) | 存储 | 依赖闭合的单端口 SRAM 衍生实现。 | 掩码写与读延迟检查 | `Apache-2.0` |
| [ot_sram_2p](projects/memory/ot_sram_2p) | 存储 | 依赖闭合的双端口 SRAM 衍生实现。 | 双端口与冲突策略检查 | `Apache-2.0` |
| [register_file](projects/memory/register_file) | 存储 | 带可选零寄存器的两读一写寄存器堆。 | 旁路与硬连零检查 | `Apache-2.0` |
| [ecc_ram](projects/memory/ecc_ram) | 存储 | 带验证注错端口的 32 位 SECDED RAM。 | 可纠正与不可纠正故障检查 | `Apache-2.0` |
| [wb_flash](projects/memory/wb_flash) | 存储 | 支持字节通道和等待周期应答的 Wishbone-to-Flash 接口。 | 字节通道与等待周期检查 | `LGPL-2.1-or-later` |
| [rv32i_microcore](projects/processor/rv32i_microcore) | 处理器 | 教学用途的多周期 RV32I 子集处理器。 | 算术、访存、分支、x0 与 trap 检查 | `Apache-2.0` |
| [configurable_crc_core](projects/security/configurable_crc_core) | 安全 | 参数化串行 CRC 生成与校验核心。 | 逐位 CRC-7 参考计分板 | `LicenseRef-Unknown` |
| [apbtoaes128](projects/security/apbtoaes128) | 安全 | 支持 ECB、CBC 和 CTR 模式的 APB AES-128 加速器。 | 已知答案、暂停恢复与 DMA 测试 | `LGPL-2.1-or-later` |
| [sha_core](projects/security/sha_core) | 安全 | SHA-1 与 SHA-256 哈希核心。 | SHA-1/SHA-256 已知答案测试 | `LicenseRef-OpenCores-Permissive` |
| [logicprobe](projects/verification/logicprobe) | 验证 | 包含采样捕获、读出复用和 UART 输出的嵌入式逻辑分析仪。 | 捕获、读出复用与 UART 检查 | `BSD-2-Clause` |
| [oc_axi_bfm](projects/verification/oc_axi_bfm) | 验证 | 用于生成读写事务的 AXI4-Lite 总线功能主机模型。 | AXI4-Lite 握手场景检查 | `LicenseRef-Unknown` |
| [ready_valid_checker](projects/verification/ready_valid_checker) | 验证 | 可综合 ready/valid 协议检查器。 | 稳定性违规检测与清除检查 | `Apache-2.0` |
| [video_stream_scaler](projects/video/video_stream_scaler) | 视频 | 支持双线性/最近邻模式和运行时分辨率调节的流式视频缩放器。 | 恒等缩放与 2 倍下采样黄金数据流比对 | `LGPL-2.1-or-later` |

“当前验证”列只表示仓库已经自动执行的检查。DMA 当前覆盖 APB 控制面与 AXI
空闲不变量，不覆盖真实载荷搬运、错误恢复，也不代表综合、CDC、时序或量产签核。

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

`run_all.py` 会依次从 `PATH`、仓库上级工作区的 `.tools` 目录，以及上述绝对路径
环境变量中查找工具。生成经过许可证门控的公开目录可执行：

```bash
python3 tools/export_release.py --output /tmp/ai4eda-sv-corpus-public
```

只有 `source_released` 项目会导出完整工程；`pending_review` 与
`metadata_only` 项目仅导出 catalog、图谱和任务元数据，不包含 RTL、include、
testbench、补丁及验证日志。

安装图谱工具依赖并验证全部 IP-ETG：

```bash
python3 -m pip install -r requirements-dev.txt
python3 tools/run_ipgraph_checks.py
```

当前本地 `v0.1.0` 发布候选包含 40 个通过 schema 验证且可重复生成的 IP-ETG，
以及 389 条不含答案的候选任务；40 个项目均至少达到 Q2。项目级切分已按
24/6/5/5 锁定为 train/dev/public/frozen，公开的实验前导出会排除 61 条冻结任务。
其中 1 个 train 项目已通过 10/10 mutation campaign 达到 Q3；其余候选仍保持
Q2，双专家审核也尚未完成，不能整体作为 Q3/Q4 论文训练数据。

### 发布候选质量与发布状态

<!-- BEGIN GENERATED PROJECT STATUS -->
| 项目 | 分类 | 质量等级 | 发布状态 | 候选任务数 |
|---|---|---:|---|---:|
| [apb_register_bank](projects/interconnect/apb_register_bank) | interconnect | Q2 | `source_released` | 7 |
| [apbtoaes128](projects/security/apbtoaes128) | security | Q2 | `source_released` | 16 |
| [axi_lite_slice](projects/interconnect/axi_lite_slice) | interconnect | Q2 | `source_released` | 7 |
| [binary_to_bcd](projects/arithmetic/binary_to_bcd) | arithmetic | Q2 | `source_released` | 11 |
| [cdc_handshake](projects/cdc/cdc_handshake) | cdc | Q2 | `source_released` | 7 |
| [cdc_ufifo](projects/interconnect/cdc_ufifo) | interconnect | Q2 | `source_released` | 7 |
| [configurable_crc_core](projects/security/configurable_crc_core) | security | Q2 | `metadata_only` | 7 |
| [dma_axi32](projects/interconnect/dma_axi32) | interconnect | Q2 | `metadata_only` | 16 |
| [dma_axi64](projects/interconnect/dma_axi64) | interconnect | Q2 | `metadata_only` | 16 |
| [ecc_ram](projects/memory/ecc_ram) | memory | Q2 | `source_released` | 7 |
| [fir_filter](projects/arithmetic/fir_filter) | arithmetic | Q2 | `source_released` | 7 |
| [fixed_point_arithmetic_parameterized](projects/arithmetic/fixed_point_arithmetic_parameterized) | arithmetic | Q2 | `metadata_only` | 11 |
| [i2c](projects/communication/i2c) | communication | Q2 | `metadata_only` | 11 |
| [ima_adpcm_enc_dec](projects/arithmetic/ima_adpcm_enc_dec) | arithmetic | Q2 | `metadata_only` | 11 |
| [logicprobe](projects/verification/logicprobe) | verification | Q2 | `source_released` | 11 |
| [oc_axi_bfm](projects/verification/oc_axi_bfm) | verification | Q2 | `metadata_only` | 7 |
| [ot_sram_1p](projects/memory/ot_sram_1p) | memory | Q2 | `source_released` | 7 |
| [ot_sram_2p](projects/memory/ot_sram_2p) | memory | Q2 | `source_released` | 7 |
| [pid_controller](projects/arithmetic/pid_controller) | arithmetic | Q2 | `metadata_only` | 7 |
| [pipelined_fft_64](projects/arithmetic/pipelined_fft_64) | arithmetic | Q2 | `metadata_only` | 16 |
| [pipelined_mac](projects/arithmetic/pipelined_mac) | arithmetic | Q2 | `source_released` | 15 |
| [pit](projects/control/pit) | control | Q2 | `source_released` | 11 |
| [ready_valid_checker](projects/verification/ready_valid_checker) | verification | Q2 | `source_released` | 7 |
| [ready_valid_fifo](projects/interconnect/ready_valid_fifo) | interconnect | Q3 | `source_released` | 7 |
| [register_file](projects/memory/register_file) | memory | Q2 | `source_released` | 7 |
| [reset_synchronizer](projects/cdc/reset_synchronizer) | cdc | Q2 | `source_released` | 7 |
| [rtfsimpleuart](projects/communication/rtfsimpleuart) | communication | Q2 | `source_released` | 11 |
| [rv32i_microcore](projects/processor/rv32i_microcore) | processor | Q2 | `source_released` | 15 |
| [scalable_arbiter](projects/control/scalable_arbiter) | control | Q2 | `source_released` | 11 |
| [sha_core](projects/security/sha_core) | security | Q2 | `metadata_only` | 11 |
| [simple_gpio](projects/control/simple_gpio) | control | Q2 | `metadata_only` | 7 |
| [simple_pic](projects/control/simple_pic) | control | Q2 | `metadata_only` | 7 |
| [skid_buffer](projects/interconnect/skid_buffer) | interconnect | Q2 | `source_released` | 7 |
| [tiny_spi](projects/communication/tiny_spi) | communication | Q2 | `source_released` | 7 |
| [uart2bus](projects/communication/uart2bus) | communication | Q2 | `source_released` | 11 |
| [versatile_fifo](projects/interconnect/versatile_fifo) | interconnect | Q2 | `source_released` | 11 |
| [video_stream_scaler](projects/video/video_stream_scaler) | video | Q2 | `source_released` | 11 |
| [wb_flash](projects/memory/wb_flash) | memory | Q2 | `source_released` | 7 |
| [wishbone_apb_bridge](projects/interconnect/wishbone_apb_bridge) | interconnect | Q2 | `source_released` | 7 |
| [xge_mac](projects/communication/xge_mac) | communication | Q2 | `source_released` | 16 |
<!-- END GENERATED PROJECT STATUS -->

也可以指定工具路径：

```bash
IVERILOG=/path/iverilog \
VVP=/path/vvp \
VERILATOR=/path/verilator \
python3 tools/run_all.py
```

当前本地发布候选中 40/40 个项目通过编译、自检仿真和 lint 回归。详细信息见
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

每个项目单独记录 `source_released`、`metadata_only` 或 `pending_review` 发布状态。
免责声明不能创造再分发权，制作公开 Release 前必须阅读
[`LICENSE_POLICY.md`](LICENSE_POLICY.md) 和机器可读审计结果。

## 公开发布提示

当前有 6 个项目使用 `LicenseRef-Unknown` 或
`LicenseRef-LGPL-Unspecified-Version`。公开传播或用于商业场景之前，应进一步
核对 OpenCores 上游发布信息、联系权利人，并进行必要的版权或法律审查。
仓库设为私有也不会自动消除版权义务。
