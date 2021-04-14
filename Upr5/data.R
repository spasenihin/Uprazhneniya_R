# Скрипт парсинга WDI, Портала открытых данных РФ и Yandex.Карты
# Население беженцев в разбивке по странам или территориям происхождения
library('httr')
library('jsonlite')
library('XML')
library('RCurl')
library('WDI')
library('data.table')

# Индикатор показателя
indicator.code <- 'SM.POP.REFG.OR'

dat <- WDI(indicator = indicator.code, start = 2019, end = 2019)

# Загружаем данные
df <- data.table(dat)

# Загружаем данные в .csv файл
write.csv(df, file = './data/data1.csv', row.names = F)

# Портал открытых данных РФ

API.key <- 'f617fa2f0f198be3cfc3e788ff348104'
URL.base <- 'http://data.gov.ru/api/'

# Функция для работы с API портала открытых данных РФ
getOpenDataRF <- function(api.params, url.base = URL.base, api.key = API.key){
  par <- paste0(api.params, collapse = '/')
  url <- paste0(url.base, par, '/?access_token=', api.key)
  message(paste0('Загружаем ', url, ' ...'))
  resp <- GET(url)
  fromJSON(content(resp, 'text'))
}

# id: Перечень учреждений дошкольного образования
dataset_id <- '8911021440-biblioteki'

# Задаем параметры и получаем данные
params <- c('dataset', dataset_id)
dataset <- getOpenDataRF(params)

# Количество версий таблицы
params <- c(params, 'version')
versions <- getOpenDataRF(params)

nrow(versions)

# Загружаем последнюю версию в объект doc
mrv <- versions[nrow(versions), 1]
params <- c(params, mrv)
content <- c(params, 'content')
doc <- getOpenDataRF(content)
colnames(doc)[3] <- 'Address'

# Оставляем только те данные в которых присутствует поселок Пурпе
doc <- doc[grep('поселок Пурпе', doc$Address), ]

head(doc)

API.key <- '13ae988e-8470-4547-b9c0-41dd74d8cc5e'
URL.base <- 'https://geocode-maps.yandex.ru/1.x/'

# Функция для работы с API Yandex Карт
getYandexMaps <- function(api.params, url.base = URL.base, api.key = API.key){
  par <- paste0(api.params, collapse = '&')
  url <- paste0(url.base, '?format=xml&apikey=', api.key, par)
  message(paste0('Загружаем ', url, ' ...'))
  doc.ya <- content(GET(url), 'text', encoding = 'UTF-8')
  
  rootNode <- xmlRoot(xmlTreeParse(doc.ya, useInternalNodes = TRUE))
  coords <- xpathSApply(rootNode, "//*[name()='Envelope']/*", xmlValue)
  coords <- lapply(strsplit(coords, ' '), as.numeric)
  coords <- c((coords[[1]][1] + coords[[2]][1])/2, (coords[[1]][2] + coords[[2]][2])/2)
  names(coords) <-c('lat', 'long')
  coords
}

# Задаем параметры
params <-paste0('&geocode=', gsub(pattern =' ', replacement ='+',
                                  curlEscape(doc$Address[1])))


# Парсим координаты
coords <- sapply(as.list(doc$Address), function(x){
  params <- paste0('&geocode=', gsub(curlEscape(x), pattern = ' ',
                                     replacement = '+'))
  try(getYandexMaps(params))
})

df.coords <- as.data.frame(t(coords))
colnames(df.coords) <- c('long', 'lat')

#Добавляем координаты в основной фрейм данных
doc <- cbind(doc, df.coords)
colnames(doc)[1] <- 'name'
colnames(doc)[2] <- 'FIO'
colnames(doc)[4] <- 'phone'
colnames(doc)[5] <- 'email'
doc
# Сохраняем данные в файл
write.csv2(doc, file = './data/data2.csv', row.names = F)
