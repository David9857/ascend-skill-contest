# vLLM Ascend 特性指南

本文档介绍 vLLM Ascend 支持的性能优化特性。详细开关参数和使用示例请参考官方文档。

## 特性一览表

| 特性 | 作用 | 适用场景 |
|------|------|----------|
| **Graph Mode** | Ascend 图执行模式优化推理性能 | 默认启用，适合大多数场景 |
| **Quantization** | 模型量化减少内存/加速推理 | 内存受限、大模型部署 |
| **KV Pool** | PD 分离架构 KV 缓存共享 | PD 分离部署、MLA 模型 |
| **Weight Prefetch** | 权重预取到 L2 缓存优化延迟 | 高并发、高吞吐量 |
| **External DP** | 外部数据并行+负载均衡 | 大规模跨节点部署 |
| **MTP** | 多 token 预测加速推理 | DeepSeek-V3 模型 |
| **Layer Sharding** | 层权重分片减少内存 | 极深模型（61 层） |
| **Large-Scale EP** | 大规模专家并行+分布式 DP | 多节点 MoE 模型 |
| **EPLB** | MoE 专家负载均衡 | MoE 模型、高并发 |

---

## 1. Graph Mode（图模式）

### 作用
Ascend 图执行模式，通过将模型计算编译为图来优化推理性能。默认启用。

### 使用场景
- 需要更高推理性能的场景
- 详细参数请参考：`docs/source/user_guide/feature_guide/graph_mode.md`

---

## 2. Quantization（量化）

### 作用
通过降低权重和激活的数值精度来减少模型大小和计算开销，节省内存并提高推理速度。

### 使用场景
- 内存受限的环境
- 大模型部署
- 需要提高推理速度
- 详细参数请参考：`docs/source/user_guide/feature_guide/quantization.md`

---

## 3. KV Pool（KV 缓存池）

### 作用
实现 Prefill-Decode（PD）分离架构中的 KV 缓存共享，支持 Prefill 节点和 Decode 节点之间高效传输 KV 缓存。

### 使用场景
- PD 分离部署架构
- 需要分离 Prefill 和 Decode 节点
- 长上下文场景下的缓存共享
- 详细参数请参考：`docs/source/user_guide/feature_guide/kv_pool.md`

---

## 4. Weight Prefetch（权重预取）

### 作用
将权重预加载到 L2 缓存，减少模型执行过程中内存访问造成的延迟。创建独立的预取流水线，与向量计算并行运行。

### 使用场景
- 高并发场景（`--max-num-seqs` 较大）
- 追求高吞吐量而非低延迟
- 详细参数请参考：`docs/source/user_guide/feature_guide/weight_prefetch.md`

---

## 5. External DP（外部数据并行）

### 作用
将数据并行 rank 的编排和负载均衡交给外部处理，支持跨节点数据并行和请求长度感知的负载均衡。

### 使用场景
- 大规模部署
- 跨节点数据并行
- 需要外部负载均衡
- 详细参数请参考：`docs/source/user_guide/feature_guide/external_dp.md`

---

## 6. MTP（多 Token 预测）

### 作用
通过并行预测多个 token 提升推理性能。

### 使用场景
- 支持 MTP 的模型（如 DeepSeek-V3、GLM-5 等）
- 需要降低推理延迟
- 需要提升推理吞吐量
- 详细参数请参考：`docs/source/user_guide/feature_guide/Multi_Token_Prediction.md`

---

## 7. Layer Sharding（层分片）

### 作用
将多层共享相同结构的线性算子权重分片到多个 NPU 设备，减少内存压力。

### 使用场景
- 使用 FlashComm2 时
- 使用 DSA-CP 时
- 极深架构（61 层，如 DeepSeek-V3/R1）
- 详细参数请参考：`docs/source/user_guide/feature_guide/layer_sharding.md`

---

## 8. Large-Scale EP（大规模专家并行）

### 作用
支持大规模 Expert Parallelism 场景下的 PD 分离部署，使用分布式 DP 服务器实现多节点协调。

### 使用场景
- 大规模 MoE 模型（DeepSeek-R1 等）
- 多节点部署
- PD 分离架构
- 详细参数请参考：`docs/source/user_guide/feature_guide/large_scale_ep.md`

---

## 9. EPLB（专家负载均衡）

### 作用
为 MoE 模型提供专家负载均衡，通过异步零开销的专家移动，动态平衡专家负载以提高吞吐量。

### 使用场景
- MoE 模型（DeepSeek-V3/R1、Qwen3-MoE）
- 高并发推理
- 详细参数请参考：`docs/source/user_guide/feature_guide/eplb_swift_balancer.md`

---

## 特性推荐

根据不同需求选择合适的特性：

| 需求场景 | 推荐特性 |
|----------|----------|
| **内存受限** | Quantization、Layer Sharding |
| **性能提升** | KV Pool、Weight Prefetch、EPLB、Graph Mode |
| **多节点部署** | Large-Scale EP、External DP |
| **MoE 模型** | MTP、Large-Scale EP、EPLB |

---

## 参考文档

详细开关参数和使用示例请参考以下官方文档：

- 官方文档 - 快速入门: https://vllm-ascend.readthedocs.io/
- `docs/source/user_guide/feature_guide/` 目录下的各个特性文档
