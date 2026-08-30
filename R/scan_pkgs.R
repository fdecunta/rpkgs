.scan_pkgs <-
function()
{
	args <- commandArgs(TRUE)
	flags <- args[1L]
	args <- paste(args[2L], collapse=" ")
	args <- strsplit(args, "nextArg", fixed=TRUE)[[1L]][-1L]

	Hflag <- grepl("H", flags)
	dflag <- grepl("d", flags)
	rflag <- grepl("r", flags)
	vflag <- grepl("v", flags)

	pkgs <- lapply(args, .scan_file)
	names(pkgs) <- args

	if (dflag) {
		pdb <- available.packages(repos = findCRANmirror("web"))
		deps <- tools::package_dependencies(
			unlist(unique(pkgs)),
			recursive = rflag,
			db = pdb
		)
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
