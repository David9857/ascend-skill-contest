---
name: vllm-deploy
description: 使用 vLLM 框架在华为昇腾 Ascend NPU 上部署大语言模型服务，或将模型部署为 OpenAI 兼容 API。触发场景：deploy vLLM, launch LLM inference, start model server, serve model on Ascend NPU, vLLM 部署, 启动推理服务, 模型服务化, OpenAI API.
version: 1.0.0
---

# vLLM Ascend 部署指南

使用 vLLM 框架在 Ascend NPU 上快速部署大语言模型推理服务。

## 快速开始

### 环境设置

在启动 vLLM 服务前，设置以下环境变量：

```bash
# 使用 ModelScope 加速模型下载（推荐）
export VLLM_USE_MODELSCOPE=true
```

### 启动服务

```bash
# 基本启动命令（默认端口 8000）
vllm serve <model_path> &

# 指定端口
vllm serve <model_path> --port <port> --host 0.0.0.0 &

# 带参数启动
vllm serve <model_path> --trust-remote-code --host 0.0.0.0 --port 8000 &
```

参数说明：
- `<model_path>`: 模型路径或 ModelScope 模型名（如 `Qwen/Qwen3-0.6B`）
- `--port`: 服务端口（默认 8000）
- `--host`: 监听地址（默认 0.0.0.0）
- `--trust-remote-code`: 是否信任远程代码（某些模型需要）

### 验证服务

服务启动后（约 30 秒），验证服务是否正常运行：

```bash
# 查看模型列表
curl http://localhost:8000/v1/models
```

### 测试推理

```bash
curl http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "<model_name>",
    "prompt": "Hello, how are you?",
    "max_tokens": 20,
    "temperature": 0
  }'
```

## 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `model_path` | - | 模型路径或 ModelScope 模型名（必填） |
| `--port` | 8000 | 服务端口 |
| `--host` | 0.0.0.0 | 监听地址 |
| `--trust-remote-code` | false | 是否信任远程代码 |
| `--tensor-parallel-size` | 1 | Tensor 并行度 |
| `--max-model-len` | 模型默认值 | 最大模型长度 |

## 常见模型示例

以下是在 Ascend NPU 上经过测试的模型：

| 模型 | 命令 | 说明 |
|------|------|------|
| Qwen3-0.6B | `vllm serve Qwen/Qwen3-0.6B &` | 基础模型 |
| Qwen2.5-0.5B | `vllm serve Qwen/Qwen2.5-0.5B-Instruct &` | 指令模型 |
| Llama-3 | `vllm serve meta-llama/Meta-Llama-3-8B-Instruct &` | Meta Llama |
| GLM-4 | `vllm serve THUDM/glm-4-9b-chat &` | 智谱 GLM |

更多模型支持请参考官方文档。

## 部署步骤

### Step 1: 确认环境

确保已在 Ascend NPU 环境中，可通过以下命令确认：

```bash
# 检查 NPU 设备
ls /dev/davinci*

# 检查 vLLM 安装
python -c "import vllm; print('vLLM installed')"
```

### Step 2: 设置环境变量

```bash
export VLLM_USE_MODELSCOPE=true
```

### Step 3: 启动服务

```bash
# 创建启动脚本
cat > deploy.sh << 'EOF'
export VLLM_USE_MODELSCOPE=true

vllm serve <model_path> \
  --host 0.0.0.0 \
  --port 8000 \
  --trust-remote-code &

echo "Waiting for service to start..."
sleep 30
EOF

# 执行脚本
bash deploy.sh &
```

### Step 4: 验证服务

```bash
# 等待服务启动后执行
curl http://localhost:8000/v1/models
```

### Step 5: 测试推理

```bash
curl http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "<model_name>",
    "prompt": "Write a short story.",
    "max_tokens": 100,
    "temperature": 0.7
  }'
```

## 停止服务

```bash
# 查找进程并停止
VLLM_PID=$(pgrep -f "vllm serve")
kill -2 "$VLLM_PID"
```

## 性能优化

当用户询问如何优化性能或内存时，主动推荐合适的特性。

### 常用特性一览

| 特性 | 作用 | 适用场景 |
|------|------|----------|
| **Graph Mode** | 图执行模式优化性能 | 默认启用，适合大多数场景 |
| **Quantization** | 模型量化减少内存/加速 | 内存受限、大模型部署 |
| **Weight Prefetch** | 权重预取优化延迟 | 高并发、高吞吐量 |
| **Layer Sharding** | 层权重分片减少内存 | 极深模型（61 层） |
| **KV Pool** | PD 分离 KV 缓存共享 | MLA 模型、PD 部署 |
| **External DP** | 外部数据并行+负载均衡 | 大规模跨节点部署 |
| **MTP** | 多 token 预测加速 | DeepSeek-V3 模型 |
| **Large-Scale EP** | 大规模专家并行 | 多节点 MoE 模型 |
| **EPLB** | MoE 专家负载均衡 | MoE 模型、高并发 |

### 场景推荐

根据用户需求推荐特性：

| 用户需求 | 推荐特性 |
|----------|----------|
| 内存受限、减少内存占用 | Quantization、Layer Sharding、KV Pool |
| 高吞吐量、高并发 | Weight Prefetch、EPLB、External DP |
| 多节点大规模部署 | Large-Scale EP、External DP |
| MoE 模型优化 | MTP、Large-Scale EP、EPLB |
| 单节点推理（默认） | Graph Mode（已默认启用） |

详细特性参数和使用示例请参考 `reference/features.md`。

## 故障排除

遇到问题时，请参考 `reference/troubleshooting.md` 获取详细的故障排除指南。

常见问题包括：
- 模型下载/加载失败
- 端口被占用
- 内存不足 (OOM)
- 服务启动失败
- 性能问题

## 参考资料

- vLLM Ascend 官方文档: https://vllm-ascend.readthedocs.io/
- 性能优化特性指南: `reference/features.md`
- 故障排除指南: `reference/troubleshooting.md`
- ModelScope 模型市场: https://www.modelscope.cn/models
- vLLM 项目: https://github.com/vllm-project/vllm
