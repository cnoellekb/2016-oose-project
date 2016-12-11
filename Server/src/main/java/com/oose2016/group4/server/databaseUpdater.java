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

import org.sql2o.Connection;
import org.sql2o.Query;

import com.google.gson.Gson;

public class databaseUpdater {
    private static String SQL_INITIATE_TABLE_CRIMES ="CREATE TABLE IF NOT EXISTS crimes "
            + "(date INTEGER NOT NULL, linkId INTEGER NOT NULL, address TEXT NOT NULL, "
            + "latitude REAL NOT NULL, longitude REAL NOT NULL, "
            + "type TEXT, alarm REAL NOT NULL, PRIMARY KEY (date, linkId, type));";

    private static String SQL_INITIATE_LINKID_GRID="CREATE TABLE IF NOT EXISTS grid "
            + "(x INTEGER NOT NULL, y INTEGER NOT NULL, linkId INTEGER NOT NULL, AADT2010 INTEGER NOT NULL, "
            + " AADT2011 INTEGER NOT NULL, AADT2012 INTEGER NOT NULL, AADT2013 INTEGER NOT NULL, "
            + " AADT2014 INTEGER NOT NULL, AADT2015 INTEGER NOT NULL, AADT2016 INTEGER NOT NULL, "
            + " PRIMARY KEY (x, y));";

    private Connection mConnection;

    private static String URL_TRAFFIC_SOURCE="http://data.imap.maryland.gov/datasets/3f4b959826c34480be3e4740e4ee025f_1.geojson";

    public databaseUpdater(Connection conn){
        mConnection = conn;
    }

    /**
     * Execute the initial SQL query to make sure of the table existing before updating tuples into it
     */
    protected void initialUpdate(){
        mConnection.createQuery(SQL_INITIATE_TABLE_CRIMES).executeUpdate();
    }

    /**
     * Fetch raw crime data from data.baltimorecity.gov and transform the result into proper form to store.
     * @return the crime data in an ArrayList
     * @throws IOException
     */
    private ArrayList<Object> preProccessCrimeData() throws IOException {
        String stringResult = makeGetRequest(URL_CRIME_SOURCE);
        return new Gson().fromJson(stringResult, ArrayList.class);
    }

    private void updateLinkIdGrid(){

    }

    /**
     * Main task of the databaseUpdater class
     * @throws IOException
     */
    public void update(String table) throws IOException {
        initialUpdate();
        ArrayList<Object> crimeList = CrimeAPIHandler.preProccessCrimeData();
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
            int linkid = MapQuestHandler.requestLinkId(latitude, longitude);

            if (inOut.equals("I")) continue;

            String sql = "insert into :table(date, linkId, address, latitude, longitude, type) "
                    + "SELECT * FROM (SELECT :dateParam, :linkIdParam, :addressParam, :latitudeParam, :longitudeParam, :typeParam) "
                    + "where not exists (select * from crimes where date = :dateParam and linkId = :linkIdParam "
                    + "and type = :typeParam);";

            Query query = mConnection.createQuery(sql);
            query.addParameter("dateParam", date).addParameter("linkIdParam", linkid)
                    .addParameter("addressParam", address).addParameter("latitudeParam", latitude)
                    .addParameter("longitudeParam", longitude).addParameter("typeParam", type)
                    .addParameter("table", table).executeUpdate();
        }
    }
}
