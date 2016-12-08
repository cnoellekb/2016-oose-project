package com.oose2016.group4.server;


import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Map;

import com.google.gson.internal.ObjectConstructor;
import org.sql2o.Connection;
import org.sql2o.Query;

import com.google.gson.Gson;



public class Updater {
    private static String SQL_INITIATE_DATABASE ="CREATE TABLE IF NOT EXISTS crimes "
            + "(date INTEGER NOT NULL, linkId INTEGER NOT NULL, address TEXT NOT NULL, "
            + "latitude REAL NOT NULL, longitude REAL NOT NULL, "
            + "type TEXT, PRIMARY KEY (date, linkId, type));";
    private static String URL_CRIME_SOURCE ="https://data.baltimorecity.gov/resource/4ih5-d5d5.json";
//    private Sql2o mDB;
    private Connection mConnection;
    private String mMapQuestKey;
    private String mMapQuestEndpoint;
//    private SurvivalService mService;

    public Updater(Connection conn, String key, String endPoint){
//        mDB=db;
//        mConnection = mDB.open();
//        mService=argService;
        mConnection = conn;
        mMapQuestKey = key;
        mMapQuestEndpoint = endPoint;
    }

    private void initialUpdate(){
        mConnection.createQuery(SQL_INITIATE_DATABASE).executeUpdate();
    }

    private ArrayList<Object> fetchRawCrimeData() throws IOException {
        String stringResult = makeGetRequest(URL_CRIME_SOURCE);
        return new Gson().fromJson(stringResult, ArrayList.class);
    }

    public void update() throws IOException {
        initialUpdate();
        ArrayList<Object> crimeList = fetchRawCrimeData();
        for (Object crimeObj: crimeList) {
            Map<String, Object> crime = (Map<String,Object>) crimeObj;

            if (!crime.containsKey("crimedate") || !crime.containsKey("description")
                    || !crime.containsKey("inside_outside") || !crime.containsKey("location")
                    || !crime.containsKey("location_1"))
                continue;

            String dateStr = (String) crime.get("crimedate");
            LocalDate dateLocal = LocalDate.parse(dateStr, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
            int date = 86400 * (int) dateLocal.toEpochDay();
            String type = (String) crime.get("description");
            String inOut = (String) crime.get("inside_outside");
            String address = (String) crime.get("location");
            Map<String, Object> location_1 = (Map<String, Object>) crime.get("location_1");
            ArrayList<Double> a = (ArrayList<Double>) location_1.get("coordinates");
            double latitude = a.get(1);
            double longitude = a.get(0);
            int linkid = requestLinkId(latitude, longitude);

            if (inOut.equals("I")) continue;

            String sql = "insert into crimes(date, linkId, address, latitude, longitude, type) "
                    + "SELECT * FROM (SELECT :dateParam, :linkIdParam, :addressParam, :latitudeParam, :longitudeParam, :typeParam) "
                    + "where not exists (select * from crimes where date = :dateParam and linkId = :linkIdParam "
                    + "and type = :typeParam);";

            Query query = mConnection.createQuery(sql);
            query.addParameter("dateParam", date).addParameter("linkIdParam", linkid)
                    .addParameter("addressParam", address).addParameter("latitudeParam", latitude)
                    .addParameter("longitudeParam", longitude).addParameter("typeParam", type)
                    .executeUpdate();
        }
    }

    /**
     * GETs the linkId associated with a particular crime's coordinates.
     * @param lat latitude
     * @param lng longitude
     * @return the linkId of that crime
     * @throws IOException if GET request doesn't work
     */
    private int requestLinkId(double lat, double lng) throws IOException {
        String url = mMapQuestEndpoint + "?key=" + mMapQuestKey + "&lat=" + lat + "&lng=" + lng;
        String response = makeGetRequest(url);
        Map<String, Object> resp = new Gson().fromJson(response, Map.class);
        // TODO determine the issue here...
        double linkiddble = (double) resp.get("linkId");
        int linkid = (int) linkiddble;
        return linkid;
    }


    /**
     * Takes in any url (assumed to include endpoint and params) and makes a
     * GET request.
     * @param url compose of endpoint and any potential parameters
     * @return the response object as a JSON
     * @throws IOException if GET request doesn't work
     */
    private String makeGetRequest(String url) throws IOException {
        URL obj = new URL(url);
        HttpURLConnection con = (HttpURLConnection) obj.openConnection();

        con.setRequestMethod("GET");

        BufferedReader in = new BufferedReader(
                new InputStreamReader(con.getInputStream()));
        String inputLine;
        String response = "";

        while ((inputLine = in.readLine()) != null) {
            response += inputLine;
        }
        in.close();
        return response;
    }

}
