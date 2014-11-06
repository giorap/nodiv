
# Definition of nodiv-class
# #samme som ovenfor (har det samme i sig) +
# 
# matrix parent_representation_matrix
# spatialGrid/PointsDataframe sitestatistics
# data.frame nodestatistics
# vector GND




nodiv_data <- function(phylo, commatrix, coords, proj4string = CRS(as.character(NA)), type = c("auto", "grid", "points"))
{
  type = match.arg(type)
  
  if(!(class(phylo) == "phylo")) stop ("phylo must be a phylogeny in the ape format") 
  
  if(!class(commatrix) == "distrib_data")
  {
    if(missing(coords)) stop("if commatrix is not an object of type distrib_data, coords must be specified")
    dist_dat <- distrib_data(commatrix, coords, proj4string, type)
  } else dist_dat <- commatrix
  
  nodiv_dat <- dist_dat
  
  cat("Comparing taxon names in phylogeny and communities (using picante)\n")
  dat <- match.phylo.comm(phylo, dist_dat$comm)
  nodiv_dat$phylo <- dat$phy
  nodiv_dat$comm <- dat$comm
  if(!(is.data.frame(nodiv_dat$comm) & nrow(nodiv_dat$comm) > 1)) stop("The tip labels in the phylogeny do not match the names in the community matrix")
  
  nodiv_dat$coords <- dist_dat$coords[match(rownames(nodiv_dat$comm), dist_dat$coords$sites),]
  nodiv_dat$hcom <- matrix2sample(nodiv_dat$comm)
  nodiv_dat$hcom[,1] <- as.character(nodiv_dat$hcom[,1])
  nodiv_dat$hcom[,2] <- as.character(nodiv_dat$hcom[,2])
  
  cat("Calculating which species descend from each node\n")
  nodiv_dat$node_species <- Create_node_by_species_matrix(nodiv_dat$phylo)
  
  class(nodiv_dat) <- c("nodiv_data","distrib_data")
  return(nodiv_dat)
}


distrib_data <- function(commatrix, coords, proj4string_in = CRS(as.character(NA)), type = c("auto", "grid", "points"))
{
  type = match.arg(type)
  cat("Checking input data\n")
  ## Testing that input objects are all right
  if(class(coords) == "SpatialPointsDataFrame" | class(coords) == "SpatialPixelsDataFrame")
    if(!all.equal(proj4string_in,coords@proj4string))
    { 
      proj4string_in <- proj4string(coords)
      warning("specified proj4string overridden by the coords data")
    } 

  if(is.data.frame(commatrix) & ncol(commatrix) == 3 & !is.numeric(commatrix[,3])) commatrix <- sample2matrix(commatrix) #i.e. is the commatrix in phylocom format?
  
  if(is.data.frame(commatrix)) commatrix <- as.matrix(commatrix)
  if(!is.matrix(commatrix)) stop("commatrix must be a matrix of 0's and 1's, indicating presence or absence")
  if(!all.equal(sort(unique(as.numeric(commatrix))), 0:1)) stop("commatrix must be a matrix of 0's and 1's, indicating presence or absence")
  
  if(is.matrix(coords)) coords <- as.data.frame(coords)
  if(is.data.frame(coords)) coords <- toSpatialPoints(coords,proj4string_in, commatrix, type)

  if(class(coords) == "SpatialPixelsDataFrame") type <- "grid" else if (class(coords) == "SpatialPointsDataFrame") type <- "points" else stop("coords must be a data.frame of coordinates or an sp data.frame object")
  
  ## making sure that the points and the commatrix fit
  
  
  commatrix <- match_commat_coords(commatrix, coords$sites)  
  
  ret <- list(comm = as.data.frame(commatrix), type = type, coords = coords)
  ret$species <- colnames(ret$comm)
  
  class(ret) <- "distrib_data"
  return(ret)

}


#internal functions

#TODO
#much of this testing can be done with try-catch phrases
#use the testthat library to test everything


match_commat_coords <- function(commatrix, sitenames)
{
  cat("Comparing sites in community data and spatial points\n")
  
  if(is.null(rownames(commatrix)))
    if(nrow(commatrix) == length(sitenames)) 
      rownames(commatrix) <- sitenames else stop("The number of sites in coords and the data matrix do not fit and there are no rownames in the community matrix to use for matching")  
      
  if(sum(sitenames %in% rownames(commatrix)) < 2)
        stop("the coordinate names and the rownammes of the community matrix do not match")
      
  sitenames <- sitenames[sitenames %in% rownames(commatrix)]

    
  commatrix <- commatrix[match(sitenames, rownames(commatrix)),]
  return(commatrix) 
}


toSpatialPoints <- function(coords, proj4string, commat, type)
{
    xcol <- 0
    ycol <- 0
    
    ret <- coords
    
    colnames(ret) <- tolower(colnames(ret))
    if('x' %in% colnames(ret) & 'y' %in% colnames(ret))
    {
      xcol <- which(colnames(ret) == 'x')
      ycol <- which(colnames(ret) == 'y')
      ret <- ret[,c(xcol, ycol)]
      
    } else if('lon' %in% substr(colnames(ret),1,3) & 'lat' %in% substr(colnames(ret), 1, 3)) {
      
      colnames(ret) <- substr(colnames(ret), 1, 3)
      xcol <- which(colnames(ret) == 'lon')[1]
      ycol <- which(colnames(ret) == 'lat')[1]
      ret <- ret[,c( xcol, ycol)]
    }
    
    if(!ncol(ret) == 2) stop("ret should be a data.frame or spatial data.frame with 2 columns, giving the x/longitude, and y/latitude of all sites")
      
    ret <- SpatialPoints(ret, proj4string)
    
    if (ncol(coords)==3 & !(xcol + ycol == 0)) sitenames <- coords[,-c(xcol, ycol)] else 
      if(length(coords) == nrow(commatrix) & !is.null(rownames(commatrix))) sitenames <- rownames(commatrix) else
        if(!is.null(rownames(coords))) sitenames <- rownames(coords) else 
          stop("There must be valid site names in the rownames of commatrix or in the coords data")
    
    type_auto <- ifelse(isGrid(ret), "grid", "points")
    
    if(type == "auto") type <- type_auto else 
      if(!type == type_auto)
        warning("The specified type of data (points or grid) seems to conflict with the automatic setting. This may cause problems")
    
    
    if(type == "grid") ret <- SpatialPixelsDataFrame(ret, data.frame(sites = sitenames, stringsAsFactors = F)) else
      ret <- SpatialPointsDataFrame(ret, data.frame(sites = sitenames, stringsAsFactors = F))
    
    return(ret)  
}

isGrid <- function(coords)
  return(isGridVar(coordinates(coords)[,1]) & isGridVar(coordinates(coords)[,2]))

isGridVar <- function(gridVar)
{
  dists <- diff(sort(unique(gridVar)))
  distab <- table(dists)
  smallest <- as.numeric(names(distab[1]))
  most_common <- as.numeric(names(distab))[distab == max(distab)]
  return(all.equal(dists/smallest, floor(dists/smallest)) & smallest %in% most_common)
  #if all differences are a multiplum of the smallest, and the smallest distance is the most common, it is probably a grid
}