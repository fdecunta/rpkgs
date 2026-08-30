# This starts with a comment!
source("config.R")

library(lattice)
library(nlme) # this pkg is for some stuff, and this is a comment
library(emmeans); library(multcomp) # this are two library calls in a line
library(
	ggplot2
)

pacman::p_load(knitr, # my gradnma used to knit
               metafor, 
               patchwork, # layout of plots
               cowplot, 
               ggpubr,
               gridExtra,
               #orchaRd, 
               gridGraphics, 
               here,
               #boot, # comment this again for weirdness
               ggthemes,
               vcd,
               statpsych
               )
