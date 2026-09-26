# Ruby 3.3.12 vs Ruby 4.0.7 — Rails 8.1.3.1 A/B Comparison

Same Rails 8.1.3.1 app (single `Bicycle` CRUD resource, RSpec, Puma), identical
code and gem versions in both directories — only the Ruby version differs.

- `r3` = `test_app_v7_to_v8_org_v6_r3`, Ruby 3.3.12
- `r4` = `test_app_v7_to_v8_org_v6_r4`, Ruby 4.0.7
- Both benchmarked concurrently on the same machine (macOS 26.7, Darwin 25.6.0, arm64), 2026-09-24 ~18:10 UTC.

## Results

| Metric | r3 (3.3.12) | r4 (4.0.7) | Δ (r4 − r3) | % change | Faster/lower |
|---|---|---|---|---|---|
| Boot time (mean of 5) | 0.336 s | 0.318 s | −0.018 s | −5.4% | r4 |
| Boot peak RSS (mean of 5) | 86.34 MB | 92.32 MB | +5.98 MB | +6.9% | r3 |
| Test suite duration (mean of 3) | 1.120 s | 1.063 s | −0.057 s | −5.1% | r4 |
| HTTP `/bicycles` req/s | 391.66 | 374.71 | −16.95 | −4.3% | r3 |
| HTTP `/bicycles` mean latency | 25.53 ms | 26.69 ms | +1.16 ms | +4.5% | r3 |
| HTTP `/bicycles` p95 | 29 ms | 37 ms | +8 ms | +27.6% | r3 |
| HTTP `/bicycles` p99 | 40 ms | 42 ms | +2 ms | +5.0% | r3 |
| HTTP `/bicycles/1` req/s | 452.62 | 421.15 | −31.47 | −7.0% | r3 |
| HTTP `/bicycles/1` mean latency | 22.09 ms | 23.75 ms | +1.65 ms | +7.5% | r3 |
| HTTP `/bicycles/1` p95 | 25 ms | 31 ms | +6 ms | +24.0% | r3 |
| HTTP `/bicycles/1` p99 | 27 ms | 37 ms | +10 ms | +37.0% | r3 |
| Puma RSS after load | 107.45 MB | 126.02 MB | +18.56 MB | +17.3% | r3 |
| Microbench: AR validation | 61,386 ips | 61,262 ips | −124 | −0.2% | no meaningful difference |
| Microbench: JSON roundtrip | 2,541,064 ips | 2,805,049 ips | +263,985 | +10.4% | r4 |
| Microbench: 10k-array sort | 673.8 ips | 648.1 ips | −25.7 | −3.8% | no meaningful difference |

## Reading the results

- **No meaningful difference** (within ~10% noise band, single-machine/low-sample-size): boot time, test suite duration, AR validation microbench, array-sort microbench, and JSON-roundtrip microbench. These sit close enough to each other, with only 3–5 samples on a tiny demo app, that ordinary run-to-run variance (disk cache state, JIT/interpreter warmup, background OS activity) is a fully sufficient explanation — no version-driven conclusion should be drawn.
- **Consistent, larger differences worth flagging directly**:
  - **Boot RSS**: r4's 5 samples (92.2–92.5 MB) never overlap r3's 5 samples (85.5–86.6 MB) — a repeatable ~7% higher baseline memory footprint on Ruby 4.0.7 for this app.
  - **Puma RSS after load**: r4 is 17% higher (126 MB vs 107 MB), consistent with the higher boot RSS carrying through under request load.
  - **HTTP tail latency (p95/p99)**: r4 is 24–37% higher on both endpoints, and throughput is 4–7% lower. This is the most notable performance-relevant signal in the whole run.

## Caveats

- **Both apps were benchmarked concurrently on the same machine**, competing for CPU during the HTTP load tests. This is a real confound: it could inflate both apps' latency roughly equally, but it could also asymmetrically favor whichever process happened to get scheduled first/more — the HTTP numbers above should be treated as directional, not authoritative, until re-run sequentially (or on isolated hardware).
- **Sample sizes are small** (5 boot-time samples, 3 test-suite runs, one `ab` run of 500 requests per endpoint) — not enough for a real statistical test. Treat every row as a point estimate with meaningful spread, not a precise number.
- **Micro-benchmark methodology differs slightly between runs**: Ruby 4.0 removed `benchmark` from its default gems, so the r4 agent used `Process.clock_gettime(CLOCK_MONOTONIC)` instead of `Benchmark.realtime` (which itself wraps `clock_gettime`) to avoid modifying the Gemfile. Functionally equivalent, but worth noting as a real Ruby 3→4 compatibility change in its own right — any app still calling `require "benchmark"` without declaring it as a gem will break on Ruby 4.0.
- This is a **tiny demo app** (one model, no background jobs, no cache pressure) — it does not exercise the workloads (GC pressure, large object graphs, concurrency) where Ruby version differences are most likely to show up. These results characterize this specific CRUD app's boot/request path, not Ruby 4.0.7 in general.

## Bottom line

On this small app, Ruby 4.0.7 boots marginally faster and matches Ruby 3.3.12 on CPU-bound micro-benchmarks and test-suite speed, but consistently uses ~7–17% more memory and shows noticeably worse HTTP tail latency (p95/p99 up 24–37%) under load — though that HTTP result is weakened by both apps having been benchmarked at the same time on shared hardware. Nothing here indicates a regression severe enough to block a Ruby 4.0.7 upgrade for a workload like this, but the memory and tail-latency deltas are consistent enough (not just noise) to be worth re-checking with an isolated, larger-scale load test before trusting them for a production capacity decision.
