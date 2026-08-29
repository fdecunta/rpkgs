# This starts with a comment!
source("config.R")

library(lattice)
library(nlme) # this pkg is for some stuff, and this is a comment
library(emmeans); library(multcomp)
library(
	ggplot2
)

knitr::opts_chunk$set(echo = TRUE, include = TRUE)
# Loading packages
pacman::p_load(knitr, # knit markdown
               metafor, 
               patchwork, # layout of plots
               cowplot, 
               ggpubr,
               gridExtra,
               #orchaRd, # forest-like plot
               gridGraphics, # Redraw Base Graphics Using 'grid' Graphics. `gridGraphics` is required to handle base-R plots.
               here,
               #boot, # Bootstrap Resampling
               ggthemes,
               vcd,
               statpsych
               )

dat <- read.csv("../data/data_exp2024.csv")

dat[["endophyte"]] <- as.factor(dat[["endophyte"]])
dat[["root_herb"]] <- as.factor(dat[["root_herb"]])
dat[["foliar_herb"]] <- as.factor(dat[["foliar_herb"]])
dat[["bloque"]] <- as.factor(dat[["bloque"]])

dat[["shoot_root"]] <- dat$ag_biomass / dat$root_biomass
dat[["total_biom"]] <- dat$ag_biomass + dat$root_biomass

## Total Biomass

summary(dat[["total_biom"]])

dotchart(dat[["total_biom"]])

coplot(total_biom ~ endophyte | root_herb * foliar_herb, data = dat)

### Modelling

options(contrasts = c("contr.sum", "contr.poly"))

#### Variance structure selection (ML)

totbiom_0 <- lme(total_biom ~ endophyte * root_herb * foliar_herb,
            random = ~ 1 | bloque,
            method = "ML",
            data = dat)

totbiom_1 <- lme(total_biom ~ endophyte * root_herb * foliar_herb,
            random = ~ 1 | bloque,
            weights = varIdent(form = ~ 1 | endophyte),
            method = "ML",
            data = dat)

totbiom_2 <- lme(total_biom ~ endophyte * root_herb * foliar_herb,
            random = ~ 1 | bloque,
            weights = varIdent(form = ~ 1 | root_herb),
            method = "ML",
            data = dat)

totbiom_3 <- lme(total_biom ~ endophyte * root_herb * foliar_herb,
            random = ~ 1 | bloque,
            weights = varIdent(form = ~ 1 | endophyte * foliar_herb),
            method = "ML",
            data = dat)

AIC(totbiom_0, totbiom_1, totbiom_2, totbiom_3)
