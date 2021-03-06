if (require("testthat") && require("parameters")) {
  set.seed(123)
  mod <- lm(formula = cbind(mpg, disp) ~ wt, data = mtcars)
  mp <- model_parameters(mod)

  test_that("model_parameters,mlm", {
    expect_equal(
      mp$Coefficient,
      c(37.28513, -5.34447, -131.14842, 112.47814),
      tolerance = 1e-3
    )
    expect_equal(
      colnames(mp),
      c("Parameter", "Coefficient", "SE", "CI_low", "CI_high", "t",
        "df_error", "p", "Response")
    )
    expect_equal(mp$Response, c("mpg", "mpg", "disp", "disp"))
  })
}
