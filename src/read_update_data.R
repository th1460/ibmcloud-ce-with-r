# config ------------------------------------------------------------------
Sys.setenv(TZ = "America/Sao_Paulo")

# read data ---------------------------------------------------------------
url <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv"
covid19 <- 
  read.csv(url, stringsAsFactors = FALSE)

# prepare data ------------------------------------------------------------
covid19 <- 
  covid19 |> 
  subset(Country.Region %in%  c("Brazil", "Peru", "Bolivia", 
                                "Chile", "Argentina", "Colombia",
                                "Venezuela", "Ecuador", "Uruguay",
                                "Paraguay"),
         select = -Province.State)

varying = names(covid19[, 4:ncol(covid19)])

covid19 <- 
  covid19 |> 
  reshape(direction = "long", 
          idvar = c("Country.Region", "Lat", "Long"),
          v.names = "Cumulate",
          varying = varying,
          timevar = "Date",
          times = gsub("\\.", "-", gsub("X", "", varying)))

covid19$Date <- lubridate::mdy(covid19$Date) |> as.character()
names(covid19)[1] <- "Country"

sqlite <- DBI::dbConnect(RSQLite::SQLite(), dbname="covid19.sqlite")
DBI::dbWriteTable(sqlite, "COVID19", value = covid19, overwrite = TRUE)

# write data --------------------------------------------------------------
drv <-
  RJDBC::JDBC("com.ibm.db2.jcc.DB2Driver", "jars/db2jcc4.jar")

host <- Sys.getenv("DB2_HOST")
user <- Sys.getenv("DB2_USER")
password <- Sys.getenv("DB2_PASSWORD")

url <- 
  sprintf("jdbc:db2://%s/bludb:user=%s;password=%s;sslConnection=true;", host, user, password)

db2 <-
  DBI::dbConnect(drv, url)

if ("COVID19" %in% DBI::dbListTables(db2)) {
  DBI::dbRemoveTable(db2, "COVID19")
  cat(sprintf("INFO [%s] remove table", format(Sys.time(), '%Y-%m-%d %X')), "\n")
}

rs <- DBI::dbSendQuery(sqlite, "SELECT * FROM COVID19")
while (!DBI::dbHasCompleted(rs)) {
  chunk <- DBI::dbFetch(rs, 1000)
  DBI::dbWriteTable(db2, "COVID19", value = chunk, append = TRUE)
  cat(sprintf("INFO [%s] write %i rows in table", format(Sys.time(), '%Y-%m-%d %X'), nrow(chunk)), "\n")
}
DBI::dbClearResult(rs)
DBI::dbDisconnect(sqlite)

if (DBI::dbDisconnect(db2)) {
  cat(sprintf("INFO [%s] disconnect db", format(Sys.time(), '%Y-%m-%d %X')), "\n")
}


