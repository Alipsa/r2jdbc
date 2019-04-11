
## JDBCDriver
## Adapted from RJDBC by Simon Urbanek


setClass("JDBCDriver", representation("DBIDriver", identifier.quote="character", ptr="externalptr"))

JDBC <- function(driverClass='', classPath='', identifier.quote=NA) {
  driver <- do.call('import', list(as.name(driverClass)))
  new("JDBCDriver", identifier.quote=as.character(identifier.quote), ptr=driver$new())
}

setMethod("dbListConnections", "JDBCDriver", def=function(drv, ...) {
    warning("JDBC driver maintains no list of active connections.");
    list()
})

setMethod("dbGetInfo", "JDBCDriver", def=function(dbObj, ...)
  list(name="JDBC", driver.version="0.1-1",
       DBI.version="0.1-1",
       client.version=NA,
       max.connections=NA)
          )

setMethod("dbUnloadDriver", "JDBCDriver", def=function(drv, ...) FALSE)

setMethod("dbConnect", "JDBCDriver", def=function(drv, url, user='', password='', ...) {
	if (getOption("dbi.debug", F)) message("II: Connecting to ",url," with user ", user, " and a non-printed password.")
	prop <- import(java.util.Properties)$new()
	prop$setProperty("user", user)
	prop$setProperty("password", password)
	jconn <- drv@ptr$connect(url, prop)
  new("JDBCConnection", ptr=jconn, identifier.quote=drv@identifier.quote)},
          valueClass="JDBCConnection")

dbDriver <- function(drvName, ...)   do.call(drvName, list(...))

