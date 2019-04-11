package se.alipsa.r2jdbc.columns;


import org.renjin.sexp.*;

import java.sql.ResultSet;
import java.sql.SQLException;

public class BlobColumnBuilder implements ColumnBuilder {


    //private RawVector.Builder vector = new RawVector.Builder();
    //private StringByteArrayVector.Builder vector = new StringByteArrayVector.Builder();
    private StringArrayVector.Builder vector = new StringArrayVector.Builder();


    public static boolean acceptsType(String columnType) {
      return columnType.equals("blob") || columnType.equals("binary") || columnType.equals("varbinary");
    }

    @Override
    public void addValue(ResultSet rs, int columnIndex) throws SQLException {
        //byte[] value = rs.getBytes(columnIndex);
        String value = rs.getString(columnIndex);
        if(rs.wasNull()) {
            vector.addNA();
        } else {
            vector.add(value);
        }
    }

    public AtomicVector build() {
        return vector.build();
    }
}
