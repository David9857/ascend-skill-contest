# AISBench Test Skill

使用 AISBench 对 vLLM-Ascend 进行性能测试的完整流程。

## 使用场景

当用户需要测试 vLLM-Ascend 服务的**性能或精度**时，使用此 Skill。

## ⚠️ 重要：查阅参考文档

> **重要提示**：`reference/ais_bench_docs.md` 中的内容整理自 AISBench 官方文档。对于不确定的内容，建议同时查阅原始官方文档获取最完整的信息。官方文档链接见参考文档首页。

> **原则**：不要基于假设或猜测行动。当你不确定某个参数的含义或某个功能的行为时，必须先查阅参考文档确认后再执行。

## ⚠️ 重要：确定测试场景

在开始测试前，必须先确认用户的测试场景。根据用户需求，自动选择合适的配置：

### 测试类型选择

请询问用户需要哪种测试类型。如果不确定各 mode 的区别，请查阅参考文档 `reference/ais_bench_docs.md` 中的"测试模式"章节。

### 数据集选择

| 用户需求 | 自动选择 |
|----------|----------|
| 精度测试 | 真实数据集 |
| 性能测试 + prefix_cache/MTP/EAGLE-3 | 真实数据集 |
| 需要固定输入/输出长度 | 随机数据集 (Synthetic) |

### 流式/非流式选择

| 用户需求 | 自动选择 |
|----------|----------|
| 测试 TTFT/TPOT 等流式指标 | 流式模式 (`vllm_api_stream_chat`) |
| 只关心最终结果 | 非流式模式 (`vllm_api_general_chat`) |

如果用户没有明确说明测试场景，请主动询问以上信息。

---

## 常用数据集

| 数据集 | 配置名 | 说明 |
|--------|--------|------|
| C-Eval | ceval_gen_0_shot_cot_chat_prompt | 中文多选题 |
| GSM8K | gsm8k_gen_0_shot_cot_str_perf | 数学推理 |
| MMLU | mmlu_gen_0_shot_cot_chat_prompt | 多任务语言理解 |
| Math | math500_gen_0_shot_cot_chat_prompt | 数学 |
| ShareGPT | sharegpt_gen | 对话数据集 |
| Synthetic | synthetic_gen | 随机数据（固定长度） |

> **注意**：数据集配置名可在 `<aisbench_install_path>/ais_bench/benchmark/configs/datasets/` 目录下查看 available 的数据集配置。

---

## 前置条件

### ⚠️ 需要用户提供的参数

以下参数需要在使用前询问用户：

| 参数 | 说明 | 示例 |
|------|------|------|
| `<host_ip>` | vLLM 服务所在服务器的 IP 地址 | localhost, 192.168.1.100 |
| `<port>` | vLLM 服务的端口号 | 8000, 8001, 8113 |
| `<model_path>` | 模型权重路径 | /home/weights/Qwen3-VL-30B |

> **注意**：`<model_name_in_vllm>` 可通过 `curl http://<host_ip>:<port>/v1/models` 查询，不需要用户提供。

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

## 真实数据集测试流程

### 1. 下载数据集

数据集下载方式请查阅参考文档 `reference/ais_bench_docs.md` 中的"数据集下载"章节。

### 2. 配置模型参数

> **⚠️ 重要：运行前先检查现有配置，确认必填字段**
>
> 以下字段需要确保有正确的值：
> - `<model_path>`
> - `<model_name_in_vllm>`
> - `<host_ip>`
> - `<port>`

编辑配置文件：
- 流式: `<aisbench_install_path>/ais_bench/benchmark/configs/models/vllm_api/vllm_api_stream_chat.py`
- 非流式: `<aisbench_install_path>/ais_bench/benchmark/configs/models/vllm_api/vllm_api_general_chat.py`

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

### 3. 运行测试

```bash
cd $BENCHMARK_HOME

# 性能测试
ais_bench \
  --models vllm_api_stream_chat \
  --datasets <dataset_name> \
  --mode perf \
  --num-prompts <num_prompts>

# 推理+精度测试
ais_bench \
  --models vllm_api_stream_chat \
  --datasets <dataset_name> \
  --mode all
```

---

## 随机数据集测试流程 (Synthetic)

### 1. 配置随机数据集参数

编辑 `<aisbench_install_path>/ais_bench/datasets/synthetic/synthetic_config.py`：

```python
synthetic_config = {
    "Type": "string",
    "RequestCount": <num_requests>,  # 并发测试时需 >= batch_size × 10
    "TrustRemoteCode": True,
    "StringConfig": {
        "Input": {
            "Method": "uniform",  # 支持 uniform/gaussian/zipf
            "Params": {"MinValue": <min_input>, "MaxValue": <max_input>}
        },
        "Output": {
            "Method": "uniform",
            "Params": {"MinValue": <min_output>, "MaxValue": <max_output>}
        }
    }
}
```

### 2. 配置模型参数（添加 ignore_eos）

> **⚠️ 重要：运行前先检查现有配置，确认必填字段**
>
> 以下字段需要确保有正确的值：
> - `<model_path>`
> - `<model_name_in_vllm>`
> - `<host_ip>`
> - `<port>`

编辑 `<aisbench_install_path>/ais_bench/benchmark/configs/models/vllm_api/vllm_api_stream_chat.py`：

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
        batch_size = <concurrency>,  # 并发测试时设置
        trust_remote_code=True,
        generation_kwargs = dict(
            temperature = 0,
            repetition_penalty = 1.0,
            ignore_eos = True,  # 关键：忽略 EOS，持续生成直到 max_out_len
        ),
    )
]
```

### 3. 运行测试

```bash
cd $BENCHMARK_HOME
ais_bench \
  --models vllm_api_stream_chat \
  --datasets synthetic_gen \
  --mode perf \
  --num-prompts <num_prompts>
```

---

## 更多参考

- **配置参数和变量说明**：请查阅参考文档 `reference/ais_bench_docs.md` 中的"关键配置文件位置"、"模型配置参数"、"文档变量说明"章节
- **测试结果解读**：请查阅参考文档 `reference/ais_bench_docs.md` 中的"测试结果解读"、"结果文件"章节

---

## 常见问题处理

遇到问题时请参考：`reference/faq.md`
