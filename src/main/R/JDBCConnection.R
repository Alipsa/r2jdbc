
## JDBCConnection
## Adapted from RJDBC by Simon Urbanek


setClass("JDBCConnection", representation("DBIConnection", ptr="externalptr", identifier.quote="character"))

setMethod("dbDisconnect", "JDBCConnection", def=function(conn, ...) {
    conn@ptr$close();
    TRUE
})

.fillStatementParameters <- function(s, l) {
  for (i in 1:length(l)) {
    v <- l[[i]]
    if (is.na(v)) { # map NAs to NULLs (courtesy of Axel Klenk)
      sqlType <- if (is.integer(v)) 4 else if (is.numeric(v)) 8 else 12
      .jcall(s, "V", "setNull", i, as.integer(sqlType))
    } else if (is.integer(v))
      .jcall(s, "V", "setInt", i, v[1])
    else if (is.numeric(v))
      .jcall(s, "V", "setDouble", i, as.double(v)[1])
    else
      .jcall(s, "V", "setString", i, as.character(v)[1])
  }
}

setMethod("dbSendQuery", signature(conn="JDBCConnection", statement="character"),  def=function(conn, statement, ..., list=NULL) {
 	if (getOption("dbi.debug", F))  message("QQ: '", statement, "'")
 	
 	stmt <- conn@ptr$createStatement()
 	res <-  stmt$execute(statement)

 	new("JDBCResult", statement = stmt, resultset = JDBCUtils$gimmeResults(stmt))
})

if (is.null(getGeneric("dbSendUpdate"))) setGeneric("dbSendUpdate", function(conn, statement, ...) standardGeneric("dbSendUpdate"))

setMethod("dbSendUpdate",  signature(conn="JDBCConnection", statement="character"), def=function(conn, statement, ..., list=NULL, max.batch=10000L) {
	if(length(list(...))){
		if (length(list(...))) statement <- .bindParameters(conn, statement, list(...))

	}
    stmt <- conn@ptr$createStatement()
    res <-  stmt$execute(statement)

    new("JDBCResult", statement = stmt, success = res)

})

setMethod("dbGetQuery", signature(conn="JDBCConnection", statement="character"),
    def=function(conn, statement, ...) {
  r <- dbSendQuery(conn, statement, ...)
  ## Teradata needs this - closing the statement also closes the result set according to Java docs
  #on.exit(.jcall(r@stat, "V", "close"))
  fetch(r, -1)
})

setMethod("dbGetException", "JDBCConnection",
          def = function(conn, ...) list()
          , valueClass = "list")

setMethod("dbGetInfo", "JDBCConnection",
          def = function(dbObj, ...) list() )

setMethod("dbListResults", "JDBCConnection",
          def = function(conn, ...) { warning("JDBC maintains no list of active results"); NULL }
          )

setMethod("dbIsValid", "JDBCConnection",
          def = function(dbObj, ...) {

       TRUE
})

.fetch.result <- function(r) {
  md <- .jcall(r, "Ljava/sql/ResultSetMetaData;", "getMetaData", check=FALSE)
  .verify.JDBC.result(md, "Unable to retrieve JDBC result set meta data")
  res <- new("JDBCResult", jr=r, md=md, stat=.jnull(), pull=.jnull())
  fetch(res, -1)
}

setMethod("dbListTables", "JDBCConnection", def=function(conn, schema=NULL, ...) {
	JDBCUtils$getTables(conn@ptr,c("TABLE") )
})

if (is.null(getGeneric("dbGetTables"))) setGeneric("dbGetTables", function(conn, ...) standardGeneric("dbGetTables"))

setMethod("dbGetTables", "JDBCConnection", def=function(conn, pattern="%", schema=NULL, ...) {
    stop("TODO")
})

setMethod("dbExistsTable", "JDBCConnection", def=function(conn, name, ...) {
	tolower(gsub("(^\"|\"$)","",as.character(name))) %in%
			tolower(dbListTables(conn))
})

setMethod("dbRemoveTable", "JDBCConnection", def=function(conn, name, ...) {
    dbSendUpdate(conn, paste("DROP TABLE", name))
    invisible(TRUE)
})

setMethod("dbListFields", "JDBCConnection", def=function(conn, name, pattern="%", full=FALSE, ...) {
  	if (!dbExistsTable(conn, name))
  		stop("Unknown table ", name);
  	JDBCUtils$getColumns(conn@ptr, name)
})

if (is.null(getGeneric("dbGetFields"))) setGeneric("dbGetFields", function(conn, ...) standardGeneric("dbGetFields"))

setMethod("dbGetFields", "JDBCConnection", def=function(conn, name, pattern="%", ...) {
  md <- .jcall(conn@jc, "Ljava/sql/DatabaseMetaData;", "getMetaData", check=FALSE)
  .verify.JDBC.result(md, "Unable to retrieve JDBC database metadata")
  r <- .jcall(md, "Ljava/sql/ResultSet;", "getColumns", .jnull("java/lang/String"),
              .jnull("java/lang/String"), name, pattern, check=FALSE)
  .verify.JDBC.result(r, "Unable to retrieve JDBC columns list for ",name)
  on.exit(.jcall(r, "V", "close"))
  .fetch.result(r)
})

setMethod("dbDataType", signature(dbObj="JDBCConnection", obj = "ANY"),
          def = function(dbObj, obj, ...) {
            if (is.integer(obj)) "INTEGER"
            else if (is.numeric(obj)) "DOUBLE PRECISION"
            else "VARCHAR(255)"
          }, valueClass = "character")

.sql.qescape <- function(s, identifier=FALSE, quote="\"") {
  s <- as.character(s)
  if (identifier) {
    vid <- grep("^[A-Za-z]+([A-Za-z0-9_]*)$",s)
    if (length(s[-vid])) {
      if (is.na(quote)) stop("The JDBC connection doesn't support quoted identifiers, but table/column name contains characters that must be quoted (",paste(s[-vid],collapse=','),")")
      s[-vid] <- .sql.qescape(s[-vid], FALSE, quote)
    }
    return(s)
  }
  if (is.na(quote)) quote <- ''
  s <- gsub("\\\\","\\\\\\\\",s)
  if (nchar(quote)) s <- gsub(paste("\\",quote,sep=''),paste("\\\\\\",quote,sep=''),s,perl=TRUE)
  paste(quote,s,quote,sep='')
}


setMethod("dbWriteTable", "JDBCConnection", def=function(conn, name, value, overwrite=TRUE, append=FALSE,
 csvdump=FALSE, transaction=TRUE, ..., max.batch=10000L) {

    if (is.vector(value) && !is.list(value)) value <- data.frame(x=value)
	if (length(value)<1) stop("value must have at least one column")
	if (is.null(names(value))) names(value) <- paste("V", 1:length(value), sep='')
	if (length(value[[1]])>0) {
		if (!is.data.frame(value)) value <- as.data.frame(value, row.names=1:length(value[[1]]))
	} else {
		if (!is.data.frame(value)) value <- as.data.frame(value)
	}
	if (overwrite && append) {
		stop("Setting both overwrite and append to true makes no sense.")
	}
	qname <- make.db.names(conn, name)
	if (dbExistsTable(conn, qname)) {
		if (overwrite) dbRemoveTable(conn, qname)
		if (!overwrite && !append) stop("Table ", qname, " already exists. Set overwrite=TRUE if you want
							to remove the existing table. Set append=TRUE if you would like to add the new data to the
							existing table.")
	}
	if (!dbExistsTable(conn, qname)) {
		fts <- sapply(value, function(x) {
					dbDataType(conn, x)
				})
		fdef <- paste(make.db.names(conn, tolower(names(value))), fts, collapse=', ')
		ct <- paste("CREATE TABLE ", qname, " (", fdef, ")", sep= '')
		dbSendUpdate(conn, ct)
	}
	if (length(value[[1]])) {
		vins <- paste("(", paste(rep("?", length(value)), collapse=', '), ")", sep='')

		if (transaction) dbBegin(conn)
		# chunk some inserts together so we do not need to do a round trip for every one
		splitlen <- 0:(nrow(value)-1) %/% getOption("dbi.insert.splitsize", 1000)

		lapply(split(value, splitlen),
				function(valueck) {
					bvins <- c()
					for (j in 1:length(valueck[[1]])) {
						bvins <- c(bvins, .bindParameters(conn, vins, as.list(valueck[j, ])))

					}
					dbSendUpdate(conn, paste0("INSERT INTO ", qname, " VALUES ",paste0(bvins, collapse=", ")))
				})
		if (transaction) dbCommit(conn)
	}
	invisible(TRUE)
})


setMethod("dbBegin", "JDBCConnection", def = function(conn, ...) {
	JDBCUtils$toggleAutocommit(conn@ptr, FALSE)
	invisible(TRUE)
})

setMethod("dbCommit", "JDBCConnection", def=function(conn, ...) {
    conn@ptr$commit()
    invisible(TRUE)

})

setMethod("dbRollback", "JDBCConnection", def=function(conn, ...) {
	conn@ptr$rollback()
	JDBCUtils$toggleAutocommit(conn@ptr, TRUE)
	invisible(TRUE)
})


# TODO: this breaks if the value contains a ?, fix this (also in MonetDB.R!)
.bindParameters <- function(con, statement, param) {
	for (i in 1:length(param)) {
		value <- param[[i]]
		valueClass <- class(value)
		if (is.na(value))
			statement <- sub("?", "NULL", statement, fixed=TRUE)
		else if (valueClass %in% c("numeric", "logical", "integer"))
			statement <- sub("?", sub(",", ".",value), statement, fixed=TRUE)

		else if (valueClass == "factor")
			statement <- sub("?", paste(dbQuoteString(con, toString(as.character(value))), sep=""), statement,
					fixed=TRUE)
		else if (valueClass == c("raw"))
			stop("raw() data is so far only supported when reading from BLOBs")
		else
			statement <- sub("?", paste(dbQuoteString(con, toString(value)), sep=""), statement,
					fixed=TRUE)
	}
	statement
}
