
import std / [strutils, sequtils]

type
  SimpleDataFrame*[T] = object
    variables: seq[string]
    data: seq[seq[T]]
  FloatDF* = SimpleDataFrame[float]

proc parsefloatdf*(fname: string; sep = " "; rownumbers = false): FloatDF =
  for line in fname.lines:
    if line.strip.startswith("#"):
      continue
    elif result.variables == @[]:
      result.variables = line.strip.split(sep)
      result.data = newSeqWith(result.variables.len, newSeq[float]())
    else:
      let linesegm = if rownumbers: line.strip.split(sep)[1..^1]
                     else:          line.strip.split(sep)
      for i, segm in linesegm:
        result.data[i].add segm.parseFloat

proc n_cols*(df: FloatDF): int =
  df.variables.len

proc n_rows*(df: FloatDF): int =
  if df.n_cols == 0 or df.data == @[]: 0 else: df.data[0].len

proc idx_of*(df: FloatDF; k: string): int =
  for i, v in df.variables:
    if v == k:
      return i

proc `[]`*(df: FloatDF; k: string): seq[float] = df.data[df.idx_of(k)]
proc `[]`*(df: var FloatDF; k: string): var seq[float] = df.data[df.idx_of(k)]
proc `[]=`*(df: var FloatDF; k: string; s: seq[float]) = df.data[df.idx_of(k)] = s

