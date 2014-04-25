# =========== Main functions ===========

#'@title A semPLS compatibility wrapper for matrixpls
#'
#'@description
#'\code{matrixpls.sempls} mimics \code{\link[semPLS]{sempls}} function of the \code{semPLS} package.
#'The arguments and their default values and the output of the function are identical with \code{\link[semPLS]{sempls}} function,
#'but internally the function uses matrixpls estimation.
#'
#'@param model An object inheriting from class \code{plsm} as returned from \code{\link[semPLS]{plsm}}
#' or \code{\link[semPLS]{read.splsm}}.  
#' 
#'@inheritParams semPLS::sempls
#'
#'@return An object of class \code{\link[semPLS]{sempls}}. 
#'
#'@references Monecke, A., & Leisch, F. (2012). semPLS: Structural Equation Modeling Using Partial Least Squares. \emph{Journal of Statistical Software}, 48(3), 1–32.

#'
#'@seealso
#'\code{\link[semPLS]{sempls}}
#'
#'@export
#'@example example/matrixpls.sempls-example.R

matrixpls.sempls <-
	function(model, data, maxit=20, tol=1e-7, scaled=TRUE, sum1=FALSE, wscheme="centroid", pairwise=FALSE,
					 method=c("pearson", "kendall", "spearman"),
					 convCrit=c("relative", "square"), verbose=TRUE, ...){
		
		# This function is largely copied from the semPLS package (licensed under GPL 2)
		# The code specific to matrixpls are marked in the following way
		
		# Start of matrixpls code
		library(semPLS)
		# End of matrixpls code
		
		method <- match.arg(method)
		convCrit <- match.arg(convCrit)
		result <- list(coefficients=NULL, path_coefficients=NULL,
									 outer_loadings=NULL ,cross_loadings=NULL,
									 total_effects=NULL,inner_weights=NULL, outer_weights=NULL,
									 blocks=NULL, factor_scores=NULL, data=NULL, scaled=scaled,
									 model=model, weighting_scheme=NULL, weights_evolution=NULL,
									 sum1=sum1, pairwise=pairwise, method=method, iterations=NULL,
									 convCrit=convCrit, verbose=verbose, tolerance=tol, maxit=maxit, N=NULL,
									 incomplete=NULL, Hanafi=NULL)
		class(result) <- "sempls"
		
		# checking the data
		data <- data[, model$manifest]
		N <- nrow(data)
		missings <- which(complete.cases(data)==FALSE)
		if(length(missings)==0 & verbose){
			cat("All", N ,"observations are valid.\n")
			if(pairwise){
				pairwise <- FALSE
				cat("Argument 'pairwise' is reset to FALSE.\n")
			}
		}
		else if(length(missings)!=0 & !pairwise & verbose){
			# Just keeping the observations, that are complete.
			data <- na.omit(data[, model$manifest])
			cat("Data rows:", paste(missings, collapse=", "),
					"\nare not taken into acount, due to missings in the manifest variables.\n",
					"Total number of complete cases:", N-length(missings), "\n")
		}
		else if(verbose){
			cat("Data rows", paste(missings, collapse=", "),
					" contain missing values.\n",
					"Total number of complete cases:", N-length(missings), "\n")
		}
		## check the variances of the data
		if(!all(apply(data, 2, sd, na.rm=TRUE) != 0)){
			stop("The MVs: ",
					 paste(colnames(data)[which(apply(data, 2, sd)==0)], collapse=", "),
					 "\n  have standard deviation equal to 0.\n",
					 "  Recheck model!\n")
		}
		
		## scale data?
		# Note: scale() changes class(data) to 'matrix'
		if(scaled) data <- scale(data)
		
		#############################################
		# Select the function according to the weighting scheme
		if(wscheme %in% c("A", "centroid")) {
			# Start of matrixpls code
			inner.estimator <- inner.centroid
			# End of matrixpls code
			result$weighting_scheme <- "centroid"
		}
		else if(wscheme %in% c("B", "factorial")) {
			# Start of matrixpls code
			inner.estimator <- inner.factorial
			# End of matrixpls code
			result$weighting_scheme <- "factorial"
		}
		else if(wscheme %in% c("C", "pw", "pathWeighting")) {
			# Start of matrixpls code
			inner.estimator <- inner.path
			# End of matrixpls code
			result$weighting_scheme <- "path weighting"
		}
		else {stop("The argument E can only take the values 'A', 'B' or 'C'.\n See ?sempls")}
		
		# Start of matrixpls code
		
		modes <- unlist(lapply(model$blocks, function(x) attr(x,"mode")))
		modeA <- modes == "A"
		
		if(max(modeA) == 0) outerEstimators <- outer.modeB	
		else if(min(modeA) == 1) outerEstimators <- outer.modeA
		else{
			outerEstimators <- list(rep(NA,length(modeA)))
			outerEstimators[!modeA] <- list(outer.modeB)
			outerEstimators[modeA] <- list(outer.modeA)
		}
		
		S <- cov(data)
		
		if(convCrit=="relative"){
			convCheck <- function(Wnew, Wold){
				max(abs((Wold[Wnew != 0]-Wnew[Wnew != 0])/Wnew[Wnew != 0]))
			} 
		}
		else if(convCrit=="square"){
			convCheck <- function(Wnew, Wold){
				max((Wold-Wnew)^2)
			}
		}	
		
		
		matrixpls.model <- list(inner = t(model$D), 
														reflective = model$M, 
														formative = matrix(0, ncol(model$M), nrow(model$M),
																							 dimnames = list(colnames(model$M), rownames(model$M))))
		
		matrixpls.res <- matrixpls(S,
															 matrixpls.model,
															 innerEstimator = inner.estimator,
															 outerEstimators = outerEstimators,
															 convCheck = convCheck, tol = tol)
				
		converged <- attr(matrixpls.res, "converged")
		i <- attr(matrixpls.res, "iterations") + 1
		Wnew <- attr(matrixpls.res, "W")
		innerWeights <- attr(matrixpls.res, "E")
		whist <- attr(matrixpls.res, "history")
		weights_evolution <- NULL
		
			# End of matrixpls code
			
			
			## print
			if(converged & verbose){
				cat(paste("Converged after ", (i-1), " iterations.\n",
									"Tolerance: ", tol ,"\n", sep=""))
				if (wscheme %in% c("A", "centroid")) cat("Scheme: centroid\n")
				if (wscheme %in% c("B", "factorial")) cat("Scheme: factorial\n")
				if (wscheme %in% c("C", "pw", "pathWeighting")) cat("Scheme: path weighting\n")
			}
		else if(!converged){
			stop("Result did not converge after ", result$maxit, " iterations.\n",
					 "\nIncrease 'maxit' and rerun.", sep="")
		}
		
		weights_evolution <- weights_evolution[weights_evolution!=0,]
		weights_evolution$LVs <- factor(weights_evolution$LVs,  levels=model$latent)
		# create result list
		ifelse(pairwise, use <- "pairwise.complete.obs", use <- "everything")
		
		# Start of matrixpls code
		result$path_coefficients <- matrixpls.res
		result$cross_loadings <- attr(matrixpls.res,"IC")
		# End of matrixpls code
		
		result$outer_loadings <- result$cross_loadings
		result$outer_loadings[Wnew==0] <- 0
		
		# Start of matrixpls code
		result$total_effects <- effects(matrixpls.res)$Total
		# End of matrixpls code
		
		result$inner_weights <- innerWeights
		result$outer_weights <- Wnew
		result$weights_evolution <- weights_evolution
		
		# Start of matrixpls code
		result$Hanafi <- NA
		result$factor_scores <- NA
		# End of matrixpls code
		
		result$data <- data
		result$N <- N
		result$incomplete <- missings
		result$iterations <- (i-1)
		
		ref <- matrixpls.model$reflective
		inn <- t(matrixpls.model$inner)
		
		pathNames <- paste(colnames(ref)[col(ref)[ref==1]], "->", rownames(ref)[row(ref)[ref==1]])
		estimates <- t(attr(matrixpls.res,"IC"))[ref==1]
		coefNames <- paste("lam",col(ref)[ref==1],unlist(apply(ref,2,function(x) 1:sum(x))),sep="_")

		pathNames <- c(pathNames, paste(rownames(inn)[row(inn)[inn==1]], "->", colnames(inn)[col(inn)[inn==1]]))
		estimates <- c(estimates, t(attr(matrixpls.res,"beta"))[inn==1])
		coefNames <- c(coefNames, paste("beta",row(inn)[inn==1],col(inn)[inn==1],sep="_"))
		
		# Start of matrixpls code
		
		result$coefficients <- data.frame(Path = pathNames,
																			Estimate = estimates, 
																			row.names = coefNames)
		# End of matrixpls code

		return(result)
	}

plsLoop <- expression({
	#######################################################################
	# Iterate over step 2 to step 5
	i <- 1
	converged <- FALSE
	while(!converged){
		
		#############################################
		# step 2
		innerWeights <- innerWe(model, fscores=factor_scores, pairwise, method)
		factor_scores <- step2(Latent=factor_scores, innerWeights, model, pairwise)
		
		#############################################
		# step 3
		Wnew <-  outerApprx2(Latent=factor_scores, data, model,
												 sum1=sum1, pairwise, method)
		
		#############################################
		# step 4
		factor_scores <- step4(data, outerW=Wnew, model, pairwise)
		if(!sum1){
			# to ensure: w'Sw=1
			sdYs <- rep(attr(factor_scores, "scaled:scale"),
									each=length(model$manifest))
			Wnew <- Wnew / sdYs
		}
		weights_evolution_tmp <- reshape(as.data.frame(Wnew),
																		 v.names="weights",
																		 ids=rownames(Wnew),
																		 idvar="MVs",
																		 times=colnames(Wnew),
																		 timevar="LVs",
																		 varying=list(colnames(Wnew)),
																		 direction="long")
		weights_evolution_tmp <- cbind(weights_evolution_tmp, iteration=i)
		weights_evolution <- rbind(weights_evolution, weights_evolution_tmp)
		Hanafi_tmp <- cbind(f=sum(abs(cor(factor_scores)) * model$D),
												g=sum(cor(factor_scores)^2 * model$D),
												iteration=i)
		Hanafi <- rbind(Hanafi, Hanafi_tmp)
		
		#############################################
		# step 5
		st5 <- step5(Wold, Wnew, tol, converged, convCrit)
		Wold <- st5$Wold
		converged <- st5$converged
		
		#############################################
		
		
		if(i == maxit && !converged){
			# 'try-error' especially for resempls.R
			class(result) <- c(class(result), "try-error")
			i <- i+1
			break
		}
		
		i <- i+1
	}
})