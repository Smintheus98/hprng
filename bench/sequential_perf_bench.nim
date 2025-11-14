import std / [sequtils, strformat, sugar]
import benchutils / [parsedata, timemeasure, bootstat]

import std / random
import ../src/hprng / [philox, lcg]


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
]

let titles = [
  "Internal",
  "Philox2x32",
  "Philox2x64",
  "Philox4x32",
  "Philox4x64",
  "Minstd",
  "Rand48",
  "Rand48r",
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
    measure fmt"{title:<12}", ms, float:
      p_value = htest(X, Y, bootrep, rsmpl)
    if show_p_val: echo "p value:  ", p_value


when isMainModule:
  main()
