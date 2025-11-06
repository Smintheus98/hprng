# ******************************************************************************
# Copyright (c) 2025, Yannic Kitten
#
# This project is licensed under BSD 3-Clause License.
# See the file "LICENSE", included in this distribution, for more details on
# licensing and copyright.
# ******************************************************************************

##
## hprng/private - Arbitrary 2x Uint types
##
## This template constructs a new Uint type, based on an array of two half-size Uint types,
## effecively enabling 128-bit arithmetic in pure nim, as for example required for LCGs jump
## procedure.
##

import utils

template makeArbitrary2xUint*(arbuint: untyped; U: typedesc[SomeUnsignedInt]): untyped =
  # This template constructs an unsigned integer type consisting of an array of 2 `U`-type values.
  # This constraint mainly serves naming conventions and simplicity.

  type arbuint* = object
      data: array[2, U]

  converter `to arbuint`*(u: SomeUnsignedInt): arbuint =
    arbuint(data: [u.U, (u shr U.n_bits).U])

  converter toU*(u: arbuint): U =
    u.data[0]

  proc lo*(u: arbuint): U = u.data[0]
  proc lo*(u: var arbuint): var U = u.data[0]
  proc `lo=`*(u: var arbuint, val: U) = u.data[0] = val

  proc hi*(u: arbuint): U = u.data[1]
  proc hi*(u: var arbuint): var U = u.data[1]
  proc `hi=`*(u: var arbuint, val: U) = u.data[1] = val

  proc low*(u: typedesc[arbuint]): arbuint = arbuint(data: [U.low, U.low])
  proc low*(u: arbuint): arbuint = arbuint(data: [U.low, U.low])

  proc high*(u: typedesc[arbuint]): arbuint = arbuint(data: [U.high, U.high])
  proc high*(u: arbuint): arbuint = arbuint(data: [U.high, U.high])

  proc `<`*(a, b: arbuint): bool =
    a.hi < b.hi or (a.hi == b.hi and a.lo < b.lo)

  proc `<=`*(a, b: arbuint): bool =
    a < b or a == b

  proc `>`*(a, b: arbuint): bool =
    b < a

  proc `>=`*(a, b: arbuint): bool =
    b <= a

  proc `shl`*(u: arbuint; n: Natural): arbuint =
    if n == 0: return u
    if n >= arbuint.n_bits: return arbuint(data: [0, 0])
    result.hi =
      if n <= U.n_bits: (u.hi shl n) or (u.lo shr (U.n_bits - n))
                  else: (u.hi shl n) or (u.lo shl (n - U.n_bits))
    result.lo = u.lo shl n

  proc `shr`*(u: arbuint; n: Natural): arbuint =
    if n == 0: return u
    if n >= arbuint.n_bits: return arbuint(data: [0, 0])
    result.lo =
      if n <= U.n_bits: (u.lo shr n) or (u.hi shl (U.n_bits - n))
                  else: (u.lo shr n) or (u.hi shr (n - U.n_bits))
    result.hi = u.hi shr n

  proc `not`*(a: arbuint): arbuint =
    result.lo = not a.lo
    result.hi = not a.hi

  proc `and`*(a, b: arbuint): arbuint =
    result.lo = a.lo and b.lo
    result.hi = a.hi and b.hi

  proc `or`*(a, b: arbuint): arbuint =
    result.lo = a.lo or b.lo
    result.hi = a.hi or b.hi

  proc `xor`*(a, b: arbuint): arbuint =
    result.lo = a.lo xor b.lo
    result.hi = a.hi xor b.hi

  proc `+`*(a, b: arbuint): arbuint =
    result.lo = a.lo + b.lo
    let carry = if result.lo < a.lo: 1.U else: 0.U
    result.hi = a.hi + b.hi + carry

  proc `-`*(a, b: arbuint): arbuint =
    result.lo = a.lo - b.lo
    let carry = if result.lo > a.lo: 1.U else: 0.U
    result.hi = a.hi - b.hi - carry

  proc `extended U mul`*(a, b: U): arbuint =
    const
      halfBits = U.n_bits div 2
      mask_lo: U = (1.U shl halfBits) - 1
    let
      a_hi = a shr halfBits
      a_lo = a and mask_lo
      b_hi = b shr halfBits
      b_lo = b and mask_lo
      prod_hh = a_hi * b_hi
      prod_hl = a_hi * b_lo
      prod_lh = a_lo * b_hi
      prod_ll = a_lo * b_lo
      carry = ( (prod_hl and mask_lo) + (prod_lh and mask_lo) + (prod_ll shr halfBits) ) shr halfBits
    result.lo = prod_ll + (prod_hl shl halfBits) + (prod_lh shl halfBits)
    result.hi = prod_hh + (prod_hl shr halfBits) + (prod_lh shr halfBits) + carry

  proc lomul*(a, b: arbuint): arbuint =
    `extended U mul`(a.lo, b.lo)

  proc `*`*(a, b: arbuint): arbuint =
    let
      prod_hl_lo: U = a.hi * b.lo
      prod_lh_lo: U = a.lo * b.hi
    result = `extended U mul`(a.lo, b.lo)
    result.hi += prod_hl_lo + prod_lh_lo

  proc divmod*(a, b: arbuint): tuple[quotient: arbuint, remainder: arbuint] =
    assert b != 0
    for i in countdown(arbuint.n_bits - 1, 0):
      result.remainder = (result.remainder shl 1) or ((a shr i) and 1)
      if result.remainder >= b:
        result.remainder = result.remainder - b
        result.quotient = result.quotient or (1.arbuint shl i)

  proc `div`*(a, b: arbuint): arbuint =
    divmod(a, b).quotient

  proc `mod`*(a, b: arbuint): arbuint =
    divmod(a, b).remainder


makeArbitrary2xUint(uint2x64, uint64)
