% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/matrixpls.postestimation.R
\name{fitted.matrixpls}
\alias{fitted.matrixpls}
\title{Model implied covariance matrix based on matrixpls results}
\usage{
\method{fitted}{matrixpls}(object, ...)
}
\arguments{
\item{object}{matrixpls estimation result object produced by the \code{\link{matrixpls}} function.}

\item{...}{All other arguments are ignored.}
}
\value{
a matrix containing the model implied covariances.
}
\description{
The \code{matrixpls} method for generic function \code{fitted} computes the model implied
covariance matrix by combining  \code{inner}, \code{reflective}, and \code{formative} as a 
simultaneous equations system. The error terms are constrained to be uncorrelated and 
covariances between exogenous variables are fixed at their sample values. Defining a
composite as dependent variable in both inner and formative creates an impossible model
and results in an error.
}
\seealso{
Other post-estimation functions: \code{\link{ave}},
  \code{\link{cr}}, \code{\link{effects.matrixpls}},
  \code{\link{fitSummary}}, \code{\link{gof}},
  \code{\link{htmt}}, \code{\link{loadings}},
  \code{\link{predict.matrixpls}}, \code{\link{r2}},
  \code{\link{residuals.matrixpls}}
}

