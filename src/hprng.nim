#import hprng/...
#export ...


# generic base HPRNG type/constraint
#> either OOP-like approach with each RNG deriving from HPRNG
#type HPRNG* = object of RootObj
#> or as a meta-type (like someInteger) consisting of all available RNGs
#type HPRNG* = ... | ... | ... | ...
#> or using concepts 
#type HPRNG[T, S] = concept
#   proc seed(self: Self): S
#   proc seed(self: var Self, s: S)
#   proc next(self: var Self): T
#   proc jump(self: var Self; n: SomeInteger)
#   proc min(self: Self): T
#   proc max(self: Self): T
