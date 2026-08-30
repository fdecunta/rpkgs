\name{scan_pkgs}
\alias{scan_pkgs}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
A Capitalized Title (ideally limited to 65 characters)
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
scan_pkgs()
}
%- maybe also 'usage' for other objects documented here.
\details{
%%  ~~ If necessary, more details than the description above ~~
}
\value{
%%  ~Describe the value returned
%%  If it is a LIST, use
%%  \item{comp1 }{Description of 'comp1'}
%%  \item{comp2 }{Description of 'comp2'}
%% ...
}
\references{
%% ~put references to the literature/web site here ~
}
\author{
%%  ~~who you are~~
}
\note{
%%  ~~further notes~~
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
%% ~~objects to See Also as \code{\link{help}}, ~~~
}
\examples{
##---- Should be DIRECTLY executable !! ----
##-- ==>  Define data, use random,
##--	or standard data sets, see data().

## The function is currently defined as
function () 
{
    args <- commandArgs(TRUE)
    args <- paste(args, collapse = " ")
    args <- strsplit(args, "nextArg", fixed = TRUE)[[1L]][-1L]
    Hflag <- FALSE
    dflag <- FALSE
    rflag <- FALSE
    vflag <- TRUE
    pkgs <- lapply(args, .scan_file)
    names(pkgs) <- args
    if (dflag) {
        deps <- tools::package_dependencies(unlist(unique(pkgs)), 
            recursive = rflag)
        names(deps) <- unlist(unique(pkgs))
    }
    if (vflag) {
        all_pkgs <- c(unlist(unique(pkgs)), if (dflag) unlist(unique(deps)))
        version <- lapply(all_pkgs, .get_pkg_version)
        names(version) <- all_pkgs
    }
    for (f in args) {
        for (p in pkgs[[f]]) {
            line <- p
            if (Hflag) 
                line <- paste(f, p, sep = ":")
            if (vflag) 
                line <- paste(line, version[[p]], sep = ":")
            if (dflag) {
                for (d in deps[[p]]) {
                  dline <- paste(line, d, sep = ":")
                  if (vflag) 
                    dline <- paste(dline, version[[d]], sep = ":")
                  writeLines(dline)
                }
            }
            else {
                writeLines(line)
            }
        }
    }
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory (show via RShowDoc("KEYWORDS")):
% \keyword{ ~kwd1 }
% \keyword{ ~kwd2 }
% Use only one keyword per line.
% For non-standard keywords, use \concept instead of \keyword:
% \concept{ ~cpt1 }
% \concept{ ~cpt2 }
% Use only one concept per line.
