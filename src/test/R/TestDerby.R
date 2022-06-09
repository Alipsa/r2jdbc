library("org.renjin.cran:DBI")
library("se.alipsa:R2JDBC")
library("hamcrest")


drv <- JDBC("org.apache.derby.iapi.jdbc.AutoloadedDriver")
con <- dbConnect(drv, url="jdbc:derby:derbyDB;create=true")

tryCatch(dbSendUpdate(con, "DROP TABLE MyTable"), error = function(e) e)

# Creating table
dbSendUpdate(con, paste('CREATE TABLE MyTable (
	"id" INT NOT NULL,
	"title" VARCHAR(50) NOT NULL,
	"author" VARCHAR(20) NOT NULL,
	"submission_date" DATE,
	"insert_date" TIMESTAMP,
	"price" NUMERIC(20, 2)
	)
'))

# add some data
dbSendUpdate(con, paste("
insert into MyTable values
(1, 'Answer to Job', 'C.G. Jung', CURRENT_DATE, CURRENT_TIMESTAMP, 22),
(2, 'Lord of the Rings', 'J.R.R. Tolkien', '2019-01-20', CURRENT_TIMESTAMP, 14.11),
(3, 'Siddharta', 'Herman Hesse', '2019-01-23', CURRENT_TIMESTAMP, 9.90)
"
))

# some simple tests

books <- dbGetQuery(con, "select * from MyTable")
assertThat(books[books$id == 3, "title"], identicalTo("Siddharta"))

books <- dbGetQuery(con, paste("select * from MyTable"))
assertThat(books[books$submission_date == '2019-01-23', "price"], identicalTo(9.90))

books <- dbGetQuery(con, paste("select * from MyTable"))
assertThat(books[books$price == 14.11, "author"], identicalTo('J.R.R. Tolkien'))
dbDisconnect(con)

testBatchInsert <- function(name, df) {
  con <- dbConnect(drv, url="jdbc:derby:derbyDB;create=true")
  dbBatchInsert(con, name=name, df=df, overwrite=TRUE)
  dbDf <- dbGetQuery(con, paste("select * from", name))
  dbDisconnect(con)

  assertThat(ncol(dbDf), equalTo(ncol(df)))
  assertThat(nrow(dbDf), equalTo(nrow(df)))

  for (col in seq_len(ncol(df))) {
    for(row in seq_len(nrow(df))) {
      if (df[[row,col]] != dbDf[[row,col]]) {
        # TODO: change to stop
        warning(paste(name, "row", row, "col", col, ": does not equal, expected",df[[row,col]], "but was", dbDf[[row,col]]))
      }
    }
  }

}


test.batchInsertMtCars <- function() {
  testBatchInsert("mtcars", df=mtcars)
}

test.batchInsertIris <- function() {
  testBatchInsert("iris", df=iris)
}

test.batchInsertOrange <- function() {
  testBatchInsert("orange", df=Orange)
}

test.batchInsertToothGrowth <- function() {
  testBatchInsert("ToothGrowth", ToothGrowth)
}

test.batchInsertPlantGrowth <- function() {
  df <- PlantGrowth
  print("TODO: consider adding some automatic renaming scheme if df contains sql keywords")
  names(df)[names(df) == "group"] <- "plantgroup"
  testBatchInsert("PlantGrowth", df)
}

test.batchInsertUSArrests <- function() {
  testBatchInsert("USArrests", USArrests)
}

