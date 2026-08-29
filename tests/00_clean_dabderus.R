library(ENMeval)
library(geodata)
library(terra)
library(predicts)

WORLDCLIM_PATH <- path.expand("~/worldclim")
CMIP6_PATH <- path.expand("~/cmip6")

## Leer datos y transformar a 'SpatVector' para plotear con datos de WorldClim
df <- read.table("../data/raw/gbif_d_abderus.csv", sep = "\t")

## need to do some weird manipulation. the data is a bit broken
names(df) <- df[1, ]
df <- df[-1, ]

## filtrar Argentina
df <- df[df[["countryCode"]] == "AR", ]

## sacar, los que no tengan coordenadas
df[["long"]] <- as.numeric(df[["decimalLongitude"]])
df[["lat"]] <- as.numeric(df[["decimalLatitude"]])
df <- df[!is.na(df[["long"]]) | !is.na(df[["lat"]]), ]
occs <- df[ , c("long", "lat")]

## ----------------------------------------
## Move to terra objects
occs <- terra::vect(occs, geom = c("long", "lat"), crs = "EPSG:4326")
envs <- geodata::worldclim_global(var = "bio", res = 5, path = WORLDCLIM_PATH)

## Crop to Argentina
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

## Remove variables with high VIF to avoid colinearity problems
envs.vif <- usdm::vifstep(envs)
envs.rem <- envs.vif@excluded
envs <- envs[[!(names(envs) %in% envs.rem)]]

## remove dups
occs.cells <- terra::extract(envs[[1]], occs, cellnumbers = TRUE, ID = FALSE)
occs.cellDups <- duplicated(occs.cells[,1])
occs <- occs[!occs.cellDups,]


png("../figs/dist_dabderus_raw.png", res = 300, units = "in", width = 4, height = 7)
plot(arg_shape, border = "grey40", col = "grey97", main = "Diloboderus abderus")
points(occs, col = rgb(1, 0, 0, 0.4), cex = 1.1)
dev.off()

## ## Hay algunas observaciones en el NOA, pero parece ser mas una cosa extraña que realmente el
## ## bicho viviendo ahi. Voy a sacarlas para que no ensucien los datos
## noa <- (crds(occs)[ , 1] < -62 & crds(occs)[ , 2] > -27)
## occs <- occs[!noa]

## terra::plot(envs[[1]])
## terra::points(occs, col = rgb(1, 0, 0, 0.4), pch = 20)

## Don't work with the buffer zone. the idea is to show the dist in Argentina

## ----------------------------------------------------------------------
## Background points
##
## TODO: fix bias?

bg <- terra::spatSample(envs, size = 10000, na.rm = TRUE, 
                        values = FALSE, xy = TRUE) |> as.data.frame()
colnames(bg) <- c("x", "y")

plot(envs[[1]])
points(bg, pch = 20, cex = 0.2)


## ----------------------------------------------------------------------
## Model tunning

## transformar a data frame con xy
occs <- crds(occs)

mod <- ENMevaluate(
    occs = occs,
    envs = envs,
    bg = bg, 
    algorithm = 'maxnet',
    partitions = 'block', 
    tune.args = list(fc = c("L", "Q", "LQ"), rm = 1:3)
)

mod@results

## best model
mod@results[mod@results[["delta.AICc"]] == min(mod@results[["delta.AICc"]]), ]

pred <- mod@predictions["fc.LQ_rm.1"]

saveRDS(pred, "../Rds/dabderus_pred.rds")

plot(
    eval.predictions(mod)[['fc.LQ_rm.1']],
    col = terrain.colors(100),
    main = expression(paste("Distribución ", italic("Diloboderus abderus")))
)

## ----------------------------------------------------------------------
## Validación
##
## TODO: hacer plot de validación. AUC, CBI, etc.
## check: https://groups.google.com/g/maxent/c/2o2XFzRlSNE



## ----------------------------------------------------------------------

## Mapa binario
## 
## Podria terminar aca, pero hagamos un mapa binario. Para eso hay que definir thresholds.
## ENMeval es solo para tunear modelos. Como GridSearch de scikit learn.
##
## Para esta parte es mejor 'predicts'.

## Common thresholds to extract:
## - Minimum Training Presence (or.mtp)
## - 10th Percentile Training Presence (or.10p)
## - Equal Training Sensitivity & Specificity

best_model_idx <- which(mod@results$delta.AICc == 0) # or other selection criteria

mtp_threshold <- mod@results$or.mtp.avg[best_model_idx]
p10_threshold <- mod@results$or.10p.avg[best_model_idx]

## get the continuous prediction raster for your best model
pred_raster <- mod@predictions[[best_model_idx]] 

## Using a fixed threshold (e.g., 0.5)
binary_fixed <- ifel(pred_raster >= 0.5, 1, 0)
## Method 2: Using MTP threshold
binary_mtp <- ifel(pred_raster >= mtp_threshold, 1, 0)
## Method 3: Using 10th percentile threshold
binary_p10 <- ifel(pred_raster >= p10_threshold, 1, 0)


plot_bichos <- function() {
    terra::points(
               occs,
               ## 0.5, el 4to canal es alpha
               col = rgb(1, 0, 0, 0.1),
               pch = 19,
               cex = 0.7,
               )
}

#pdf("../figs/all_dbaderus.pdf")
png("../figs/all_dabderus.png", res = 300, units = "in", width = 8, height = 10)
par(mfrow=c(2,2))
plot(pred_raster, main="Prediccion continua")
plot(binary_fixed, main="Umbral fijo (0.5)")
plot_bichos()
plot(binary_mtp, main="Umbral Minima Presencia")
plot_bichos()
plot(binary_p10, main="Percentil 10")
plot_bichos()
dev.off()

## El percentil 10 parece tener sentido.


## ----------------------------------------------------------------------
## Climate change

## Load WorldClim data and crop to Arg
## NOTE: can't use a mask before aligning with future data. Don't know really why.
envs <- geodata::worldclim_global(var = "bio", res = 5, path = WORLDCLIM_PATH)
envs <- crop(envs, arg_shape)

envs_fut <- cmip6_world(model = "ACCESS-CM2",
  ssp = "585",
  time = "2061-2080",
  var = "bio",
  res = 5,
  path = CMIP6_PATH
)

## WorldClim y CMIP6 no tienen la misma grilla. Hay que acomodarlos con 'resample'

## NOTE: for some re
envs_fut_2 <- crop(envs_fut, envs)
envs_fut <- resample(envs_fut_2, envs, method = "bilinear")

compareGeom(envs, envs_fut, stopOnError = FALSE)

all(names(envs) == names(envs_fut))


envs_fut <- crop(mask(envs, arg_shape), arg_shape)

par(mfrow = c(1, 2))
plot(envs[[1]], main = "Curr")
plot(envs_fut[[1]], main = "Fut")

# hist(values(envs_fut[[1]] - envs[[1]] ))
