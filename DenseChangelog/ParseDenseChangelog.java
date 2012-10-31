import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.charset.Charset;

/**
 * Created with IntelliJ IDEA.
 * User: jbird
 * Date: 10/30/12
 * Time: 8:49 PM
 * To change this template use File | Settings | File Templates.
 */
public class ParseDenseChangelog {
    static boolean DEBUG = true;
    // exit codes
    static int NO_ERROR = 0;
    static int FAILED_TO_READ_INPUT_FILE = 1;
    static int FAILED_TO_MAKE_NEW_FILE = 2;

    static int DEFAULT_BUFFER_SIZE = 1048576;
    static File outFile;
    /**
     * class to make JSON formatted changelog
     * @param args args[0]= fileIn
     *             args[1]= fileOut (optional)
     */
    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("missing required params please provide input file path");
            return;
        }

        File inFile = new File(args[0]);

        try {
            outFile = new File(args[1]);
        } catch (IndexOutOfBoundsException outOfBounds) {
            outFile = new File(inFile.getParentFile().getAbsolutePath()
                + "/dense_" + inFile.getName());
        }
        if (!inFile.exists()) {
            System.out.println("input file was not found... check your references");
            System.exit(FAILED_TO_READ_INPUT_FILE);
        }

        // read the file into a String
        String jsonString = readFile(inFile);
        if (jsonString == null) {
            System.exit(FAILED_TO_READ_INPUT_FILE);
        }
        String[] commitsList = splitCommits(jsonString, "\\¶");
        if (DEBUG) {
            for (String s : commitsList) {
                System.out.println("commits to string: " + s);
            }
        }
        if (DEBUG) System.out.println("parsed symbol: ¶");
        int numberOfCommits = commitsList.length;
        JSONArray jsonArray = new JSONArray();
        for (int i = 0; numberOfCommits > i; i++) {
            jsonArray.put(getJsonObjectFromCommit(commitsList[i]));
        }
        bufferedFileWriter(jsonArray.toString());
    }

    private static void bufferedFileWriter(String jsonText) {
        if (outFile.exists())
            outFile.delete();

        try {
            BufferedWriter bufferedWriter = null;
            try {
                outFile.createNewFile();
                // buffer is large but we may be making large files
                bufferedWriter = new BufferedWriter(new FileWriter(outFile), DEFAULT_BUFFER_SIZE);
                bufferedWriter.write(jsonText);
            } finally {
                bufferedWriter.close();
            }
        } catch (IOException ioe) {
            ioe.printStackTrace();
            System.exit(FAILED_TO_MAKE_NEW_FILE);
        }
    }

    private static JSONObject getJsonObjectFromCommit(String commitString) {
        JSONObject commitObject = new JSONObject();
        String[] info = splitCommits(commitString, "\\|");
        try {
            commitObject.put("team_credit", info[0]);
            commitObject.put("path", info[1]);
            commitObject.put("commit_hash", info[2]);
            commitObject.put("parent_hashes", info[3]);
            commitObject.put("author_name", info[4]);
            commitObject.put("author_date", info[5]);
            commitObject.put("committer_name", info[6]);
            commitObject.put("committer_date", info[7]);
            commitObject.put("subject", info[8]);
            commitObject.put("body", info[9]);
            if (DEBUG) {
                debugParse("team_credit", info[0]);
                debugParse("path", info[1]);
                debugParse("commit_hash", info[2]);
                debugParse("parent_hashes", info[3]);
                debugParse("author_name", info[4]);
                debugParse("author_date", info[5]);
                debugParse("committer_name", info[6]);
                debugParse("committer_date", info[7]);
                debugParse("subject", info[8]);
                debugParse("body", info[9]);
            }
        } catch (JSONException e) {
            // shouldn't happen
            e.printStackTrace();
        } catch (IndexOutOfBoundsException lengthError) {
            // our split array is the incorrect length
        }
        return commitObject;
    }

    private static void debugParse(String name, String value) {
        System.out.println(name + " : " + value);
    }

    private static String readFile(File inFile) {
        // read the file
        // watch for this bug http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=4715154
        String unformattedFileString = null;
        try {
            FileInputStream stream = new FileInputStream(inFile);
            try {
                FileChannel fc = stream.getChannel();
                MappedByteBuffer bb = fc.map(FileChannel.MapMode.READ_ONLY, 0, fc.size());
                unformattedFileString = Charset.defaultCharset().decode(bb).toString();
            } finally {
                stream.close();
            }
        } catch (IOException ioe) {
            // bail we couldn't find the file
            ioe.printStackTrace();
            System.exit(FAILED_TO_READ_INPUT_FILE);
        }
        return unformattedFileString;
    }

    private static String[] splitCommits(String fileText, String regex) {
        return fileText.split(regex);
    }
}
