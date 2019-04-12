# r2jdbc
Renjin database connectivity.

Based on the renjin-dbi (https://github.com/bedatadriven/renjin-dbi).

# Example
```R
library("DBI")
library("se.alipsa:R2JDBC")
drv <- JDBC("org.h2.Driver") 
con <- dbConnect(drv, url="jdbc:h2:mem:test") 
df  <- dbGetQuery(con, "SELECT * from sometable")
dbDisconnect(con)

```
Note that you need to add the driver jar to the classpath in addition to R2JDBC e.g.

```
        <dependency>
            <groupId>se.alipsa</groupId>
            <artifactId>R2JDBC</artifactId>
            <version>10.0.16</version>
        </dependency>
        <!-- the driver -->
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <version>1.4.197</version>
        </dependency>
```

# Building 
Note:
This does not build properly on Windows for some reason (classes are does not end correctly with RData,
this is probably a bug in the renjin-maven-plugin or the gcc bridge). Until this is resolved you need to build in Linux
(though it probably works on other Unix like distributions as well)
