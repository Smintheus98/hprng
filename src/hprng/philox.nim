# ******************************************************************************
# Copyright (c) 2025, Yannic Kitten
#
# This project is licensed under BSD 3-Clause License.
# See the file "LICENSE", included in this distribution, for more details on
# licensing and copyright.
# ******************************************************************************

##
## hprng - philox random number generator
##
## This implementation was based on the Random123 library which can be found at
## https://random123.com/, respectively https://github.com/DEShawResearch/random123
##

import private/utils

type LoHiUint*[U: SomeUnsignedInt] = tuple
  ## Tuple to contain lower and higher part of an uint number, double the size of uint-type `U` as
  ## required for multiplication of two type `U` numbers.
  lo, hi: U

proc standardMul*[U: SomeUnsignedInt; U2: SomeUnsignedInt](a, b: U): LoHiUint[U] =
  ## Wraps normal multiplication operation to produce low and high parts as type `LoHiUint`.
  ## This procedure may be preferred when both `U` and `U2` can be properly used and converted to.
  ## 
  ## The `U2` type is required to have at least double the size as `U`
  static: assert U2.sizeof >= 2 * U.sizeof
  const
    u_size = U.sizeof * 8
    u_mask: U2 = U.high
  let prod: U2 = a.U2 * b.U2
  (lo: (prod and u_mask).U, hi: (prod shr u_size).U)

proc manualMul*[U: SomeUnsignedInt](a, b: U): LoHiUint[U] =
  ## Calculates product of `a` and `b` and returns low and high bit parts of the result as tuple of
  ## parameter type `U`.
  ## 
  ## This procedure follows classic multiplication rules with input components split-up into two
  ## parts each, which allows to use `U`-bit arithmetic only.
  ## It is especially useful, when there is no bigger integer type available or suitable than the
  ## parameter type `U`, since multiplication of big numbers often needs up to double the bit size.
  ##
  ## This implementation operates on pure Nim, which reduces dependency constraints, but on the
  ## counter side is also a bit slower than bindings to native solutions like the common, yet not
  ## standard, uint128 C-compiler extension.
  # TODO: optimize?
  const
    halfBits = U.sizeof div 2 * 8
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


template makePhiloxType*(
      rngTypeName: untyped;
      U: typedesc[SomeUnsignedInt];
      n_words, rounds: static[uint];
      multipliers, round_consts: static array[n_words div 2, U];
      mul: proc(a,b: U): LoHiUint[U]
      ): untyped =
  ## Template factory to generate Philox generator types.
  # Inject/gensym pragmas are used explicitly here for clarification!

  # ***** Constructed type *****
  type rngTypeName* {.inject.} = object
    ## Philox generator type.
    counter, output_buffer: array[n_words, U]
    key: array[n_words div 2, U]
    output_it: uint8

  # ***** Internal procedures *****
  proc bumpKey(key: array[n_words div 2, U]): array[n_words div 2, U] {.gensym, inline.} =
    for i in 0..<key.len: # TODO: unroll
      result[i] = key[i] + round_consts[i]

  proc iterateState(ctr: array[n_words, U]; key: array[n_words div 2, U]): array[n_words, U] {.gensym, inline.} =
    for i in 0..<n_words.div2: # TODO: unroll
      let r = n_words.div2 - 1 - i
      let (lo, hi) = mul(ctr[2*i], multipliers[i])
      result[2*r]   = hi xor ctr[2*r+1] xor key[r]
      result[2*r+1] = lo

  proc genOutputBuffer(rng: var rngTypeName) {.gensym.} =
    var
      ctr = rng.counter
      key = rng.key
    for i in 0..<(rounds.pred): # TODO: unroll
      ctr = iterateState(ctr, key)
      key = bumpKey(key)
    ctr = iterateState(ctr, key)
    rng.output_buffer = ctr

  proc incCtr[V: SomeUnsignedInt](rng: var rngTypeName; n: V = 1.U) {.gensym.} =
    ## Increment internal counter by `n`, resulting in a jump of `n`*`n_words` output values
    const u_bit_width = U.sizeof * 8
    if n == 0:
      return
    elif V.sizeof > U.sizeof and (n shr u_bit_width > 0):
      # careful increment
      var n = n
      for i in 0..<n_words: # TODO: unroll
        rng.counter[i].inc n.U
        if unlikely(rng.counter[i] < n.U):
          n += 1.V shl u_bit_width
        n = n shr u_bit_width
        if n == 0:
          break
    else:
      # straight forward increment
      rng.counter[0].inc n.U
      if likely(rng.counter[0] >= n.U):
        return
      for i in 1..<n_words: # TODO: unroll
        rng.counter[i].inc  # under the checked conditions the carry can not be bigger than 1
        if likely(rng.counter[i] != 0.U):
          break

  proc incCtrAndGenOutput[V: SomeUnsignedInt](rng: var rngTypeName; n: V = 1.U) {.gensym.} =
    incCtr(rng, n)
    genOutputBuffer(rng)

  # ***** Exported procedures *****
  proc key*(rng: var rngTypeName; key: array[n_words div 2, U]; resetOutputIt = true) {.inject.} =
    ## Key setter.
    ## The `key` is used as seed.
    rng.key = key
    genOutputBuffer(rng)
    if resetOutputIt:
      rng.output_it = 0

  proc counter*(rng: var rngTypeName; ctr: array[n_words, U]; resetOutputIt = true) {.inject.} =
    ## Counter setter.
    ## The counter represents the internal state.
    rng.counter = ctr
    genOutputBuffer(rng)
    if resetOutputIt:
      rng.output_it = 0

  proc offset*(rng: var rngTypeName; offset: range[0..n_words] = 0) {.inject.} =
    ## Output buffer offset setter.
    ## The offset is assigned to the `output_it` attribute which iterates over the output buffer.
    ## For most use cases `jump()` is to be prefered!
    rng.output_it = offset.uint8

  proc seed*(rng: var rngTypeName; seeds: varargs[U]; resetOutputIt = true) {.inject.} =
    ## Type generic seed setter.
    ## Internaly `key` is used as seed.
    rng.key = rng.key.typeof.default
    for i in 0..<min(rng.key.len, seeds.len):
      rng.key[i] = seeds[i]
    genOutputBuffer(rng)
    if resetOutputIt:
      rng.output_it = 0

  proc min*(rng: rngTypeName): U {.inject, inline.} =
    ## Minimal possible generated random number.
    return U.low

  proc max*(rng: rngTypeName): U {.inject, inline.} =
    ## Minimal possible generated random number.
    return U.high

  proc next*(rng: var rngTypeName): U {.inject.} =
    ## Return next random number.
    if rng.output_it >= n_words:
      incCtrAndGenOutput(rng)
      rng.output_it = 0'u8
    result = rng.output_buffer[rng.output_it]
    rng.output_it.inc

  proc jump*[P: Positive](rng: var rngTypeName; n: P) {.inject.} =
    ## Jump ahead by `n` values in the current random number stream.
    # TODO: fix instabilities
    let increment = ((n + rng.output_it.P) div n_words).uint
    if increment > 0:
      incCtrAndGenOutput(rng, increment)
    rng.output_it = ((n + rng.output_it.P) mod n_words).uint8

  proc init*(rng: var rngTypeName; seed: varargs[U]) {.inject.} =
    rng.seed(seed)

  proc `init rngTypeName`*(seed: varargs[U]): rngTypeName {.inject.} =
    result.init(seed)


makePhiloxType(Philox2x32_10, uint32, 2, 10, [0xD256D193'u32                                ], [0x9E3779B9'u32                                ], standardMul[uint32, uint])
makePhiloxType(Philox2x64_10, uint64, 2, 10, [0xD2B74407B1CE6E93'u64                        ], [0x9E3779B97F4A7C15'u64                        ], manualMul[uint64]        )
makePhiloxType(Philox4x32_10, uint32, 4, 10, [0xD2511F53'u32,         0xCD9E8D57'u32        ], [0x9E3779B9'u32,         0xBB67AE85'u32        ], standardMul[uint32, uint])
makePhiloxType(Philox4x64_10, uint64, 4, 10, [0xD2E7470EE14C6C93'u64, 0xCA5A826395121157'u64], [0x9E3779B97F4A7C15'u64, 0xBB67AE8584CAA73B'u64], manualMul[uint64]        )

