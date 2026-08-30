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
