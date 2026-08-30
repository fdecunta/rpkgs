library(ENMeval)
library(geodata)
library(terra)
library(predicts)

WORLDCLIM_PATH <- path.expand("~/worldclim")
CMIP6_PATH <- path.expand("~/cmip6")

## Leer datos y transformar a 'SpatVector' para plotear con datos de WorldClim
df <- read.table("../data/raw/gbif_d_abderus.csv", sep = "\t")

occs <- terra::vect(occs, geom = c("long", "lat"), crs = "EPSG:4326")
envs <- geodata::worldclim_global(var = "bio", res = 5, path = WORLDCLIM_PATH)

arg_shape <- geodata::gadm(country = "ARG", level = 0, path = tempdir())

arg_shape_file <- "../Rds/arg_shape.rds"
arg_shape <-
    if (file.exists(arg_shape_file)) {
        readRDS(arg_shape_file)
    } else {
        geodata::gadm(country = "ARG", level = 0, path = tempdir())
    }

occs <- crop(mask(occs, arg_shape), arg_shape)
envs <- crop(mask(envs, arg_shape), arg_shape)

envs.vif <- usdm::vifstep(envs)
envs.rem <- envs.vif@excluded
envs <- envs[[!(names(envs) %in% envs.rem)]]

occs.cells <- terra::extract(envs[[1]], occs, cellnumbers = TRUE, ID = FALSE)
occs.cellDups <- duplicated(occs.cells[,1])
occs <- occs[!occs.cellDups,]

plot(arg_shape, border = "grey40", col = "grey97", main = "Diloboderus abderus")
points(occs, col = rgb(1, 0, 0, 0.4), cex = 1.1)
dev.off()

terra::plot(envs[[1]])
terra::points(occs, col = rgb(1, 0, 0, 0.4), pch = 20)

