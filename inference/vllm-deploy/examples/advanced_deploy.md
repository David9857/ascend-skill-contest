# 高级部署示例

## 场景 1：多卡并行部署

```bash
# Tensor 并行：使用 2 卡部署
vllm serve THUDM/glm-4-9b-chat \
  --tensor-parallel-size 2 \
  --host 0.0.0.0 \
  --port 8000 &
```

## 场景 2：自定义最大长度

```bash
# 设置 max_model_len 为 4096
vllm serve Qwen/Qwen3-0.6B \
  --max-model-len 4096 \
  --host 0.0.0.0 \
  --port 8000 &
```

## 场景 3：启用 trust_remote_code

```bash
# 某些模型需要 trust-remote-code
vllm serve <model_path> \
  --trust-remote-code \
  --host 0.0.0.0 \
  --port 8000 &
```

## 场景 4：PD 分离部署

```bash
# Prefill 节点
vllm serve <model_path> \
  --headless \
  --additional-config '{"role": "prefill"}' &

# Decode 节点
vllm serve <model_path> \
  --headless \
  --additional-config '{"role": "decode"}' &
```

## 场景 5：量化部署

```bash
# 使用 AWQ 量化
vllm serve <model_path> \
  --quantization awq \
  --host 0.0.0.0 \
  --port 8000 &
```

---

## 多卡部署：TP / DP / EP

### TP (Tensor Parallelism) - 张量并行

**原理**：将模型权重按张量维度切分到多个 NPU，单节点内并行计算。

```bash
# 使用 2 卡张量并行
vllm serve <model_path> \
  --tensor-parallel-size 2 \
  --host 0.0.0.0 --port 8000 &

# 使用 4 卡张量并行
vllm serve <model_path> \
  --tensor-parallel-size 4 \
  --host 0.0.0.0 --port 8000 &
```

**适用场景**：
- 单节点内大模型部署
- 模型参数量超过单卡显存

---

### DP (Data Parallelism) - 数据并行

**原理**：多个模型副本处理不同请求，横向扩展吞吐。

```bash
# 使用专用 DP 参数（单节点 4 副本）
vllm serve <model_path> \
  --data-parallel-size 4 \
  --host 0.0.0.0 --port 8000 &

# 多节点 DP
# 节点 0（master）
vllm serve <model_path> \
  --data-parallel-size 4 \
  --data-parallel-rank 0 \
  --data-parallel-address <master_ip> \
  --data-parallel-rpc-port 12345 &

# 节点 1
vllm serve <model_path> \
  --data-parallel-size 4 \
  --data-parallel-rank 1 \
  --data-parallel-address <master_ip> \
  --data-parallel-rpc-port 12345 &
```

**适用场景**：
- 高并发、低延迟需求
- 跨节点扩展

---

### EP (Expert Parallelism) - 专家并行

**原理**：MoE（Mixture of Experts）模型的专家层按专家维度切分到多个 NPU 上。
- **EP = 总卡数**（默认，专家切分到所有 NPU）
- **非专家层**：DP × TP = 总卡数（用满所有卡）

```bash
# 4 卡 MoE 部署：EP=4，非专家层 DP×TP=4
# 方案 1：DP=1, TP=4
export ASCEND_RT_VISIBLE_DEVICES=0,1,2,3
vllm serve <model_path> \
  --data-parallel-size 1 \
  --tensor-parallel-size 4 \
  --enable-expert-parallel \
  --host 0.0.0.0 --port 8000 &

# 方案 2：DP=2, TP=2
export ASCEND_RT_VISIBLE_DEVICES=0,1,2,3
vllm serve <model_path> \
  --data-parallel-size 2 \
  --tensor-parallel-size 2 \
  --enable-expert-parallel \
  --host 0.0.0.0 --port 8000 &

# 方案 3：DP=4, TP=1
export ASCEND_RT_VISIBLE_DEVICES=0,1,2,3
vllm serve <model_path> \
  --data-parallel-size 4 \
  --tensor-parallel-size 1 \
  --enable-expert-parallel \
  --host 0.0.0.0 --port 8000 &
```

**适用场景**：
- DeepSeek-V3 等 MoE 模型
- 多节点大规模部署

---

### 并行策略对比

| 策略 | 参数 | 说明 | 适用模型 |
|------|------|------|----------|
| TP | `--tensor-parallel-size` | 处理非专家层 | 所有模型 |
| DP | `--data-parallel-size` | 副本扩展 | 所有模型 |
| EP | `--enable-expert-parallel` | 处理专家层 | MoE 模型 |

---

## 性能优化特性组合

| 需求 | 配置 |
|------|------|
| 高吞吐量 | `--additional-config '{"weight_prefetch": true}'` |
| 低延迟 | `--additional-config '{"graph_mode": true}'` |
| 大模型（内存受限） | `--quantization fp8 --tensor-parallel-size 2` |

详细特性参数请参考 `reference/features.md`。
