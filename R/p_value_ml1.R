#' @title "m-l-1" approximation for SEs, CIs and p-values
#' @name p_value_ml1
#'
#' @description Approximation of degrees of freedom based on a "m-l-1" heuristic as suggested by Elff et al. (2019).
#'
#' @param model A mixed model.
#' @param dof Degrees of Freedom.
#' @inheritParams ci.merMod
#'
#' @details \subsection{Small Sample Cluster corrected Degrees of Freedom}{
#' Inferential statistics (like p-values, confidence intervals and
#' standard errors) may be biased in mixed models when the number of clusters
#' is small (even if the sample size of level-1 units is high). In such cases
#' it is recommended to approximate a more accurate number of degrees of freedom
#' for such inferential statitics (see \cite{Li and Redden 2015}). The
#' \emph{m-l-1} heuristic is such an approach that uses a t-distribution with
#' fewer degrees of freedom (\code{dof_ml1}) to calculate p-values
#' (\code{p_value_ml1}), standard errors (\code{se_ml1}) and confidence intervals
#' (\code{ci(method = "ml1")}).
#' }
#' \subsection{Degrees of Freedom for Longitudinal Designs (Repeated Measures)}{
#' In particular for repeated measure designs (longitudinal data analysis),
#' the \emph{m-l-1} heuristic is likely to be more accurate than simply using the
#' residual or infinite degrees of freedom, because \code{dof_ml1()} returns
#' different degrees of freedom for within-cluster and between-cluster effects.
#' }
#' \subsection{Limitations of the "m-l-1" Heuristic}{
#' Note that the "m-l-1" heuristic is not applicable (or at least less accurate)
#' for complex multilevel designs, e.g. with cross-classified clusters. In such cases,
#' more accurate approaches like the Kenward-Roger approximation (\code{dof_kenward()})
#' is recommended. However, the "m-l-1" heuristic also applies to generalized
#' mixed models, while approaches like Kenward-Roger or Satterthwaite are limited
#' to linear mixed models only.
#' }
#' @seealso \code{dof_ml1()} and \code{se_ml1()} are small helper-functions
#' to calculate approximated degrees of freedom and standard errors of model
#' parameters, based on the "m-l-1" heuristic.
#'
#' @examples
#' \donttest{
#' if (require("lme4")) {
#'   model <- lmer(Petal.Length ~ Sepal.Length + (1 | Species), data = iris)
#'   p_value_ml1(model)
#' }
#' }
#' @return A data frame.
#' @references \itemize{
#'   \item Elff, M.; Heisig, J.P.; Schaeffer, M.; Shikano, S. (2019). Multilevel Analysis with Few Clusters: Improving Likelihood-based Methods to Provide Unbiased Estimates and Accurate Inference, British Journal of Political Science.
#'   \item Li, P., Redden, D. T. (2015). Comparing denominator degrees of freedom approximations for the generalized linear mixed model in analyzing binary outcome in small sample cluster-randomized trials. BMC Medical Research Methodology, 15(1), 38. \doi{10.1186/s12874-015-0026-x}
#' }
#' @importFrom stats pt coef
#' @export
p_value_ml1 <- function(model, dof = NULL) {
  if (is.null(dof)) {
    dof <- dof_ml1(model)
  }
  .p_value_dof(model, dof, method = "ml1")
}
