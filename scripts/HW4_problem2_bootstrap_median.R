set.seed(123)

# Load the dataset
library(car)
data("Prestige")

income <- Prestige$income
income <- income[!is.na(income)]  # safety

# Bootstrapping setup
B <- 20000
n <- length(income)
boot_medians <- numeric(B)

# Bootstrap resampling
for (b in 1:B) {
  sample_b <- sample(income, size = n, replace = TRUE)
  boot_medians[b] <- median(sample_b)
}

# Point estimate (sample median)
median_hat <- median(income)

# 95% bootstrap percentile CI
ci <- quantile(boot_medians, probs = c(0.025, 0.975))

# Print results
cat("Sample median:", median_hat, "\n")
cat("95% Bootstrap CI for median:\n")
print(ci)

# Visualize outcomes
hist(boot_medians,
     breaks = 30,
     main = "Bootstrap Distribution of Median (Prestige$income)",
     xlab = "Bootstrapped median",
     col = "gray",
     border = "white")

abline(v = median_hat, lwd = 2)
abline(v = ci[1], lwd = 2, lty = 2)
abline(v = ci[2], lwd = 2, lty = 2)

# Optional: show density curve too
plot(density(boot_medians),
     main = "Density of Bootstrapped Medians",
     xlab = "Bootstrapped median")
abline(v = median_hat, lwd = 2)
abline(v = ci[1], lwd = 2, lty = 2)
abline(v = ci[2], lwd = 2, lty = 2)
