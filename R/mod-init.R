
#' @rdname moduleset-ship
#' @export
init_covid_ship <- function(x, param, init, control, s) {

  # Master Data List
  dat <- list()
  dat$param <- param
  dat$init <- init
  dat$control <- control

  dat$attr <- list()
  dat$stats <- list()
  dat$stats$nwstats <- list()
  dat$temp <- list()

  ## Network Setup ##
  # Initial network simulations
  dat$nw <- list()
  for (i in 1:length(x)) {
    dat$nw[[i]] <- simulate(x[[i]]$fit, basis = x[[i]]$fit$newnetwork)
  }
  nw <- dat$nw

  # Pull Network parameters
  dat$nwparam <- list()
  for (i in 1:length(x)) {
    dat$nwparam[i] <- list(x[[i]][-which(names(x[[i]]) == "fit")])
  }

  ## Nodal Attributes Setup ##
  num <- network.size(nw[[1]])
  dat$attr$active <- rep(1, num)
  dat$attr$arrival.time <- rep(1, num)
  dat$attr$uid <- 1:num

  # Pull in attributes on network
  nwattr.all <- names(nw[[1]][["val"]][[1]])
  nwattr.use <- nwattr.all[!nwattr.all %in% c("na", "vertex.names")]
  for (i in seq_along(nwattr.use)) {
    dat$attr[[nwattr.use[i]]] <- get.vertex.attribute(nw[[1]], nwattr.use[i])
  }

  # Convert to tergmLite method
  dat <- init_tergmLite(dat)

  ## Infection Status and Time Modules
  dat <- init_status_covid_ship(dat)

  ## Get initial prevalence
  dat <- prevalence_covid_ship(dat, at = 1)

  # Network stats
  if (dat$control$save.nwstats == TRUE) {
    dat <- calc_nwstats_covid(dat, at = 1)
  }

  return(dat)
}


init_status_covid_ship <- function(dat) {

  e.num.pass <- dat$init$e.num.pass
  e.num.crew <- dat$init$e.num.crew

  type <- dat$attr$type
  active <- dat$attr$active
  num <- sum(dat$attr$active)

  ## Disease status
  status <- rep("s", num)
  if (e.num.pass > 0) {
    status[sample(which(active == 1 & type == "p"), size = e.num.pass)] <- "e"
  }
  if (e.num.crew > 0) {
    status[sample(which(active == 1 & type == "c"), size = e.num.crew)] <- "e"
  }

  dat$attr$status <- status
  dat$attr$active <- rep(1, length(status))
  dat$attr$entrTime <- rep(1, length(status))
  dat$attr$exitTime <- rep(NA, length(status))

  # Infection Time
  idsInf <- which(status == "e")
  infTime <- rep(NA, length(status))
  clinical <- rep(NA, length(status))
  statusTime <- rep(NA, length(status))
  statusTime[idsInf] <- 1
  dxStatus <- rep(0, length(status))
  transmissions <- rep(0, length(status))

  dat$attr$statusTime <- statusTime
  dat$attr$infTime <- infTime
  dat$attr$clinical <- clinical
  dat$attr$dxStatus <- dxStatus
  dat$attr$transmissions <- transmissions

  return(dat)
}
