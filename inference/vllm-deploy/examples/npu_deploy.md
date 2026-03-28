# NPU 设备指定部署

## 场景
在特定 NPU 设备上部署 vLLM 服务。

## 默认行为
- 默认使用 **NPU 0**
- 如果 NPU 0 被占用，部署会失败或性能下降

## 检查 NPU 占用情况

```bash
# 查看所有 NPU 设备列表
npu-smi info -l

# 查看特定 NPU 是否被占用（判断空闲的唯一方式）
npu-smi info -t proc-mem -i 0
# 输出 "No process in device." → NPU 空闲
# 输出 "Process id:xxx Process memory(MB):xxx" → NPU 被占用
```

## 指定 NPU 设备

### 方式一：环境变量指定（推荐）

```bash
# 指定使用 NPU 0
export ASCEND_RT_VISIBLE_DEVICES=0

# 指定使用 NPU 1
export ASCEND_RT_VISIBLE_DEVICES=1

# 指定使用多个 NPU（如 0,1）
export ASCEND_RT_VISIBLE_DEVICES=0,1
```

### 方式二：启动脚本指定

```bash
# 在 deploy.sh 中指定
export ASCEND_RT_VISIBLE_DEVICES=1
vllm serve <model_path> --host 0.0.0.0 --port 8000 &
```

## 自动选择可用 NPU

如果不确定哪个 NPU 可用，可以先检查再部署：

```bash
#!/bin/bash
# 自动选择空闲 NPU

for npu in {0..7}; do
    if npu-smi info -t proc-mem -i $npu | grep -q "No process in device"; then
        echo "找到空闲 NPU: $npu"
        export ASCEND_RT_VISIBLE_DEVICES=$npu
        break
    fi
done

echo "使用 ASCEND_RT_VISIBLE_DEVICES=$ASCEND_RT_VISIBLE_DEVICES"
```

## 多卡部署时的 NPU 指定

使用多卡（DP/TP/EP）时，需要指定连续的多个 NPU：

```bash
# 纯 TP（4 卡）：DP=1, TP=4
export ASCEND_RT_VISIBLE_DEVICES=0,1,2,3
vllm serve <model_path> --data-parallel-size 1 --tensor-parallel-size 4 &

# MoE EP 部署（4 卡）：EP=4，DP×TP=4
# 方案 1：DP=1, TP=4
export ASCEND_RT_VISIBLE_DEVICES=0,1,2,3
vllm serve <model_path> --data-parallel-size 1 --tensor-parallel-size 4 --enable-expert-parallel &

# 方案 2：DP=2, TP=2
export ASCEND_RT_VISIBLE_DEVICES=0,1,2,3
vllm serve <model_path> --data-parallel-size 2 --tensor-parallel-size 2 --enable-expert-parallel &
```

## 常见问题

| 问题 | 解决方案 |
|------|----------|
| 部署失败提示设备忙 | 使用 `ASCEND_RT_VISIBLE_DEVICES` 指定其他 NPU |
| 多卡部署卡住 | 确保指定的多个 NPU 都空闲 |
| 不确定 NPU 是否可用 | 先运行 `npu-smi info -l` 检查 |
