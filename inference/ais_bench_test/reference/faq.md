# AISBench 常见问题处理

## 1. 数据集未找到

```
FileExistsError: Dataset path is not exist!
```

解决：下载对应的数据集到 `<aisbench_install_path>/ais_bench/datasets/` 目录。

## 2. 服务连接失败

```
ConnectionError: Failed to connect to vLLM service
```

解决：
1. 检查 vLLM 服务是否运行：`curl http://<host_ip>:<port>/v1/models`
2. 检查 host_ip 和 host_port 配置是否正确

## 3. 测试失败

查看详细日志：
```bash
<BENCHMARK_HOME>/outputs/default/<timestamp>/logs/performances/<model>/<dataset>.out
```
