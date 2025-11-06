
template div2*[T: SomeInteger](value: T): T =
  ## advanced implementation of `value div 2` using bit shift
  value shr 1.T

template mod2*[T: SomeInteger](value: T): T =
  ## advanced implementation of `value mod 2` using bit look-up
  value and 1.T

template n_bits*(x: typedesc): int =
  x.sizeof * 8

template n_bits*[T](x: T): int =
  x.sizeof * 8

