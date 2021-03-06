library(rgdal)
library(dplyr)
library(leaflet)
library(readxl)
library(leaflet.extras)
nys_spdf <- readOGR( 
  dsn= paste0(getwd(),"/dataset/Map/NYS") , 
  layer="cty036",
  verbose=FALSE
)
# Loading Geographic Data
nys_geo <- nys_spdf@data[,c('NAME', 'POP2000')]
lat = c()
lng = c()
for (i in c(1:67)){
  coord = nys_spdf@polygons[[i]]@labpt
  lat <- append(lat, coord[2])
  lng <- append(lng, coord[1])
}
nys_geo$lati <- lat
nys_geo$long <- lng
nys_geo <- nys_geo %>% group_by(NAME) %>%
  summarize(lati = mean(lati, na.rm=TRUE), long = mean(long, na.rm=TRUE))

# Loading Covid Case Data
nys_case <- read.csv("./dataset/Covid/NYS_Covid_Case.csv",
                     , sep=",", dec=".")

# Loading Work_Residence Data
commute <-
  read_excel("./dataset/Work_Residence/Work_Residence.xlsx")  
commute$commuter <- commute$Worked_outside_PoR / commute$Total_Labor

info<-merge(x=nys_case, y=commute, by.x="County", by.y = "Geographic", all= T)
info<-merge(x=info, y=nys_geo, by.x="County", by.y = "NAME", all= T)
info <- as_tibble(info)

order <- nys_spdf@data$NAME
nys_spdf@data <- merge(x=nys_spdf@data, y=commute,
                       by.x="NAME", by.y = "Geographic",
                       all= T, sort=FALSE)

nys_spdf@data <- nys_spdf@data %>%
  slice(match(order, NAME))

info$TestDate <- as.Date(as.character(info$TestDate), format = "%m/%d/%y")

info$sqtcum <- sqrt(info$Cumulative_Positives)
info$logcum <- log(info$Cumulative_Positives+1)
info$sqtnew <- sqrt(info$New_Positives)
info$lognew <- log(info$New_Positives+1)

bin_max = max(info$commuter)
bin_min = min(info$commuter)

info_final <- info[info$TestDate == '2020-11-28',]
info_final <- as_tibble(info_final)

palette <- colorBin(c('#fee0d2',  
                      '#fcbba1',
                      '#fc9272',
                      '#fb6a4a',
                      '#ef3b2c',
                      '#cb181d',
                      '#a50f15',
                      '#67000d'), 
                    bins = c(bin_min, bin_max/8, 2*bin_max/8,
                             3*bin_max/8, 4*bin_max/8,
                             5*bin_max/8, 6*bin_max/8,
                             7*bin_max/8, bin_max))

info_mar <- info[info$TestDate <= '2020-03-28',]
monthly <- info_mar %>% group_by(County) %>% summarize(monthly = sum(New_Positives))
info_mar <-merge(x=info_mar, y=monthly, by.x="County", by.y = "County", all= T)
info_mar <- as_tibble(info_mar)

info_apr <- info[(info$TestDate > '2020-03-28')&(info$TestDate <= '2020-04-28'),]
monthly <- info_apr %>% group_by(County) %>% summarize(monthly = sum(New_Positives))
info_apr <-merge(x=info_apr, y=monthly, by.x="County", by.y = "County", all= T)
info_apr <- as_tibble(info_apr)

info_may <- info[(info$TestDate > '2020-04-28')&(info$TestDate <= '2020-05-28'),]
monthly <- info_may %>% group_by(County) %>% summarize(monthly = sum(New_Positives))
info_may <-merge(x=info_may, y=monthly, by.x="County", by.y = "County", all= T)
info_may <- as_tibble(info_may)

info_jun <- info[(info$TestDate > '2020-05-28')&(info$TestDate <= '2020-06-28'),]
monthly <- info_jun %>% group_by(County) %>% summarize(monthly = sum(New_Positives))
info_jun <-merge(x=info_jun, y=monthly, by.x="County", by.y = "County", all= T)
info_jun <- as_tibble(info_jun)

info_jul <- info[(info$TestDate > '2020-06-28')&(info$TestDate <= '2020-07-28'),]
monthly <- info_jul %>% group_by(County) %>% summarize(monthly = sum(New_Positives))
info_jul <-merge(x=info_jul, y=monthly, by.x="County", by.y = "County", all= T)
info_jul <- as_tibble(info_jul)

info_aug <- info[(info$TestDate > '2020-07-28')&(info$TestDate <= '2020-08-28'),]
monthly <- info_aug %>% group_by(County) %>% summarize(monthly = sum(New_Positives))
info_aug <-merge(x=info_aug, y=monthly, by.x="County", by.y = "County", all= T)
info_aug <- as_tibble(info_aug)

info_sep <- info[(info$TestDate > '2020-08-28')&(info$TestDate <= '2020-09-28'),]
monthly <- info_sep %>% group_by(County) %>% summarize(monthly = sum(New_Positives))
info_sep <-merge(x=info_sep, y=monthly, by.x="County", by.y = "County", all= T)
info_sep <- as_tibble(info_sep)

info_oct <- info[(info$TestDate > '2020-09-28')&(info$TestDate <= '2020-10-28'),]
monthly <- info_oct %>% group_by(County) %>% summarize(monthly = sum(New_Positives))
info_oct <-merge(x=info_oct, y=monthly, by.x="County", by.y = "County", all= T)
info_oct <- as_tibble(info_oct)

info_nov <- info[(info$TestDate > '2020-10-28')&(info$TestDate <= '2020-11-28'),]
monthly <- info_nov %>% group_by(County) %>% summarize(monthly = sum(New_Positives))
info_nov <-merge(x=info_nov, y=monthly, by.x="County", by.y = "County", all= T)
info_nov <- as_tibble(info_nov)

# Construct Leaflet Map
mymap <- leaflet() %>% 
  addProviderTiles("Esri.WorldGrayCanvas",
                   options = tileOptions(minZoom=2, maxZoom=10)
  )%>%
  addPolygons(data = nys_spdf, 
              fillColor = ~palette(nys_spdf@data$commuter),
              fillOpacity = 0.6,         ## how transparent do you want the polygon to be?
              color = "darkgrey",       ## color of borders between districts
              weight = 1.5,            ## width of borders
              group="background_group",
              label = nys_spdf@data$NAME,
              popup = ~ paste0("<b>", nys_spdf@data$NAME, 
                               "</b><br>Total Labor: <br>", nys_spdf@data$Total_Labor,
                               "</b><br>Outside PoR: <br>", nys_spdf@data$Worked_outside_PoR)
  )%>%
  addCircleMarkers(
    group = "2020-Mar",
    data = info_mar,
    lng = ~long,
    lat = ~lati, 
    radius = ~1.3*log(monthly+1)+1, 
    color = "Teal",
    fillOpacity=0.1,
    stroke = FALSE, 
    popup = ~ paste0("<b>", County, "</b><br>Monthly Confirmed Cases: <br>", monthly)
  )%>%
  addCircleMarkers(
    group = "2020-Apr",
    data = info_apr,
    lng = ~long,
    lat = ~lati, 
    radius = ~1.3*log(monthly+1)+1, 
    color = "Teal", 
    opacity = 0.6,
    stroke = FALSE, 
    popup = ~ paste0("<b>", County, "</b><br>Monthly Confirmed Cases: <br>", monthly)
  )%>%
  addCircleMarkers(
    group = "2020-May",
    data = info_may,
    lng = ~long,
    lat = ~lati, 
    radius = ~1.3*log(monthly+1)+1, 
    color = "Teal", 
    opacity = 0.6,
    stroke = FALSE, 
    popup = ~ paste0("<b>", County, "</b><br>Monthly Confirmed Cases: <br>", monthly)
  )%>%
  addCircleMarkers(
    group = "2020-Jun",
    data = info_jun,
    lng = ~long,
    lat = ~lati, 
    radius = ~1.3*log(monthly+1)+1, 
    color = "Teal", 
    opacity = 0.6,
    stroke = FALSE, 
    popup = ~ paste0("<b>", County, "</b><br>Monthly Confirmed Cases: <br>", monthly)
  )%>%
  addCircleMarkers(
    group = "2020-Jul",
    data = info_jul,
    lng = ~long,
    lat = ~lati, 
    radius = ~1.3*log(monthly+1)+1, 
    color = "Teal",
    opacity = 0.6,
    stroke = FALSE, 
    popup = ~ paste0("<b>", County, "</b><br>Monthly Confirmed Cases: <br>", monthly)
  )%>%
  addCircleMarkers(
    group = "2020-Aug",
    data = info_aug,
    lng = ~long,
    lat = ~lati, 
    radius = ~1.3*log(monthly+1)+1, 
    color = "Teal", 
    opacity = 0.6,
    stroke = FALSE, 
    popup = ~ paste0("<b>", County, "</b><br>Monthly Confirmed Cases: <br>", monthly)
  )%>%
  addCircleMarkers(
    group = "2020-Sep",
    data = info_sep,
    lng = ~long,
    lat = ~lati, 
    radius = ~1.3*log(monthly+1)+1, 
    color = "Teal",
    opacity = 0.6,
    stroke = FALSE, 
    popup = ~ paste0("<b>", County, "</b><br>Monthly Confirmed Cases: <br>", monthly)
  )%>%
  addCircleMarkers(
    group = "2020-Oct",
    data = info_oct,
    lng = ~long,
    lat = ~lati, 
    radius = ~1.3*log(monthly+1)+1, 
    color = "Teal", 
    opacity = 0.6,
    stroke = FALSE, 
    popup = ~ paste0("<b>", County, "</b><br>Monthly Confirmed Cases: <br>", monthly)
  )%>%
  addCircleMarkers(
    group = "2020-Nov",
    data = info_nov,
    lng = ~long,
    lat = ~lati, 
    radius = ~1.3*log(monthly+1)+1, 
    color = "Teal",
    opacity = 0.6,
    stroke = FALSE, 
    popup = ~ paste0("<b>", County, "</b><br>Monthly Confirmed Cases: <br>", monthly)
  )%>%
  addLayersControl(
    baseGroups = c("2020-Mar", "2020-Apr", "2020-May", "2020-Jun", "2020-Jul", "2020-Aug",
                   "2020-Sep", "2020-Oct", "2020-Nov"), 
    position = "bottomleft", 
    options = layersControlOptions(collapsed = FALSE)
  )%>% 
  addLegend(position = 'topright', 
            colors = c('#fee0d2',
                       '#fcbba1',
                       '#fc9272',
                       '#fb6a4a',
                       '#ef3b2c',
                       '#cb181d',
                       '#a50f15',
                       '#67000d'), 
            labels = c(paste(trunc(100*bin_min), '%', sep=""),"","","",
                       "","","",paste(trunc(100*bin_max), '%', sep="")),  
            opacity = 0.6,      
            title = "Labor working <br>outside county<br> of residence"
  )%>%
  addLegend(position = 'topleft',
            colors = 'Teal',
            labels = "New Postive <br>During the Month"
  )%>%
  addResetMapButton()
mymap  