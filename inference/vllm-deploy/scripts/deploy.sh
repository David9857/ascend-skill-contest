#!/bin/bash
#
# vLLM Ascend 部署脚本
# 用法: ./deploy.sh <model_path> [port]
#

set -e

# 默认值
MODEL_PATH="${1:-Qwen/Qwen3-0.6B}"
PORT="${2:-8000}"
HOST="0.0.0.0"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== vLLM Ascend 部署脚本 ===${NC}"
echo "模型: $MODEL_PATH"
echo "端口: $PORT"

# 检查环境变量
export VLLM_USE_MODELSCOPE=true
export PYTORCH_NPU_ALLOC_CONF=expandable_segments:True

echo -e "${YELLOW}正在启动 vLLM 服务...${NC}"

# 启动 vLLM 服务
vllm serve "$MODEL_PATH" \
  --host "$HOST" \
  --port "$PORT" \
  --trust-remote-code &

VLLM_PID=$!
echo "vLLM 进程 PID: $VLLM_PID"

# 等待服务启动
echo -e "${YELLOW}等待服务启动（约 30 秒）...${NC}"
sleep 30

# 验证服务
if curl -s http://localhost:$PORT/v1/models > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 服务启动成功!${NC}"
    echo ""
    echo "服务地址: http://localhost:$PORT"
    echo "模型列表: http://localhost:$PORT/v1/models"
    echo ""
    echo "停止服务: kill -2 $VLLM_PID"
else
    echo -e "${RED}✗ 服务启动失败，请检查日志${NC}"
    exit 1
fi
