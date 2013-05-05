import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.lang.System;
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
        long time;
        try {
            time = Long.parseLong((String) input.getJSONObject(1).get("modified")) * 1000;
        } catch (JSONException je) {
            // may contain nightlies folder check the next in line
            System.out.println("Failed to find date... Trying one more time to find date.");
            time = Long.parseLong((String) input.getJSONObject(1).get("modified")) * 1000;
        }
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
        System.out.println("found date of last update: " + df.format(time));
    }
}
