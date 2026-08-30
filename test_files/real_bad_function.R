# ---
# 'Práctica 2.1'
#  'Manejo, visualización, obtención de datos climáticos y análisis espacial' 
# 
# - Dr. Fernando Biganzoli [U.B.A, Facultad de Agronomía. Departamento de Métodos Cuantitativos y Sistemas de Información]
# - Dra. Cecilia Casas [U.B.A, Facultad de Agronomía. Departamento de Recursos Naturales y ambiente. Edafología. IFEVA-CONICET]

# 
#   En esta práctica vamos a:
#   - obtener y depurar datos de presencia de la especie de interés
# - obtener datos climáticos o ambientales desde WorldClim
# - acondicionar las capas para posteriores análisis
# - muestrear y extraer valores ambientales en puntos georreferenciados


# Working dir
# setcwd("~/curso/practicas/02/")

options(digits = 3) # Mostrar 3 dígitos decimales en los outputs numéricos

# ── Paquetes ────────────────────────────────────────────────────────────────
# Todos los paquetes se cargan aquí para facilitar la instalación y revisión.
# Si alguno no está instalado: install.packages("nombre_del_paquete")
library(dplyr)             # manipulación de datos (filter, select, mutate, etc.)
library(sf)                # datos vectoriales espaciales (reemplaza sp, rgdal, maptools)
library(ggplot2)           # sistema de gráficos por capas
library(rnaturalearth)     # capas geográficas de países listas para usar
library(rnaturalearthdata) # datos internos que usa rnaturalearth
library(leaflet)           # mapas interactivos
library(rgbif)             # interfaz con la API de GBIF (reemplaza dismo::gbif)
library(terra)             # datos raster y vectoriales (reemplaza raster)
library(geodata)           # descarga de datos climáticos y ambientales

# file.exists() verifica si el archivo existe en el directorio de trabajo
# antes de intentar cargarlo, evitando errores poco claros más adelante.
# getwd() muestra el directorio actual si hay dudas sobre la ubicación.
if (!file.exists("Myrmecophaga.csv")) {
  stop("Archivo Myrmecophaga.csv no encontrado. 
       Verificar el directorio de trabajo con getwd()")
}

# fileEncoding = "latin1" es necesario cuando el archivo fue generado en
# Windows o con Excel en español. Estos programas guardan los archivos con
# codificación latin1 (también llamada ISO-8859-1) en lugar de UTF-8.
# Sin este argumento, los caracteres especiales como tildes (á, é) y la ñ
# aparecen como símbolos extraños o generan errores al graficar.
# Si no se sabe el encoding del archivo, se puede detectar con:
#   library(readr); guess_encoding("Myrmecophaga.csv")
myrdat <- read.csv("Myrmecophaga.csv",
                   header       = TRUE,
                   sep          = ";",
                   fileEncoding = "latin1")

summary(myrdat)

names(myrdat)

# as.factor() convierte una variable de texto ("character") a factor.
# Los factores son variables categóricas: R las trata de forma especial
# en resúmenes (muestra frecuencias por categoría) y en modelos estadísticos.
myrdat$country       <- as.factor(myrdat$country)
myrdat$stateprovince <- as.factor(myrdat$stateprovince)
myrdat$locality      <- as.factor(myrdat$locality)
myrdat$specificepithet <- as.factor(myrdat$specificepithet)

summary(myrdat)

# nrow() devuelve el número de filas del dataframe
n_antes <- nrow(myrdat)

# filter() del paquete dplyr conserva solo las filas que cumplen la condición.
# is.na() devuelve TRUE cuando el valor es NA (dato faltante).
# El operador "!" niega la condición: !is.na() conserva los que NO son NA.
# El operador "&" exige que AMBAS condiciones se cumplan simultáneamente.
myrdat <- myrdat %>%
    filter(!is.na(decimallatitude) & !is.na(decimallongitude))

## NOTA: esto no filtra nada
table(is.na(myrdat$decimallatitude))
table(is.na(myrdat$decimallongitude))

n_despues <- nrow(myrdat)

# cat() imprime texto y variables en la consola (más flexible que print)
# "\n" es un salto de línea
cat("Registros eliminados por coordenadas faltantes:", n_antes - n_despues, "\n")
cat("Registros restantes:", n_despues, "\n")

# El operador "|" significa "o": se conservan filas que cumplan ALGUNA condición
coords_invalidas <- myrdat %>%
  filter(decimallatitude  < -90  | decimallatitude  > 90 |
         decimallongitude < -180 | decimallongitude > 180)

if (nrow(coords_invalidas) > 0) {
  warning("¡Se detectaron coordenadas fuera de rango!")
  print(coords_invalidas)
} else {
  cat("Todas las coordenadas están dentro del rango válido.\n")
}


# Para esta especie, toda longitud positiva es sospechosa:
# implicaría que el punto está en el hemisferio este (África, Europa, Asia)
posible_inversion <- myrdat %>%
  filter(decimallongitude > 0)

if (nrow(posible_inversion) > 0) {
  cat("Registros con longitud positiva (posible inversión de coordenadas):\n")
  # Mostramos solo las columnas relevantes para el diagnóstico
  print(posible_inversion[, c("decimallongitude", "decimallatitude", "country")])
}

# %in% verifica si cada elemento de un vector está contenido en otro vector.
# Es equivalente a múltiples comparaciones con == unidas por |, pero más compacto.
# Ej: country %in% c("A","B") es lo mismo que country == "A" | country == "B"
paises_esperados <- c("Argentina", "Bolivia", "Brazil", "Colombia",
                      "Ecuador", "Guyana", "Panama", "Paraguay",
                      "Peru", "Suriname", "Trinidad and Tobago",
                      "Uruguay", "Venezuela")

## cuantos?
myrdat[!(myrdat[["country"]] %in% paises_esperados), ]

myrdat[myrdat[["country"]] %in% paises_esperados, ]

# El "!" niega %in%: conservamos los que NO están en la lista esperada
fuera_rango <- myrdat %>%
  filter(!country %in% paises_esperados)

if (nrow(fuera_rango) > 0) {
  cat("Registros en países fuera del área de distribución esperada:\n")
  print(fuera_rango[, c("decimallongitude", "decimallatitude", "country")])
}

## Chequear si realmente estan mal
myrdat[!(myrdat[["country"]] %in% paises_esperados), ]

##          country stateprovince                                       locality decimallatitude decimallongitude specificepithet Curso
## 5  United States         Texas             SAN ANTONIO ZOO (CAPTIVITY ANIMAL)            29.5            -98.5      tridactyla     1
## 33 United States    California                Santa Barbara Childs Estate Zoo            34.4           -119.7      tridactyla     1
## 34 United States    California                Santa Barbara Childs Estate Zoo            34.4           -119.7      tridactyla     1
## 54 United States    California Santa Barbara Santa Barbara Zoological Gardens            34.4           -119.7      tridactyla     1

## Sacar estos que son de zoologicos.

## Check if the place where they say is ok.

plot_dat <- function(df) {
    library(ggplot2)
    library(maps)

    world_map <- map_data("world")

    ggplot() +
        geom_polygon(data = world_map, 
                     aes(x = long, y = lat, group = group), 
                     fill = "lightgray", 
                     color = "white") +
                                        # Add your specific long/lat points
        geom_point(data = clean_dat, 
                   aes(x = decimallongitude, y = decimallatitude), 
                   color = "red", 
                   size = 3) +
                                        # Add text labels to the points
        geom_text(data = clean_dat,
                  aes(x = decimallongitude, y = decimallatitude, label = country), 
                  color = "darkblue", 
                  vjust = -1.2, size = 3) + # vjust moves text up so it doesn't cover the dot
        coord_fixed(1.3) +
        labs(x = "Longitude", 
             y = "Latitude") +
        theme_minimal()
}

plot_dat(clean_dat)

## Okey, Peru looks weird.
myrdat[myrdat$country == "Peru", ]

## The bad is this:
## 1     Peru          Amazonas                                            La Poza Rio Santiago          -77.75            -4.02      tridactyla     1
clean_dat <- clean_dat[!(clean_dat$country == "Peru" & clean_dat$decimallongitude > -5), ]

plot_dat(clean_dat)

## Se eliminan entonces esos 5 datos:
## Los 4 de US y uno de Peru-antartico.

clean_myrdat <- function(df) {
    df$country       <- as.factor(df$country)
    df$stateprovince <- as.factor(df$stateprovince)
    df$locality      <- as.factor(df$locality)
    df$specificepithet <- as.factor(df$specificepithet)

    paises_esperados <- c("Argentina", "Bolivia", "Brazil", "Colombia",
                          "Ecuador", "Guyana", "Panama", "Paraguay",
                          "Peru", "Suriname", "Trinidad and Tobago",
                          "Uruguay", "Venezuela")
    clean_df <- df[(df[["country"]] %in% paises_esperados), ]
    clean_df <- clean_df[!(clean_df$country == "Peru" & clean_df$decimallongitude > -5), ]
    clean_df
}

clean_dat <- clean_myrdat(myrdat)


## ----------------------------------------

# st_as_sf() convierte un dataframe con columnas de coordenadas en un objeto espacial.
# coords: indicamos qué columnas contienen longitud y latitud (SIEMPRE en ese orden: x, y)
# crs = 4326: código EPSG del sistema de referencia WGS84 (el estándar GPS global).
#             Cada sistema de coordenadas tiene un código EPSG único; 4326 es el más común
#             para datos con coordenadas en grados decimales a escala global.
# remove = FALSE: conserva las columnas originales de coordenadas en el dataframe,
#                 útil para poder exportar o verificar los valores numéricos luego
myrdat_sf <- st_as_sf(
  myrdat,
  coords = c("decimallongitude", "decimallatitude"),
  crs    = 4326,
  remove = FALSE
)

class(myrdat_sf) # Verificamos que el objeto es ahora de clase "sf"

# ne_countries() devuelve polígonos de países del mundo.
# scale = "medium": resolución media, buen equilibrio entre detalle y velocidad.
# returnclass = "sf": devuelve el mapa en formato sf, compatible con geom_sf()
world <- ne_countries(scale = "medium", returnclass = "sf")

# En ggplot2 los gráficos se construyen sumando capas con el operador "+"
# geom_sf() dibuja cualquier objeto espacial sf (puntos, líneas o polígonos)
# coord_sf() recorta el mapa a la extensión indicada (xlim=longitud, ylim=latitud)
# alpha = 0.7: transparencia de los puntos (0 = invisible, 1 = completamente opaco)
ggplot() +
  geom_sf(data = world, fill = "lightgray", color = "white", linewidth = 0.3) +
  geom_sf(data = myrdat_sf, color = "red", size = 2, alpha = 0.7) +
  coord_sf(xlim = c(-122, -2), ylim = c(-79, 36)) +
  theme_minimal() +
  labs(title = "Registros de Myrmecophaga tridactyla",
       x = "Longitud", y = "Latitud")

# leaflet() inicializa el mapa vacío con los datos como referencia
# addTiles() agrega el mapa base (OpenStreetMap por defecto, no requiere clave de API)
# addCircleMarkers() dibuja un círculo por cada punto de presencia
# popup: texto HTML que aparece al hacer clic; el "~" indica que es una fórmula
#        que accede a columnas del dataframe; paste() concatena texto y variables;
#        "<br>" es un salto de línea en HTML
## leaflet(myrdat_sf) %>%
##   addTiles() %>%
##   addCircleMarkers(
##     color  = "red",
##     radius = 4,
##     popup  = ~paste(
##       "<b>País:</b>",      country,
##       "<br><b>Provincia:</b>", stateprovince,
##       "<br><b>Localidad:</b>", locality,
##       "<br><b>Lat:</b>",   decimallatitude,
##       "<br><b>Lon:</b>",   decimallongitude
##     )
##   )

# Si identificás puntos a corregir o eliminar, ejecutá
# "CORRECCIONES MANUALES" y volvé a correr desde myrdat_sf <- st_as_sf... hasta acá.

# ── CORRECCIONES MANUALES ──────────────────────────────────────────
# Ejemplos
#Punto en Antártida: coordenadas invertidas, el registro real es Perú
#Fuente: verificado contra etiqueta del ejemplar (voucher XXXX)
myrdat <- myrdat %>%
  mutate(
    lat_temp         = decimallatitude,
    decimallatitude  = ifelse(decimallatitude < -10 & decimallongitude > -10, 
                              decimallongitude, decimallatitude),
    decimallongitude = ifelse(lat_temp < -10 & decimallongitude > -10, 
                              lat_temp, decimallongitude)
  ) %>%
  select(-lat_temp)

# Registros de EEUU: fuera del rango nativo confirmado, se eliminan
myrdat <- myrdat %>%
  filter(country != "United States")

## ----------------------------------------------------------------------

# # Guardamos el gráfico en un objeto "p" para pasárselo explícitamente a ggsave()
# # Si no se especifica plot=, ggsave() guarda el último gráfico mostrado
# p <- ggplot() +
#   geom_sf(data = world, fill = "lightgray", color = "white", linewidth = 0.3) +
#   geom_sf(data = myrdat_sf, color = "red", size = 2, alpha = 0.7) +
#   coord_sf(xlim = c(-122, -2), ylim = c(-79, 36)) +
#   theme_minimal() +
#   labs(title = "Registros de Myrmecophaga tridactyla",
#        x = "Longitud", y = "Latitud")
# 
# # width y height en pulgadas; dpi = resolución en puntos por pulgada
# # dpi = 300 es el estándar mínimo para figuras de publicación científica
# ggsave("Myrmecophaga_map.png", plot = p, width = 10, height = 8, dpi = 300)

# # occ_search() busca ocurrencias en GBIF aplicando filtros.
# # hasCoordinate = TRUE: descarta registros sin coordenadas (evita NAs desde el origen)
# # limit: número máximo de registros por consulta (el máximo permitido por GBIF es 100.000)
# L.cuyanus <- occ_search(
#   scientificName = "Liolaemus cuyanus",
#   hasCoordinate  = TRUE,
#   limit          = 500
# )
# 
# # El resultado de occ_search() es una lista con varios elementos.
# # Los datos de ocurrencias están en el elemento "$data" como dataframe.
# L.cuyanus_df <- L.cuyanus$data
# 
# # dim() muestra dimensiones: primer número = filas (registros), segundo = columnas
# dim(L.cuyanus_df)

# # select() elige las columnas que queremos conservar, reduciendo el dataframe
# # Nota: rgbif devuelve los nombres de columnas con mayúsculas iniciales
# #       (decimalLongitude, decimalLatitude), a diferencia del CSV local
# #       que usaba todo en minúsculas (decimallongitude, decimallatitude)
# L.cuyanus_limpio <- L.cuyanus_df %>%
#   select(species, decimalLongitude, decimalLatitude,
#          country, stateProvince, verbatimLocality,year) %>%
#   filter(!is.na(decimalLongitude) & !is.na(decimalLatitude))
# 
# dim(L.cuyanus_limpio)

# # Convertimos a objeto espacial sf con el mismo procedimiento que usamos antes
# L.cuyanus_sf <- st_as_sf(
#   L.cuyanus_limpio,
#   coords = c("decimalLongitude", "decimalLatitude"),
#   crs    = 4326
p# )
# 
# # Mapa interactivo para revisar la calidad de los datos descargados
# # El popup muestra atributos útiles para detectar errores o registros dudosos
# leaflet(L.cuyanus_sf) %>%
#   addTiles() %>%
#   addCircleMarkers(
#     color  = "blue",
#     radius = 4,
#     popup  = ~paste("País:", country,
#                     "<br>Provincia:", stateProvince,
#                     "<br>Localidad:", verbatimLocality,
#                     "<br>Año:", year)
#   )

## ----------------------------------------------------------------------
## BLOQUE 2
## ----------------------------------------------------------------------

if (!dir.exists("data/worldclim")) dir.create("data/worldclim", recursive = TRUE)

# worldclim_country(): descarga datos para un solo país.
# Útil cuando el área de estudio está dentro de un único país.
Ecuador <- worldclim_country("Ecuador", var = "tmin", path = "data/worldclim")

## plot las 12 capas de temperatura minima
plot(Ecuador) 


# worldclim_tile(): descarga el mosaico (tile) que contiene las coordenadas indicadas.
# Útil para áreas de estudio pequeñas que no justifican descargar datos globales.
# lat y lon indican un punto dentro del tile deseado (aquí: centro de Ecuador)
Mosaico <- worldclim_tile(var = "tmin", res = 5,
                          lat = -1.8, lon = -78,
                          path = "data/worldclim")
Mosaico
# plot(Mosaico)

# worldclim_global(): descarga las 19 variables bioclimáticas para todo el mundo.
# Es el más usado en modelado de distribución de especies.
# res = 5: resolución de 5 minutos de arco (~10 km en el ecuador).
# Resoluciones disponibles: 0.5, 2.5, 5 y 10 (minutos de arco)
dat_bio <- worldclim_global(var = "bio", res = 5, path = "data/worldclim")


# dat_bio es un SpatRaster con las 19 variables bioclimáticas apiladas.
# En terra no es necesario convertirlo con stack() como se hacía con el paquete raster:
# el objeto ya viene listo para usar.
dat_bio

# plot() sobre un SpatRaster muestra todas las capas en una grilla
plot(dat_bio)

class(dat_bio)   # Verificamos que es un SpatRaster (objeto de terra)

names(dat_bio)   # Nombres de las 19 capas bioclimáticas

# nlyr() devuelve el número de capas del SpatRaster
# (equivale a nlayers() del paquete raster, que ya no se recomienda usar)
nlyr(dat_bio)

## NOTE: "bio" is not documented in the function. But can find it here:
## https://www.worldclim.org/data/bioclim.html
## They are coded as follows:
## BIO1 = Annual Mean Temperature
## BIO2 = Mean Diurnal Range (Mean of monthly (max temp - min temp))
## BIO3 = Isothermality (BIO2/BIO7) (×100)
## BIO4 = Temperature Seasonality (standard deviation ×100)
## BIO5 = Max Temperature of Warmest Month
## BIO6 = Min Temperature of Coldest Month
## BIO7 = Temperature Annual Range (BIO5-BIO6)
## BIO8 = Mean Temperature of Wettest Quarter
## BIO9 = Mean Temperature of Driest Quarter
## BIO10 = Mean Temperature of Warmest Quarter
## BIO11 = Mean Temperature of Coldest Quarter
## BIO12 = Annual Precipitation
## BIO13 = Precipitation of Wettest Month
## BIO14 = Precipitation of Driest Month
## BIO15 = Precipitation Seasonality (Coefficient of Variation)
## BIO16 = Precipitation of Wettest Quarter
## BIO17 = Precipitation of Driest Quarter
## BIO18 = Precipitation of Warmest Quarter
## BIO19 = Precipitation of Coldest Quarter

# dat_bio[[1]] extrae la primera capa (bio1: Annual Mean Temperature)
# En WorldClim 2.1 la temperatura está en °C (a diferencia de versiones anteriores
# que la almacenaban en °C x 10 para ahorrar espacio). Verificar siempre las
# unidades en la documentación de la versión descargada:
# https://www.worldclim.org/data/v1.4/formats.html
plot(dat_bio[[1]])
title("Mean Annual Temperature (°C)")

# list.files() lista todos los archivos de una carpeta que cumplan un patrón.
# pattern = "tif$": selecciona archivos cuyo nombre TERMINA en "tif"
#           (el "$" en expresiones regulares significa "fin de cadena")
# full.names = TRUE: devuelve la ruta completa, no solo el nombre del archivo
water <- list.files(path = "wc2.1_2.5m_vapr", pattern = "tif$", full.names = TRUE)

water  # Verificamos que encontró los 12 archivos mensuales

# rast() con un vector de archivos crea un SpatRaster apilado con todas las capas.
# Equivale a stack() del paquete raster, pero más eficiente en memoria.
waterstack <- rast(water)

nlyr(waterstack)  # Debe ser 12 (uno por mes)

plot(waterstack)

# app() aplica una función pixel a pixel sobre todas las capas del SpatRaster.
# fun = mean: calcula el promedio de los 12 meses para cada pixel.
# Equivale a calc() del paquete raster.
# El resultado es un SpatRaster de una sola capa con el promedio anual.
watermean <- app(waterstack, fun = mean)

nlyr(watermean)  

plot(watermean)
title("Water vapor pressure (kPa) — promedio anual")

## ----------------------------------------------------------------

## This crops to South America.

# ext() define una extensión rectangular por sus límites geográficos.
# El orden de los argumentos es: xmin, xmax, ymin, ymax
# (izquierda, derecha, abajo, arriba) — o sea: lon_min, lon_max, lat_min, lat_max
# crop() recorta el SpatRaster a esa extensión
bio_SA <- crop(dat_bio, ext(-85, -35, -56, 13))
plot(bio_SA)

nlyr(bio_SA)
## 19 layers, because of the 19 BIO layers

# ext() aplicado sobre un SpatRaster extrae su extensión geográfica actual.
# Esto es útil para asegurarse de que dos capas tienen exactamente la misma extensión,
# lo cual es necesario para operaciones entre capas (suma, extracción de valores, etc.)
limites <- ext(bio_SA)

water_SA <- crop(watermean, limites)

# Las dos sentencias anteriores pueden anidarse en una sola línea:
# water_SA <- crop(watermean, ext(bio_SA))

old_par <- par(mar = c(3, 3, 3, 5))
on.exit(par(old_par))
plot(water_SA)
title("Water vapor pressure (kPa)")

res(dat_bio) 

res(watermean) 

# resample() ajusta resolución Y extensión de un raster para que coincida con otro.
# method = "bilinear": interpolación bilineal, recomendada para variables continuas
#          (temperatura, precipitación, presión de vapor).
#          Alternativa: method = "near" para variables categóricas (uso del suelo, etc.)
# "y" es la plantilla: watermean va a quedar con la resolución y extensión de dat_bio

watermean <- resample(watermean, dat_bio, method = "bilinear")

# writeRaster() guarda el raster en disco para reutilizarlo en futuras sesiones
# sin necesidad de recalcularlo. overwrite = TRUE permite sobreescribir si ya existe.
writeRaster(watermean, filename = "watermean_5m.tif", overwrite = TRUE)

# Verificamos que quedaron iguales
res(dat_bio)

res(watermean)

## ----------------------------------------------------------------------
## BLOQUE 3
## ----------------------------------------------------------------------

## This was before.
##
## myrdat_sf <- st_as_sf(
##   myrdat,
##   coords = c("decimallongitude", "decimallatitude"),
##   crs    = 4326,
##   remove = FALSE
## )

# Reproyectamos a Mercator (EPSG:3857), cuyas unidades son metros
xy_merc <- st_transform(myrdat_sf, crs = 3857)

# st_buffer() crea el buffer; dist en metros porque el CRS está en metros
# Reemplaza a raster::buffer(), que operaba directamente en grados
buf_merc <- st_buffer(xy_merc, dist = 700000)  # 700 km = 700 000 m

# st_union() disuelve los círculos solapados en un único polígono
buf_merc <- st_union(buf_merc)

# Volvemos a WGS84 para superponer con los rasters
buf_sf <- st_transform(buf_merc, crs = 4326)

plot(water_SA)
plot(buf_sf,    add = TRUE, border = "blue", lwd = 2)
plot(myrdat_sf, add = TRUE, col = "red", pch = 19, cex = 0.5)
title("Buffer de 700 km alrededor de presencias — Sudamérica", cex.main = 1)

# terra::spatSample() reemplaza raster::sampleRandom()
# method = "random": extrae celdas al azar
# na.rm  = TRUE: descarta celdas sin dato (océano, etc.)
# xy     = TRUE: guarda las coordenadas de cada punto muestreado
# as.points = TRUE: devuelve un SpatVector (objeto espacial de terra)
random1 <- spatSample(water_SA,
                      size      = 1000,
                      method    = "random",
                      na.rm     = TRUE,
                      xy        = TRUE,
                      as.points = TRUE)

class(random1)

summary(as.data.frame(random1))

plot(water_SA)
plot(random1, add = TRUE, cex = 0.3)
title("1000 puntos aleatorios en Sudamérica")

# as.data.frame() con geom = "XY" preserva las coordenadas en columnas x e y
random1_sf <- st_as_sf(random1)
class(random1_sf)

# ext() define la extensión rectangular (lon_min, lon_max, lat_min, lat_max)
ext_bsas <- ext(-64, -56, -41, -33)

random3 <- spatSample(water_SA,
                      size      = 200,
                      method    = "random",
                      na.rm     = TRUE,
                      xy        = TRUE,
                      ext       = ext_bsas,
                      as.points = TRUE)

## Aca estan como magic numbers los límites del mapa. Se han 
plot(water_SA, xlim = c(-70, -50), ylim = c(-42, -32))

plot(random3, add = TRUE, cex = 0.5, col = "darkblue")
title("200 puntos — área de Buenos Aires")

# plot(water_SA)
# e       <- draw()    # hacer clic dos veces sobre el mapa para definir el rectángulo
# random4 <- spatSample(water_SA, size = 1000, method = "random",
#                       na.rm = TRUE, xy = TRUE, ext = e, as.points = TRUE)
# plot(water_SA)
# plot(random4, add = TRUE)

# Convertimos el buffer sf → SpatVector para operar con terra
## Aca hay que pasar 'buf_sf' a SpatVector. Basicamente, pasar de 'sf' a 'terra'.
buf_sv <- vect(buf_sf)

# mask() asigna NA a todos los píxeles fuera del polígono.
# crop() recorta primero la extensión para ahorrar memoria (buena práctica).
# Partimos de water_SA, que ya está recortada a Sudamérica.
water_buf <- mask(crop(water_SA, buf_sv), buf_sv)

random6 <- spatSample(water_buf,
                      size      = 1000,
                      method    = "random",
                      na.rm     = TRUE,
                      xy        = TRUE,
                      as.points = TRUE)

plot(water_SA)
plot(buf_sf,    add = TRUE, border = "blue", lwd = 1.5)
plot(myrdat_sf, add = TRUE, col = "red",   pch = 19, cex = 0.4)
plot(random6,   add = TRUE, col = "black", pch = 20, cex = 0.3)
title("1000 puntos dentro del buffer de 700 km")

random7 <- spatSample(water_buf,
                      size      = 1000,
                      method    = "random",
                      na.rm     = TRUE,
                      xy        = TRUE,
                      as.points = TRUE)

# extract() recupera el valor del raster en cada punto del SpatVector
random7_v <- extract(water_SA, random7)
summary(random7_v)
hist(random7_v[, 2], main = "Distribución de presión de vapor — buffer",
     xlab = "kPa", col = "lightblue")

# ne_countries() devuelve polígonos de países del mundo
# returnclass = "sf": devuelve directamente un objeto sf
mundo   <- ne_countries(scale = "medium", returnclass = "sf")
map_URU <- mundo[mundo$iso_a3 == "URY", ]

plot(water_SA)
## need to select _what_ to plot from map_URU
plot(map_URU[ , c("iso_a3", "geometry")], add = TRUE, border = "darkgreen", lwd = 2)
title("Uruguay sobre capa de vapor de agua — Sudamérica", cex.main = 1)

## convert from WKT to SpatVector
uru_sv    <- vect(map_URU)
water_URU <- mask(crop(water_SA, uru_sv), uru_sv)

random8 <- spatSample(water_URU,
                      size      = 100,
                      method    = "random",
                      na.rm     = TRUE,
                      xy        = TRUE,
                      as.points = TRUE)

plot(water_SA, xlim = c(-61, -50), ylim = c(-40, -26))
plot(map_URU, add = TRUE, border = "darkgreen", lwd = 2)
plot(random8, add = TRUE, col = "purple", pch = 19, cex = 0.6)
title("100 puntos aleatorios — Uruguay")

random8_v <- extract(water_SA, random8)
summary(random8_v)

# Filtramos Ecuador directamente desde rnaturalearth, igual que hicimos con Uruguay.
# Esto evita depender de un archivo shapefile local.
ne_countries(scale = "medium", returnclass = "sf")

ecuador <- ne_countries(scale = "medium", returnclass = "sf") %>%
  subset(iso_a3 == "ECU")

# Si en otro contexto necesitaran leer un shapefile local, el equivalente sería:
# ecuador <- st_read("ruta/al/archivo.shp", quiet = TRUE)
# Si el archivo no tiene .prj: ecuador <- st_set_crs(ecuador, 4326)

plot(water_SA, xlim = c(-85, -70), ylim = c(-7, 3))
plot(ecuador, add = TRUE, border = "orange", lwd = 2)
title("Ecuador sobre capa SA")

ecuador_sv <- vect(ecuador)
water_ECU  <- mask(crop(water_SA, ecuador_sv), ecuador_sv)

random81 <- spatSample(water_ECU,
                       size      = 100,
                       method    = "random",
                       na.rm     = TRUE,
                       xy        = TRUE,
                       as.points = TRUE)

plot(water_SA, xlim = c(-85, -70), ylim = c(-7, 3))
plot(ecuador,  add = TRUE, border = "orange", lwd = 2)
plot(random81, add = TRUE, col = "blue", pch = 19, cex = 0.5)
title("100 puntos aleatorios en Ecuador")

random81_v <- extract(water_SA, random81)
summary(random81_v)

# Al pasar un SpatRaster con 19 capas, spatSample() extrae los valores
# de todas las capas simultáneamente para cada punto muestreado
random9 <- spatSample(bio_SA,
                      size      = 1000,
                      method    = "random",
                      na.rm     = TRUE,
                      xy        = TRUE,
                      as.points = TRUE)

# Para confirmar que extrae de las mismas coordenadas en cada capa,
# duplicamos una capa y verificamos que los valores sean idénticos:
s_prueba <- c(water_SA, water_SA)
names(s_prueba) <- c("layer1", "layer2")
prueba <- spatSample(s_prueba, size = 5, method = "random", na.rm = TRUE, xy = TRUE)
prueba   # layer1 y layer2 deben ser idénticos para cada fila

identical(prueba[["layer1"]], prueba[["layer2"]])


# BIO1 = Temperatura Media Anual (en °C en WorldClim 2.1)
plot(bio_SA[[1]])
title("Temperatura Media Anual (°C) en Sudamérica", cex.main = 1)
plot(random9, add = TRUE, cex = 0.2)

# as.data.frame() con geom = "XY" incluye las columnas x e y de las coordenadas
dat_random9 <- as.data.frame(random9, geom = "XY")

names(dat_random9)
dim(dat_random9)   # 1000 filas × (19 variables + x + y)

# sep = ";" para compatibilidad con Excel en español (que usa ";" como separador)
write.csv(dat_random9, "data/Random_bio19_SA.csv", row.names = FALSE)

# # Convertimos SpatVector → sf para usar st_write()
# random9_sf <- st_as_sf(random9)
# 
# # st_write() reemplaza raster::shapefile() y rgdal::writeOGR()
# # delete_layer = TRUE sobreescribe si el archivo ya existe
# st_write(random9_sf,
#          dsn          = "random9_bio19_SA.shp",
#          delete_layer = TRUE)
# 
# # Es normal ver un aviso "Field names abbreviated for ESRI Shapefile driver".
# # El formato .shp tiene un límite de 10 caracteres para nombres de columna,
# # por lo que sf abrevia automáticamente los nombres largos (ej: "wc2.1_5m_bio_1" → "wc2_5m_b_1").
# # El archivo se escribe correctamente; el aviso es solo informativo.
# 
# # Para ver la tabla de equivalencias entre nombres originales y abreviados:
# nombres_originales  <- names(random9_sf)
# nombres_abreviados  <- abbreviate(nombres_originales, minlength = 10)
# data.frame(original = nombres_originales, shapefile = nombres_abreviados)
# 
# # Por eso recomendamos guardar SIEMPRE también el .csv (ver sección anterior):
# # el .csv conserva los nombres completos y es más fácil de abrir en cualquier programa.
