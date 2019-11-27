import org.testcontainers.containers.JdbcDatabaseContainer;

import java.io.IOException;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public abstract class AbstractDbTest {

  protected Connection getConnection(JdbcDatabaseContainer container) throws SQLException {
    return DriverManager.getConnection(container.getJdbcUrl(), container.getUsername(), container.getPassword());
  }

  protected String getResourceContent(String resourcePath) throws IOException, URISyntaxException {

    Path path = Paths.get(
        getClass().getProtectionDomain().getCodeSource().getLocation().toURI()
    ).resolve(
        Paths.get(resourcePath)
    );

    return new String(Files.readAllBytes(path));
  }
}
