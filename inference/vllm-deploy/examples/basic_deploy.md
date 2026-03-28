# 基础部署示例

## 场景
使用默认配置快速部署 vLLM-Ascend 服务。

## 示例

```bash
# 使用 ModelScope 下载并部署 Qwen3-0.6B 模型
export VLLM_USE_MODELSCOPE=true
vllm serve Qwen/Qwen3-0.6B --host 0.0.0.0 --port 8000 &

# 等待 30 秒后验证
sleep 30
curl http://localhost:8000/v1/models
```

## 使用部署脚本

```bash
cd <skill-path>/scripts
bash deploy.sh Qwen/Qwen3-0.6B 8000
```

## 常见模型部署

| 模型 | 命令 |
|------|------|
| Qwen3-0.6B | `vllm serve Qwen/Qwen3-0.6B &` |
| Qwen2.5-0.5B | `vllm serve Qwen/Qwen2.5-0.5B-Instruct &` |
| Llama-3 | `vllm serve meta-llama/Meta-Llama-3-8B-Instruct &` |
| GLM-4 | `vllm serve THUDM/glm-4-9b-chat &` |

## 验证服务

```bash
# 查看模型列表
curl http://localhost:8000/v1/models

# 测试推理
curl http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "<model_name>",
    "prompt": "Hello, how are you?",
    "max_tokens": 20,
    "temperature": 0
  }'
```
