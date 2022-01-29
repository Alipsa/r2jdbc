import org.junit.Rule;
import org.junit.Test;
import org.renjin.script.RenjinScriptEngine;
import org.renjin.script.RenjinScriptEngineFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testcontainers.containers.MSSQLServerContainer;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;

public class SqlServerTest extends AbstractDbTest {

   Logger log = LoggerFactory.getLogger(SqlServerTest.class);

   @Rule
   public MSSQLServerContainer mssqlserver = new MSSQLServerContainer();

   @Test
   public void testFromJava() throws ClassNotFoundException, SQLException {
      Class.forName(mssqlserver.getDriverClassName());
      try(Connection con = DriverManager.getConnection(mssqlserver.getJdbcUrl(), mssqlserver.getUsername(), mssqlserver.getPassword())) {
         System.out.println("Creating table");
         con.createStatement().executeUpdate("CREATE TABLE #TestTable (\n" +
             "id INT NOT NULL,\n" +
             "title VARCHAR(50) NOT NULL,\n" +
             "author VARCHAR(20) NOT NULL,\n" +
             "submission_date DATE,\n" +
             "insert_date DATETIME,\n" +
             "price NUMERIC(20, 2)\n" +
             ");");
         System.out.println("Inserting data");
         con.createStatement().executeUpdate("insert into #TestTable values\n" +
             "(1, 'Answer to Job', 'C.G. Jung', cast(getdate() as date), getdate(), 22),\n" +
             "(2, 'Lord of the Rings', 'J.R.R. Tolkien', '2019-01-20', getdate(), 14.11),\n" +
             "(3, 'Siddharta', 'Herman Hesse', '2019-01-23', getdate(), 9.90)");
         System.out.println("Selecting data");
         ResultSet rs = con.createStatement().executeQuery("select count(*) from #TestTable");
         rs.next();
         assertEquals(3, rs.getInt(1));
      }
   }

   @Test
   public void testSqlServer() {
      String scriptPath = "TestSqlServer.Rscript";

      RenjinScriptEngineFactory factory = new RenjinScriptEngineFactory();
      RenjinScriptEngine engine = factory.getScriptEngine();
      engine.put("database", mssqlserver);
      try {
         String script = getResourceContent(scriptPath);
         engine.eval(script);
      } catch (Exception e) {
         log.warn("Exception running rest", e);
         fail(e.getMessage());
      }
   }
}
