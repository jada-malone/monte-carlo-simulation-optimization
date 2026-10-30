############################################################
# ISQS-7339 Homework 4 (MS-DS): Problems 1–3
# One combined R script
############################################################

set.seed(123)

############################################################
# PROBLEM 1: Wind Turbine Input Analysis + Simulation
############################################################

cat("\n====================\n")
cat("PROBLEM 1\n")
cat("====================\n")

# Load data
wind <- read.csv("windTurbineData(3).csv")

cat("\nWind turbine columns:\n")
print(colnames(wind))
cat("\nFirst 5 rows:\n")
print(head(wind))

# Correct columns in your file
fail   <- wind$failure.count
repair <- wind$rapair.time     # misspelled in file
drive  <- wind$drive.time

cat("\nSummary stats:\n")
print(summary(wind))

# ---- 1(a) FailCount (Discrete): Poisson vs Negative Binomial ----
mean_fail <- mean(fail)
var_fail  <- var(fail)

cat("\nFailCount mean =", mean_fail, "\n")
cat("FailCount variance =", var_fail, "\n")

lambda_hat <- mean_fail
cat("Poisson lambda_hat =", lambda_hat, "\n")

# Fit Negative Binomial (MASS)
if (!requireNamespace("MASS", quietly=TRUE)) install.packages("MASS")
library(MASS)

nb_fit <- fitdistr(fail, "Negative Binomial")
cat("\nNegative Binomial fit:\n")
print(nb_fit)

# ---- 1(a) RepairTime & DriveTime (Continuous): fit candidate dists ----
if (!requireNamespace("fitdistrplus", quietly=TRUE)) install.packages("fitdistrplus")
library(fitdistrplus)

cat("\nHistograms for input analysis...\n")
hist(repair, breaks=20, probability=TRUE, main="Histogram: rapair.time", xlab="rapair.time")
hist(drive,  breaks=20, probability=TRUE, main="Histogram: drive.time",  xlab="drive.time")

# Fit RepairTime distributions
fit_repair_norm  <- fitdist(repair, "norm")
fit_repair_logn  <- fitdist(repair, "lnorm")
fit_repair_gamma <- fitdist(repair, "gamma")
fit_repair_weib  <- fitdist(repair, "weibull")

# Fit DriveTime distributions
fit_drive_norm  <- fitdist(drive, "norm")
fit_drive_logn  <- fitdist(drive, "lnorm")
fit_drive_gamma <- fitdist(drive, "gamma")
fit_drive_weib  <- fitdist(drive, "weibull")

# AIC comparison tables
repair_AIC <- data.frame(
  Distribution = c("Normal","Lognormal","Gamma","Weibull"),
  AIC = c(fit_repair_norm$aic, fit_repair_logn$aic, fit_repair_gamma$aic, fit_repair_weib$aic)
)

drive_AIC <- data.frame(
  Distribution = c("Normal","Lognormal","Gamma","Weibull"),
  AIC = c(fit_drive_norm$aic, fit_drive_logn$aic, fit_drive_gamma$aic, fit_drive_weib$aic)
)

cat("\nRepairTime AIC Comparison:\n")
print(repair_AIC)

cat("\nDriveTime AIC Comparison:\n")
print(drive_AIC)

# Select best continuous models (lowest AIC)
best_repair_name <- repair_AIC$Distribution[which.min(repair_AIC$AIC)]
best_drive_name  <- drive_AIC$Distribution[which.min(drive_AIC$AIC)]

cat("\nBest RepairTime model:", best_repair_name, "\n")
cat("Best DriveTime model:", best_drive_name, "\n")

# Optional: diagnostic plots for best fits (can comment out if too many plots)
par(mfrow=c(2,2))
plot(fit_repair_norm, main="Repair: Normal")
plot(fit_repair_gamma, main="Repair: Gamma")
plot(fit_drive_norm, main="Drive: Normal")
plot(fit_drive_gamma, main="Drive: Gamma")
par(mfrow=c(1,1))

# ---- 1(b) Simulation of income ----
N <- 20000

# Decide FailCount model: use NegBin if overdispersed
use_negbin <- (var_fail > mean_fail * 1.2)

if (use_negbin) {
  size_hat <- nb_fit$estimate["size"]
  mu_hat   <- nb_fit$estimate["mu"]
  fail_sim <- rnbinom(N, size=size_hat, mu=mu_hat)
  cat("\nFailCount model used: Negative Binomial\n")
  cat("size =", size_hat, "mu =", mu_hat, "\n")
} else {
  fail_sim <- rpois(N, lambda=lambda_hat)
  cat("\nFailCount model used: Poisson\n")
  cat("lambda =", lambda_hat, "\n")
}

# Simulate RepairTime using chosen best model
if (best_repair_name == "Normal") {
  repair_sim <- rnorm(N, mean=fit_repair_norm$estimate["mean"], sd=fit_repair_norm$estimate["sd"])
} else if (best_repair_name == "Lognormal") {
  repair_sim <- rlnorm(N, meanlog=fit_repair_logn$estimate["meanlog"], sdlog=fit_repair_logn$estimate["sdlog"])
} else if (best_repair_name == "Gamma") {
  repair_sim <- rgamma(N, shape=fit_repair_gamma$estimate["shape"], rate=fit_repair_gamma$estimate["rate"])
} else {
  repair_sim <- rweibull(N, shape=fit_repair_weib$estimate["shape"], scale=fit_repair_weib$estimate["scale"])
}

# Simulate DriveTime using chosen best model
if (best_drive_name == "Normal") {
  drive_sim <- rnorm(N, mean=fit_drive_norm$estimate["mean"], sd=fit_drive_norm$estimate["sd"])
} else if (best_drive_name == "Lognormal") {
  drive_sim <- rlnorm(N, meanlog=fit_drive_logn$estimate["meanlog"], sdlog=fit_drive_logn$estimate["sdlog"])
} else if (best_drive_name == "Gamma") {
  drive_sim <- rgamma(N, shape=fit_drive_gamma$estimate["shape"], rate=fit_drive_gamma$estimate["rate"])
} else {
  drive_sim <- rweibull(N, shape=fit_drive_weib$estimate["shape"], scale=fit_drive_weib$estimate["scale"])
}

# Income formula
income_sim <- 2 * (repair_sim + drive_sim) * fail_sim

# Report stats + 95% CI for mean
mean_income <- mean(income_sim)
sd_income   <- sd(income_sim)
CI_income   <- mean_income + c(-1, 1) * 1.96 * sd_income / sqrt(N)

cat("\n--- Problem 1(b) Results ---\n")
cat("Mean income =", mean_income, "\n")
cat("SD income   =", sd_income, "\n")
cat("95% CI for mean income =", CI_income[1], "to", CI_income[2], "\n")

hist(income_sim, breaks=30, main="Simulated Yearly Income per Turbine", xlab="Income ($)")

############################################################
# PROBLEM 2: Bootstrap median + 95% CI (Prestige dataset)
############################################################

cat("\n====================\n")
cat("PROBLEM 2\n")
cat("====================\n")

if (!requireNamespace("car", quietly=TRUE)) install.packages("car")
library(car)
data("Prestige")

income <- Prestige$income
income <- income[!is.na(income)]

B <- 20000
n <- length(income)

boot_medians <- numeric(B)
for (b in 1:B) {
  boot_medians[b] <- median(sample(income, size=n, replace=TRUE))
}

median_hat <- median(income)
CI_median  <- quantile(boot_medians, probs=c(0.025, 0.975))

cat("\n--- Problem 2 Results ---\n")
cat("Sample median =", median_hat, "\n")
cat("95% Bootstrap CI for median:\n")
print(CI_median)

hist(boot_medians, breaks=30,
     main="Bootstrap Distribution of Median (Prestige$income)",
     xlab="Bootstrapped median")
abline(v=median_hat, lwd=2)
abline(v=CI_median[1], lty=2, lwd=2)
abline(v=CI_median[2], lty=2, lwd=2)

############################################################
# PROBLEM 3: Newsvendor resampling simulation
############################################################

cat("\n====================\n")
cat("PROBLEM 3\n")
cat("====================\n")

news <- read.csv("newsVendorData(1).csv")

cat("\nNewsvendor columns:\n")
print(colnames(news))
cat("\nFirst 5 rows:\n")
print(head(news))

demand <- news$demand

C <- 12
R <- 18
S <- 10

profit_fn <- function(Q, D) {
  sold <- pmin(Q, D)
  leftover <- pmax(Q - D, 0)
  R*sold + S*leftover - C*Q
}

Q_grid <- seq(min(demand), max(demand), by=1)
B <- 20000

avg_profit <- numeric(length(Q_grid))

for (i in seq_along(Q_grid)) {
  Q <- Q_grid[i]
  D_sim <- sample(demand, size=B, replace=TRUE)
  avg_profit[i] <- mean(profit_fn(Q, D_sim))
}

Q_star <- Q_grid[which.max(avg_profit)]
cat("\nOptimal purchase quantity Q* =", Q_star, "\n")

plot(Q_grid, avg_profit, type="l",
     main="Expected Profit vs Order Quantity (Resampling Simulation)",
     xlab="Order Quantity Q", ylab="Mean Profit")

# Profit distribution at optimal Q*
D_star <- sample(demand, size=B, replace=TRUE)
profit_star <- profit_fn(Q_star, D_star)

CI_profit <- quantile(profit_star, probs=c(0.025, 0.975))

cat("\n--- Problem 3 Results ---\n")
cat("Mean profit at Q* =", mean(profit_star), "\n")
cat("95% CI for profit at Q*:\n")
print(CI_profit)

hist(profit_star, breaks=30,
     main=paste("Profit Distribution at Optimal Q* =", Q_star),
     xlab="Profit")
