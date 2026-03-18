# Skill 职责划分

## 概述

本文档说明 AISBench 相关 Skill 的职责划分，遵循单一职责原则。

## Skill 职责

| Skill | 职责 | 使用场景 |
|-------|------|---------|
| **ais_bench_test** | 基础测试能力 | 单次测试、配置模型、运行基础性能测试 |
| **performance_benchmarking** | 高级寻优能力 | 自动寻优最优并发、二分法搜索、性能对比 |

## 依赖关系

```
performance_benchmarking
    └── 依赖 ais_bench_test（作为基础能力）
```

**performance_benchmarking** 引用 **ais_bench_test** 作为基础测试工具，但 **ais_bench_test** 不引用其他 Skill，保持独立。

## 何时使用哪个 Skill

| 需求 | 推荐 Skill |
|------|-----------|
| 测试模型精度 | ais_bench_test |
| 测试单次性能 | ais_bench_test |
| 固定并发压测 | ais_bench_test |
| **寻优最优并发** | performance_benchmarking |
| 满足特定 TPOT/TTFT 约束的最优吞吐 | performance_benchmarking |

## 原则

1. **ais_bench_test**：提供原子化的基础能力，不依赖其他 Skill
2. **performance_benchmarking**：组合基础能力，提供高级流程（如二分法寻优）
3. 避免 Skill 之间相互引用形成循环依赖
