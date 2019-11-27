import static org.junit.Assert.fail;

import org.junit.Rule;
import org.junit.Test;
import org.renjin.script.RenjinScriptEngine;
import org.renjin.script.RenjinScriptEngineFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testcontainers.containers.PostgreSQLContainer;

import java.sql.Connection;
import java.sql.SQLException;

public class PostgresqlTest extends AbstractDbTest {

  Logger log = LoggerFactory.getLogger(PostgresqlTest.class);

  @Rule
  public PostgreSQLContainer pgServer = new PostgreSQLContainer();


  @Test
  public void testPostgresMetaData() throws SQLException {
    try(Connection con = getConnection(pgServer)) {
      con.createStatement().executeUpdate("create table if not exists test(" 
                                          + "id INT8 not null primary key, note varchar(255), num int, nametest name)");
    }

    String scriptPath = "TestPostgres.Rscript";

    RenjinScriptEngineFactory factory = new RenjinScriptEngineFactory();
    RenjinScriptEngine engine = factory.getScriptEngine();
    engine.put("database", pgServer);
    try {
      String script = getResourceContent(scriptPath);
      engine.eval(script);
    } catch (Exception e) {
      log.warn("Exception running rest");
      fail(e.getMessage());
    }
  }
}
