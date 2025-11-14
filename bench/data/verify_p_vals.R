#!/usr/bin/Rscript

offset <- 10000 # data offset
N <- 1000 # sample size
M <- 2000 # bootstrap replications

T.n <- function(x, y) {
  N <- length(x)
  abs(mean(x) - mean(y)) / sqrt( (var(x) + var(y)) / N )
}

df <- read.table("./two-sample-test.dat", header=TRUE)

X <- df$X[1:N + offset]
Y <- df$Y[1:N + offset]
XY <- c(X, Y)


Tn <- T.n(X, Y)
Tnk <- lapply(1:M, function(i) {
  XY.boot <- sample(XY, replace=TRUE)
  T.n(XY.boot[1:N], XY.boot[1:N + N])
})

p.val <- mean(unlist(Tnk) >= Tn)

print(paste("Tn:       ", Tn))
print(paste("Tnk-mean: ", mean(unlist(Tnk))))
print(paste("p-value:  ", p.val))

