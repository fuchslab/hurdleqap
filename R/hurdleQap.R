#' @export
#'
#' @title hurdleQAP
#' @description hurdleQap is a function for regression analysis for sparse network data with dependency structure
#' using a combination of a hurdle model and the quadratic assignment procedure (QAP).
#'
#' @param y nxn adjacency matrix with count target variable.
#' @param x list of nxn adjacency matrices: first matrix should be a distance matrix, following matrices are further covariates.
#' @param removeControl logical value: is there data which should not be considered? Default value is FALSE.
#' @param logicMatrix if removeControl = TRUE: logical nxn-matrix containing information about
#' which data should not be considered: observation which should be removed are TRUE.
#' @param maxDist maximum distance (in unit of distance matrix x[[1]]); only distances smaller than maxDist are considered.
#' @param kbasis number of basis functions in bam (used only for first element of x (distance)).
#' @param reps number of permutations.
#' @return Object of class HurdleQap: list which contains among others:
#' \itemize{
#' \item modelGlmBin: model output of the zero part from the parametric model.
#' \item modelGlmPois: model output of the count part from the parametric model.
#' \item modelGamBin: model output of the zero part from the non-parametric model.
#' \item modelGamPois: model output of the count part from the non-parametric model.
#' \item qaplist: list element which contains permutations model coefficients and QAP-pvalues for each model.
#' }
#'
#' @examples
#' set.seed(123)
#' library("VGAM")
#' pois <- rzipois(n = 2500, lambda = 4, pstr0 = 0.6)
#' m <- matrix(pois, ncol = 50, nrow = 50)
#' m[lower.tri(m)] = t(m)[lower.tri(m)]
#' diag(m) <- 0
#' my_y <- m
#'
#' dist <- c(rgamma(n = 1000, shape = 12, scale = 30),
#'           rgamma(n = 1500, shape = 12, scale = 30),
#'           rgamma(n = 500, shape = 30, scale = 40))
#' n <- matrix(dist, ncol = 50, nrow = 50)
#' n[lower.tri(n)] = t(n)[lower.tri(n)]
#' diag(n) <- 0
#' # one covariate
#' my_x <- list(n)
#' # depending on number of reps, this takes a while
#' myQap <- hurdleQap(y = my_y, x = my_x, removeControl = FALSE, logicMatrix = NULL, maxDist = 700, kbasis = 8, reps = 10)
#' summary(myQap$modelGlmBin)
#' summary(myQap$modelGamPois)
#' # QAP pvalues
#' myQap$qaplist$zeroGlm$xbin_1[2:4]
#'
#' plotHurdleQap(hurdleqap = myQap, method = "parametric", rug = FALSE, display = "terms",
#'               plotTitles = list("Binomial part\nDistance",
#'                                 "Poissonian part\nDistance"),
#'               xLabels = list(bquote(hat(beta)[binDist]),
#'                              bquote(hat(beta)[poisDist])))
#'
#' plotHurdleQap(hurdleqap = myQap, method = "nonparametric", rug = FALSE, display = "terms",
#'               plotTitles = list("Binomial part\nDistance",
#'                                 "Poissonian part\nDistance"),
#'               xLabels = list("Distance in m",
#'                              "Distance in m"))
#'
#' plotHurdleQap(hurdleqap = myQap, method = "nonparametric", rug = FALSE, display = "response",
#'               plotTitles = list("Binomial part\nDistance",
#'                                 "Poissonian part\nDistance"),
#'               xLabels = list("Distance in m",
#'                              "Distance in m"))
#'
#'
#'
#' # two covariates
#' vals <- rnorm(n = 2500, mean = 30, sd = 70)
#' r <- matrix(vals, ncol = 50, nrow = 50)
#' r[lower.tri(r)] = t(r)[lower.tri(r)]
#' diag(r) <- 0
#'
#' my_x <- list(n, r)
#' myQap2 <- hurdleQap(y = my_y, x = my_x, removeControl = FALSE, logicMatrix = NULL, maxDist = 600, kbasis = 8, reps = 10)
#' #' QAP pvalues
#' myQap2$qaplist$zeroGlm$xbin_1[2:4]
#' myQap2$qaplist$zeroGlm$xbin_2[2:4]
#'
#' plotHurdleQap(hurdleqap = myQap2, method = "parametric", rug = FALSE, display = "terms")
#'
#' plotHurdleQap(hurdleqap = myQap2, method = "nonparametric", rug = TRUE, display = "terms",
#'               plotTitles = list("Binomial part\nx1",
#'                                 "Poissonian part\nx1",
#'                                 "Binomial part\nx2",
#'                                 "Poissonian part\nx2"),
#'               xLabels = list("Distance in m",
#'                              "Distance in m",
#'                              "Value", "Value"))

hurdleQap <- function(y, x, removeControl = FALSE, logicMatrix = NULL, maxDist, kbasis, reps){
  # original model
  modelOriginal <- hurdleQapOriginal(y = y, x = x, removeControl = removeControl,
                                        logicMatrix = logicMatrix , maxDist = maxDist, kbasis = kbasis)
  # permutation
  allperms <- hurdleQapPerms(OriginalResults = modelOriginal, reps = reps, seed = NULL)
  # combined results (original and permutations)
  combined <- hurdleQapCombine(permutationList = allperms, OriginalList = modelOriginal)
}
