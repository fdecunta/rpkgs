.find_pkgs <-
function(x)
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
.get_pkg_version <-
function(pkg)
{
	if (length(find.package(pkg, quiet=TRUE)) > 0) {
		utils::packageVersion(pkg) 
	} else {
		""
	}
}
.scan_file <-
function(f)
{
	parsed <- parse(file = f, srcfile = srcfile(f))    
	all_pkgs <- unique(unlist(lapply(parsed, .find_pkgs)))
	unique(all_pkgs)
}
.println <-
function(s)
{
	tryCatch(
		writeLines(s),
		error = function(e) {
			# ignore SIGPIPE signal. 
			# eg. 'rpks *.R | head -5' produces that
			if (!grepl("ignoring SIGPIPE signal", e$message)) stop(e)
		}
	)
}
