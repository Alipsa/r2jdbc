# r2jdbc
Renjin database connectivity.

Based on renjin-dbi (https://github.com/bedatadriven/renjin-dbi).

Releases are now available on maven central. 

# Example
```R
library("org.renjin.cran:DBI")
library("se.alipsa:R2JDBC")
drv <- JDBC("org.h2.Driver") 
con <- dbConnect(drv, url="jdbc:h2:mem:test") 
df  <- dbGetQuery(con, "SELECT * from sometable")
dbDisconnect(con)

```
Note that you need to add the driver jar to the classpath in addition to R2JDBC e.g.

```
        <dependency>
          <groupId>org.renjin.cran</groupId>
          <artifactId>DBI</artifactId>
          <version>1.0.0-b9</version>
        </dependency>
        <dependency>
            <groupId>se.alipsa</groupId>
            <artifactId>R2JDBC</artifactId>
            <version>10.0.23</version>
        </dependency>
        <dependency>
          <groupId>joda-time</groupId>
          <artifactId>joda-time</artifactId>
          <version>2.10.13</version>
        </dependency>
        <!-- the driver, depends on what db you want to use ;) -->
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <version>2.0.202</version>
        </dependency>
```

# Special cases
The microsoft SQl server driver (an maybe others) gets confused when user and password is specified in the url only. 
In most other JDBC drivers, supplying and empty string for user and password works where the username/password in the url
will then take precedence, but not so for the SQL server driver. Hence, you need to set user and password to NA to get it to work.
E.g. this pattern (which works for postgres, derby, h2 etc) will not work:
```
drv <- JDBC("com.microsoft.sqlserver.jdbc.SQLServerDriver")
con <- dbConnect(
        drv, 
        url="jdbc:sqlserver://localhost:1433;databaseName=tempdb;user=test;password=unS3cur3P@55"
)
```

but this will work fine:

```
drv <- JDBC("com.microsoft.sqlserver.jdbc.SQLServerDriver")
con <- dbConnect(
        drv,
        url="jdbc:sqlserver://localhost:1433;databaseName=tempdb;user=test;password=unS3cur3P@55",
        user=NA,
        password=NA
)
```

and of course so will this:

```
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

## Ver 10.0.23
- upgrade dependencies (h2, maven site plugin)
- improve bigint support for postgresql (when detected as int8), add support for bigserial

## Ver 10.0.22
- Add support for CHARACTER VARYING data type (e.g. H2)
- Version bump of dependencies. 

## Ver 10.0.21
- mysql has a BIGINT UNSIGNED type; treat it as a regular BIGINT for now.
- Version bump of dependencies.

## Ver 10.0.20
- Add support for the "name" datatype (e.g. in postgresql).

## Ver 10.0.19
- Fix for Sql server when url contains username/password. 
- Add unit tests using TestContainer with Docker.
- Version bump of dependencies.

## Ver 10.0.18
- Add support for datetimeoffset datatype. Published on maven central.

## Ver 10.0.17
- Fix for boolean datatype on postgres (announced as "bool" type)

## Ver 10.0.16
R2JDBC is a renjin extension providing database connectivity. It is Based on the renjin-dbi (https://github.com/bedatadriven/renjin-dbi). 
Most of the changes consists of support for more data types.
