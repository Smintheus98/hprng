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
## This implementation was based on the Random123 library which can be found at
## https://random123.com/, respectively https://github.com/DEShawResearch/random123
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

  proc trunc(x: U): U {.gensym.} =
    ## Truncate value according to `bit_range`
    const bit_range_len = bit_range.high - bit_range.low + 1
    (x shr bit_range.low) and ( (1.U shl bit_range_len) - 1 )

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
    when modulus_is_power_of_2 and modulus == U.sizeof * 8:
      rng.state = multiplier * rng.state + increment
    elif modulus_is_power_of_2 and modulus < U.sizeof * 8:
      rng.state = (multiplier * rng.state + increment) and ((1.U shl modulus) - 1)
    else:
      rng.state = (multiplier * rng.state + increment) mod modulus

    when use_range_trunc: return trunc(rng.state)
    else:                 return rng.state

  proc jump*[P: Positive](rng: var rngTypeName; n: P) {.inject.} =
    ## Jump ahead by `n` values in the current random number stream.
    ## TODO: add jumping
    discard

  proc init*(rng: var rngTypeName; seed: varargs[U]) {.inject.} =
    rng.seed(seed)

  proc `init rngTypeName`*(seed: varargs[U]): rngTypeName {.inject.} =
    result.init(seed)


makeLinearCongruentialGenerator(minstd, uint32, 48271'u32, 0'u32, 2147483647'u32)
makeLinearCongruentialGenerator(rand48, uint64, 25214903917'u64, 11'u64, 48, true)
makeLinearCongruentialGenerator(rand48r, uint64, 25214903917'u64, 11'u64, 48, true, range[16..47])

if isMainModule:
  let rng = initMinstd()
