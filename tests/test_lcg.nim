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

include hprng/lcg

suite "Test Minstd random generator":
  setup:
    type U = uint32
    var rng = initMinstd()

  test "Compare to ground truth (sampled from std-c++)":
    for line in "tests/cxx/groundtruth/minstd_rand.dat".lines:
      var gen_n: int
      for data in line.split(";"):
        if data.startswith("seed="):
          rng.seed(data[5..^1].parseUInt.U)
        elif data.startswith("jump="):
          rng.jump(data[5..^1].parseUInt)
        elif data.startswith("gen="):
          let numbers = data[4..^1].strip(chars={','}).split(",").mapIt(it.parseUInt.U)
          for i in 0..<numbers.len:
            check rng.next() == numbers[i]
        else:
          echo "ERROR: Ground truth data format likely invalid!"
          QuitFailure.quit

suite "Test Rand48 random generator":
  setup:
    type U = uint64
    var rng = initRand48()

  test "Compare to ground truth (sampled from std-c++)":
    for line in "tests/cxx/groundtruth/rand48.dat".lines:
      var gen_n: int
      for data in line.split(";"):
        if data.startswith("seed="):
          rng.seed(data[5..^1].parseUInt.U)
        elif data.startswith("jump="):
          rng.jump(data[5..^1].parseUInt)
        elif data.startswith("gen="):
          let numbers = data[4..^1].strip(chars={','}).split(",").mapIt(it.parseUInt.U)
          for i in 0..<numbers.len:
            check rng.next() == numbers[i]
        else:
          echo "ERROR: Ground truth data format likely invalid!"
          QuitFailure.quit

suite "Test Rand48r random generator":
  setup:
    type U = uint64
    var rng = initRand48r()

  test "Compare to ground truth (sampled from std-c++)":
    for line in "tests/cxx/groundtruth/rand48.dat".lines:
      var gen_n: int
      for data in line.split(";"):
        if data.startswith("seed="):
          rng.seed(data[5..^1].parseUInt.U)
        elif data.startswith("jump="):
          rng.jump(data[5..^1].parseUInt)
        elif data.startswith("gen="):
          let numbers = data[4..^1].strip(chars={','}).split(",").mapIt(it.parseUInt.U)
          for i in 0..<numbers.len:
            check rng.next() == numbers[i] shr 16
        else:
          echo "ERROR: Ground truth data format likely invalid!"
          QuitFailure.quit


suite "Extensive jump test for Rand48":
  setup:
    type
      U = uint64
    let seed = 1234567.U
    var rng_a = initRand48(seed)
    var rng_b = initRand48(seed)

  test "Jump 1":
    rng_a.jump(1)
    discard rng_b.next()
    check rng_a.next() == rng_b.next()

  test "Jump 2":
    rng_a.jump(2)
    discard rng_b.next()
    discard rng_b.next()
    check rng_a.next() == rng_b.next()

  test "Jump 3":
    rng_a.jump(3)
    discard rng_b.next()
    discard rng_b.next()
    discard rng_b.next()
    check rng_a.next() == rng_b.next()

  test "Jump 4":
    rng_a.jump(4)
    discard rng_b.next()
    discard rng_b.next()
    discard rng_b.next()
    discard rng_b.next()
    check rng_a.next() == rng_b.next()

  test "Jump 10000":
    rng_a.jump(10_000)
    for i in 0..<10_000:
      discard rng_b.next()
    check rng_a.next() == rng_b.next()

  test "Jump by modulus":
    rng_a.jump(1.U shl 48)
    check rng_a.next() == rng_b.next()

  test "Jump by modulus + 1":
    rng_a.jump(1.U shl 48 + 1)
    discard rng_b.next()
    check rng_a.next() == rng_b.next()

  test "Jump by modulus - 1":
    rng_a.jump(1.U shl 48 - 1)
    discard rng_a.next()
    check rng_a.next() == rng_b.next()

