# hprng
A library for high-performance (pseudo-)random number generation fit for highly parallel applications.

This library provides a collection of powerful and well established pseudorandom number generators (PRNGs) all of which implement some form of advanced jump-ahead algorithm (sub-stream partitioning) or equivalent multi-stream algorithm to allow generation of independent and non-overlapping pseudorandom number streams.
These algorithms are especially useful in a parallel context as usually found in scientific computing (e.g. Monte Carlo simulations, statistical bootstrap, etc.).

Eventually hardware vectorization of the PRNGs are considered.

ATTENTION: This library does not provide cryptographically secure random number generators.

WARNING: This library is under heavy development! Use at own risk!

### Structure
In contrast to the classic object oriented approach this library tries to reduce runtime resolutions and thus does not make use of methods.

Instead the different generators are covered by a concept, which requires a generator to provide procedures to set the seed, get the minimal, maximal and next random number and to jump ahead in the generator state.
This concept makes it easy to pass different generators to e.g. a single procedure.

The actual generators are defined using factory templates per generator kind.
Aside of the generic creation of different generators of one kind, this approach promises some compile time optimization like parameter substitution.

## Implemented RNGs

| RNG type | Status | Jump complexity best/avg/worst | Parallelization approach | Implementations | Pending optimizations |
| - | :-: | :-: | :-: | - | - |
| LCG | complete | $O(1)/O(\log(n))/O(\log(n))$ | substream | Minstd, Rand48, Rand48r, ... | Remove external bigints dependency |
| Philox | complete | $O(1)/O(1)/O(1)$ | substream, multistream | Philox2x32_10, Philox2x64_10, Philox4x32_10, Philox4x64_10 | Remove external unroll dependency |

## planned PRNGs
- [ ] RNG base concept
- [ ] CBRNGs (counter based)
  - [x] Philox
  - [ ] Threefry
- [ ] Mersenne Twister
  - [ ] mt19937
- [ ] WELL
- [x] LCG
- [ ] fib-lagged
- [ ] shuffled
- [ ] PCG
- [ ] L'Ecuyer CMRG
- [ ] Xorshift-family
