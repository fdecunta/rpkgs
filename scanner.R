require(tools)

## need to clean Rmd fiels first.
## my_file <- "03_total_biomass.Rmd"

my_file <- "03_total_biomass.R"

parsed <- parse(file = my_file, srcfile = srcfile(my_file))    


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

unlist(sapply(parsed, scan_pkgs))

match.arg(TRUE)
