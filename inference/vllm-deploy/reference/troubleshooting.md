# vLLM Ascend 故障排除指南

本文档提供 vLLM 在 Ascend NPU 上部署时常见问题的解决方案。

## 目录

- [环境检查](#环境检查)
- [模型相关问题](#模型相关问题)
- [网络与端口问题](#网络与端口问题)
- [内存问题](#内存问题)
- [服务启动问题](#服务启动问题)
- [性能问题](#性能问题)

---

## 环境检查

### 检查 NPU 设备

```bash
# 确认 NPU 设备存在
ls -la /dev/davinci*

# 查看 NPU 设备信息
npu-smi info -l
```

**常见问题**: 如果 `/dev/davinci*` 不存在，检查 Ascend 驱动是否正确安装。

### 检查 vLLM 安装

```bash
# 检查 vLLM 是否安装
python -c "import vllm; print('vLLM installed')"

# 检查 vLLM 版本
pip show vllm

# 检查 vllm-ascend 插件
pip show vllm-ascend
```

**常见问题**: 如果导入失败，检查 PYTHONPATH 或尝试重新安装。

### 检查环境变量

```bash
# 确认关键环境变量
echo $VLLM_USE_MODELSCOPE
echo $ASCEND_RT_VISIBLE_DEVICES
```

---

## 模型相关问题

### 模型下载失败

**症状**: 启动时提示模型下载失败

**解决方案**:

```bash
# 方案1: 使用 ModelScope
export VLLM_USE_MODELSCOPE=true

# 方案2: 使用 HuggingFace 镜像
# 设置 HF_ENDPOINT 环境变量

# 方案3: 手动下载模型后指定本地路径
vllm serve /path/to/local/model &
```

### 模型加载失败

**症状**: 服务启动但模型加载失败

**解决方案**:

```bash
# 添加 --trust-remote-code 参数
vllm serve <model_path> --trust-remote-code &

# 检查模型路径是否正确
ls -la <model_path>
```

### 不支持的模型

**症状**: 提示模型不受支持

**解决方案**:

参考官方支持的模型列表:
- 查看 vLLM Ascend 官方快速入门文档
- 访问 https://docs.vllm.ai/en/latest/models/supported_models.html

---

## 网络与端口问题

### 端口被占用

**症状**: 提示端口已被占用

```bash
# 查看端口占用情况
lsof -i :8000
netstat -tlnp | grep 8000

# 方案1: 使用其他端口
vllm serve <model_path> --port 8001 &

# 方案2: 杀掉占用端口的进程
kill -9 <PID>
```

### 无法访问服务

**症状**: curl 请求超时或连接拒绝

```bash
# 检查服务是否启动
ps aux | grep "vllm serve"

# 检查端口监听
ss -tlnp | grep <port>

# 检查防火墙
# 临时关闭防火墙（测试用）
systemctl stop firewalld
# 或
iptables -F
```

---

## 内存问题

### 内存不足 (OOM)

**症状**: 服务启动时崩溃，提示内存不足

**解决方案**:

```bash
# 方案1: 减少批处理大小
vllm serve <model_path> --max-num-batched-tokens 2048 &

# 方案2: 减少最大模型长度
vllm serve <model_path> --max-model-len 4096 &

# 方案3: 减少 GPU 内存利用率
vllm serve <model_path> --gpu-memory-utilization 0.8 &

# 方案4: 使用量化模型
# 部署 INT4/INT8 量化版本
```

### 内存碎片

**症状**: 运行一段时间后内存不足

**解决方案**:

```bash
# 设置内存分配优化
export PYTORCH_NPU_ALLOC_CONF=expandable_segments:True
```

---

## 服务启动问题

### 服务启动失败

**症状**: 服务启动后立即退出

**解决方案**:

```bash
# 查看详细日志
# 前台运行查看输出
vllm serve <model_path> --host 0.0.0.0 --port 8000

# 或查看系统日志
journalctl -u vllm -f

# 检查错误日志
dmesg | grep -i npu
```

### vllm 命令找不到

**症状**: 提示 vllm 命令不存在

```bash
# 方案1: 检查 vLLM 安装
which vllm

# 方案2: 使用 python 模块方式
python -m vllm serve <model_path> &

# 方案3: 重新安装
pip install vllm
```

### 循环导入错误

**症状**: 提示 `ModuleNotFoundError` 或循环依赖

**解决方案**:

```bash
# 方案1: 在特定目录执行
cd <your-project-path>
bash deploy.sh &

# 方案2: 设置 PYTHONPATH
export PYTHONPATH=/vllm-workspace/vllm:$PYTHONPATH
```

---

## 性能问题

### TPOT 过高

**症状**: 每 token 输出时间过长

**解决方案**:

```bash
# 方案1: 减少并发数
# 修改启动脚本中的 batch_size

# 方案2: 启用 PagedAttention（默认开启）
# 确保未使用 --disable-paged-attention

# 方案3: 启用 Tensor 并行
vllm serve <model_path> --tensor-parallel-size 2 &
```

### TTFT 过长

**症状**: 首个 token 生成时间过长

**解决方案**:

```bash
# 方案1: 启用 prefix caching
vllm serve <model_path> --enable-prefix-caching &

# 方案2: 减少 max-model-len
vllm serve <model_path> --max-model-len 8192 &
```

### 服务响应慢

**症状**: API 响应时间过长

**解决方案**:

```bash
# 方案1: 检查并发请求数
# 调整 --max-num-seqs

# 方案2: 启用 async 调度
vllm serve <model_path> --async-scheduling &

# 方案3: 检查 NPU 利用率
npu-smi info
```

---

## 日志分析

### 查看 vLLM 日志

```bash
# 实时查看日志
tail -f /var/log/vllm.log

# 或使用 journalctl
journalctl -u vllm -f

# 查看特定级别日志
# DEBUG: 详细日志
# INFO: 一般信息
# WARNING: 警告
# ERROR: 错误
```

### 常见日志错误

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `CUDA out of memory` | GPU 内存不足 | 减少 batch size |
| `Connection refused` | 服务未启动 | 检查服务状态 |
| `Model not found` | 模型路径错误 | 检查模型路径 |
| `Permission denied` | 权限不足 | 使用 sudo |

---

## 获取帮助

如果以上方案无法解决问题:

1. 查看官方文档: https://vllm-ascend.readthedocs.io/
2. 访问 vLLM 社区: https://discuss.vllm.ai
3. 提交 Issue: https://github.com/vllm-project/vllm/issues
4. 查看 Ascend 相关: https://github.com/vllm-project/vllm-ascend
