library(rgdal)
library(dplyr)
library(leaflet)

nys_spdf <- readOGR( 
  dsn= paste0(getwd(),"/dataset/Map/NYS") , 
  layer="cty036",
  verbose=TRUE
)
nys_poly <- nys_spdf@polygons

nys_case <- 
  read.csv("./dataset/Covid/NYS_Covid_Case.csv",
           , sep=",", dec=".")

nys_case_1 <- nys_case[nys_case$Test.Date == '04/14/2020',]
nys_case_2 <- nys_case[nys_case$Test.Date == '05/14/2020',]
nys_case_3 <- nys_case[nys_case$Test.Date == '06/14/2020',]

bin_max = max(nys_case$New.Positives)
bin_min = min(nys_case$New.Positives)
palette <- colorBin(c('#fee0d2',  
                      '#fcbba1',
                      '#fc9272',
                      '#fb6a4a',
                      '#ef3b2c',
                      '#cb181d',
                      '#a50f15',
                      '#67000d'), 
                    bins = c(0, bin_max/8, 2*bin_max/8,
                             3*bin_max/8, 4*bin_max/8,
                             5*bin_max/8, 6*bin_max/8,
                             7*bin_max/8, bin_max))

mymap <- leaflet() %>% 
  addProviderTiles("Esri.WorldGrayCanvas",
                   options = tileOptions(minZoom=1, maxZoom=10)) %>%
  addPolygons(data = nys_spdf, 
            fillColor = ~palette(nys_case_1$New.Positives),
            fillOpacity = 0.6,         ## how transparent do you want the polygon to be?
            color = "darkgrey",       ## color of borders between districts
            weight = 1.5,            ## width of borders
            group="date1")%>%
  addPolygons(data = nys_spdf, 
            fillColor = ~palette(nys_case_2$New.Positives),
            fillOpacity = 0.6,         ## how transparent do you want the polygon to be?
            color = "darkgrey",       ## color of borders between districts
            weight = 1.5,            ## width of borders
            group="date2")%>%  
  addPolygons(data = nys_spdf, 
            fillColor = ~palette(nys_case_3$New.Positives),
            fillOpacity = 0.6,         ## how transparent do you want the polygon to be?
            color = "darkgrey",       ## color of borders between districts
            weight = 1.5,            ## width of borders
            group="date3")%>%
  addLayersControl(
    overlayGroups =c("date1", "date2", "date3"),
    options = layersControlOptions(collapsed=FALSE))%>%
  addLegend(position = 'topleft', 
            colors = c('#fee0d2',
                       '#fcbba1',
                       '#fc9272',
                       '#fb6a4a',
                       '#ef3b2c',
                       '#cb181d',
                       '#a50f15',
                       '#67000d'), 
            labels = c('0%',"","","","","","",'100%'),  
            opacity = 0.6,      
            title = "relative<br>amount")   
mymap