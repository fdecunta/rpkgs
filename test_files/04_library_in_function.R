library(dplyr)
library(sf)
library(ggplot2)
library(rnaturalearth)
library(rnaturalearthdata)
library(leaflet)
library(rgbif)
library(terra)
library(geodata)

plot_dat <- function(df) {
    library(ggplot2)
    library(maps)

    world_map <- map_data("world")

    ggplot() +
        geom_polygon(data = world_map, 
                     aes(x = long, y = lat, group = group), 
                     fill = "lightgray", 
                     color = "white") +
        geom_point(data = clean_dat, 
                   aes(x = decimallongitude, y = decimallatitude), 
                   color = "red", 
                   size = 3) +
        geom_text(data = clean_dat,
                  aes(x = decimallongitude, y = decimallatitude, label = country), 
                  color = "darkblue", 
                  vjust = -1.2, size = 3) + 
        coord_fixed(1.3) +
        labs(x = "Longitude", 
             y = "Latitude") +
        theme_minimal()
}

plot_dat(clean_dat)

