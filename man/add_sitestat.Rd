\name{sitestat}
\alias{add_sitestat}
\alias{sitestat}
\alias{plot_sitestat}
\title{
Site statistics of \code{nodiv} data objects 
}
\description{
Adds, plots or reads site statistics from objects in the \code{nodiv} package
}
\usage{
add_sitestat(distrib_data, sitestat, site = NULL)
plot_sitestat(distrib_data, x, ...)
sitestat(distrib_data, statname = NULL, site = NULL)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{distrib_data}{
An object of type \code{distrib_data}, \code{nodiv_data} or \code{nodiv_result}
}
  \item{sitestat}{
A site statistic, such as species richness or mean temperature. This can be a vector or a data.frame. If 
\code{site} is not specified, the function tries to match \code{sitestat} to the site names of the \code{distrib_data} 
object. The function looks for vector names, rownames, or variables in the data.frame that match the site names. 
If sitenames are absent and the number of sitestats match, the sitestat is assumed to be in the correct order. 
}
  \item{site}{
A character or numeric variable specifying the sites in which to enter or read sitestat
}
  \item{statname}{
The name of a sitestatistic in the \code{distrib_data} object. If statname is not given, a list of
names of sitestatistics is given
}
  \item{x}{
A variable to plot on sites, can either be a numeric variable, or the name of a 
sitestatistic in the \code{distrib_data} object
}
\item{\dots}{
Further arguements to the plotting function
}

}

\value{
\code{add_sitestat} returns the object with the new sitestat inside. 
\code{sitestat} returns the named sitestatistic.
}

\author{
Michael Krabbe Borregaard
}


%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
\code{\link{distrib_data}}
}

% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
