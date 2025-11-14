import std / [sequtils, strformat]
import benchutils / [parsedata, timemeasure, bootstat]

import std / random
import ../src/hprng / [philox, lcg]
import pkg / random / [mersenne, xorshift]
import pkg / splitmix64
import pkg / sitmo
import pkg / librng


# *** RNG setup ***
var
  internal = initRand() 
  p2x32 = initPhilox2x32_10(internal.next())
  p2x64 = initPhilox2x64_10(internal.next())
  p4x32 = initPhilox4x32_10(internal.next())
  p4x64 = initPhilox4x64_10(internal.next())
  minstd = initMinstd(internal.next())
  rand48 = initRand48(internal.next())
  rand48r = initRand48r(internal.next())
  rndmt = initMersenneTwister(internal.next().uint32)
  rndx128p = initXorshift128Plus(internal.next().uint64)
  rndx1024s = initXorshift1024Star(internal.next().uint64)
  splitmix = Splitmix64(x: internal.next())
  pkgsitmo = newsitmo(internal.next().uint32)
  lrnglcg = newRNG(algo = LCG)
  lrngpcg = newRNG(algo = PCG)
  lrngsm = newRNG(algo = Splitmix64)
  lrngmt = newRNG(algo = MersenneTwister)
  lrngx128 = newRNG(algo = Xoroshiro128)
  lrngx128pp = newRNG(algo = Xoroshiro128PlusPlus)
  lrngx128ss = newRNG(algo = Xoroshiro128StarStar)

type pkgrandomRNG = MersenneTwister|Xorshift128Plus|Xorshift1024Star
proc next(rng: var pkgrandomRNG): uint32 = rng.randomInt(uint32)
proc next(rng: var sitmo): uint32 = rng.random
type pkglibrngRNG = librng.RNG
proc next(rng: var pkglibrngRNG): uint = cast[uint](rng.randint())


# *** The resample procs and titles ***

let resampler = [
  float_resample_lambda(internal),
  float_resample_lambda(p2x32),
  float_resample_lambda(p2x64),
  float_resample_lambda(p4x32),
  float_resample_lambda(p4x64),
  float_resample_lambda(minstd),
  float_resample_lambda(rand48),
  float_resample_lambda(rand48r),
  float_resample_lambda(rndmt),
  float_resample_lambda(rndx128p),
  float_resample_lambda(rndx1024s),
  float_resample_lambda(splitmix),
  float_resample_lambda(pkgsitmo),
  float_resample_lambda(lrnglcg),
  float_resample_lambda(lrngpcg),
  float_resample_lambda(lrngsm),
  float_resample_lambda(lrngmt),
  float_resample_lambda(lrngx128),
  float_resample_lambda(lrngx128pp),
  float_resample_lambda(lrngx128ss),
]

let titles = [
  "Internal (std/random)",
  "Philox2x32 (hprng)",
  "Philox2x64 (hprng)",
  "Philox4x32 (hprng)",
  "Philox4x64 (hprng)",
  "Minstd (hprng)",
  "Rand48 (hprng)",
  "Rand48r (hprng)",
  "MersenneTwister (pkg/random)",
  "Xorshift128+ (pkg/random)",
  "Xorshift1024* (pkg/random)",
  "Splitmix64 (pkg/splitmix64)",
  "Sitmo (pkg/sitmo)",
  "LCG (pkg/librng)",
  "PCG (pkg/librng)",
  "Splitmix (pkg/librng)",
  "MersenneTwister (pkg/librng)",
  "Xoroshiro128 (pkg/librng)",
  "Xoroshiro128++ (pkg/librng)",
  "Xoroshiro128** (pkg/librng)",
]


proc main() =
  let htest = pv_two_sample_test_equal_mean
  let
    offset = 2100
    n = 8000
    bootrep = 20000
    df = parsefloatdf("./data/two-sample-test.dat")
    X = df["X"][offset..<offset+n]
    Y = df["Y"][offset..<offset+n]
    show_p_val = false

  var p_value: float

  for (title, rsmpl) in zip(titles, resampler):
    measure fmt"{title:<32}", ms, float:
      p_value = htest(X, Y, bootrep, rsmpl)
    if show_p_val: echo "p value:  ", p_value


when isMainModule:
  main()
