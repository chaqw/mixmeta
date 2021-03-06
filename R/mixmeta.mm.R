###
### R routines for the R package mixmeta (c)
#
mixmeta.mm <-
function(Xlist, ylist, Slist, nalist, k, m, p, nall, control, ...) {
#
################################################################################
#
  # FIT FIXED EFFECTS MODEL
  gls <- glsfit(Xlist,ylist,Slist,onlycoef=FALSE)
#
  # RE-CREATE THE FULL-REGRESSION OBJECTS
  Wlist <- mapply(function(invU,na) {
    W <- matrix(0,k,k)
    W[!na,!na] <- tcrossprod(invU)
    return(W)},gls$invUlist,nalist,SIMPLIFY=FALSE)
  I <- diag(m)
  W <- do.call("cbind",lapply(seq_along(Wlist), function(i) I[,i] %x% Wlist[[i]]))
  na <- unlist(nalist)
  X <- matrix(0,m*k,k*p)
  X[!na,] <- do.call("rbind",Xlist)
  y <- rep(0,m*k)
  y[!na] <- unlist(ylist)
#
  # HAT MATRIX
  tXWXtot <- sumList(lapply(gls$invtUXlist,crossprod))
  invtXWXtot <- chol2inv(chol(tXWXtot))
  H <- X %*% invtXWXtot %*% crossprod(X,W)
  IminusH <- diag(m*k)-H
#
  # Q matrix
  Q <- fbtr(W%*%tcrossprod(IminusH%*%y),k)
#
  # A AND B
  A <- crossprod(IminusH,W)
  B <- crossprod(IminusH,diag(!na))
#
  # BLOCK COMPUTATION
  btrB <- fbtr(B,k)
  ind <- (seq(m)-1)*k
  indrow <- rep(ind,length(ind))
  indcol <- rep(ind,each=length(ind))
  tBA <- sumList(lapply(seq(indrow), function(i) {
    row <- indrow[i]+(seq(k))
    col <- indcol[i]+(seq(k))
    t(B[row,col]%x%A[row,col])}))
#
  # SOLVE THE SYSTEM
  Psi1 <- qr.solve(tBA,as.numeric(Q-btrB))
#
  # CREATE Psi
  dim(Psi1) <- c(k,k)
  Psi <- (Psi1+t(Psi1))/2
#
  # FORCE SEMI-POSITIVE DEFINITENESS
  Psi <- checkPD(Psi,set.negeigen=control$set.negeigen,force=TRUE,error=FALSE)
#
  # FIT BY GLS
  Sigmalist <- getSigmalist(NULL,nalist,Psi,Slist)
  gls <- glsfit(Xlist,ylist,Sigmalist,onlycoef=FALSE)
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
  # RETURN
  list(coefficients=gls$coef,vcov=vcov,Psi=Psi,residuals=res,
    fitted.values=fitted,df.residual=nall-rank-length(par),rank=rank,logLik=NA)
}
