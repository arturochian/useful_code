dms_dd <- function(x, sep=":", hem) {
  ## Convert degrees minutes seconds to decimal degrees:
  # x: a vector containing the lat or long with elements separated by single character
  # sep: the character separating the degrees, minutes, seconds (default ":")
  # hem: the hemisphere ("N","S","E","W").  Assumes all coords in the same hemisphere
  if (hem %in% c("N","S","E","W")) {
    x <- lapply(strsplit(x,sep), as.numeric)
    x <- unlist(lapply(x, function(y) (y[1]+y[2]/60+y[3]/3600)))
    ifelse(hem %in% c("N","E"),
           ifelse(x>0,mult <- 1, mult <- -1),
           ifelse(x<0,mult <- 1, mult <- -1))
    x <- x*mult
    x
  } else {
    print("Error: 'hem' must be N,S,E, or W")
  }
}

###############################################################################

utm_dd <- function(zone=NULL, easting=NULL, northing=NULL, datum="NAD83"
                   , data=NULL, key=NULL) {

  ## Convert zone+utm pairs to lat/long. Can take either a single zone + utm,
  ## or a data frame with many.  Allows for datasets with different zones and 
  ## datum for each utm.
  #
  # Depends: rgdal, plyr
  #
  # zone: a number, or column name in 'data'
  # easting: a number, or column name in 'data'
  # northing: a number, or column name in 'data'
  # data: (optional) a data frame with zone + utms
  # key: Name of column 'data' that contains a unique identifier for each row
  # datum: string or column name in 'data'. Default 'NAD83'
  #
  # Returns: either a vector of length 2 with longitude  and latitude
  #          respectively, or a dataframe with the 'key' column and longitude
  #          and latitude.
  
  require(rgdal)
  require(plyr)
  
  get_dd <- function(d) {
    # requires a one-row dataframe with zone, easting, northing, datum (in that order)
    
    utm <- SpatialPoints(d[2:3]
                         , proj4string=CRS(paste0("+proj=utm +datum=", d[4]
                                                  , " +zone=", d[1])))
    sp <- spTransform(utm, CRS("+proj=longlat"))  
    coordinates(sp)
    
  }
  
  if (any(is.null(zone),is.null(easting),is.null(northing))) {
    
    stop("You must supply zone, easting, and northing")
    
  } else if (is.null(data)) {
    
    utms <- data.frame(zone,easting,northing,datum, stringsAsFactors=FALSE)
    as.vector(get_dd(utms))
    
  } else if (is.null(key)) {
    
    stop("You must supply a column name for 'key'")
    
  } else {
    if (!datum %in% colnames(data)) {
      datum <- rep(datum,nrow(data))
      utms <- data.frame(data[c(key,zone,easting,northing)],datum
                         , stringsAsFactors=FALSE)
    } else {
      utms <- data[c(key,zone,easting,northing,datum)]
    }
    
    longlat <- ddply(.data=utms,.variables=1, .fun= function(x) get_dd(x[2:5]))
    names(longlat)[2:3] <- c("Longitude","Latitude")
    longlat
    
  }
    
}
