package com.oose2016.group4.server;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.Map;

import com.google.gson.Gson;


/**
 * Created by vegito2002 on 12/11/16.
 */
public class TrafficAPIHandler extends RequestHandler {
    private static String URL_TRAFFIC_SOURCE="http://data.imap.maryland.gov/datasets/3f4b959826c34480be3e4740e4ee025f_1.geojson";

    /**
     * Fetch data from the traffics source library to update to database.
     * @return an ArrayList that can be further processed by DatabaseUpdater's updateTraffic() method;
     * @throws IOException
     */
    protected static ArrayList<Object> preProcessTrafficData() throws IOException {
        String stringResponse = makeGetRequest(URL_TRAFFIC_SOURCE);
        Map<String, Object> mapResponse = new Gson().fromJson(stringResponse, Map.class);
        ArrayList<Object> listTraffics = (ArrayList<Object>) mapResponse.get("features");
        return listTraffics;
    }

}
