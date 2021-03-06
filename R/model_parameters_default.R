#' Parameters from (General) Linear Models
#'
#' Extract and compute indices and measures to describe parameters of (general) linear models (GLMs).
#'
#' @param model Model object.
#' @param ci Confidence Interval (CI) level. Default to 0.95 (95\%).
#' @param bootstrap Should estimates be based on bootstrapped model? If \code{TRUE}, then arguments of \link[=model_parameters.stanreg]{Bayesian regressions} apply (see also \code{\link[=bootstrap_parameters]{bootstrap_parameters()}}).
#' @param iterations The number of bootstrap replicates. This only apply in the case of bootstrapped frequentist models.
#' @param standardize The method used for standardizing the parameters. Can be \code{"refit"}, \code{"posthoc"}, \code{"smart"}, \code{"basic"}, \code{"pseudo"} or \code{NULL} (default) for no standardization. See 'Details' in \code{\link[effectsize]{standardize_parameters}}. Note that robust estimation (i.e. \code{robust=TRUE}) of standardized parameters only works when \code{standardize="refit"}.
#' @param exponentiate Logical, indicating whether or not to exponentiate the the coefficients (and related confidence intervals). This is typical for, say, logistic regressions, or more generally speaking: for models with log or logit link. \strong{Note:} standard errors are also transformed (by multiplying the standard errors with the exponentiated coefficients), to mimic behaviour of other software packages, such as Stata.
#' @param robust Logical, if \code{TRUE}, robust standard errors are calculated (if possible), and confidence intervals and p-values are based on these robust standard errors. Additional arguments like \code{vcov_estimation} or \code{vcov_type} are passed down to other methods, see \code{\link[=standard_error_robust]{standard_error_robust()}} for details.
#' @param component Model component for which parameters should be shown. May be one of \code{"conditional"}, \code{"precision"} (\pkg{betareg}), \code{"scale"} (\pkg{ordinal}), \code{"extra"} (\pkg{glmx}), \code{"marginal"} (\pkg{mfx}), \code{"conditional"} or \code{"full"} (for \code{MuMIn::model.avg()}) or \code{"all"}.
#' @param p_adjust Character vector, if not \code{NULL}, indicates the method to adjust p-values. See \code{\link[stats]{p.adjust}} for details.
#' @param df_method Method for computing degrees of freedom for confidence intervals (CI). Only applies to models of class \code{glm} or \code{polr}. May be \code{"profile"} or \code{"wald"}.
#' @param verbose Toggle warnings and messages.
#' @param ... Arguments passed to or from other methods. For instance, when \code{bootstrap = TRUE}, arguments like \code{ci_method} are passed down to \code{\link[bayestestR]{describe_posterior}}.
#'
#' @seealso \code{\link[insight:standardize_names]{standardize_names()}} to rename
#'   columns into a consistent, standardized naming scheme.
#'
#' @examples
#' library(parameters)
#' model <- lm(mpg ~ wt + cyl, data = mtcars)
#'
#' model_parameters(model)
#'
#' # bootstrapped parameters
#' model_parameters(model, bootstrap = TRUE)
#'
#' # standardized parameters
#' model_parameters(model, standardize = "refit")
#'
#' # different p-value style in output
#' model_parameters(model, p_digits = 5)
#' model_parameters(model, digits = 3, ci_digits = 4, p_digits = "scientific")
#'
#' # logistic regression model
#' model <- glm(vs ~ wt + cyl, data = mtcars, family = "binomial")
#' model_parameters(model)
#'
#' # show odds ratio / exponentiated coefficients
#' model_parameters(model, exponentiate = TRUE)
#' @return A data frame of indices related to the model's parameters.
#' @export
model_parameters.default <- function(model,
                                     ci = .95,
                                     bootstrap = FALSE,
                                     iterations = 1000,
                                     standardize = NULL,
                                     exponentiate = FALSE,
                                     robust = FALSE,
                                     p_adjust = NULL,
                                     verbose = TRUE,
                                     ...) {
  out <- .model_parameters_generic(
    model = model,
    ci = ci,
    bootstrap = bootstrap,
    iterations = iterations,
    merge_by = "Parameter",
    standardize = standardize,
    exponentiate = exponentiate,
    robust = robust,
    p_adjust = p_adjust,
    verbose = verbose,
    ...
  )

  attr(out, "object_name") <- deparse(substitute(model), width.cutoff = 500)
  out
}



.model_parameters_generic <- function(model,
                                      ci = .95,
                                      bootstrap = FALSE,
                                      iterations = 1000,
                                      merge_by = "Parameter",
                                      standardize = NULL,
                                      exponentiate = FALSE,
                                      effects = "fixed",
                                      component = "conditional",
                                      robust = FALSE,
                                      df_method = NULL,
                                      p_adjust = NULL,
                                      verbose = TRUE,
                                      ...) {

  # to avoid "match multiple argument error", check if "component" was
  # already used as argument and passed via "...".
  mc <- match.call()
  comp_argument <- parse(text = .safe_deparse(mc))[[1]]$component

  # Processing
  if (bootstrap) {
    params <- bootstrap_parameters(model, iterations = iterations, ci = ci, ...)
  } else {
    params <- .extract_parameters_generic(
      model,
      ci = ci,
      component = component,
      merge_by = merge_by,
      standardize = standardize,
      effects = effects,
      robust = robust,
      df_method = df_method,
      p_adjust = p_adjust,
      verbose = verbose,
      ...
    )
  }

  if (exponentiate) params <- .exponentiate_parameters(params)
  params <- .add_model_parameters_attributes(
    params,
    model,
    ci,
    exponentiate,
    bootstrap,
    iterations,
    df_method = df_method,
    p_adjust = p_adjust,
    verbose = verbose,
    ...
  )
  class(params) <- c("parameters_model", "see_parameters_model", class(params))

  params
}





# GLM ------------------------

#' @importFrom insight n_obs
#' @rdname model_parameters.default
#' @export
model_parameters.glm <- function(model,
                                 ci = .95,
                                 df_method = "profile",
                                 bootstrap = FALSE,
                                 iterations = 1000,
                                 standardize = NULL,
                                 exponentiate = FALSE,
                                 robust = FALSE,
                                 p_adjust = NULL,
                                 verbose = TRUE,
                                 ...) {
  if (insight::n_obs(model) > 1e4 && df_method == "profile") {
    message("Profiled confidence intervals may take longer time to compute. Use 'df_method=\"wald\"' for faster computation of CIs.")
  }

  out <- .model_parameters_generic(
    model = model,
    ci = ci,
    df_method = df_method,
    bootstrap = bootstrap,
    iterations = iterations,
    merge_by = "Parameter",
    standardize = standardize,
    exponentiate = exponentiate,
    robust = robust,
    p_adjust = p_adjust,
    ...
  )

  attr(out, "object_name") <- deparse(substitute(model), width.cutoff = 500)
  out
}

#' @export
model_parameters.polr <- model_parameters.glm

#' @export
model_parameters.negbin <- model_parameters.glm

#' @export
model_parameters.logistf <- model_parameters.glm

#' @export
model_parameters.mle2 <- model_parameters.glm

#' @export
model_parameters.mle <- model_parameters.glm



# other special cases ------------------------------------------------


#' @export
model_parameters.sem <- model_parameters.default

#' @export
model_parameters.HLfit <- model_parameters.default

#' @export
model_parameters.mipo <- model_parameters.default

#' @export
model_parameters.margins <- function(model, ci = .95, exponentiate = FALSE, p_adjust = NULL, verbose = TRUE, ...) {
  # Parameters, Estimate and CI
  params <- insight::get_parameters(model)
  params <- .data_frame(
    params,
    SE = summary(model)$SE
  )

  # CI
  params <- merge(params, ci(model, ci = ci), by = "Parameter", sort = FALSE)

  # Statistic
  statistic <- insight::get_statistic(model)
  params <- merge(params, statistic, by = "Parameter", sort = FALSE)

  # p-value
  params <- .data_frame(params, p = summary(model)$p)

  # ==== Renaming

  if ("Statistic" %in% names(params)) {
    names(params) <- gsub("Statistic", gsub("(-|\\s)statistic", "", attr(statistic, "statistic", exact = TRUE)), names(params))
    names(params) <- gsub("chi-squared", "Chi2", names(params))
  }
  names(params) <- gsub("(c|C)hisq", "Chi2", names(params))
  names(params) <- gsub("Estimate", "Coefficient", names(params))

  # ==== adjust p-values?

  if (!is.null(p_adjust) && tolower(p_adjust) %in% stats::p.adjust.methods && "p" %in% colnames(params)) {
    params$p <- stats::p.adjust(params$p, method = p_adjust)
  }

  if (exponentiate) params <- .exponentiate_parameters(params)

  params <- .add_model_parameters_attributes(
    params,
    model,
    ci,
    exponentiate,
    p_adjust = p_adjust,
    verbose = verbose,
    ...
  )

  attr(params, "object_name") <- deparse(substitute(model), width.cutoff = 500)
  class(params) <- c("parameters_model", "see_parameters_model", class(params))

  params
}



#' @export
model_parameters.mediate <- function(model, ci = .95, exponentiate = FALSE, verbose = TRUE, ...) {
  # Parameters, Estimate and CI
  params <- insight::get_parameters(model)

  # CI
  params <- merge(params, ci(model, ci = ci), by = "Parameter", sort = FALSE)
  params$CI <- NULL

  # p-value
  params <- merge(params, p_value(model), by = "Parameter", sort = FALSE)

  # ==== Renaming

  if (any(grepl("\\(control\\)$", params$Parameter))) {
    params$Component <- gsub("(.*)\\((.*)\\)$", "\\2", params$Parameter)
  }

  if (exponentiate) params <- .exponentiate_parameters(params)
  attr(params, "object_name") <- deparse(substitute(model), width.cutoff = 500)
  params <- .add_model_parameters_attributes(params, model, ci, exponentiate, verbose = verbose, ...)
  class(params) <- c("parameters_model", "see_parameters_model", class(params))

  params
}
