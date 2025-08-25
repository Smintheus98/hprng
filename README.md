# hprng
A library for high-performance (pseudo-)random number generation fit for highly parallel applications.

This library provides a collection of powerful and well established pseudorandom number generators (PRNGs) all of which implement some form of advanced jump-ahead algorithm (sub-stream partitioning) or equivalent multi-stream algorithm to allow generation of independent and non-overlapping pseudorandom number streams.
These algorithms are especially useful in a parallel context as usually found in scientific computing (e.g. Monte Carlo simulations, statistical bootstrap, etc.).

Eventually hardware vectorization of the PRNGs are considered.

ATTENTION: This library does not provide cryprographically secure random number generators.

WARNING: This library is under heavy development! Usage at own risk!

### Structure
The generartors follow an compiletime-parametrized-engine approch which has been inspired by the random number generators as defined by the C++ standard.

## planned PRNGs
- [ ] RNG base object
- [ ] CBRNGs (counter based)
  - [ ] Philox
    - [ ] 4x32_10
    - [ ] ...
  - [ ] Threefry
    - [ ] 4x32_70
    - [ ] ...
- [ ] Mersenne Twister
  - [ ] mt19937
- [ ] WELL
  - [ ] ...
- [ ] LCG
  - [ ] ...
  - [ ] fib-lagged
  - [ ] shuffled
- [ ] PCG
  - [ ] ...
- [ ] L'Ecuyer CMRG
- [ ] Xorshift-family
  - [ ] ...
