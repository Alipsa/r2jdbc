
## JDBCResult
## Adapted from RJDBC by Simon Urbanek


setClass("JDBCResult", representation("DBIResult", statement="externalptr", resultset="externalptr", success="logical"))

setMethod("fetch", signature(res="JDBCResult", n="numeric"), def=function(res, n, block=2048L, ...) {
 	JDBCUtils$fetch(res@resultset, n)
})

setMethod("dbClearResult", "JDBCResult",
          def = function(res, ...) { .jcall(res@jr, "V", "close"); .jcall(res@stat, "V", "close"); TRUE },
          valueClass = "logical")

setMethod("dbGetInfo", "JDBCResult", def=function(dbObj, ...) list(has.completed=TRUE), valueClass="list")

## this is not needed for recent DBI, but older implementations didn't provide default methods
setMethod("dbHasCompleted", "JDBCResult", def=function(res, ...) TRUE, valueClass="logical")

setMethod("dbColumnInfo", "JDBCResult", def = function(res, ...) {
  cols <- .jcall(res@md, "I", "getColumnCount")
  l <- list(field.name=character(), field.type=character(), data.type=character())
  if (cols < 1) return(as.data.frame(l))
  for (i in 1:cols) {
    l$name[i] <- .jcall(res@md, "S", "getColumnLabel", i)
    l$field.type[i] <- .jcall(res@md, "S", "getColumnTypeName", i)
    ct <- .jcall(res@md, "I", "getColumnType", i)
    l$data.type[i] <- if (ct == -5 | ct ==-6 | (ct >= 2 & ct <= 8)) "numeric" else "character"
    l$field.name[i] <- .jcall(res@md, "S", "getColumnName", i)
  }
  as.data.frame(l, row.names=1:cols)
},
          valueClass = "data.frame")

setMethod("dbIsValid", "JDBCResult", def = function(dbObj, ...) {
    TRUE
})