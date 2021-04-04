library('shiny')               # создание интерактивных приложений
library('lattice')             # графики lattice
library('data.table')          # работаем с объектами "таблица данных"
library('ggplot2')             # графики ggplot2
library('dplyr')               # трансформации данных
library('lubridate')           # работа с датами, ceiling_date()
library('zoo')                 # работа с датами, as.yearmon()
library('stringr')
library('gridExtra')

# API comtrade un, функция
source("https://raw.githubusercontent.com/aksyuk/R-data/master/API/comtrade_API.R")

# Получаем данные с UN COMTRADE за период 2010-2020 года, по следующим кодам
code = c('0201', '0202', '0203', '0204', '0205', '0206')

data <- data.frame()

for (i in code){
  print(i)
  for (j in 2010:2020){
    Sys.sleep(5)
    s1 <- get.Comtrade(r = 'all', p = 643,
                       ps = as.character(j), freq = "M",
                       cc = i, fmt = 'csv')
    data <- rbind(data, s1$data)
    print(j)
  }
}

data.dir <- './data'

# Создаем директорию для данных
if (!file.exists(data.dir)) {
  dir.create(data.dir)
}

# Загружаем полученные данные в файл, чтобы не выгружать их в дальнейшем заново
file.name <- paste('./data/dannye.csv', sep = '')
write.csv(data, file.name, row.names = FALSE)

write(paste('Файл',
            paste('dannye.csv', sep = ''),
            'загружен', Sys.time()), file = './data/download.log', append=TRUE)

data <- read.csv('./data/dannye.csv', header = T, sep = ',')
data <- data[, c(2, 4, 8, 10, 22, 30)]

data <- data[!is.na(data$Netweight..kg.), ]
data

data.1 <- data.frame()
data.2 <- data.frame()
for (year in 2010:2020){
  for (m in month.name[1:6]){
    data.1 <- rbind(data.1, cbind(data[data$Year == year & str_detect(data$Period.Desc., m), ], data.frame(Period = 'янв-авг')))
  }
  for (m in month.name[7:12]){
    data.2 <- rbind(data.2, cbind(data[data$Year == year & str_detect(data$Period.Desc., m), ], data.frame(Period = 'сен-дек')))
  }
}

data <- rbind(data.1, data.2)
data

# Коды товаров
filter.1 <- as.character(unique(data$Commodity.Code))
names(filter.1) <- filter.1
filter.1 <- as.list(filter.1)
filter.1

# Товарные потоки
filter.2 <- as.character(unique(data$Trade.Flow))
names(filter.2) <- filter.2
filter.2 <- as.list(filter.2)
filter.2

file.name <- paste('./data/dannye_2.csv', sep = '')
write.csv(data, file.name, row.names = FALSE)

data <- read.csv('./data/dannye_2.csv', header = T, sep = ',')
data

data.filter <- data[data$Commodity.Code == filter.1[2] & data$Trade.Flow == filter.2[2], ]
data.filter

ggplot(data.filter, aes(y = Netweight..kg., group = Period, color = Period)) +
  geom_density() +
  coord_flip() + scale_color_manual(values = c('red', 'blue'),
                                    name = 'Период') +
  labs(title = 'График плотности массы поставок по годам',
       y = 'Масса', x = 'Плотность')

# Запуск приложения
runApp('./comtrade_un', launch.browser = TRUE,
       display.mode = 'showcase')
