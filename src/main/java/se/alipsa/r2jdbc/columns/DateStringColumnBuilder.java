package se.alipsa.r2jdbc.columns;

import org.renjin.sexp.AtomicVector;
import org.renjin.sexp.StringArrayVector;
import org.renjin.sexp.StringVector;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

/**
 * Constructs a character vector column from a date-time field in a ResultSet.
 */
public class DateStringColumnBuilder implements ColumnBuilder {
    
    private final StringArrayVector.Builder vector = new StringVector.Builder();
    
    public DateTimeFormatter format;

    public static boolean acceptsType(String columnType) {
        return columnType.equals("datetime") || columnType.equals("timestamp")
            || columnType.equals("datetime2") || columnType.equals("datetimeoffset");
    }

    public DateStringColumnBuilder(DateTimeFormatter format) {
        this.format = format;
    }

    @Override
    public void addValue(ResultSet rs, int columnIndex) throws SQLException {
        Timestamp date = rs.getTimestamp(columnIndex);
        if(date == null) {
            vector.addNA();
        } else {
            LocalDateTime dateTime;
            try {
                // Modern jdbc drivers should support this
                dateTime = rs.getObject(columnIndex, LocalDateTime.class);
            } catch (SQLException e) {
                // But in case there is an older driver, use system default zone id to convert
                dateTime = date.toInstant().atZone(ZoneId.systemDefault()).toLocalDateTime();
            }
            vector.add(format.format(dateTime));
        }
    }

    @Override
    public AtomicVector build() {
        return vector.build();
    }
}
