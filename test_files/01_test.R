library(randomForest)
library(terra)

WORLDCLIM_PATH <- path.expand("~/worldclim")

obs <- terra::vect(df, geom = c("long", "lat"), crs = "EPSG:4326")
envs <- geodata::worldclim_global(var = "bio", res = 5, path = WORLDCLIM_PATH)

arg_shape_file <- "../Rds/arg_shape.rds"
arg_shape <-
    if (file.exists(arg_shape_file)) {
        readRDS(arg_shape_file)
    } else {
        geodata::gadm(country = "ARG", level = 0, path = tempdir())
    }

obs <- crop(mask(obs, arg_shape), arg_shape)
envs <- crop(mask(envs, arg_shape), arg_shape)

envs.vif <- usdm::vifstep(envs)
envs.rem <- envs.vif@excluded
envs <- envs[[!(names(envs) %in% envs.rem)]]

plot(arg_shape, border = "grey40", col = "grey97", main = "Epichloë spp.")
points(obs, col = rgb(1, 0, 0, 0.4), cex = 1.1)
