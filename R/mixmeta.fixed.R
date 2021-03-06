###
### R routines for the R package mixmeta (c)

#
mixmeta.fixed <-
function(Xlist, ylist, Slist, nall, control, ...) {
#
################################################################################
#
  # FIT GLS (WITHOUT RANDOM PART)
  gls <- glsfit(Xlist,ylist,Slist,onlycoef=FALSE)
#
  # COMPUTE (CO)VARIANCE MATRIX OF coef
  qrinvtUX <- qr(gls$invtUX)
  R <- qr.R(qrinvtUX)
  Qty <- qr.qty(qrinvtUX,gls$invtUy)
  vcov <- tcrossprod(backsolve(R,diag(1,ncol(gls$invtUX))))
#
  # COMPUTE RESIDUALS (LATER), FITTED AND RANK
  res <- NULL
  fitted <- lapply(Xlist,"%*%",gls$coef)
  rank <- qrinvtUX$rank
#
  # LIKELIHOOD FUNCTION
  # CONSTANT PART
  pconst <- -0.5*nall*log(2*pi)
  # I GUESS IN STATA:
  #const <- -0.5*length(ylist)*ncol(Psi)*log(2*pi)
  # RESIDUAL COMPONENT
  pres <- -0.5*(crossprod(gls$invtUy-gls$invtUX%*%gls$coef))
  # DETERMINANT COMPONENT
  pdet <- -sum(sapply(gls$Ulist,function(U) sum(log(diag(U)))))
#
  logLik <- as.numeric(pconst + pdet + pres)
#
  # RETURN
  list(coefficients=gls$coef,vcov=vcov,residuals=res,fitted.values=fitted,
    df.residual=nall-rank,rank=rank,logLik=logLik)
}
