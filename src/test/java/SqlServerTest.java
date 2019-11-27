import org.junit.Rule;
import org.junit.Test;
import org.renjin.script.RenjinScriptEngine;
import org.renjin.script.RenjinScriptEngineFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testcontainers.containers.MSSQLServerContainer;

import static org.junit.Assert.fail;

public class SqlServerTest extends AbstractDbTest {

   Logger log = LoggerFactory.getLogger(SqlServerTest.class);

   @Rule
   public MSSQLServerContainer mssqlserver = new MSSQLServerContainer();

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
         log.warn("Exception running rest");
         fail(e.getMessage());
      }
   }
}
