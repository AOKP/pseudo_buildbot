import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.text.DateFormat;
import java.text.SimpleDateFormat;

@SuppressWarnings("UtilityClass")
public class LastUpdateFinder {
    private static final File mLastUpdateFile = new File("last_update_time");

    private LastUpdateFinder() {
    }

    @SuppressWarnings("SimpleDateFormatWithoutLocale")
    public static void main(String... args) throws JSONException, IOException {
        if (args[0] == null) {
            return;
        }

        JSONArray input = new JSONObject(args[0]).getJSONArray("list");
        long time = Long.parseLong((String) input.getJSONObject(0).get("modified")) * 1000;
        DateFormat df = new SimpleDateFormat("MM-dd-yyyy");
        FileWriter fileWriter = null;
        try {
            fileWriter = new FileWriter(mLastUpdateFile);
            fileWriter.append(df.format(time));
        } finally {
            if (fileWriter == null) {
                throw new AssertionError();
            }
            fileWriter.close();
        }
        System.out.println("last update {" + df.format(time)
            + "} has been written to file {" + mLastUpdateFile.getAbsolutePath()
            + '}');
    }
}
