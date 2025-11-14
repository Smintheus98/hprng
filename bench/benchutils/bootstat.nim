import std / [math, stats, sugar]

proc two_sample_mean_stat(x, y: openArray[float]): float =
  let n = x.len
  abs(mean(x) - mean(y)) / sqrt( (x.varianceS + y.varianceS) / n.float )

proc pv_two_sample_test_equal_mean*(x, y: seq[float]; bootrep = 2000, resample: seq[float] -> seq[float]): float =
  let
    n = x.len
    xy = x & y
    tn = two_sample_mean_stat(x, y)
  var p_value = 0
  for _ in 0..<bootrep:
    let xy_boot = xy.resample
    if two_sample_mean_stat(xy_boot[0..<n], xy_boot[n..<2*n]) >= tn:
      p_value.inc
  p_value.float / bootrep.float


proc resample*[T, RNG](a: seq[T]; rng: var RNG): seq[T] =
  let N = a.len
  result = newSeqOfCap[float](N)
  for i in 0..<N:
    result.add a[rng.next().uint mod N.uint]

template make_resample*(name: untyped): untyped =
  proc `resample name`[T](a: seq[T]): seq[T] = resample(a, name)

template float_resample_lambda*(name: untyped): untyped =
  (a: seq[float]) => resample(a, name)


