library(randomForest)
library(terra)

WORLDCLIM_PATH <- path.expand("~/worldclim")

## Leer datos y transformar a 'SpatVector' para plotear con datos de WorldClim
df <- read.csv("../data/raw/Semmartin_et_al_2014.csv")

## Para usar MaxEnt debería usar presencia ausencia. 
## Para dicotomizar incidencia habría que definir un umbral.
## 
## Voy a usar una forma muy simplista: marcar como ausencia
## muestreos donde no hubo ni una sola planta con endofito (incidence == 0).
## De esta forma, el modelado se basaría en ausencias absolutas,
## muestreos donde no apareció un solo endofito.
df[["presence"]] <- ifelse(df[["incidence"]] == 0, 0, 1)

## Solo para chequear que todo esta bien:
obs <- terra::vect(df, geom = c("long", "lat"), crs = "EPSG:4326")
envs <- geodata::worldclim_global(var = "bio", res = 5, path = WORLDCLIM_PATH)

## Crop to Argentina

## arg_ext <- ext(-73.5, -53.5, -55.5, -21.5)
## obs <- crop(obs, arg_ext)
## envs <- crop(envs, arg_ext)

arg_shape_file <- "../Rds/arg_shape.rds"
arg_shape <-
    if (file.exists(arg_shape_file)) {
        readRDS(arg_shape_file)
    } else {
        geodata::gadm(country = "ARG", level = 0, path = tempdir())
    }

obs <- crop(mask(obs, arg_shape), arg_shape)
envs <- crop(mask(envs, arg_shape), arg_shape)

## Remove variables with high VIF to avoid colinearity problems
envs.vif <- usdm::vifstep(envs)
envs.rem <- envs.vif@excluded
envs <- envs[[!(names(envs) %in% envs.rem)]]

png("../figs/dist_epichloe_raw.png", res = 300, units = "in", width = 4, height = 7)
plot(arg_shape, border = "grey40", col = "grey97", main = "Epichloë spp.")
points(obs, col = rgb(1, 0, 0, 0.4), cex = 1.1)
dev.off()

## La base de datos de Semmartin tiene datos de variables climáticas.
## Como el paper tiene 10 años, quizas fueron actualizados o mejorados, asi
## que voy a sacarlos y usar los de WorldClim.


df_envs <- terra::extract(envs, obs, ID = FALSE)

## df_for <- na.omit(cbind(obs[[("incidence"]], df_envs))
df_for <- cbind(obs[["incidence"]], df_envs)


# 1. Train the model
mod_rf <- randomForest(incidence ~ .,
                       importance=TRUE,
                       data = df_for,
                       ntree = 1e3)

mod_rf_2 <- randomForest(incidence ~ .,
                       importance=TRUE,
                       data = df_for,
                       ntree = 1e4)

pred_1 <- predict(envs, mod_rf, type = "response")
pred_2 <- predict(envs, mod_rf_2, type = "response")

# Plot the result
par(mfrow = c(1, 2))


# 0 = Blue, 0.5 = White, 1 = Pink/Red
base_palette <- cm.colors(100)
inc_values <- obs$incidence  
point_colors <- base_palette[ceiling(inc_values * 99)]



plot(
    pred_1,
    main = "Random Forest - 1000 trees",
    col = hcl.colors(100, palette = "viridis")
)
terra::points(obs, col = point_colors, pch = 19, cex = 0.8)

plot(
    pred_2,
    main = "Random Forest - 10000 trees",
    col = hcl.colors(100, palette = "viridis")
)
terra::points(obs, col = point_colors, pch = 19, cex = 0.8)

