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

template makeLinearCongruentialGenerator*(
      rngTypeName: untyped;
      U: typedesc[SomeUnsignedInt];
      multiplier, increment, modulus: static[U];
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
    assert not modulus_is_power_of_2 or modulus <= U.sizeof * 8
    # bit_range has to stay within Us bit count
    assert bit_range.low >= 0  and bit_range.low < U.sizeof * 8
    assert bit_range.high >= 0 and bit_range.high < U.sizeof * 8

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

  proc modulo_op(x: U): U {.gensym, inline.} =
    ## Optimized modulo operation.
    when modulus_is_power_of_2 and modulus == U.sizeof * 8:
      return x
    elif modulus_is_power_of_2 and modulus < U.sizeof * 8:
      return x and ((1.U shl modulus) - 1)
    else:
      return x mod modulus

  #[ # There are some issues left, (actual or emulated) 128-bit arithmetic can solve
  proc modpow(b, e, m: U): U =
    ## calculate (b ^ e) mod m
    discard

  proc calc_jump_multiplier[L: static[int]](jmp_wds: array[L, uint]): array[L, U] {.gensym.} =
    # TODO: produces wrong results, if `multiplier^2` already overflows U
    for i in 0..<L:
      result[i] = modpow(multiplier, jmp_wds[i], modulus)
      #result[i] = 1
      #for k in 0..<jmp_wds[i]:
      #  result[i] = modulo_op(result[i] * modulo_op(multiplier))

  proc calc_jump_increment[L: static[int]](jmp_wds, jmp_mult: array[L, uint]): array[L, U] {.gensym.} =
    when increment == 0:
      return
    for i in 0..<L:
      result[i] = 0

  const
    jump_widths: array[4, uint] = [2, 4, 8, 16]
    jump_multiplier = calc_jump_multiplier[4](jump_widths)
    #jump_increment = calc_jump_increment[4](jump_widths, jump_multiplier)
  ]#

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
    when modulus_is_power_of_2 and modulus == U.sizeof * 8:
      result = U.high
    elif modulus_is_power_of_2 and modulus < U.sizeof * 8:
      result = (1.U shl modulus) - 1
    else:
      result = modulus - 1
    when use_range_trunc:
      return trunc(result)

  proc next*(rng: var rngTypeName): U {.inject.} =
    ## Return next random number.
    rng.state = modulo_op(multiplier * rng.state + increment)
    when use_range_trunc: return trunc(rng.state)
    else:                 return rng.state

  proc jump*[P: Positive](rng: var rngTypeName; n: P) {.inject.} =
    ## Jump ahead by `n` values in the current random number stream.
    ## TODO: Optimize jump ahead. (NOTE: There are some issues left,
    ##        only (actual or emulated) 128-bit arithmetic can reliably solve!)
    for i in 0..<n:
      discard rng.next()

  proc init*(rng: var rngTypeName; seed: varargs[U]) {.inject.} =
    rng.seed(seed)

  proc `init rngTypeName`*(seed: varargs[U]): rngTypeName {.inject.} =
    result.init(seed)


makeLinearCongruentialGenerator(minstd, uint32, 48271'u32, 0'u32, 2147483647'u32)
makeLinearCongruentialGenerator(rand48, uint64, 25214903917'u64, 11'u64, 48, true)
makeLinearCongruentialGenerator(rand48r, uint64, 25214903917'u64, 11'u64, 48, true, range[16..47])

