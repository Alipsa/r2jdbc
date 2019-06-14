# r2jdbc
Renjin database connectivity.

Based on renjin-dbi (https://github.com/bedatadriven/renjin-dbi).

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
            <version>10.0.16</version>
        </dependency>
        <dependency>
          <groupId>joda-time</groupId>
          <artifactId>joda-time</artifactId>
          <version>2.10.1</version>
        </dependency>
        <!-- the driver, depends on what db you want to use ;) -->
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <version>1.4.197</version>
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
