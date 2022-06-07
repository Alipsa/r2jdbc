# r2jdbc
Renjin database connectivity.

Based on [renjin-dbi](https://github.com/bedatadriven/renjin-dbi).

Releases are now available on maven central. 

## Example
```R
library("org.renjin.cran:DBI")
library("se.alipsa:R2JDBC")
drv <- JDBC("org.h2.Driver") 
con <- dbConnect(drv, url="jdbc:h2:mem:test") 
df  <- dbGetQuery(con, "SELECT * from sometable")
dbDisconnect(con)
```

All the api functions uses a connection to perform tasks. 
In order to create a connection to the database you need to load the driver first, e.g:
```R
con <- dbConnect(JDBC("org.h2.Driver"), url="jdbc:h2:mem:test")
```
Note that you need to add the driver jar to the classpath in addition to R2JDBC e.g.

```xml
    <dependencies>
        <dependency>
          <groupId>org.renjin.cran</groupId>
          <artifactId>DBI</artifactId>
          <version>1.0.0-b9</version>
        </dependency>
        <dependency>
            <groupId>se.alipsa</groupId>
            <artifactId>R2JDBC</artifactId>
            <version>10.0.25</version>
        </dependency>
        <!-- the driver, depends on what db you want to use ;) -->
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <version>2.1.212</version>
        </dependency>
    </dependencies>
```

# Functions provided

## Create
```R
dbSendUpdate(con, paste('CREATE TABLE MyTable (
  "id" INT NOT NULL,
  "title" VARCHAR(50) NOT NULL,
  "author" VARCHAR(20) NOT NULL,
  "submission_date" DATE,
  "insert_date" TIMESTAMP,
  "price" NUMERIC(20, 2)
)'))
```

## Insert
```R
dbSendUpdate(con, paste("
  insert into MyTable values
    (1, 'Answer to Job', 'C.G. Jung', CURRENT_DATE, CURRENT_TIMESTAMP, 22),
    (2, 'Lord of the Rings', 'J.R.R. Tolkien', '2019-01-20', CURRENT_TIMESTAMP, 14.11),
    (3, 'Siddharta', 'Herman Hesse', '2019-01-23', CURRENT_TIMESTAMP, 9.90)
"))
```
## Select
```R
df  <- dbGetQuery(con, "SELECT * from MyTable")
```
## Update
```R
dbSendUpdate(con, "update MyTable set price = 25 where id = 1")
```

## Delete
```R
dbSendUpdate(con, "delete from MyTable where id = 1")
```
## Other functions
### dbGetException
### dbGetInfo
### dbListTables
### dbGetTables
### dbExistsTable
### dbRemoveTable
### dbGetFields
### dbDataType
### dbBatchInsert
Used to insert a dataframe
  - Example
  ```R
    con <- dbConnect(drv, url="jdbc:derby:derbyDB;create=true")
    dbBatchInsert(con, name=name, df=mtcars, overwrite=TRUE)
  ```
### dbWriteTable

## Handling transactions
### dbBegin
Begins a transaction, sets autocommit to false
### dbCommit 
Commit the transaction
### dbRollback
Rollback the transaction

# Special cases
The microsoft SQL Server driver (and maybe others) gets confused when user and password is specified in the url only. 
In most other JDBC drivers, supplying and empty string for user and password works where the username/password in the url
will then take precedence, but not so for the SQL server driver. Hence, you need to set user and password to NA to get it to work.
E.g. this pattern (which works for postgres, derby, h2 etc) will not work:
```R
drv <- JDBC("com.microsoft.sqlserver.jdbc.SQLServerDriver")
con <- dbConnect(
        drv, 
        url="jdbc:sqlserver://localhost:1433;databaseName=tempdb;user=test;password=unS3cur3P@55"
)
```

but this will work fine:

```R
drv <- JDBC("com.microsoft.sqlserver.jdbc.SQLServerDriver")
con <- dbConnect(
        drv,
        url="jdbc:sqlserver://localhost:1433;databaseName=tempdb;user=test;password=unS3cur3P@55",
        user=NA,
        password=NA
)
```

and of course so will this:

```R
drv <- JDBC("com.microsoft.sqlserver.jdbc.SQLServerDriver")
con <- dbConnect(
        drv,
        url="jdbc:sqlserver://localhost:1433;databaseName=tempdb",
        user="test",
        password="unS3cur3P@55"
)
```

# Building 
Note:
This does not build properly on Windows for some reason (classes are does not end correctly with RData,
this is probably a bug in the renjin-maven-plugin or the gcc bridge). Until this is resolved you need to build in Linux
(though it probably works on other Unix like distributions as well)

# Version history

## Ver 10.0.25, Feb 04, 2022
- Removed dependency on Joda Time
- Make dateTime retrieval more robust
- Upgrade jdbc drivers used in test

## Ver 10.0.24, Jan 29, 2022
- Upgrade h2 dependency 
- Workaround for RowNamesVector changes in renjin master compared to 0.9.2716 (now works in all versions)
- upgrade slf4j version 
- upgrade testcontainers versions

## Ver 10.0.23, Jan 7, 2022
- upgrade dependencies (h2, maven site plugin)
- improve bigint support for postgresql (when detected as int8), add support for bigserial

## Ver 10.0.22, Dec 14, 2021
- Add support for CHARACTER VARYING data type (e.g. H2)
- Version bump of dependencies. 

## Ver 10.0.21, Mar 10, 2021
- mysql has a BIGINT UNSIGNED type; treat it as a regular BIGINT for now.
- Version bump of dependencies.

## Ver 10.0.20, Dec 17, 2019
- Add support for the "name" datatype (e.g. in postgresql).

## Ver 10.0.19, Jul 02, 2019
- Fix for Sql server when url contains username/password. 
- Add unit tests using TestContainer with Docker.
- Version bump of dependencies.

## Ver 10.0.18, May 04, 2019
- Add support for datetimeoffset datatype. Published on maven central.

## Ver 10.0.17, Apr 24, 2019
- Fix for boolean datatype on postgres (announced as "bool" type)

## Ver 10.0.16, Apr 12, 2019
R2JDBC is a renjin extension providing database connectivity. It is Based on the renjin-dbi (https://github.com/bedatadriven/renjin-dbi). 
Most of the changes consists of support for more data types.
