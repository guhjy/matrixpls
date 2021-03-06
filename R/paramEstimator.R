# =========== Parameter estimators ===========

#'@title Parameter estimation of full model
#'  
#'@description \code{paramsEstimator} functions estimates the statistical model described by \code{model}
#'
#'@template modelSpecification
#'  
#'@details
#'Model estimation proceeds as follows. The weights \code{W} and the
#'data covariance matrix \code{S} are used to calculate the composite covariance matrix \code{C}
#'and the indicator-composite covariance matrix \code{IC}. These are matrices are used to
#'separately estimate each of teh three model matrices \code{inner}, \code{reflective}, and
#'\code{formative}. This approach of estimating the parameter matrices separately is the
#'standard way of estimation in the PLS literature.
#'  
#'The default estimation approach is to estimate all parameters with a series of OLS 
#'regressions using \code{\link{estimator.ols}}.
#'  
#'@inheritParams matrixpls-common
#'@inheritParams matrixpls-functions
#'  
#'@param parametersInner A function used to estimate the \code{inner} model matrix. The default is
#'  \code{\link{estimator.ols}}
#'  
#'@param parametersReflective A function used to estimate the \code{reflective} model matrix. The
#'  default is \code{\link{estimator.ols}}
#'  
#'@param parametersFormative A function used to estimate the \code{formative} model matrix. The
#'  default is \code{\link{estimator.ols}}
#'  
#'@param disattenuate If \code{TRUE}, \code{C} is
#'  disattenuated before applying \code{parametersInner}.
#'  
#'@param ... All other arguments are passed through to \code{parametersInner},
#'\code{parametersReflective}, and\code{parametersFormative}
#'  
#'@return A named vector of parameter estimates.
#'  
#'@templateVar attributes parameterEstim.separate,C IC inner reflective formative Q,c
#'@template attributes
#'  
#'@name parameterEstim
NULL

#'@describeIn parameterEstim Estimates the model parameters in \code{inner}, \code{reflective}, and
#'\code{formative} separately.
#'
#'@export
#'
parameterEstim.separate <- function(S, model, W, ...,
                                    parametersInner = estimator.ols,
                                    parametersReflective = estimator.ols,
                                    parametersFormative = estimator.ols,
                                    disattenuate = FALSE,
                                    reliabilities = reliabilityEstim.weightLoadingProduct){
  
  nativeModel <- parseModelToNativeFormat(model)
  
  results <- c()
  
  # Calculate the composite covariance matrix
  C <- W %*% S %*% t(W)
  
  # Calculate the covariance matrix between indicators and composites
  IC <- W %*% S
  
  reflectiveEstimates <- parametersReflective(S, nativeModel$reflective, W, ..., C = C, IC = t(IC))  
  
  if(is.list(reflectiveEstimates)){
    reflectiveSEs <- reflectiveEstimates$se
    reflectiveEstimates <- reflectiveEstimates$est
  }
  else{
    reflectiveSEs <- reflectiveEstimates
    reflectiveSEs[] <- NA
  }
  
  if(disattenuate){
    
    Q <- reliabilities(S, reflectiveEstimates, W, ...)
    
    C <- C / sqrt(Q) %*% t(sqrt(Q))
    diag(C) <- 1
    
    # Fix the IC matrix. Start by replacing covariances with the corrected loadings
    tL <- t(reflectiveEstimates)
    IC[tL!=0] <- tL[tL!=0]
    
    # Disattenuate the remaining covariances
    IC[tL==0] <- (IC/sqrt(Q))[tL==0]
  }
  
  # C may be non-symmetric because of rounding errors. Force it to be symmetric
  C[lower.tri(C)]=t(C)[lower.tri(C)]
  
  formativeEstimates <- parametersFormative(S, nativeModel$formative, W, ..., IC = IC)  
  
  if(is.list(formativeEstimates)){
    formativeSEs <- formativeEstimates$se
    formativeEstimates <- formativeEstimates$est
  }
  else{
    formativeSEs <- formativeEstimates
    formativeSEs[] <- NA
  }
  
  innerEstimates <- parametersInner(S, nativeModel$inner, W, ..., C = C)  
  
  if(is.list(innerEstimates)){
    innerSEs <- innerEstimates$se
    innerEstimates <- innerEstimates$est
  }
  else{
    innerSEs <- innerEstimates
    innerSEs[] <- NA
  }
  
  
  results <- c(estimatesMatrixToVector(innerEstimates, nativeModel$inner, "~"),
               estimatesMatrixToVector(reflectiveEstimates, nativeModel$reflective, "=~", reverse = TRUE),
               estimatesMatrixToVector(formativeEstimates, nativeModel$formative, "<~"))
  
  se <- c(estimatesMatrixToVector(innerSEs, nativeModel$inner, "~"),
          estimatesMatrixToVector(reflectiveSEs, nativeModel$reflective, "=~", reverse = TRUE),
          estimatesMatrixToVector(formativeSEs, nativeModel$formative, "<~"))
  
  # Copy all non-standard attributes from the estimates objects
  
  for(object in list(innerEstimates, reflectiveEstimates, formativeEstimates)){
    for(a in setdiff(names(attributes(object)), c("dim", "dimnames", "class", "names"))){
      attr(results,a) <- attr(object,a)
      attr(W,a) <- NULL
    }
  }
  
  # Store these in the result object
  attr(results,"C") <- C
  attr(results,"IC") <- IC
  attr(results,"inner") <- innerEstimates
  attr(results,"reflective") <- reflectiveEstimates
  attr(results,"formative") <- formativeEstimates
  
  if(any(! is.na(se))){
    attr(results,"se") <- se
  }
  
  if(disattenuate){
    attr(results,"Q") <- Q
  }

  return(results)
}
