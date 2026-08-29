# Scan R files looking for packages names.

require(tools, quietly = TRUE)

scan_pkgs <- function(x)
{
    ret <- c()
    if (any(grepl("library", x, fixed = TRUE))) {
        ret <- c(ret,(as.character(x))[-1L])
    }
    if (any(grepl("p_load", x, fixed = TRUE))) {
        ret <- c(ret,as.character(x)[-1L])
    }
    if (any(i <- grepl("::", x, fixed = TRUE))) {
        ret <- c(ret, 
                 strsplit(as.character(x[i]), "::", fixed=TRUE)[[1L]][1L])
    }
    ret
}

args <- commandArgs(TRUE)
args <- paste(args, collapse=" ")
args <- strsplit(args, "nextArg", fixed=TRUE)[[1L]][-1L]
args <- trimws(args)


scan_file <- function(f)
{
	parsed <- parse(file = f, srcfile = srcfile(f))    
	unlist(sapply(parsed, scan_pkgs))
}

pkgs <- lapply(args, scan_file)
names(pkgs) <- args

print(pkgs)

