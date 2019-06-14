library("org.renjin.cran:DBI")
library("se.alipsa:R2JDBC")
library("hamcrest")

# SQL Server cannot handle blank string as username and password in combination with
# user name and password as part of the ur (which works fine for postgres etc.)
# to support this case, NA as user and password can be used instead

# this test needs a local sql server and a user called test, e.g.
# CREATE LOGIN [test] WITH PASSWORD='unS3cur3P@55',
# DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
# GO
# use tempdb;
# go
# CREATE USER [test] FOR LOGIN [test] WITH DEFAULT_SCHEMA=[dbo]
# GO

drv <- JDBC("com.microsoft.sqlserver.jdbc.SQLServerDriver")


# "Normal" way, this always works
# con <- dbConnect(
#         drv,
#         url="jdbc:sqlserver://localhost:1433;databaseName=tempdb",
#         user="test",
#         password="unS3cur3P@55"
# )

# Username and password in the url
# This does NOT work
#con <- dbConnect(
#        drv,
#        url="jdbc:sqlserver://localhost:1433;databaseName=tempdb;user=test;password=unS3cur3P@55"
#)
# Instead we need to do this
tryCatch( {
    con <- dbConnect(
            drv,
            url="jdbc:sqlserver://localhost:1433;databaseName=tempdb;user=test;password=unS3cur3P@55",
            user=NA,
            password=NA
    )
    assign("con", con, envir = .GlobalEnv)
}, error = function(e) {
    loginMsg <- "Error: Login failed for user"
    errStr <- substr(e, 1, nchar(loginMsg))
    #print(paste("errStr =", errStr))
    if (errStr == loginMsg) {
        message("Login failed, either wrong password or user missing (you need to create the user first for this test to work)")
    } else {
        message("There is probably no SQL server database installed")
    }
    stop(e)
})



tryCatch(dbSendUpdate(con, "DROP TABLE #MyTable"), error = function(e) e)

# Creating table
dbSendUpdate(con, paste('CREATE TABLE #MyTable (
	"id" INT NOT NULL,
	"title" VARCHAR(50) NOT NULL,
	"author" VARCHAR(20) NOT NULL,
	"submission_date" DATE,
	"insert_date" DATETIME,
	"price" NUMERIC(20, 2)
	)
'))

# add some data
dbSendUpdate(con, paste("
insert into #MyTable values
(1, 'Answer to Job', 'C.G. Jung', cast(getdate() as date), getdate(), 22),
(2, 'Lord of the Rings', 'J.R.R. Tolkien', '2019-01-20', getdate(), 14.11),
(3, 'Siddharta', 'Herman Hesse', '2019-01-23', getdate(), 9.90)
"
))

# some simple tests

books <- dbGetQuery(con, "select * from #MyTable")
assertThat(books[books$id == 3, "title"], identicalTo("Siddharta"))

books <- dbGetQuery(con, paste("select * from #MyTable"))
assertThat(books[books$submission_date == '2019-01-23', "price"], identicalTo(9.90))

books <- dbGetQuery(con, paste("select * from #MyTable"))
assertThat(books[books$price == 14.11, "author"], identicalTo('J.R.R. Tolkien'))

dbDisconnect(con)