# Performance Benchmarking

使用 AISBench 进行推理服务化性能测试，自动寻优最优并发配置。

## 使用场景

当用户需要进行推理服务性能测试，并希望找到满足时延要求的最优吞吐时，使用此 Skill。

典型场景：
- "测试 xxx 服务的性能"
- "在满足 TTFT < 2s, TPOT < 50ms 情况下，找出最优吞吐"
- "对推理服务进行压测，找出最大吞吐"

## ⚠️ 前置条件

此 Skill 依赖 `ais_bench_test` skill 进行基础测试操作。确保 Agent 已加载该 skill。

## 交互流程

### Step 1: 与用户确认测试需求

必须与用户确认以下信息：

| 信息 | 说明 | 示例 |
|------|------|------|
| 服务 IP | vLLM 服务所在服务器 IP | localhost, 192.168.1.100 |
| 服务端口 | vLLM 服务端口 | 8000, 8001, 8113 |
| 测试数据集 | Synthetic 或真实数据集 | Synthetic |
| 输入长度 | 输入 token 数 | 1024 |
| 输出长度 | 输出 token 数 | 1024 |
| TTFT 要求 | 首个 token 延迟要求 | < 2000ms |
| TPOT 要求 | 每 token 延迟要求 | < 50ms |

如果用户未指定，使用默认值：
- 输入：1024
- 输出：1024
- TTFT：2000ms
- TPOT：50ms

### Step 2: 配置测试环境

1. 设置环境变量：
   ```bash
   export BENCHMARK_HOME=<aisbench_install_path>
   ```

2. 使用 ais_bench_test skill 配置模型参数：
   - 参考 ais_bench_test 中的"配置模型参数"步骤
   - 确保 `<host_ip>`、`<port>`、`<model_path>` 正确

3. 配置 Synthetic 数据集参数：
   ```bash
   # 编辑 synthetic_config.py
   "StringConfig": {
       "Input": {"Method": "uniform", "Params": {"MinValue": <input_len>, "MaxValue": <input_len>}},
       "Output": {"Method": "uniform", "Params": {"MinValue": <output_len>, "MaxValue": <output_len>}}
   }
   ```

### Step 3: 自动寻优（二分法）

使用二分法自动寻找满足时延要求的最优并发：

```python
def optimize_concurrency(target_ttft, target_tpot, max_concurrency=64):
    """
    二分法寻优：找到满足时延要求的最优并发

    Args:
        target_ttft: 目标 TTFT (ms)
        target_tpot: 目标 TPOT (ms)
        max_concurrency: 最大并发数

    Returns:
        (best_concurrency, best_result): 最优并发和测试结果
    """
    low, high = 1, max_concurrency
    best_concurrency = 1
    best_throughput = 0
    best_result = None

    while low <= high:
        mid = (low + high) // 2
        print(f"测试并发: {mid}")

        # 执行测试（使用 ais_bench_test skill）
        result = run_ais_bench(concurrency=mid)

        if result.ttft <= target_ttft and result.tpot <= target_tpot:
            # 时延满足要求，记录结果并尝试更高并发
            best_concurrency = mid
            best_throughput = result.throughput
            best_result = result
            low = mid + 1
        else:
            # 时延不满足，降低并发
            high = mid - 1

    return best_concurrency, best_result
```

**执行寻优**（num-prompts = batch_size × 10）：
```bash
cd $BENCHMARK_HOME
# 例如测试 batch_size=32，需要 num-prompts=320
ais_bench --models vllm_api_stream_chat --datasets synthetic_gen --mode perf --num-prompts 320
```

### Step 4: 执行最终测试

使用最优并发执行完整测试（请求数 = 最优 batch_size × 10）：

```bash
# 例如最优 batch_size=16，需要 num-prompts=160+
ais_bench --models vllm_api_stream_chat --datasets synthetic_gen --mode perf --num-prompts 160
```

### Step 5: 结果分析

解析测试结果，提取关键指标：

| 指标 | 说明 |
|------|------|
| E2EL | 端到端延迟 |
| TTFT | 首个 token 时间 |
| TPOT | 每 token 时间 |
| Concurrency | 实际平均并发数 |
| Output Token Throughput | 输出 token 吞吐 |
| Total Token Throughput | 总 token 吞吐 |

> **⚠️ 重要：检查实际并发是否符合预期**
>
> 测试结果中的 **Concurrency**（实际平均并发）应该接近 **batch_size**（配置并发）。
>
> 如果 **Concurrency 远小于 batch_size**，需要检查：
> 1. **数据集条数**：检查 synthetic_config.py 中的 `RequestCount` 是否 >= `batch_size`
> 2. **请求数量**：检查命令行的 `--num-prompts` 是否 >= `batch_size`
> 3. **vLLM 配置**：检查 vLLM 启动脚本中的 `--max-num-seqs` 是否 >= `batch_size`
>
> 例如：如果 batch_size=256，但 Concurrency=10，说明并发没有真正生效，需要增加 RequestCount 和 num_prompts。

生成测试报告，包含：
- 最优并发配置
- 满足要求的性能指标
- 吞吐量分析

## 错误处理

### 服务连接失败

```
ConnectionError: Failed to connect to vLLM service
```

解决：
1. 检查服务是否运行：`curl http://<host_ip>:<port>/v1/models`
2. 确认 IP 和端口正确

### 测试失败

```
ValueError: Tokenizer path does not exist
```

解决：
1. 检查模型配置文件中的 `path` 字段
2. 确保路径指向正确的模型权重目录

### 时延始终不满足

如果无论并发多少都无法满足时延要求：
1. 降低时延要求，与用户确认
2. 检查模型性能是否存在瓶颈

## ⚠️ 关键配置规则（必须遵守）

### 规则 1：请求数规则
**`--num-prompts` 必须 >= `batch_size × 10`**

这是确保实际并发能打满配置值的关键。如果请求数不足，实际并发会远小于 batch_size。

| batch_size | 最小 num-prompts |
|------------|-----------------|
| 16 | 160 |
| 32 | 320 |
| 64 | 640 |

### 规则 2：数据集 RequestCount
**`synthetic_config.RequestCount` 必须 >= 最大测试并发 × 10**

例如：最大测试并发=64 → RequestCount >= 640

### 规则 3：验证实际并发
每次测试后，检查测试结果中的 **Concurrency** 是否接近 **batch_size**：
- 如果 `Concurrency < batch_size × 0.9`，说明并发没有打满
- 需要增加 num-prompts 或检查其他配置

## 注意事项

1. **假设 Agent 已加载 ais_bench_test skill**：基础配置操作复用该 skill
2. **Synthetic 数据集**：推荐用于快速测试，避免下载数据集的时间开销
3. **并发范围**：默认 1-64，可根据实际情况调整
4. **请求数量**：必须遵循规则 1（batch_size × 10），而不是固定数量

## 参考

- ais_bench_test skill：基础测试流程
- reference/ais_bench_docs.md：配置参数说明
