# rpkgs

Prints to stdout unique packages used in R scripts.

## Description

A cli tool that scan R files and extract the packages used. 

It parses packages from these methods:

- `library(pkg)` / `require(pkg)`
- `pkg::func()`
- `pacman::p_load(pkg1, pkg2, ...)` (or multi-line calls)

Include options to print additional information:

- Filename where each package is used.
- Package version or empty if package is not installed.
- Package dependencies.
- Package recursive dependencies.
- Version for dependencies or recursive dependencies.

Dependencies work _only_ for packages available at CRAN and needs internet connection.

## Usage

```
usage: rpkgs [-dHrv] file1 ...

Scan R files for packages used.

Options:
  -H  print with filename
  -d  dependencies
  -r  recursive dependencies (implies -d)
  -v  package version
```

## Install

```
make install
```

## Uninstall

```
make remove
```

## Examples

List packages found in file:

```
$ rpkgs test_files/00_test.R 
ENMeval
geodata
terra
predicts
usdm
```

Scan multiple files and add filenames, similar to `grep -H`:

```
rpkgs -H test_files/00_test.R test_files/01_test.R
test_files/00_test.R:ENMeval
test_files/00_test.R:geodata
test_files/00_test.R:terra
test_files/00_test.R:predicts
test_files/00_test.R:usdm
test_files/01_test.R:randomForest
test_files/01_test.R:terra
test_files/01_test.R:geodata
test_files/01_test.R:usdm
```

Show packages and their version:

```
$ rpkgs -v test_files/00_test.R
ENMeval:2.0.5.2
geodata:0.6.9
terra:1.9.34
predicts:0.2.2
usdm:2.1.7
```

The same but with dependencies. For ease of reading, pipe into [column(1)](https://man.openbsd.org/column):

```
$ rpkgs -dv 00_test.R | column -t -s ":"
ENMeval   2.0.5.2  methods             4.6.1
ENMeval   2.0.5.2  terra               1.9.34
ENMeval   2.0.5.2  maxnet              0.1.4
ENMeval   2.0.5.2  predicts            0.2.2
ENMeval   2.0.5.2  parallel            4.6.1
ENMeval   2.0.5.2  foreach             1.5.2
ENMeval   2.0.5.2  utils               4.6.1
ENMeval   2.0.5.2  stats               4.6.1
ENMeval   2.0.5.2  grDevices           4.6.1
ENMeval   2.0.5.2  dplyr               1.2.1
ENMeval   2.0.5.2  tidyr               1.3.2
ENMeval   2.0.5.2  ggplot2             4.0.3
ENMeval   2.0.5.2  glmnet              5.0
ENMeval   2.0.5.2  rangeModelMetadata  0.1.5
ENMeval   2.0.5.2  rlang               1.3.0
geodata   0.6.9    terra               1.9.34
geodata   0.6.9    rappdirs            0.3.4
terra     1.9.34   methods             4.6.1
terra     1.9.34   Rcpp                1.1.2
predicts  0.2.2    methods             4.6.1
predicts  0.2.2    terra               1.9.34
usdm      2.1.7    methods             4.6.1
usdm      2.1.7    terra               1.9.34
usdm      2.1.7    raster              3.6.32
```

Find which packages need to be installed by checking that version is empty with [awk(1)](https://man.openbsd.org/awk):

```
$ rpkgs -v 03_test.R | awk -F ":" '$2=="" { print $1 }'
multcomp
metafor
patchwork
ggpubr
gridGraphics
here
ggthemes
vcd
statpsych
pacman
```

# Bugs

- At the moment, does not work for `Rmd` and `qmd` files.
- Fails to parse correctly when a package is loaded inside a function.
