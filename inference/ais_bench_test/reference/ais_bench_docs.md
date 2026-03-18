# AISBench 参考文档

## 官方文档

- AISBench 官方文档：https://ais-bench-benchmark.readthedocs.io/zh-cn/latest/
- vLLM-Ascend 文档：https://docs.vllm.ai/projects/ascend/en/latest/
- vLLM-Ascend GitHub：https://github.com/vllm-project/vllm-ascend

## 安装 AISBench

```bash
# 克隆仓库
git clone https://gitee.com/aisbench/benchmark.git
cd benchmark/

# 安装
pip3 install -e ./ --use-pep517

# 安装额外依赖
pip3 install -r requirements/api.txt
pip3 install -r requirements/extra.txt
```

## 数据集下载

### C-Eval

```bash
cd ais_bench/datasets
mkdir ceval/
mkdir ceval/formal_ceval
cd ceval/formal_ceval
wget https://www.modelscope.cn/datasets/opencompass/ceval-exam/resolve/master/ceval-exam.zip
unzip ceval-exam.zip
rm ceval-exam.zip
```

### MMLU

```bash
cd ais_bench/datasets
wget http://opencompass.oss-cn-shanghai.aliyuncs.com/datasets/data/mmlu.zip
unzip mmlu.zip
rm mmlu.zip
```

### GSM8K

```bash
cd ais_bench/datasets
wget http://opencompass.oss-cn-shanghai.aliyuncs.com/datasets/data/gsm8k.zip
unzip gsm8k.zip
rm gsm8k.zip
```

### MATH

```bash
cd ais_bench/datasets
wget http://opencompass.oss-cn-shanghai.aliyuncs.com/datasets/data/math.zip
unzip math.zip
rm math.zip
```

### AIME 2024

```bash
cd ais_bench/datasets
mkdir aime/
cd aime/
wget http://opencompass.oss-cn-shanghai.aliyuncs.com/datasets/data/aime.zip
unzip aime.zip
rm aime.zip
```

### ShareGPT

```bash
cd ais_bench/datasets
mkdir sharegpt/
cd sharegpt/
wget https://huggingface.co/datasets/romaintha/sharegpt_filtered/resolve/main/sharegpt_filtered.json
```

---

## Synthetic 数据集配置

### 分布方法

- **uniform**: 均匀分布
  - MinValue: 最小值 [1, 2^20]
  - MaxValue: 最大值 [1, 2^20]

- **gaussian**: 高斯分布
  - Mean: 平均值
  - Var: 方差
  - MinValue: 最小值
  - MaxValue: 最大值

- **zipf**: Zipf 分布
  - Alpha: 形状参数 (1.0, 10.0]
  - MinValue: 最小值
  - MaxValue: 最大值

### TokenID 模式

使用 TokenID 模式可以精确控制 token 数量（需要 tokenizer）：

```python
synthetic_config = {
    "Type": "tokenid",
    "RequestCount": 10,
    "TrustRemoteCode": True,
    "TokenIdConfig": {
        "RequestSize": 1024  # 每条请求的 token 数量
    }
}
```

## 测试模式

| 用户需求 | 命令参数 | 说明 |
|----------|-------------|------|
| 性能测试 | `--mode perf` | 测试 TTFT、TPOT、吞吐量等性能指标 |
| 推理 | `--mode infer` | 仅生成推理结果 |
| 评估 | `--mode eval` | 基于已有推理结果执行评估（需要先运行 `--mode infer`） |
| 推理+评估 | `--mode all` | 推理+评估（不包含性能测试） |

> **说明**：
> - `--mode eval`: 基于已有推理结果执行评估（需要先运行 `--mode infer`）
> - `--mode all`: 推理+评估（不包含性能测试）
> - 如果需要同时运行性能测试和评估，需要分别运行 `--mode perf` 和 `--mode infer` + `--mode eval`

---

## 结果文件

```
outputs/default/<timestamp>/
├── configs/                    # 配置信息
├── logs/                       # 执行日志
│   └── performances/
│       └── <model_abbr>/
│           └── <dataset>.out
├── predictions/                # 推理结果
├── results/                   # 原始分数
└── performances/              # 性能结果
    └── <model_abbr>/
        ├── <dataset>.csv
        ├── <dataset>.json
        └── <dataset>_details.json
```

---

## 关键配置文件位置

| 用途 | 路径 |
|------|------|
| 流式模型配置 | `<aisbench_install_path>/ais_bench/benchmark/configs/models/vllm_api/vllm_api_stream_chat.py` |
| 非流式模型配置 | `<aisbench_install_path>/ais_bench/benchmark/configs/models/vllm_api/vllm_api_general_chat.py` |
| 随机数据配置 | `<aisbench_install_path>/ais_bench/datasets/synthetic/synthetic_config.py` |
| 真实数据集配置目录 | `<aisbench_install_path>/ais_bench/benchmark/configs/datasets/` |

> **配置说明**：
> - **模型配置**: `benchmark/configs/models/` 目录下配置 vLLM 服务的连接信息（host_ip、port等）
> - **真实数据集**: 需要同时配置数据文件（`datasets/<name>/`）和配置文件（`benchmark/configs/datasets/<name>/`）
> - **随机数据集(Synthetic)**: 只需配置 `datasets/synthetic/synthetic_config.py`

---

## 模型配置参数

| 参数 | 说明 | 示例值 |
|------|------|--------|
| `abbr` | AISBench 中的任务标识 | vllm-api-stream-chat, vllm-api-general-chat |
| `path` | 模型权重路径 | /home/weights/TeleChat2-7B-32K/ |
| `model` | vLLM 中的模型名称 | telechat, qwen |
| `host_ip` | vLLM 服务 IP | localhost, 192.168.1.100 |
| `host_port` | vLLM 服务端口 | 8000, 8113 |
| `max_out_len` | 最大输出 token 数 | 512, 1024, 2048 |

### generation_kwargs 子参数

| 参数 | 说明 | 示例值 |
|------|------|--------|
| `temperature` | 采样温度 | 0 (确定性) |
| `ignore_eos` | 是否忽略 EOS | True/False |
| `repetition_penalty` | 重复惩罚（性能测试默认 1.0） | 1.0, 1.1 |

---

## 文档变量说明

本文档中使用 `< >` 包裹的变量说明：

| 变量 | 说明 |
|------|------|
| `<aisbench_install_path>` | AISBench 安装路径 |
| `<host_ip>` | vLLM 服务 IP |
| `<port>` | vLLM 服务端口 |
| `<model_abbr>` | 对应模型配置中的 `abbr` 字段 |
| `<model_path>` | 对应模型配置中的 `path` 字段 |
| `<model_name_in_vllm>` | 对应模型配置中的 `model` 字段 |
| `<max_out_len>` | 对应模型配置中的 `max_out_len` 字段 |
| `<num_requests>` | Synthetic 数据集生成的数据条数，对应 RequestCount 字段 |
| `<concurrency>` | 并发测试时的并发数，对应模型配置中的 batch_size 字段 |
| `<num_prompts>` | 测试时实际发送的请求数量，对应命令行的 --num-prompts 参数 |
| `<dataset_name>` | 数据集配置名 |
| `<timestamp>` | 测试运行的时间戳 |
| `<min_input>` | Synthetic 数据集输入的最小长度（Type=string 时为字符数，Type=tokenid 时为 token 数） |
| `<max_input>` | Synthetic 数据集输入的最大长度（Type=string 时为字符数，Type=tokenid 时为 token 数） |
| `<min_output>` | Synthetic 数据集输出的最小长度（Type=string 时为字符数，Type=tokenid 时为 token 数） |
| `<max_output>` | Synthetic 数据集输出的最大长度（Type=string 时为字符数，Type=tokenid 时为 token 数） |

> **注意**: Synthetic 数据集配置中的 `Type` 决定参数含义：
> - `Type="string"`: 使用 `StringConfig` 配置，MinValue/MaxValue 单位是**字符数**
> - `Type="tokenid"`: 使用 `TokenIdConfig.RequestSize` 配置，单位是 **token 数**

---

## 测试结果解读

### 流式输出关键指标

| 指标 | 说明 |
|------|------|
| **TTFT** | Time To First Token，首个 token 响应时间 |
| **TPOT** | Time Per Output Token，每个输出 token 的平均时间 |
| **ITL** | Inter-Token Latency，token 之间的延迟 |
| **E2EL** | End-to-End Latency，端到端延迟 |

### 吞吐量指标

| 指标 | 说明 |
|------|------|
| **Input Token Throughput** | 输入 token 吞吐量 (token/s) |
| **Output Token Throughput** | 输出 token 吞吐量 (token/s) |
| **Total Token Throughput** | 总 token 吞吐量 (token/s) |
| **Request Throughput** | 请求吞吐量 (req/s) |
