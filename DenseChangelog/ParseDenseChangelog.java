/*
 * Copyright (C) 2012 The Android Open Kang Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.lang.Exception;
import java.lang.IndexOutOfBoundsException;
import java.lang.System;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.charset.Charset;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Created with IntelliJ IDEA.
 * Author: JBirdVegas
 * Date: 10/31/12
 */
public class ParseDenseChangelog {
    static String TAG;
    static boolean DEBUG = false; // always ship false else
    static boolean CHATTY = false;
    // term output is mostly noise
    // exit codes
    static int NO_ERROR = 0;
    static int FAILED_TO_READ_INPUT_FILE = 1;
    static int FAILED_TO_MAKE_NEW_FILE = 2;

    static int DEFAULT_BUFFER_SIZE = 1048576;
    static String LINE_RETURN = System.getProperty("line.separator");
    static File outFile;

    /**
     * class to make JSON formatted changelog
     *
     * @param args args[0]= fileIn
     * args[1]= fileOut (optional)
     */
    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("missing required params please provide input file path");
            return;
        }

        if (DEBUG) {
            for (String s : args) {
                System.out.println("Found arg (" + s + ")");
            }
        }

        printLines(2);

        // grab the class name
        TAG = Thread.currentThread().getStackTrace()[1].getClassName();
        System.out.println("Hello welcome to " + TAG);

        File inFile = new File(args[0]);

        try {
            if (!Character.isDigit(args[1].charAt(0))) {
                outFile = new File(args[1]);
            } else {
                outFile = new File(inFile.getParentFile().getAbsolutePath()
                    + "/dense_" + inFile.getName());
            }
        } catch (IndexOutOfBoundsException outOfBounds) {
            outFile = new File(inFile.getParentFile().getAbsolutePath()
                    + "/dense_" + inFile.getName());
        }
        if (!inFile.exists()) {
            System.out.println("input file was not found... check your path");
            System.exit(FAILED_TO_READ_INPUT_FILE);
        }

        System.out.println("Parsing input file: " + inFile.getAbsolutePath());

        // read the file into a String
        String jsonString = readFile(inFile);
        if (jsonString == null) {
            System.exit(FAILED_TO_READ_INPUT_FILE);
        }
        System.out.println("Log parser splicing at symbol: ¶");
        String[] commitsList = splitCommits(jsonString, "\\¶");
        if (CHATTY) {
            for (String s : commitsList) {
                System.out.println("commits to string: " + s);
            }
        }
        int numberOfCommits = commitsList.length;
        System.out.println("Generating JSON formated output...");
        JSONArray jsonArray = new JSONArray();
        for (int i = 0; numberOfCommits > i; i++) {
            try {
                jsonArray.put(getJsonObjectFromCommit(commitsList[i]));
            } catch (IndexOutOfBoundsException indexException) {
                if (DEBUG) System.out.println("Fail at index: " + i);
            }
        }

        if (args[args.length - 1] != null && args[args.length - 1].trim() != "") {
            System.out.println("Removing indices outside of range");
            JSONObject commit = new JSONObject();
            JSONArray rangedList = new JSONArray();
            for (int i = 0; jsonArray.length() > i; i++) {
                try {
                    commit = jsonArray.getJSONObject(i);
                    Date time = new Date();
                    // Wed May 1 13:11:53 2013 -0700
                    DateFormat df = new SimpleDateFormat("EEE MMM dd hh:mm:ss yyyy");
                    DateFormat endFormat = new SimpleDateFormat("MM/dd/yyyy");

                    // if no end date was supplied use current time
                    Date endDate = null;
                    try {
                        endDate = endFormat.parse(args[args.length - 1]);
                    } catch (Exception e) {
                        endDate = new Date();
                        endDate.setTime(System.currentTimeMillis());
                    }
                    try {
                        time = df.parse(commit.getString("committer_date"));
                    } catch (NumberFormatException e) {
                        time = df.parse(commit.getString("author_date"));
                    }

                    if (time.before(endDate)) {
                        rangedList.put(jsonArray.getJSONObject(i));
                        if (DEBUG) System.out.println("found commit in acceptable range");
                    } else {
                        if (DEBUG) System.out.println("commit not in range" + endDate.toString());
                    }
                } catch (JSONException e) {
                    if (DEBUG) e.printStackTrace();
                } catch (ParseException e) {
                    if (DEBUG) e.printStackTrace();
                }
            }
            try {
                bufferedFileWriter(rangedList.toString(DEBUG ? 4 : 0));
                showSuccessMessage();
            } catch (JSONException je) {
                je.printStackTrace();
                System.exit(FAILED_TO_MAKE_NEW_FILE);
            }
        } else {
            System.out.println("args not acceptable: " + args[args.length - 1]);
        }

        try {
            bufferedFileWriter(jsonArray.toString(DEBUG ? 4 : 0));
            showSuccessMessage();
        } catch (JSONException js) {
            js.printStackTrace();
            System.exit(FAILED_TO_MAKE_NEW_FILE);
        }
    }

    private static void printLines(int lines) {
        for (int i = 0; lines > i; i++) {
            System.out.print(LINE_RETURN);
        }
    }

    private static void bufferedFileWriter(String jsonText) {
        if (outFile.exists())
            outFile.delete();

        System.out.println("Writting file: " + outFile.getAbsolutePath());
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

    private static JSONObject getJsonObjectFromCommit(String commitString)
            throws IndexOutOfBoundsException {
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
                if (CHATTY)
                    debugParse("body", info[9]);
            }
        } catch (JSONException e) {
            // shouldn't happen
            e.printStackTrace();
        } catch (IndexOutOfBoundsException lengthError) {
            // our split array is the incorrect length
            throw new IndexOutOfBoundsException("Failed to parse commit information for provided commit");
        }
        return commitObject;
    }

    private static void debugParse(String name, String value) {
        System.out.println(name + " : " + value);
    }

    // read the file
    private static String readFile(File inFile) {
        // this bug http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=4715154
        // prevents us from performing clean up here in java
        // instead we must perform after generation via shell
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

    private static void showSuccessMessage() {
        printLines(2);
        System.out.println("Success! your changelog sir: "
            + outFile.getAbsolutePath());
        System.exit(0);
    }
}
