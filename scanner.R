# Scan R files looking for packages names.

require(tools, quietly = TRUE)

find_pkgs <- function(x)
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
	m <- gregexpr(pkg_pattern, as.character(x[i]), perl = TRUE)
	raw_pkg <- regmatches(as.character(x[i]), m)
	pkgs <- lapply(raw_pkg, function(s) sub("::$", "", s))
        ret <- c(ret, unlist(pkgs))
    }
    ret
}

scan_file <- function(f)
{
	parsed <- parse(file = f, srcfile = srcfile(f))    
	all_pkgs <- unique(unlist(lapply(parsed, find_pkgs)))
	unique(all_pkgs)
}

get_pkg_version <- function(pkg)
{
	if (length(find.package(pkg, quiet=TRUE)) > 0) {
		packageVersion(pkg) 
	} else {
		""
	}
}

main <- function()
{
	args <- commandArgs(TRUE)
	args <- paste(args, collapse=" ")
	args <- strsplit(args, "nextArg", fixed=TRUE)[[1L]][-1L]

	dflag <- 1
	rflag <- 0
	vflag <- 1

	# TODO: remove this
	if (length(args) == 0) {
		args <- c("tests/00_clean_dabderus.R", "tests/Bad Name.R")
	}

	pkgs <- lapply(args, scan_file)
	names(pkgs) <- args

	if (dflag) {
		deps <- package_dependencies(unlist(unique(pkgs)), recursive = rflag)
		names(deps) <- unlist(unique(pkgs))
	} 

	if (vflag) {
		all_pkgs <- c(
			unlist(unique(pkgs)),
			if (dflag) unlist(unique(deps))
		)
		version <- lapply(all_pkgs, get_pkg_version)
		names(version) <- all_pkgs
	}

	for (f in args) {
		for (p in pkgs[[f]]) {
			line <- paste(f, p, sep=":")
			if (vflag) line <- paste(line, version[[p]], sep=":")

			if (dflag) {
				for (d in deps[[p]]) {
					depline <- paste(line, d, sep=":")
					if (vflag) 
						depline <- paste(depline, version[[d]], sep=":")
					writeLines(depline)
				}
			}
		}
	}
}

main()
