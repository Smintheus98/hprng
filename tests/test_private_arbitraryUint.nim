# ******************************************************************************
# Copyright (c) 2025, Yannic Kitten
#
# This project is licensed under BSD 3-Clause License.
# See the file "LICENSE", included in this distribution, for more details on
# licensing and copyright.
# ******************************************************************************

##
## hprng/tests - tests for private arbitraryUint type template
##
## This template can be used to enable some parts of uint-128-bit arithmetic,
## as for example required for LCGs jump procedure.
##

import std / unittest

include hprng/private/arbitraryUint

# exemplary uint2x8 is tested, especially, since it's the easiest type to check
makeArbitrary2xUint(uint2x8, uint8)
type
  U = uint8
  U2 = uint16

proc toU2(u: uint2x8): U2 =
  u.lo.U2 + (u.hi.U2 shl U.n_bits)

proc lo(u: U2): U2 =
  u and ((1.U2 shl (U2.n_bits div 2)) - 1)

proc divmodU2(a, b: U2): tuple[quotient, remainder: uint2x8] =
  ((a div b).uint2x8, (a mod b).uint2x8)


suite "Test uint2x8 arbitrary integer type":
  setup:
    let
      a16 = 62954'u16
      b16 = 38617'u16
      l16 = uint16.low
      h16 = uint16.high

      a = a16.uint2x8
      b = b16.uint2x8
      l = l16.uint2x8
      h = h16.uint2x8

  test "initialization":
    check:
      a.toU2 == a16
      b.toU2 == b16
      l.toU2 == l16
      h.toU2 == h16

  test "relations":
    check:
      a <  a + 1
      a <= a + 1 and a <= a
      a >  a - 1
      a >= a - 1 and a >= a
      a == a
      a != a + 1 and a != a - 1 and a != b
      not (a <  a - 1) and not (a <  a)
      not (a <= a - 1)
      not (a >  a + 1) and not (a >  a)
      not (a >= a + 1)
      not (a == a + 1) and not (a == a - 1) and not (a == b)
      not (a != a)

  test "shifting":
    for i in 0..<U2.n_bits:
      check a shl i == a16 shl i
      check a shr i == a16 shr i

  test "not/and/or/xor":
    check:
      not a     == not a16
      (a and b) == (a16 and b16)
      (a or  b) == (a16 or  b16)
      (a xor b) == (a16 xor b16)

  test "addition":
    check:
      a + 1 == a16 + 1
      a + b == a16 + b16
      a + not a == h
      h + 1 == l
      l + 1 == 1
    for i in 0..<U2.n_bits:
      check a + (a shl i) == a16 + (a16 shl i)
      check a + (a shr i) == a16 + (a16 shr i)

  test "substraction":
    check:
      a - 1 == a16 - 1
      a - b == a16 - b16
      b - a == b16 - a16
      a - a == l
      l - 1 == h
      h - 1 == h16 - 1
      h - (h - 1) == 1
    for i in 0..<U2.n_bits:
      check a - (a shl i) == a16 - (a16 shl i)
      check a - (a shr i) == a16 - (a16 shr i)

  test "low multiplication":
    check:
      extended_uint8_mul(a.lo, b.lo) == a16.lo * b16.lo
      lomul(a, b) == a16.lo * b16.lo
      lomul(b, a) == a16.lo * b16.lo
    for i in 0..<U2.n_bits:
      for j in 0..<U2.n_bits:
        check:
          lomul(a shl i, b shl j) == lo(a16 shl i) * lo(b16 shl j)
          lomul(a shl i, b shr j) == lo(a16 shl i) * lo(b16 shr j)
          lomul(a shr i, b shl j) == lo(a16 shr i) * lo(b16 shl j)
          lomul(a shr i, b shr j) == lo(a16 shr i) * lo(b16 shr j)

  test "full multiplication":
    check:
      a * b == a16 * b16
      a * b.lo == (a16 * b16.lo).uint2x8
      b * a == b16 * a16
    for i in 0..<U2.n_bits:
      for j in 0..<U2.n_bits:
        check:
          (a shl i) * (b shl j) == (a16 shl i) * (b16 shl j)
          (a shl i) * (b shr j) == (a16 shl i) * (b16 shr j)
          (a shr i) * (b shl j) == (a16 shr i) * (b16 shl j)
          (a shr i) * (b shr j) == (a16 shr i) * (b16 shr j)

  test "div(/)mod":
    check:
      divmod(a, b) == divmodU2(a16, b16)
      divmod(b, a) == divmodU2(b16, a16)
      a div b == a16 div b16 # only test calling conivention
      b div a == b16 div a16
      a mod b == a16 mod b16
      b mod a == b16 mod a16
    for i in 0..<U2.n_bits:
      for j in 0..<U2.n_bits:
        check:
          divmod(a shl i, b shl j) == divmodU2(a16 shl i, b16 shl j)
          divmod(a shl i, b shr j) == divmodU2(a16 shl i, b16 shr j)
          divmod(a shr i, b shl j) == divmodU2(a16 shr i, b16 shl j)
          divmod(a shr i, b shr j) == divmodU2(a16 shr i, b16 shr j)

