# ******************************************************************************
# Copyright (c) 2025, Yannic Kitten
#
# This project is licensed under BSD 3-Clause License.
# See the file "LICENSE", included in this distribution, for more details on
# licensing and copyright.
# ******************************************************************************

##
## hprng/tests - tests for philox random number generator
##
## For validation of the output the original C++ implementation of Random123 has been used.
## See: https://random123.com/ and https://github.com/DEShawResearch/random123
##

import std / unittest
import std / [strutils, strformat, sequtils]

include hprng/philox

proc toarray[N: static[int], U: SomeUnsignedInt](o: openArray[U]): array[N, U] =
  try:
    for i in 0..<o.len: # this might crash (by intention) if the input data is longer than expected (thus invalid)
      result[i] = o[i]
  except IndexDefect:
    echo "Error during array conversion. Data too long!"
    QuitFailure.quit


suite "Test of Philox2x32_10 random number generator":
  setup:
    type U = uint32
    const
      ctrlen = 2
      keylen = 1
    let
      toctrarray = toarray[ctrlen, U]
      tokeyarray = toarray[keylen, U]
    var rng = initPhilox2x32_10()

  test "Compare to ground truth (sampled from Random123)":
    for line in "tests/cxx/groundtruth/philox2x32.dat".lines:
      var gen_n: int
      for data in line.split(";"):
        if data.startswith("ctr="):
          let values = data[4..^1].split(",").mapIt(it.parseUInt.U).toctrarray
          rng.counter(values)
        elif data.startswith("key="):
          let values = data[4..^1].split(",").mapIt(it.parseUInt.U).tokeyarray
          rng.key(values)
        elif data.startswith("jump="):
          rng.jump(data[5..^1].parseUInt)
        elif data.startswith("gen="):
          let numbers = data[4..^1].strip(chars={','}).split(",").mapIt(it.parseUInt.U)
          for i in 0..<numbers.len:
            check rng.next() == numbers[i]
        else:
          echo "ERROR: Ground truth data format likely invalid!"
          QuitFailure.quit


suite "Test of Philox2x64_10 random number generator":
  setup:
    type U = uint64
    const
      ctrlen = 2
      keylen = 1
    let
      toctrarray = toarray[ctrlen, U]
      tokeyarray = toarray[keylen, U]
    var rng = initPhilox2x64_10()

  test "Compare to ground truth (sampled from Random123)":
    for line in "tests/cxx/groundtruth/philox2x64.dat".lines:
      var gen_n: int
      for data in line.split(";"):
        if data.startswith("ctr="):
          let values = data[4..^1].split(",").mapIt(it.parseUInt.U).toctrarray
          rng.counter(values)
        elif data.startswith("key="):
          let values = data[4..^1].split(",").mapIt(it.parseUInt.U).tokeyarray
          rng.key(values)
        elif data.startswith("jump="):
          rng.jump(data[5..^1].parseUInt)
        elif data.startswith("gen="):
          let numbers = data[4..^1].strip(chars={','}).split(",").mapIt(it.parseUInt.U)
          for i in 0..<numbers.len:
            check rng.next() == numbers[i]
        else:
          echo "ERROR: Ground truth data format likely invalid!"
          QuitFailure.quit


suite "Test of Philox4x32_10 random number generator":
  setup:
    type U = uint32
    const
      ctrlen = 4
      keylen = 2
    let
      toctrarray = toarray[ctrlen, U]
      tokeyarray = toarray[keylen, U]
    var rng = initPhilox4x32_10()

  test "Compare to ground truth (sampled from Random123)":
    for line in "tests/cxx/groundtruth/philox4x32.dat".lines:
      var gen_n: int
      for data in line.split(";"):
        if data.startswith("ctr="):
          let values = data[4..^1].split(",").mapIt(it.parseUInt.U).toctrarray
          rng.counter(values)
        elif data.startswith("key="):
          let values = data[4..^1].split(",").mapIt(it.parseUInt.U).tokeyarray
          rng.key(values)
        elif data.startswith("jump="):
          rng.jump(data[5..^1].parseUInt)
        elif data.startswith("gen="):
          let numbers = data[4..^1].strip(chars={','}).split(",").mapIt(it.parseUInt.U)
          for i in 0..<numbers.len:
            check rng.next() == numbers[i]
        else:
          echo "ERROR: Ground truth data format likely invalid!"
          QuitFailure.quit


suite "Test of Philox4x64_10 random number generator":
  setup:
    type U = uint64
    const
      ctrlen = 4
      keylen = 2
    let
      toctrarray = toarray[ctrlen, U]
      tokeyarray = toarray[keylen, U]
    var rng = initPhilox4x64_10()

  test "Compare to ground truth (sampled from Random123)":
    for line in "tests/cxx/groundtruth/philox4x64.dat".lines:
      var gen_n: int
      for data in line.split(";"):
        if data.startswith("ctr="):
          let values = data[4..^1].split(",").mapIt(it.parseUInt.U).toctrarray
          rng.counter(values)
        elif data.startswith("key="):
          let values = data[4..^1].split(",").mapIt(it.parseUInt.U).tokeyarray
          rng.key(values)
        elif data.startswith("jump="):
          rng.jump(data[5..^1].parseUInt)
        elif data.startswith("gen="):
          let numbers = data[4..^1].strip(chars={','}).split(",").mapIt(it.parseUInt.U)
          for i in 0..<numbers.len:
            check rng.next() == numbers[i]
        else:
          echo "ERROR: Ground truth data format likely invalid!"
          QuitFailure.quit



suite "Counter increment edge-cases for Philox4x32_10":
  setup:
    type U = uint32
    const
      ctrlen = 4
      keylen = 2
    let
      toctrarray = toarray[ctrlen, U]
      tokeyarray = toarray[keylen, U]
    var rng = initPhilox4x32_10()
    rng.key([0.U, 0.U])
    rng.counter([0.U, 0.U, 0.U, 0.U])

  test "Overflow increment using next()":
    rng.counter([U.high, 0.U, 0.U, 0.U])
    for i in 0..<ctrlen:
      discard rng.next()
    check rng.counter == [U.high, 0.U, 0.U, 0.U]
    check rng.output_it == ctrlen
    discard rng.next()
    check rng.counter == [0.U, 1.U, 0.U, 0.U]
    check rng.output_it == 1

  test "Overflow increment using jump()":
    rng.counter([U.high, 0.U, 0.U, 0.U])
    rng.jump(ctrlen)
    check rng.counter == [0.U, 1.U, 0.U, 0.U]
    check rng.output_it == 0

  test "Full overflow increment using next()":
    rng.counter([U.high, U.high, U.high, U.high])
    for i in 0..<ctrlen:
      discard rng.next()
    check rng.counter == [U.high, U.high, U.high, U.high]
    check rng.output_it == ctrlen
    discard rng.next()
    check rng.counter == [0.U, 0.U, 0.U, 0.U]
    check rng.output_it == 1

  test "Full overflow increment using jump()":
    rng.counter([U.high, U.high, U.high, U.high])
    rng.jump(ctrlen)
    check rng.counter == [0.U, 0.U, 0.U, 0.U]
    check rng.output_it == 0


suite "Extensive jump test for Philox4x32_10":
  setup:
    type
      U = uint32
      U2 = uint64
    const
      ctrlen = 4
      keylen = 2
    let
      toctrarray = toarray[ctrlen, U]
      tokeyarray = toarray[keylen, U]
    var rng = initPhilox4x32_10()
    rng.key([0.U, 0.U])
    rng.counter([0.U, 0.U, 0.U, 0.U])

  test "Jump 1":
    rng.jump(1)
    check rng.counter == [0.U, 0.U, 0.U, 0.U]
    check rng.output_it == 1

  test "Jump ctrlen-1":
    rng.jump(ctrlen.pred)
    check rng.counter == [0.U, 0.U, 0.U, 0.U]
    check rng.output_it == ctrlen.pred.uint8

  test "Jump ctrlen":
    rng.jump(ctrlen)
    check rng.counter == [1.U, 0.U, 0.U, 0.U]
    check rng.output_it == 0

  test "Jump ctrlen+1":
    rng.jump(ctrlen.succ)
    check rng.counter == [1.U, 0.U, 0.U, 0.U]
    check rng.output_it == 1

  test "Jump 2*ctrlen":
    rng.jump(2*ctrlen)
    check rng.counter == [2.U, 0.U, 0.U, 0.U]
    check rng.output_it == 0

  test "Jump 1 from offset 1":
    rng.offset(1)
    rng.jump(1)
    check rng.counter == [0.U, 0.U, 0.U, 0.U]
    check rng.output_it == 2

  test "Jump ctrlen-1 from offset 1":
    rng.offset(1)
    rng.jump(ctrlen.pred)
    check rng.counter == [1.U, 0.U, 0.U, 0.U]
    check rng.output_it == 0

  test "Jump ctrlen from offset 1":
    rng.offset(1)
    rng.jump(ctrlen)
    check rng.counter == [1.U, 0.U, 0.U, 0.U]
    check rng.output_it == 1

  test "Jump ctrlen+1 from offset 1":
    rng.offset(1)
    rng.jump(ctrlen.succ)
    check rng.counter == [1.U, 0.U, 0.U, 0.U]
    check rng.output_it == 2

  test "Jump 2*ctrlen from offset 1":
    rng.offset(1)
    rng.jump(2*ctrlen)
    check rng.counter == [2.U, 0.U, 0.U, 0.U]
    check rng.output_it == 1

  test "Jump U.high from 0":
    rng.jump(U.high)
    check rng.counter == [U.high div ctrlen, 0.U, 0.U, 0.U]
    check rng.output_it == ctrlen.pred.uint8

  test "Jump U.high from U.high":
    rng.counter([U.high, 0.U, 0.U, 0.U])
    rng.jump(U.high)
    check rng.counter == [U.high + (U.high div ctrlen), 1.U, 0.U, 0.U]
    check rng.output_it == ctrlen.pred.uint8

  test "Jump U2.high from 0":
    rng.jump(U2.high)
    check rng.counter == [U.high, U.high div ctrlen, 0.U, 0.U]
    check rng.output_it == ctrlen.pred.uint8

  test "Jump U2.high from U.high":
    rng.counter([U.high, 0.U, 0.U, 0.U])
    rng.jump(U2.high)
    check rng.counter == [U.high - 1, U.high div ctrlen + 1, 0.U, 0.U]
    check rng.output_it == ctrlen.pred.uint8

