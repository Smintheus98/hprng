# ******************************************************************************
# Copyright (c) 2025, Yannic Kitten
#
# This project is licensed under BSD 3-Clause License.
# See the file "LICENSE", included in this distribution, for more details on
# licensing and copyright.
# ******************************************************************************

##
## hprng - Linear Congruential Generator (LCG) random number generator family
## ==========================================================================
## 
## About LCGs
## ------------
## 
## The LCG is a rather simple and already quite old PRNG, that is still widely used, even though its
## statistical properties are rather limited and it tends to form hyperplanes.
## This might be because this generator is fast, easy to implement and has a very small state.
##
## The classic Linear Congruential Generator is formally defined using the following recurrence:
## 
##     X(n+1) = (a * X(n) + c) mod m
## 
## with parameters a, c and m, also called multiplier, increment and modulus.
## 
## Starting with an initial seed `X(0)`, this formula delivers a new pseudo-random number
## `X(n+1)` on each iteration.
## 
##
## Implementation
## --------------
## 
## Here implemented are the following generators:
## - `Minstd`
## - `Rand48`
## - `Rand48r`
##
## Which are common LCG implementations.
## However this list is obviously not very extensive.
## Other possibly desired LCG implementations can be created using the
## `makeLinearCongruentialGenerator`_ template factory.
## 
## 
## State transition and output function
## ------------------------------------
## 
## The internal state simply consists of the last generated random number, which also represents the
## output function.
## 
## 
## Parallelization
## ---------------
## 
## Even though the state transition is so simple, it is a formula of recurrence, iterating on which
## does not bring much additional performance.
## However using modulo arithmetics we can get a closed formula for a `k`-step iteration.
## 
##     X(n+k) = (a^k * X(n) + c * sum(j=0..k-1, a^j)) mod m
##            = (a^k * X(n) + c * (a^k - 1) / (a - 1)) mod m
## 
## Mathematically this is a nice solution, however it still poses some computational problems.
## For original 64-bit coefficients the `k`-step coefficient `a(k) := a^k mod m` potentially
## requires full 128 bit multiplication and the
## `c(k) := c * (a^k - 1) / (a - 1) mod m = c * (a^k mod (a-1)m - 1) / (a - 1) mod m` coefficient
## potentially requires full 256 bit multiplication.
## For that reason the coefficients are calculated using bigints package.
## 
## For fast application, the coefficients for base-2 jumps are precalculated at compile time and
## combined as required at runtime.
## 
## 
## Quality
## -------
## 
## Depending on the actual parameters the quality of the generator varies a lot.
## Most don't even pass the TestU01's SmallCrush suite, while some are able to pass TestU01's
## BigCrush suite without failure.
## When choosing a LCG generator one should take care, that it provides full period `m` and does not
## tend to form too few hyperplanes.
##

import std / [options, sequtils, sugar, algorithm]
import pkg / bigints
import private / [utils, arbitraryUint]

template makeLinearCongruentialGenerator*(
      rngTypeName: untyped;
      U: typedesc[SomeUnsignedInt];
      U2: typedesc[SomeUnsignedInt | object];
      multiplier, increment, modulus: static[U];
      jump_widths: static[openArray[U]];
      modulus_is_power_of_2 = false;
      bit_range = range[0..0]
      ): untyped =
  ## Template factory to generate LCG generators.
  ## If the `modulus_is_power_of_2` flag is set, the `modulus` parameter is interpreted as the
  ## corresponding exponent instead of the actual modulus.
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

  proc iterate(a, x, c: U): U {.gensym, inline.} =
    ## Optimized iteration.
    when modulus_is_power_of_2:
      modulo_op(a * x + c)
    else:
      modulo_op(a.U2 * x.U2 + c.U2)

  proc calc_jump_multiplier(jmp_wds: openArray[U]): seq[U] {.gensym, compileTime.} =
    ## Calculates multiplier coefficients for desired jump widths
    const m = if modulus_is_power_of_2: 1.initBigint shl modulus
              else: modulus.initBigint
    for jwd in jmp_wds:
      result.add powmod(multiplier.initBigint, jwd.initBigint, m).toInt[:U].get

  proc calc_jump_increment(jmp_wds: openArray[U]): seq[U] {.gensym, compileTime.} =
    ## Calculates increment coefficients for desired jump widths
    when increment == 0:
      return newSeqWith(jmp_wds.len, 0.U)
    else:
      const m = if modulus_is_power_of_2: 1.initBigint shl modulus
                else: modulus.initBigint
      const m2 = m * (multiplier - 1).initBigInt
      for jwd in jmp_wds:
        let
          nomin = powmod(multiplier.initBigint, jwd.initBigint, m2) - 1.initBigint
          fract = nomin div (multiplier - 1).initBigint
          jincr = (increment.initBigint * fract) mod m
        result.add jincr.toInt[:U].get

  const
    jump_multiplier {.gensym.} = calc_jump_multiplier(jump_widths)
    jump_increment {.gensym.} = calc_jump_increment(jump_widths)

  # ***** Exported procedures *****
  proc state*(rng: var rngTypeName; state: U) {.inject.} =
    ## State setter.
    ## The state is used to seed the next random number generation, which becomes the next state.
    rng.state = state

  proc seed*(rng: var rngTypeName; seeds: varargs[U, U]) {.inject.} =
    ## Type generic seed setter.
    ## Internally `state` is used as seed.
    rng.state = 1
    if seeds.len >= 1:
      rng.state = seeds[0]

  proc min*(rng: rngTypeName): U {.inject, inline.} =
    ## Minimal possible generated random number.
    return if increment == 0: 1 else: 0

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
    rng.state = iterate(multiplier, rng.state, increment)
    when use_range_trunc: return trunc(rng.state)
    else:                 return rng.state

  proc jump*[P: Positive](rng: var rngTypeName; n: P) {.inject.} =
    ## Jump ahead by `n` values in the current random number stream.
    var n = n.BiggestUint
    for i, jwd in jump_widths:
      while n >= jwd:
        rng.state = iterate(jump_multiplier[i], rng.state, jump_increment[i])
        n -= jwd
    for i in 0..<n:
      discard rng.next()

  proc init*(rng: var rngTypeName; seed: varargs[U, U]) {.inject.} =
    rng.seed(seed)

  proc `init rngTypeName`*(seed: varargs[U, U]): rngTypeName {.inject.} =
    result.init(seed)


const bit_vals_u32 {.hint[XDeclaredButNotUsed]: off.} = collect:
  for i in countdown(31,1):
    1.uint32 shl i

const bit_vals_u48 {.hint[XDeclaredButNotUsed]: off.} = collect:
  for i in countdown(47,1):
    1.uint64 shl i

const bit_vals_u64 {.hint[XDeclaredButNotUsed]: off.} = collect:
  for i in countdown(63,1):
    1.uint64 shl i


makeLinearCongruentialGenerator(Minstd, uint32, uint64, 48271'u32, 0'u32, 2147483647'u32, bit_vals_u32)
makeLinearCongruentialGenerator(Rand48, uint64, uint2x64, 25214903917'u64, 11'u64, 48, bit_vals_u48, true)
makeLinearCongruentialGenerator(Rand48r, uint64, uint2x64, 25214903917'u64, 11'u64, 48, bit_vals_u48, true, range[16..47])
