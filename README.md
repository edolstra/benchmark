# Benchmark

Tool for collecting statistics about the execution of a program

## Getting started

### Benchmarking a program

```bash
$ nix run github:edolstra/benchmark -- sleep 1

run 0...
# ...
run 9...
note: discarding 10% highest outliers
maximum RSS:        median =  10392.0000  mean =  10389.3333  stddev =      7.7460  min =  10372.0000  max =  10396.0000
soft page faults:   median =    211.0000  mean =    210.0000  stddev =      3.7081  min =    202.0000  max =    215.0000
system CPU time:    median =      0.0019  mean =      0.0015  stddev =      0.0007  min =      0.0000  max =      0.0021
user CPU time:      median =      0.0000  mean =      0.0002  stddev =      0.0004  min =      0.0000  max =      0.0009
elapsed time:       median =      1.0025  mean =      1.0027  stddev =      0.0006  min =      1.0022  max =      1.0041
```

### Analyzing the performance of different versions of a program

Let's collect and save the initial performance data.

We will be using 3 rounds (`-t 3`) this time:

```bash
$ nix run github:edolstra/benchmark -- -f ./previous-data -t 3 sleep 1

run 0...
run 1...
run 2...
note: discarding 10% highest outliers
maximum RSS:        median =  10516.0000  mean =  10516.0000  stddev =     11.3137  min =  10508.0000  max =  10524.0000
soft page faults:   median =    213.0000  mean =    213.0000  stddev =      2.8284  min =    211.0000  max =    215.0000
system CPU time:    median =      0.0008  mean =      0.0008  stddev =      0.0012  min =      0.0000  max =      0.0016
elapsed time:       median =      1.0022  mean =      1.0022  stddev =      0.0002  min =      1.0021  max =      1.0023
```

Now do the same, but save the data in another file
so that we can compare:

```bash
$ nix run github:edolstra/benchmark -- -f ./current-data -c ./previous-data -t 3 sleep 1

run 0...
run 1...
run 2...
note: discarding 10% highest outliers
maximum RSS:        median =  10312.0000  mean =  10312.0000  stddev =     11.3137  min =  10304.0000  max =  10320.0000  [rejected, p=0.00306, Δ=-204.00000±159.39884]
soft page faults:   median =    210.5000  mean =    210.5000  stddev =      0.7071  min =    210.0000  max =    211.0000  [not rejected, p=0.34906, Δ=-2.50000±29.04522]
user CPU time:      median =      0.0008  mean =      0.0008  stddev =      0.0011  min =      0.0000  max =      0.0015  [not rejected, p=0.42264, Δ=0.00076±0.01072]
elapsed time:       median =      1.0021  mean =      1.0021  stddev =      0.0000  min =      1.0021  max =      1.0021  [not rejected, p=0.36206, Δ=-0.00013±0.00156]
```

Rejected means that there is a statistical different
between `./current-data` and `./previous-data`.

You may want to run your benchmarks on a computer
that is not running other workloads than the program subject to analysis,
so that there is no noise introduced in the results.

Increasing the number of runs (`-t`) improves the stability of the results as well.
