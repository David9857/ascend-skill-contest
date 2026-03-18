---
name: ais-bench-test
description: 使用 AISBench 对 vLLM-Ascend 进行性能测试和精度评估。触发场景：用户需要测试 vLLM 推理服务的性能(TTFT/TPOT/吞吐量)、使用 AISBench 进行基准测试、测试模型精度(cEval/MMLU/GSM8K)、进行并发压力测试、使用 Synthetic 数据集进行固定长度测试。确保在用户提及性能测试、基准测试、AISBench、vLLM-Ascend 时主动使用此 Skill。
---

# AISBench Test Skill

使用 AISBench 对 vLLM-Ascend 进行性能测试的完整流程。

## 快速开始

1. **确认测试场景**：性能测试(perf) 或 精度测试(all)
2. **配置模型**：编辑 `vllm_api_stream_chat.py` 或 `vllm_api_general_chat.py`
3. **运行测试**：`ais_bench --models <model> --datasets <dataset> --mode <mode> --num-prompts <num>`

> **提示**：不确定参数含义时，查阅 `reference/ais_bench_docs.md`

---

## 使用场景

当用户需要测试 vLLM-Ascend 服务的**性能或精度**时，使用此 Skill。

## 前置条件

### 需要用户提供的参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `<host_ip>` | vLLM 服务所在服务器的 IP 地址 | localhost, 192.168.1.100 |
| `<port>` | vLLM 服务的端口号 | 8000, 8001, 8113 |
| `<model_path>` | 模型权重路径 | /home/weights/Qwen3-VL-30B |

> **注意**：`<model_name_in_vllm>` 可通过 `curl http://<host_ip>:<port>/v1/models` 查询

### 环境要求

1. **vLLM-Ascend 服务已启动**
   ```bash
   curl http://<host_ip>:<port>/v1/models
   ```

2. **AISBench 已安装**
   ```bash
   pip show ais_bench_benchmark
   ```

3. **环境变量设置**
   ```bash
   export BENCHMARK_HOME=<aisbench_install_path>
   ```

---

## 测试类型选择

在开始测试前，确认用户的测试场景：

### 测试模式

| 用户需求 | 选择模式 |
|----------|----------|
| 性能测试 | `perf` |
| 精度测试 | `all` |
| 精度测试 + prefix_cache/MTP/EAGLE-3 | `all` |

### 流式/非流式

| 用户需求 | 选择模型 |
|----------|----------|
| 测试 TTFT/TPOT 等流式指标 | `vllm_api_stream_chat` |
| 只关心最终结果 | `vllm_api_general_chat` |

### 数据集类型

| 用户需求 | 选择数据集 |
|----------|------------|
| 精度测试 | 真实数据集 |
| 性能测试 + prefix_cache/MTP/EAGLE-3 | 真实数据集 |
| 需要固定输入/输出长度 | Synthetic |

如果用户没有明确说明测试场景，请主动询问以上信息。

---

## 数据集配置

| 数据集 | 配置名 | 用途 |
|--------|--------|------|
| C-Eval | ceval_gen_0_shot_cot_chat_prompt | 中文多选题 |
| GSM8K | gsm8k_gen_0_shot_cot_str_perf | 数学推理 |
| MMLU | mmlu_gen_0_shot_cot_chat_prompt | 多任务语言理解 |
| Math | math500_gen_0_shot_cot_chat_prompt | 数学 |
| ShareGPT | sharegpt_gen | 对话数据集 |
| Synthetic | synthetic_gen | 固定长度测试 |

> **提示**：数据集配置名可在 `<BENCHMARK_HOME>/ais_bench/benchmark/configs/datasets/` 查看

---

## 测试流程

### 真实数据集测试

#### 1. 下载数据集

查阅 `reference/ais_bench_docs.md` 中的"数据集下载"章节。

#### 2. 配置模型参数

编辑配置文件：
- 流式: `<BENCHMARK_HOME>/ais_bench/benchmark/configs/models/vllm_api/vllm_api_stream_chat.py`
- 非流式: `<BENCHMARK_HOME>/ais_bench/benchmark/configs/models/vllm_api/vllm_api_general_chat.py`

```python
models = [
    dict(
        attr="service",
        type=VLLMCustomAPIChatStream,  # 流式用这个
        # type=VLLMCustomAPIChat,      # 非流式用这个
        abbr='<model_abbr>',
        path="<model_path>",
        model="<model_name_in_vllm>",
        host_ip = "<host_ip>",
        host_port = <port>,
        max_out_len = <max_out_len>,
        trust_remote_code=True,
        generation_kwargs = dict(
            temperature = 0,
            repetition_penalty = 1.0,
        ),
    )
]
```

#### 3. 运行测试

```bash
cd $BENCHMARK_HOME

# 性能测试
ais_bench --models vllm_api_stream_chat --datasets <dataset_name> --mode perf --num-prompts <num_prompts>

# 推理+精度测试
ais_bench --models vllm_api_stream_chat --datasets <dataset_name> --mode all
```

---

### Synthetic 数据集测试

#### 1. 配置随机数据集参数

编辑 `<BENCHMARK_HOME>/ais_bench/datasets/synthetic/synthetic_config.py`：

```python
synthetic_config = {
    "Type": "string",
    "RequestCount": <num_requests>,
    "TrustRemoteCode": True,
    "StringConfig": {
        "Input": {
            "Method": "uniform",
            "Params": {"MinValue": <min_input>, "MaxValue": <max_input>}
        },
        "Output": {
            "Method": "uniform",
            "Params": {"MinValue": <min_output>, "MaxValue": <max_output>}
        }
    }
}
```

#### 2. 配置模型参数

编辑 `<BENCHMARK_HOME>/ais_bench/benchmark/configs/models/vllm_api/vllm_api_stream_chat.py`：

```python
models = [
    dict(
        attr="service",
        type=VLLMCustomAPIChatStream,
        abbr='<model_abbr>',
        path="<model_path>",
        model="<model_name_in_vllm>",
        host_ip = "<host_ip>",
        host_port = <port>,
        max_out_len = <max_out_len>,
        batch_size = <concurrency>,
        trust_remote_code=True,
        generation_kwargs = dict(
            temperature = 0,
            repetition_penalty = 1.0,
            ignore_eos = True,
        ),
    )
]
```

#### 3. 运行测试

```bash
cd $BENCHMARK_HOME
ais_bench --models vllm_api_stream_chat --datasets synthetic_gen --mode perf --num-prompts <num_prompts>
```

---

## 配置参数参考

### 模型配置必填字段

| 字段 | 说明 |
|------|------|
| `path` | 模型权重路径 |
| `model` | vLLM 中注册的模型名 |
| `host_ip` | vLLM 服务 IP |
| `host_port` | vLLM 服务端口 |
| `max_out_len` | 最大输出长度 |

### Synthetic 数据集参数

| 参数 | 说明 |
|------|------|
| `RequestCount` | 请求数量，并发测试时需 >= batch_size × 10 |
| `Input.Method` | 输入生成方式：uniform/gaussian/zipf |
| `Input.Params.MinValue/MaxValue` | 输入 token 长度范围 |
| `Output.Method` | 输出生成方式 |
| `Output.Params.MinValue/MaxValue` | 输出 token 长度范围 |

---

## 故障排除

遇到问题请查阅：`reference/faq.md`

对于参数详情和测试结果解读，查阅 `reference/ais_bench_docs.md`。
