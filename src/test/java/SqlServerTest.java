import org.junit.Rule;
import org.junit.Test;
import org.renjin.script.RenjinScriptEngine;
import org.renjin.script.RenjinScriptEngineFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testcontainers.containers.MSSQLServerContainer;

import javax.script.ScriptEngine;
import java.io.*;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import static org.junit.Assert.fail;

public class SqlServerTest {

   Logger log = LoggerFactory.getLogger(SqlServerTest.class);

   @Rule
   public MSSQLServerContainer mssqlserver = new MSSQLServerContainer();

   @Test
   public void testSqlServer() {
      String scriptPath = "TestSqlServer.Rscript";

      RenjinScriptEngineFactory factory = new RenjinScriptEngineFactory();
      RenjinScriptEngine engine = factory.getScriptEngine();
      engine.put("mssqlserver", mssqlserver);
      try {
         String script = getResourceContent(scriptPath);
         engine.eval(script);
      } catch (Exception e) {
         log.warn("Exception running rest");
         fail(e.getMessage());
      }
   }

   private String getResourceContent(String resourcePath) throws IOException, URISyntaxException {

      Path path = Paths.get(
         getClass().getProtectionDomain().getCodeSource().getLocation().toURI()
      ).resolve(
         Paths.get(resourcePath)
      );

      String content = new String(Files.readAllBytes(path));
      return content;
   }
}
