# Scan R files looking for packages names.

require(tools, quietly = TRUE)

scan_pkgs <- function(x)
{
    ret <- c()
    if (any(grepl("library", x, fixed = TRUE))) {
        ret <- c(ret, (as.character(x))[-1L])
    }
    if (any(grepl("p_load", x, fixed = TRUE))) {
        ret <- c(ret, as.character(x)[-1L])
    }
    if (any(i <- grepl("::", x, fixed = TRUE))) {
	pkg_pattern <- "([a-zA-Z][a-zA-Z0-9._]*)::"
	match_i <- gregexpr(pkg_pattern, as.character(x[i]), perl = TRUE)
	matches <- regmatches(as.character(x[i]), match_i)
	pkgs <- lapply(matches, function(s) sub("::$", "", s))
        ret <- c(ret, pkgs)
    }
    ret
}


scan_file <- function(f)
{
	parsed <- parse(file = f, srcfile = srcfile(f))    
	all_pkgs <- unlist(sapply(parsed, scan_pkgs))

	# TODO:
	# here should handle:
	# - print line
	# - dependencies
	# - recursive
	
	unique(all_pkgs)
}

main <- function()
{
	args <- commandArgs(TRUE)
	args <- paste(args, collapse=" ")
	args <- strsplit(args, "nextArg", fixed=TRUE)[[1L]][-1L]
	args <- trimws(args)

	if (length(args) == 0) {
		args <- c("tests/00_clean_dabderus.R")
	}

	pkgs <- lapply(args, scan_file)
	names(pkgs) <- args

	print(pkgs)
}


main()
