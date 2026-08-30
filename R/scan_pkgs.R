scan_pkgs <-
function(args=NULL, add_filename=FALSE, dependencies=FALSE, recursive=FALSE, versions=FALSE)
{
	args <- commandArgs(TRUE)
	args <- paste(args, collapse=" ")
	args <- strsplit(args, "nextArg", fixed=TRUE)[[1L]][-1L]

	# TODO: parse flags
	Hflag <- FALSE
	dflag <- FALSE
	rflag <- FALSE
	vflag <- TRUE

	pkgs <- lapply(args, .scan_file)
	names(pkgs) <- args

	if (dflag) {
		deps <- tools::package_dependencies(unlist(unique(pkgs)), recursive = rflag)
		names(deps) <- unlist(unique(pkgs))
	} 

	if (vflag) {
		all_pkgs <- c(
			unlist(unique(pkgs)),
			if (dflag) unlist(unique(deps))
		)
		version <- lapply(all_pkgs, .get_pkg_version)
		names(version) <- all_pkgs
	}

	for (f in args) {
		for (p in pkgs[[f]]) {
			line <- p
			if (Hflag)
				line <- paste(f, p, sep=":")
			if (vflag) 
				line <- paste(line, version[[p]], sep=":")
			if (dflag) {
				for (d in deps[[p]]) {
					dline <- paste(line, d, sep=":")
					if (vflag) 
						dline <- paste(dline, version[[d]], sep=":")
					writeLines(dline)
				}
			} else {
				writeLines(line)
			}
		}
	}
}
