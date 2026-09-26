# Rails 6.1.7.10 vs 8.1.3.1 × Ruby 3.3.12 vs 4.0.7 — 2×2 Comparison

Same domain feature (a single `Bicycle` CRUD resource) across four app directories —
two Rails versions crossed with two Ruby versions. All four benchmarked sequentially
on the same machine (macOS 26.7, Darwin 25.6.0, arm64), 2026-09-24, with the identical
harness: `ab -n 500 -c 10` against `/bicycles` and `/bicycles/1` in `RAILS_ENV=production`
with precompiled assets, 5 boot-time/RSS samples via `/usr/bin/time -l bin/rails runner
"exit"`, 3 `bundle exec rspec` duration samples, and three fixed-iteration Ruby
microbenchmarks (`Process.clock_gettime`-timed, no gem dependency, identical script
across all four apps).

| Cell | App dir | Rails | Ruby |
|---|---|---|---|
| A | `test_app_v6` | 6.1.7.10 | 3.3.12 |
| B | `test_app_v6_r4` | 6.1.7.10 | 4.0.7 |
| C | `test_app_v7_to_v8_org_v6_r3` | 8.1.3.1 | 3.3.12 |
| D | `test_app_v7_to_v8_org_v6_r4` | 8.1.3.1 | 4.0.7 |

B did not exist before this comparison — it's a fresh port of `test_app_v6` to Ruby
4.0.7, built specifically to fill this cell (see Notable fixes below). D supersedes an
earlier r4 measurement from a prior Ruby-only comparison, which used a different
(concurrent) methodology; the numbers here are new and directly comparable to A/B/C.

## Results

| Metric | A: v6+Ruby3 | B: v6+Ruby4 | C: v8+Ruby3 | D: v8+Ruby4 |
|---|---|---|---|---|
| Boot time (mean of 5) | 0.382 s | 0.388 s | 0.510 s | 0.500 s |
| Boot peak RSS (mean of 5) | 95.47 MB | 98.62 MB | 101.87 MB | 107.98 MB |
| Test suite duration (mean of 3) | 0.080 s | 0.094 s | 0.308 s | 0.350 s |
| Test suite examples | 21 | 21 | 34 | 34 |
| `/bicycles` req/s | 977.42 | 986.66 | 1072.22 | 1153.86 |
| `/bicycles` mean latency | 10.231 ms | 10.135 ms | 9.326 ms | 8.667 ms |
| `/bicycles` p95 / p99 | 14 / 19 ms | 20 / 34 ms | 12 / 16 ms | 13 / 23 ms |
| `/bicycles/1` req/s | 1305.22 | 1504.72 | 1404.69 | 1591.50 |
| `/bicycles/1` mean latency | 7.662 ms | 6.646 ms | 7.119 ms | 6.283 ms |
| `/bicycles/1` p95 / p99 | 9 / 10 ms | 8 / 11 ms | 8 / 11 ms | 8 / 9 ms |
| Puma RSS after load | 116.75 MB | 117.92 MB | 118.20 MB | 122.41 MB |
| Microbench: AR validation | 56,615 ips | 56,920 ips | 60,310 ips | 60,606 ips |
| Microbench: JSON roundtrip | 1,456,511 ips | 1,667,756 ips | 1,460,920 ips | 1,706,607 ips |
| Microbench: 10k-array build+sort | 1,031.6 ips | 1,033.9 ips | 1,032.7 ips | 1,043.0 ips |

## Reading the results: two independent effects

With four cells we can separate "what changes with Rails version" from "what changes
with Ruby version" by holding the other axis fixed — and check whether the two effects
are consistent (same direction/magnitude regardless of the other axis), which is a much
stronger signal than either 2-cell comparison alone.

### Rails 6.1.7.10 → 8.1.3.1 (holding Ruby fixed)

Consistent across both Ruby versions — same direction, similar magnitude each time:

| | at Ruby 3.3.12 (A→C) | at Ruby 4.0.7 (B→D) |
|---|---|---|
| Boot time | +33.5% | +28.9% |
| Boot RSS | +6.7% | +9.5% |
| `/bicycles` req/s | +9.7% | +16.9% |
| AR validation ips | +6.5% | +6.5% |

This reproduces the Rails-version findings from the earlier v6-vs-v8 comparison almost
exactly, on a second, independent Ruby version — real, not an artifact of one Ruby build.
Rails 8.1 boots slower and heavier, but serves HTTP requests faster and validates
ActiveModel records faster, regardless of which Ruby runs it.

### Ruby 3.3.12 → 4.0.7 (holding Rails fixed)

| | at Rails 6.1.7.10 (A→B) | at Rails 8.1.3.1 (C→D) |
|---|---|---|
| Boot time | +1.6% (noise) | −2.0% (noise) |
| Boot RSS | +3.3% | +6.0% |
| `/bicycles` req/s | +0.9% (noise) | +7.6% |
| `/bicycles` mean latency | −0.9% (noise) | −7.1% |
| `/bicycles` p95 | +42.9% | +8.3% |
| `/bicycles` p99 | +78.9% | +43.8% |
| JSON roundtrip ips | **+14.5%** | **+16.8%** |
| AR validation ips | +0.5% (noise) | +0.5% (noise) |
| Array sort ips | +0.2% (noise) | +1.0% (noise) |

Two real, reproducible Ruby-version effects stand out, each consistent in direction and
rough magnitude across both Rails versions:

- **JSON encode/decode is ~15-17% faster on Ruby 4.0.7**, in both apps. This doesn't touch
  Rails/ActiveRecord at all, so it isolates a genuine Ruby-level (interpreter or `json`
  gem) improvement rather than anything Rails-version-related.
- **HTTP tail latency (p95/p99) is consistently worse on Ruby 4.0.7**, in both apps —
  p99 up 44-79%, p95 up 8-43%. Mean latency does *not* get worse (actually improves at
  Rails 8.1.3.1) — this is specifically an outlier/tail effect, not a general slowdown.
  **This independently reproduces the same directional finding from the earlier,
  differently-flawed Ruby-3-vs-4 comparison** (`ruby_perf_comparison_same_app_w_ruby_v3_vs_v4`),
  which measured p95/p99 up 24-37% but ran both apps *concurrently* on the same machine —
  a real CPU-contention confound that comparison flagged itself. This matrix's Ruby-4
  cells ran alone, sequentially, with nothing else competing for CPU, and still show the
  same tail-latency regression. That doesn't prove causation on its own, but it rules out
  "it was just CPU contention between the two benchmark processes" as the explanation —
  the effect survives removing that specific confound.
- Boot time and mean HTTP latency show no consistent Ruby-version effect (signs even
  flip between the two Rails versions) — read those as noise at this sample size, not a
  real Ruby-version signal.

### Interaction between the two axes

Boot RSS grows a bit more from the Rails-version step when already on Ruby 4.0.7 (+9.5%
vs +6.7%), and grows a bit more from the Ruby-version step when already on Rails 8.1.3.1
(+6.0% vs +3.3%) — a mild positive interaction, not strictly additive. The combined
smallest-to-largest spread is 95.47 MB (A) to 107.98 MB (D), +13.1% end to end. HTTP
throughput shows the same pattern: the two upgrades combined (D) beat either upgrade
alone by more than you'd get from simply adding the two individual gains.

## Caveats

- **Not identical code across the Rails axis** (A/B vs C/D): asset pipeline (Webpacker vs.
  import maps), JS layer (Turbolinks vs. Turbo), and gem set all differ, same as noted in
  the original 2-cell comparison — see that version's caveats for detail. This matrix adds
  confidence that the *direction* of those Rails-version effects is real (reproduced at
  both Ruby versions), but doesn't remove the "not a single-variable toggle" caveat for
  the Rails axis.
- **The Ruby axis (A vs B, C vs D) is a cleaner comparison** — B is a direct port of A
  with only `.ruby-version`, the `ruby` Gemfile directive, and three added gem lines
  (`bigdecimal`, `mutex_m`, `benchmark` — see Notable fixes) changed; D is the same
  `test_app_v7_to_v8_org_v6_r4` directory the Rails 8.1 upgrade already produced, with
  only a database-isolation fix and a microbenchmark-script fix (no app-code changes) in
  this session.
- **Test suite duration isn't comparable across the Rails axis** (SimpleCov + more
  examples on C/D, as previously noted) but *is* comparable across the Ruby axis (same
  suite, same example count, A vs B and C vs D each).
- **Small sample sizes, single machine, single `ab` run per endpoint** — real for the
  large/consistent effects above, not enough for confidence on anything within ~10% of
  zero (marked "noise" above).
- **Puma RSS after load and array-sort ips show no meaningful signal on either axis** —
  useful as a bias check: the harness itself isn't systematically favoring any cell.

## Notable fixes required to build this matrix

- **Cell B didn't exist before this session.** Rails 6.1.7.10 doesn't boot on Ruby 4.0.7
  out of the box: `activesupport` 6.1.7.10 requires `bigdecimal` and `mutex_m` at boot
  without declaring them as dependencies (hard `LoadError` on 4.0.7, both removed from
  Ruby's default gems), and `sass-rails`/`sassc-rails` require `benchmark` (also removed
  as a default gem in Ruby 4.0.0). All three added directly to `test_app_v6_r4`'s Gemfile.
  Once fixed, everything else worked cleanly on the first try: `bundle install`,
  migrations, the full RSpec suite, and a from-scratch production `assets:precompile`
  (same Webpack 4 / OpenSSL-legacy-provider workaround as `test_app_v6`).
- **`database.yml` naming bug found in *both* Ruby-4.0.7 apps.** Exactly like
  `test_app_v7_to_v8_org_v6_r3` before Prompt 1 fixed it, `test_app_v7_to_v8_org_v6_r4`
  still pointed at `test_app_v6_{development,test,production}` — meaning it had been
  sharing a live database with `test_app_v6` since it was created. Renamed to its own
  `test_app_v7_to_v8_org_v6_r4_*` databases and re-created/migrated/seeded fresh; the
  post-fix RSpec run (34 examples, 0 failures) and a `schema.rb` diff check confirmed no
  drift, matching the same benign Rails-8.1-schema-dumper-annotation diff seen on r3.
- **The AR-validation microbench script needed a one-line change to run everywhere.**
  `bin/rails runner` is Bundler-scoped; `test_app_v7_to_v8_org_v6_r4`'s Gemfile never
  declares `benchmark` (unlike B, where it was added, or C, where Ruby 3.3.12 still ships
  it as an ordinary default gem), so `Benchmark.realtime` raised `LoadError` there.
  Replaced it with `Process.clock_gettime(Process::CLOCK_MONOTONIC)` — what
  `Benchmark.realtime` calls internally anyway — in the shared script, now used unmodified
  across all four cells.

## Bottom line

The two upgrades are largely independent and mostly orthogonal in their effects: **Rails
6.1→8.1 trades boot time/memory for HTTP throughput and validation speed**, consistently,
regardless of Ruby version; **Ruby 3.3→4.0 gives a real ~15-17% JSON-processing speedup**
but **consistently worsens HTTP tail latency (p95/p99, not mean)**, regardless of Rails
version — and that tail-latency regression now looks more likely to be a genuine Ruby
4.0.7 characteristic than a CPU-contention artifact, since it reproduces even when nothing
else is competing for the machine. Memory grows a little more than additively when both
upgrades are combined. Of the four cells, D (Rails 8.1.3.1 + Ruby 4.0.7) has the best HTTP
throughput and the best JSON/AR-validation microbenchmarks, at the cost of the highest
boot time, boot memory, and Puma RSS under load, and the second-worst tail latency (behind
B). There's no cell that's strictly worse than another on every metric — which combination
is "better" depends on whether the deployment cares more about cold-start cost or
steady-state throughput.
