# ******************************************************************************
# Copyright (c) 2025, Yannic Kitten
#
# This project is licensed under BSD 3-Clause License.
# See the file "LICENSE", included in this distribution, for more details on
# licensing and copyright.
# ******************************************************************************

##
## hprng - Linear Congruential Generator (LCG) random number generator family
##
## The classic Linear Congruential Generator is formally defined using the following recurrence:
## .. math::
##    x_{n+1} = (a * x_n + c) \mod m
## with parameters a, c and m, also called multiplier, increment and modulus.
##
## Starting with an initial seed :math:`x_0`, this formula delivers a new pseudo-random number
## :math:`x_{n+1}` on each iteration.
##

import std / [options, sequtils, sugar, algorithm]
import pkg / bigints
import private / [utils, arbitraryUint]

template makeLinearCongruentialGenerator*(
      rngTypeName: untyped;
      U: typedesc[SomeUnsignedInt];
      U2: typedesc[SomeUnsignedInt | object];
      multiplier, increment, modulus: static[U];
      jump_widths: openArray[U];
      modulus_is_power_of_2 = false;
      bit_range = range[0..0]
      ): untyped =
  ## Template factory to generate LCG generators.
  ## If the `modulus_is_power_of_2` flag is set, the `modulus` parameter is interpretet as the
  ## coresponding exponent instead of the actual modulus.
  ## This opens some opportunities to optimize the calculations.
  # Inject/gensym pragmas are used explicitly here for clarification!

  # ***** Static parameter validation *****
  static:
    # if modulus is exponent, m should not exceed Us number of bits
    assert not modulus_is_power_of_2 or modulus <= U.n_bits
    # bit_range has to stay within Us bit count
    assert bit_range.low >= 0  and bit_range.low < U.n_bits
    assert bit_range.high >= 0 and bit_range.high < U.n_bits
    # jump_widths has to be sorted correctly!
    assert jump_widths == jump_widths.sorted(SortOrder.Descending)

  # ***** Constructed type *****
  type rngTypeName* {.inject.} = object
    ## LCG generator type.
    state: U

  # ***** Internal values and procedures *****
  const use_range_trunc {.gensym.} = (bit_range isnot range[0..0])

  when use_range_trunc:
    const bit_range_len {.gensym.} = bit_range.high - bit_range.low + 1
    proc trunc(x: U): U {.gensym, inline.} =
      ## Truncate value according to `bit_range`.
      (x shr bit_range.low) and ( (1.U shl bit_range_len) - 1 )

  proc modulo_op[T: U|U2](x: T): U {.gensym, inline.} =
    ## Optimized modulo operation.
    when modulus_is_power_of_2 and modulus == U.n_bits:
      return x.U
    elif modulus_is_power_of_2 and modulus < U.n_bits:
      return (x and ((1.T shl modulus) - 1)).U
    else:
      return (x mod modulus).U

  #[ # already slightly optimized version
  proc modpow(b, e, m: U; m_is_power_of_2 = false): U {.gensym.} =
    # TODO: likely optimizable
    if m == 1: return 0
    let mulOverflowsU = not m_is_power_of_2 and (((m - 1).U2 * (m - 1).U2) shr U.n_bits).U > 0
    result = 1
    var
      b = b mod m
      e = e
    while e > 0:
      if e.mod2 == 1:
        if mulOverflowsU: result = (mul(result, b) mod m.U2).U
        else:             result = (result * b) mod m
      e = e.div2
      b = (b * b) mod m
  ]#

  proc calc_jump_multiplier(jmp_wds: openArray[U]): seq[U] {.gensym.} =
    const m = if modulus_is_power_of_2: 1.initBigint shl modulus
              else: modulus.initBigint
    for jwd in jmp_wds:
      result.add powmod(multiplier.initBigint, jwd.initBigint, m).toInt[:U].get

  proc calc_jump_increment(jmp_wds: openArray[U]): seq[U] {.gensym.} =
    when increment == 0:
      return
    const m = if modulus_is_power_of_2: 1.initBigint shl modulus
              else: modulus.initBigint
    const m2 = m * multiplier.initBigInt
    for jwd in jmp_wds:
      let
        nomin = powmod(multiplier.initBigint, jwd.initBigint, m2)
        fract = nomin div (multiplier - 1).initBigint
        jincr = (increment.initBigint * fract) mod m
      result.add jincr.toInt[:U].get

  const
    jump_multiplier = calc_jump_multiplier(jump_widths)
    jump_increment = calc_jump_increment(jump_widths)


  # ***** Exported procedures *****
  proc state*(rng: var rngTypeName; state: U) {.inject.} =
    ## State setter.
    ## The state is used to seed the next random number genaration, which becomes the next state.
    rng.state = state

  proc seed*(rng: var rngTypeName; seeds: varargs[U]) {.inject.} =
    ## Type generic seed setter.
    ## Internaly `state` is used as seed.
    rng.state = 1
    if seeds.len >= 1:
      rng.state = seeds[0]

  proc min*(rng: rngTypeName): U {.inject, inline.} =
    ## Minimal possible generated random number.
    return U.low

  proc max*(rng: rngTypeName): U {.inject, inline.} =
    ## Minimal possible generated random number.
    when modulus_is_power_of_2 and modulus == U.n_bits:
      result = U.high
    elif modulus_is_power_of_2 and modulus < U.n_bits:
      result = (1.U shl modulus) - 1
    else:
      result = modulus - 1
    when use_range_trunc:
      return trunc(result)

  proc next*(rng: var rngTypeName): U {.inject.} =
    ## Return next random number.
    rng.state = modulo_op(multiplier.U2 * rng.state.U2 + increment.U2)
    when use_range_trunc: return trunc(rng.state)
    else:                 return rng.state

  proc jump*[P: Positive](rng: var rngTypeName; n: P) {.inject.} =
    ## Jump ahead by `n` values in the current random number stream.
    var n = n
    for (jwd, jmul, jinc) in zip(jump_widths, jump_multiplier, jump_increment):
      while n >= jwd:
        modulo_op(jmul.U2 * rng.state.U2 + jinc.U2) 
        n -= jwd
    for i in 0..<n:
      discard rng.next()

  proc init*(rng: var rngTypeName; seed: varargs[U]) {.inject.} =
    rng.seed(seed)

  proc `init rngTypeName`*(seed: varargs[U]): rngTypeName {.inject.} =
    result.init(seed)


const bit_vals_u32 = collect:
  for i in countdown(31,1):
    1.uint32 shl i

const bit_vals_u64 = collect:
  for i in countdown(63,1):
    1.uint64 shl i


makeLinearCongruentialGenerator(minstd, uint32, uint64, 48271'u32, 0'u32, 2147483647'u32, bit_vals_u32)
makeLinearCongruentialGenerator(rand48, uint64, uint2x64, 25214903917'u64, 11'u64, 48, bit_vals_u64, true)
makeLinearCongruentialGenerator(rand48r, uint64, uint2x64, 25214903917'u64, 11'u64, 48, bit_vals_u64, true, range[16..47])

