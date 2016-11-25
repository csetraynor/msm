context("Distribution functions and utilities")

test_that("MatrixExp",{
    A <- matrix(c(-0.11, 0.01, 0.001,  0.2, -0.2, 0,  0, 0, 0), nrow=3, byrow=TRUE)
    me <- MatrixExp(A, method="pade")
    res <- c(0.896703832431769, 0.171397960992687, 0, 0.00856989804963433, 0.81957474998506, 0, 0.00094726269518597, 9.0272890222537e-05, 1)
    expect_equal(res, as.numeric(me), tol=1e-06)
    me <- MatrixExp(A, method="series")
    expect_equal(res, as.numeric(me), tol=1e-06)
    ev <- eigen(A)
    me2 <- ev$vectors %*% diag(exp(ev$values)) %*% solve(ev$vectors)
    expect_equal(me2, me, tol=1e-06)
})

test_that("truncated normal",{
    set.seed(220676)
    rl <- rnorm(10)
    expect_equal(dtnorm(rl), dnorm(rl), tol=1e-06)
    expect_equal(dtnorm(rl, mean=2, sd=1.2), dnorm(rl, mean=2, sd=1.2), tol=1e-06)
    d <- dtnorm(rl, mean=2, sd=1.2, lower=seq(-4,5))
    expect_equal(c(0.260110259383406, 0.108097895222820, 0.0558659556833655, 0.160829438765247, 0.343919966894772, 0, 0, 0, 0, 0), d, tol=1e-06)
    expect_equal(c(0, 0.5, 1), ptnorm(c(-1000, 0, 1000)), tol=1e-06)
    expect_equal(c(0.139068959153926, 0, 0.156451685781240), ptnorm(c(-1, 0, 1), mean=c(0,1,2), sd=c(1,2,3), lower=c(-2,1,0)), tol=1e-06)
    expect_equal(rl, qtnorm(ptnorm(rl)), tol=1e-03)
    expect_warning(qtnorm(c(-1, 0, 1, 2)), "NaN")
    expect_warning(qtnorm(c(-1, 0, 1, 2),lower=-1,upper=1), "NaN")
    expect_equal(rl, qtnorm(ptnorm(rl, mean=1:10), mean=1:10))
    ## NA handling in rtnorm
    expect_warning(rtnorm(3, mean=c(1, NA, 0)), "NAs produced")
    expect_warning(res <- rtnorm(3, sd=c(1, NA, 1), lower=c(NA, 0, 2)), "NAs produced")
    expect_equal(res[1:2], c(NaN, NaN))
})

test_that("Measurement error distributions: normal",{
    expect_equal(dnorm(2), dmenorm(2), tol=1e-06)
    expect_equal(dnorm(2, log=TRUE), dmenorm(2, log=TRUE), tol=1e-06)
    expect_equal(c(0.0539909665131881, 0.241970724519143, 0.398942280401433), dmenorm(c(-2, 0, 2), mean=c(0,1,2)), tol=1e-06)
    expect_equal(c(0.119536494085260, 0.120031723608082, 0.0967922982964366), dmenorm(c(-2, 0, 2), mean=c(0,1,2), lower=c(-3,-2,-1), sderr=c(2,3,4)), tol=1e-06)
    expect_equal(pmenorm(c(-2, 0, 2)), pnorm(c(-2, 0, 2)), tol=1e-06)
    expect_equal(pmenorm(c(-2, 0, 2), log.p=TRUE), pnorm(c(-2, 0, 2), log.p=TRUE), tol=1e-06)
    expect_equal(pmenorm(c(-2, 0, 2), lower.tail=FALSE), pnorm(c(-2, 0, 2), lower.tail=FALSE), tol=1e-06)
    expect_equal(c(0.347443301205908, 0.500000000140865, 0.652556698813763), pmenorm(c(-2, 0, 2), sderr=5), tol=1e-06)
    expect_equal(c(0.00930146266876999, 0.0249300921973760, 0.0583322325986182), pmenorm(c(-2, 0, 2), sderr=5, meanerr=10), tol=1e-06)
    expect_equal(qmenorm(pmenorm(c(-2, 0, 2), sderr=5, lower=0), sderr=5, lower=0), qmenorm(pmenorm(c(-2, 0, 2))), tol=1e-03)
})

test_that("Measurement error distributions: uniform",{
    expect_equal(c(0,1,1,0,0), dmeunif(c(-2, 0, 0.7, 1, 2)))
    expect_equal(dunif(c(-2, 0, 0.7, 1, 2), min=-3:1, max=4:8), dmeunif(c(-2, 0, 0.7, 1, 2), lower=-3:1, upper=4:8), tol=1e-06)
    expect_equal(c(0.120192106440279, 0.139607083057178, 0.136490639905731, 0.120192106440279, 0.120192106440279), dmeunif(c(-2, 0, 0.7, 1, 2), lower=-3:1, upper=4:8, sderr=1), tol=1e-06)
    expect_equal(pmeunif(c(0.1, 0.5, 0.9)), punif(c(0.1, 0.5, 0.9)), tol=1e-04)
    expect_equal(c(0.468171571157871, 0.500000000120507, 0.531828429094026), pmeunif(c(0.1, 0.5, 0.9), sderr=5), tol=1e-06)
    expect_equal(c(0.0189218497312070, 0.0229301821964305, 0.0276311076816442), pmeunif(c(0.1, 0.5, 0.9), sderr=5, meanerr=10), tol=1e-06)
    expect_equal(c(0.1, 0.5, 0.9), qmeunif(pmeunif(c(0.1, 0.5, 0.9), sderr=5, lower=-1), sderr=5, lower=-1), tol=1e-03)
    expect_equal(c(0.1, 0.5, 0.9), qmeunif(pmeunif(c(0.1, 0.5, 0.9))), tol=1e-03)
})

test_that("Exponential distribution with piecewise constant hazard",{
    expect_equal(1, integrate(dpexp, 0, Inf)$value)
    rate <- c(0.1, 0.2, 0.05, 0.3)
    t <- c(0, 10, 20, 30)
    expect_equal(1, integrate(dpexp, 0, Inf, rate=rate, t=t)$value, tol=1e-04)
    x <- rexp(10)
    expect_equal(dpexp(x), dexp(x))
    expect_equal(dpexp(x, log=TRUE), log(dpexp(x)))
    expect_equal(dpexp(x, log=TRUE), dexp(x, log=TRUE))

    stopifnot(ppexp(-5) == 0)
    stopifnot(ppexp(0) == 0)
    stopifnot(ppexp(Inf) == 1)
    set.seed(22061976)
    q <- rexp(10)
    expect_equal(pexp(q), ppexp(q))
    expect_equal(pexp(q, log.p=TRUE), ppexp(q, log.p=TRUE))
    rate <- c(0.1, 0.2, 0.05, 0.3)
    t <- c(0, 10, 20, 30)
    stopifnot(ppexp(-5, rate, t) == 0)
    stopifnot(ppexp(0, rate, t) == 0)
    expect_equal(1, ppexp(Inf, rate, t))
    expect_equal(1, ppexp(9999999, rate, t))
    expect_equal(pexp(c(5, 6, 7), rate[1]), ppexp(c(5, 6, 7), rate, t))
    expect_error(ppexp(q, rate=c(1,2,3), t=c(1,2)),"length of t must be equal to length of rate")
    expect_warning(ppexp(q, rate=-4),"NaN")
    expect_error(ppexp(q, rate=c(1,2,3), t=c(-1, 4, 6)), "first element of t should be 0")

    set.seed(22061976)
    p <- runif(10)
    expect_equal(qpexp(p), qexp(p), tol=1e-03)
    expect_equal(qpexp(p, lower.tail=FALSE), qexp(p, lower.tail=FALSE), tol=1e-03)
    expect_equal(qpexp(log(p), log.p=TRUE), qexp(log(p), log.p=TRUE), tol=1e-03)
    expect_equal(p, ppexp(qpexp(p)), tol=1e-03)
    set.seed(22061976)
    q <- rexp(10)
    expect_equal(q, qpexp(ppexp(q)), tol=1e-03)

    ## "special" argument to qgeneric
    r <- c(0.3,0.6,0.8,1.3)
    t <- c(0,2,3,5)
    expect_equal(qpexp(p = c(0.1,0.5,0.9,1) , rate=r, t=t),
                 c(qpexp(p=0.1, rate=r, t=t), qpexp(p=0.5, rate=r, t=t),
                   qpexp(p=0.9, rate=r, t=t), qpexp(p=1, rate=r, t=t)))
    expect_error(qpexp(p=0.1, rate=r, t=t[-1]), "length of t must be equal to length of rate")
    expect_error(qpexp(p=0.1, rate=r, t=c(0.1, t[-1])), "first element of t should be 0")
    
    set.seed(220676)
    rt <- rpexp(10)
    set.seed(220676)
    r <- rexp(10)
    expect_equal(rt, r, tol=1e-06)
})

test_that("deltamethod",{
    ## Example in help(deltamethod)
    ## Simple linear regression, E(y) = alpha + beta x
    x <- 1:100
    set.seed(220676)
    y <- rnorm(100, 4*x, 5)
    toy.lm <- lm(y ~ x)
    (estmean <- coef(toy.lm))
    (estvar <- summary(toy.lm)$cov.unscaled * summary(toy.lm)$sigma^2)
    ## Estimate of (1 / (alphahat + betahat))
    expect_equal(0.206982798128202, as.numeric(1 / (estmean[1] + estmean[2])))
    ## Approximate standard error
    expect_equal(0.0396485739892983, deltamethod(~ 1 / (x1 + x2), estmean, estvar))
    estvar2 <- estvar; estvar2[1,2] <- Inf
    expect_equal(deltamethod(~ 1 / (x1 + x2), estmean, estvar2), Inf)
})
