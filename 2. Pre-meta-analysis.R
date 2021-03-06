source("1. Effect Size.R")
library(ggplot2)
library(cowplot)
library(ggrepel)
library(rcartocolor)
options(bitmapType="cairo")
# display_carto_all()
display_carto_pal(12, "Bold")
mycols <- carto_pal(12, "Bold")[c(4,2,1,7)]
mycols_vegsoil <- carto_pal(12, "Bold")[c(2,4)]
make_pct <- function(x) (exp(x) - 1) * 100

weighted.mean(dat$elevCO2,dat$vi); weighted.mean(dat$ambCO2,dat$vi)
weighted.mean(dat$nyears,dat$vi); median(dat$nyears)
### Global effect of eCO2 on SOC
summary(global <- rma.mv(yi, vi, data=dat, random = ~ 1 | Site / obs))
make_pct(coef(summary(global)))

# Nitrogen
Nm <- rma.mv(yi, vi, data=dat, mods=~N -1, random = ~ 1 | Site / obs)
Nm
make_pct(coef(summary(Nm)))
Nm.n <- dat %>%  group_by(N) %>% summarise(n = n())
Nm.df <- coef(summary(Nm)) %>% mutate(type="Nitrogen fertilization", 
                                          factor=as.factor(c("Yes", "No")),
                                          size=Nm.n$n)

# Soil C stocks
library(funModeling)
dat$stocks_categorical <- funModeling::equal_freq(dat$amb, 3)
stocks <- rma.mv(yi, vi, data=dat, mods=~stocks_categorical -1, random = ~ 1 | Site / obs)
stocks
make_pct(coef(summary(stocks)))
stocks.n <- dat %>%  group_by(stocks_categorical) %>% summarise(n = n())
stocks.df <- coef(summary(stocks)) %>% mutate(type="Soil C stocks", 
                                      factor=levels(dat$stocks_categorical),
                                      size=stocks.n$n)
# Ecosystem.type
Ecom <- rma.mv(yi, vi, data=dat, mods=~Ecosystem.type -1,  random = ~ 1 | Site / obs, subset= Ecosystem.type !="Wetland")
Ecom
anova(Ecom, L=c(0,1,0,-1))
make_pct(coef(summary(Ecom)))
Ecom.n <- dat %>%  group_by(Ecosystem.type) %>% summarise(n = n())
Ecom.df <- coef(summary(Ecom)) %>% mutate(type="Ecosystem type", 
                                          factor=levels(as.factor(dat$Ecosystem.type))[1:4],
                                          size=Ecom.n$n[1:4])

# Experiment.type
Expm <- rma.mv(yi, vi, data=dat, mods=~Experiment_type -1,  random = ~ 1 | Site / obs)
Expm
anova(Expm, L=c(1,-1,0))
anova(Expm, L=c(1,0,-1))
make_pct(coef(summary(Expm)))
Expm.n <- dat %>%  group_by(Experiment_type) %>% summarise(n = n())
Expm.df <- coef(summary(Expm)) %>% mutate(type="Experiment type", 
                                              factor=levels(as.factor(dat$Experiment_type)),
                                              size=Expm.n$n)
# Biome
Biomem <- rma.mv(yi, vi, data=dat, mods=~Biome -1,  random = ~ 1 | Site / obs)
Biomem
make_pct(coef(summary(Biomem)))
Biomem.n <- dat %>%  group_by(Biome) %>% summarise(n = n())
Biomem.df <- coef(summary(Biomem)) %>% mutate(type="Biome", 
                                                          factor=levels(as.factor(dat$Biome)),
                                                          size=Biomem.n$n)
# Disturbance
Disturbancem <- rma.mv(yi, vi, data=dat, mods=~Disturbance -1,  random = ~ 1 | Site / obs)
Disturbancem
anova(Disturbancem, L=c(1,-1))
make_pct(coef(summary(Disturbancem)))
Disturbancem.n <- dat %>%  group_by(Disturbance) %>% summarise(n = n())
Disturbancem.df <- coef(summary(Disturbancem)) %>% mutate(type="Disturbance", 
                                          factor=c("Disturbed","Intact"),
                                          size=Disturbancem.n$n)

# Myc
Mycm <- rma.mv(yi, vi, data=dat, mods=~Myc -1,  random = ~ 1 | Site / obs, subset= Myc != "NM")
Mycm
anova(Mycm, L=c(1,0,-1,0))
make_pct(coef(summary(Mycm)))
Mycm.n <- dat %>%  group_by(Myc) %>% summarise(n = n()) %>% filter(Myc != "NM")
Mycm.df <- coef(summary(Mycm)) %>% mutate(type="Nutrient-acquisition strategy", 
                                          factor=c("AM","AM-ER","ECM","N-fixer"),
                                          size=Mycm.n$n) %>%
        mutate(factor =  factor(factor, levels = c("AM", "ECM", "AM-ER", "N-fixer"))) %>%
        arrange(factor) 
NMyc <- rma.mv(yi, vi, data=dat, mods=~Myc -1, random = ~ 1 | Site / obs, subset=N=="Nlow")
NMyc
make_pct(coef(summary(NMyc)))
#### META PLOT ####
meta.df <- bind_rows(Ecom.df, Nm.df, stocks.df, Expm.df, Disturbancem.df, Mycm.df)

png("graphs/figure1.png",height=6, width=3, units ="in", res = 800, type = "cairo")
par(mar=c(4,4,1,2))
forest(x=meta.df$estimate,sei=meta.df$se,slab=meta.df$factor, 
       annotate=FALSE, 
       xlim=c(-30, 20),
       ilab=paste0("(",meta.df$size,")"),ilab.xpos=-13,
       psize=1,transf=make_pct, at=c(-10, 0, 10, 20), xlab=expression(paste(CO[2]," effect on soil carbon (%)", sep="")),
       subset=18:1, rows=c(1:4,7:8,11:13,16:18,21:22,25:28),ylim=c(-1, 32),cex=0.75)
text(-30, c(5,9,14,23,29), pos=4, c("Nutrient strategy","Disturbance","Experiment type",  "Nitrogen fertilization","Ecosystem type"),
     font=2, cex=0.75)
text(-30, 19, pos=4, expression(bold(paste("Soil C stocks (g m" ^-2,")"))),cex=0.75)
addpoly(global, row= -1, cex=0.75, transf=make_pct, mlab="",annotate=FALSE)
text(-30, -1, pos=4, font=2, cex=0.75, "Overall effect")
dev.off()


cairo_pdf("graphs/figure1.pdf", height=6, width=3, bg="transparent",fallback_resolution = 800)
par(mar=c(4,4,1,2))
forest(x=meta.df$estimate,sei=meta.df$se,slab=meta.df$factor, 
       annotate=FALSE, 
       xlim=c(-30, 20),
       ilab=paste0("(",meta.df$size,")"),ilab.xpos=-13,
       psize=1,transf=make_pct, at=c(-10, 0, 10, 20), xlab=expression(paste(CO[2]," effect on soil carbon (%)", sep="")),
       subset=18:1, rows=c(1:4,7:8,11:13,16:18,21:22,25:28),ylim=c(-1, 32),cex=0.75)
text(-30, c(5,9,14,23,29), pos=4, c("Nutrient strategy","Disturbance","Experiment type",  "Nitrogen fertilization","Ecosystem type"),
     font=2, cex=0.75)
text(-30, 19, pos=4, expression(bold(paste("Soil C stocks (g m" ^-2,")"))),cex=0.75)
addpoly(global, row= -1, cex=0.75, transf=make_pct, mlab="",annotate=FALSE)
text(-30, -1, pos=4, font=2, cex=0.75, "Overall effect")
dev.off()

