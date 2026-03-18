---
name: performance-benchmarking
description: 使用 AISBench 自动寻找满足时延要求的最优并发配置。触发场景：用户需要测试推理服务性能并找到最优吞吐、在满足 TTFT/TPOT 条件下进行压测、对 vLLM-Ascend 进行性能寻优。确保在用户提及"最优并发"、"性能寻优"、"压测"、"找出最大吞吐"时主动使用此 Skill。
---

# Performance Benchmarking

使用 AISBench 进行推理服务化性能测试，自动寻优最优并发配置。

## 快速开始

1. **确认测试需求**：与服务 IP、端口、TTFT/TPOT 要求
2. **配置环境**：复用 ais_bench_test skill 配置模型和数据集
3. **运行寻优**：二分法自动搜索最优并发，生成测试报告

> **前置条件**：确保已加载 `ais_bench_test` skill

---

## 使用场景

当用户需要进行推理服务性能测试，并希望找到满足时延要求的最优吞吐时，使用此 Skill。

典型场景：
- "测试 xxx 服务的性能"
- "在满足 TTFT < 2s, TPOT < 50ms 情况下，找出最优吞吐"
- "对推理服务进行压测，找出最大吞吐"

---

## 测试需求确认

与用户确认以下信息：

| 信息 | 说明 | 默认值 |
|------|------|--------|
| 服务 IP | vLLM 服务所在服务器 IP | - |
| 服务端口 | vLLM 服务端口 | - |
| 测试数据集 | Synthetic 或真实数据集 | Synthetic |
| 输入长度 | 输入 token 数 | 1024 |
| 输出长度 | 输出 token 数 | 1024 |
| TTFT 要求 | 首个 token 延迟要求 | 2000ms |
| TPOT 要求 | 每 token 延迟要求 | 50ms |

---

## 环境配置

此步骤复用 `ais_bench_test` skill：

1. **设置环境变量**：`export BENCHMARK_HOME=<aisbench_install_path>`
2. **配置模型参数**：参考 ais_bench_test 中的"配置模型参数"步骤
3. **配置 Synthetic 数据集**：参考 ais_bench_test 中的"Synthetic 数据集测试"配置

> **注意**：确保 `RequestCount >= 最大测试并发 × 10`

---

## 自动寻优流程

### Step 1: 二分法寻优

使用二分法自动寻找满足时延要求的最优并发：

```bash
# 例如测试 batch_size=32，需要 num-prompts=320
ais_bench --models vllm_api_stream_chat --datasets synthetic_gen --mode perf --num-prompts 320
```

循环测试直到找到满足 TTFT/TPOT 要求的最大并发。

### Step 2: 最终测试

使用最优并发执行完整测试：

```bash
# 最优 batch_size=16，需要 num-prompts=160+
ais_bench --models vllm_api_stream_chat --datasets synthetic_gen --mode perf --num-prompts 160
```

### Step 3: 结果分析

解析测试结果，提取关键指标：

| 指标 | 说明 |
|------|------|
| E2EL | 端到端延迟 |
| TTFT | 首个 token 时间 |
| TPOT | 每 token 时间 |
| Concurrency | 实际平均并发数 |
| Output Token Throughput | 输出 token 吞吐 |
| Total Token Throughput | 总 token 吞吐 |

> **⚠️ 重要**：检查 **Concurrency** 是否接近 **batch_size**
> - 如果 `Concurrency < batch_size × 0.9`，说明并发没有打满
> - 检查 `RequestCount` 和 `--num-prompts` 是否足够

---

## 配置规则

| 规则 | 要求 |
|------|------|
| 请求数规则 | `--num-prompts >= batch_size × 10` |
| RequestCount 规则 | `synthetic_config.RequestCount >= 最大并发 × 10` |
| 并发验证 | `Concurrency >= batch_size × 0.9` |

### 最小请求数参考

| batch_size | 最小 num-prompts |
|------------|-----------------|
| 16 | 160 |
| 32 | 320 |
| 64 | 640 |

---

## 错误处理

详见 `ais_bench_test` skill 的故障排除章节。

常见问题：
- **服务连接失败**：检查 `curl http://<host_ip>:<port>/v1/models`
- **时延不满足**：降低时延要求或检查模型性能瓶颈

---

## 参考

- ais_bench_test skill：基础测试流程
- reference/ais_bench_docs.md：配置参数说明
