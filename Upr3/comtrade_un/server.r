library('shiny')
library('dplyr')
library('data.table')
library('RCurl')
library('ggplot2')
library('lattice')
library('zoo')
library('lubridate')

data <- read.csv('dannye_2.csv', header = T, sep = ',')

data <- data.table(data)


shinyServer(function(input, output){
  DT <- reactive({
    DT <- data[between(Year, input$year.range[1], input$year.range[2]) &
               Commodity.Code == input$sp.to.plot &
               Trade.Flow == input$trade.to.plot, ]
    DT <- data.table(DT)
  })
  output$sp.ggplot <- renderPlot({
    ggplot(data = DT(), aes(y = Netweight..kg., group = Period, color = Period)) +
      geom_density() +
      coord_flip() + scale_color_manual(values = c('red', 'blue'),
                                        name = 'Период') +
      labs(title = 'График плотности массы поставок по годам',
           y = 'Масса', x = 'Плотность')
  })
})