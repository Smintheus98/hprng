
depend := ../src/hprng/lcg.nim ../src/hprng/philox.nim
sources := sequential_perf_bench.nim sequential_perf_bench_extended.nim
targets := bin/sequential_perf_bench bin/sequential_perf_bench_extended

all: $(targets) $(depend)

$(targets): bin/%: %.nim $(depend)
	nim c -d:release -d:useMalloc --mm:arc --outdir:bin $(CFLAGS) $<

clean:
	rm $(targets)

.PHONY: clean all
