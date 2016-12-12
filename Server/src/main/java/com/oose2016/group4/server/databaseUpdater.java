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

public class DatabaseUpdater {
    private static String SQL_INITIATE_TABLE_CRIMES ="CREATE TABLE IF NOT EXISTS crimes "
            + "(date INTEGER NOT NULL, linkId INTEGER NOT NULL, address TEXT NOT NULL, "
            + "latitude REAL NOT NULL, longitude REAL NOT NULL, "
            + "type TEXT, PRIMARY KEY (date, linkId, type));";

    private static String SQL_INITIATE_LINKID_GRID="CREATE TABLE IF NOT EXISTS grids "
            + "(x INTEGER NOT NULL, y INTEGER NOT NULL, linkId INTEGER NOT NULL, alarm REAL NOT NULL, AADT INTEGER NOT NULL, "
            + " PRIMARY KEY (x, y));";

    private static String SQL_INITIATE_UPDATE_LOG=
            "CREATE TABLE IF NOT EXISTS updatelog "
            +"(sourcename TEXT NOT NULL, updatecount INTEGER NOT NULL, PRIMARY KEY (sourcename));";

    private Connection mConnection;

    public DatabaseUpdater(Connection conn){
        mConnection = conn;
    }

    /**
     * Execute the initial SQL query to make sure of the table existing before updating tuples into it
     */
    protected void initialUpdate(){
        mConnection.createQuery(SQL_INITIATE_TABLE_CRIMES).executeUpdate();
        mConnection.createQuery(SQL_INITIATE_LINKID_GRID).executeUpdate();
        mConnection.createQuery(SQL_INITIATE_UPDATE_LOG).executeUpdate();

    }

    /**
     * Main task of the DatabaseUpdater class
     * @throws IOException
     */
    public void update(String table) throws IOException {
        updateTraffics();
        updateCrimes();
    }


    /**
     * The heavy weight of the updateDB operation. Fetches data from crime library, parse each record and process appropriately.
     * updateTraffics has to be executed after updateCrimes.
     * @throws IOException
     */
    private void updateCrimes() throws IOException {

        //TODO factor into operations into table log;

        ArrayList<Object> crimeList = CrimeAPIHandler.preProccessCrimeData();

        /*
        Get the date of the most recent crime record of last updateDB operation.
        Ditch those records that has already been previously updated into the database to reduce the workload of this updateDB.
         */
        String sqlDate = "SELECT MAX(date) FROM crimes";
        int dateLastUpdate = mConnection.createQuery(sqlDate).executeScalar(Integer.class);

        //TODO refactor this for loop outside to a method; or even to an abstract method to be implemented by subclasses;
        for (Object crimeEntry: crimeList) {
            Map<String, Object> crime = (Map<String,Object>) crimeEntry;

            //ditch record if incomplete.
            if (!crime.containsKey("crimedate")
                    || !crime.containsKey("description")
                    || !crime.containsKey("inside_outside")
                    || !crime.containsKey("location")
                    || !crime.containsKey("location_1"))
                continue;

            String dateStr = (String) crime.get("crimedate");
            LocalDate dateLocal = LocalDate.parse(dateStr, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
            int date = 86400 * (int) dateLocal.toEpochDay();

            //ditch record if has been covered in previous updateDB operations.
            if(date <= dateLastUpdate) continue;

            String type = (String) crime.get("description");

            //ditch records of irrelevant types;
            String typeAllCaps = type.toUpperCase();
            if (typeAllCaps.contains("AUTO")
                    || typeAllCaps.contains("ARSON")
                    || typeAllCaps.contains("BURGLARY")
                    || typeAllCaps.contains("RESIDENCE")) continue;

            int crimeTypeWeight = getCrimeTypeWeight(type);

            String inOut = (String) crime.get("inside_outside");

            if (inOut.toUpperCase().startsWith("I")) continue;

            String address = (String) crime.get("location");
            Map<String, Object> location_1 = (Map<String, Object>) crime.get("location_1");
            ArrayList<Double> a = (ArrayList<Double>) location_1.get("coordinates");
            double latitude = a.get(1);
            double longitude = a.get(0);

            /*
            We only take into consideration crime records that occurs in a relative small area around Homewood. This is enough
            to display the essence of the project and necessary to cope with MapQuest's access restrictions on non-commercial users.
             */

            /*
            If the coordinate of this crime data entry does not satisfy our location range restriction, ditch the record;
             */
            if ( !getLocationRange(latitude, longitude) ) continue;

            Grid grid = new Grid(latitude,longitude);
            int x = grid.getX();
            int y = grid.getY();

            String sqlFetchLinkId = "SELECT :linkIdParam FROM grids WHERE x=:xParam and y=:yParam";
            Query queryFetchLinkID = mConnection.createQuery(sqlFetchLinkId);
            Integer linkIdByXY = queryFetchLinkID.addParameter("xParam", x).addParameter("yParam", y).executeScalar(Integer.class);

            if (linkIdByXY == null ) {
                try {
                    linkIdByXY = MapQuestHandler.requestLinkId(latitude, longitude);

                    /*
                    Since this grid has never been discovered by either updateCrimes or updateTraffic, we have to calculate the AADT value (the traffic
                    factor) for this grid. Then we can update the grids table with due accommodation of this crime record
                     */
                    int aadt = getGridAADT(x,y);

                    String sqlUpdateGrids = "INSERT INTO grids"
                            + "VALUES(:xParam, :yParam, :linkIdByXYParam, :crimeTypeWeightParam * 10000 / :aadtParam, :aadtParam);";
                    mConnection.createQuery(sqlUpdateGrids)
                            .addParameter("xParam", x)
                            .addParameter("yParam", y)
                            .addParameter("linkIdByXYParam", linkIdByXY)
                            .addParameter("crimeTypeWeightParam", crimeTypeWeight)
                            .executeUpdate();
                } catch (IOException ioe) {
                    ioe.printStackTrace();
                }
            } else {
                if (linkIdByXY == 0) {
                    try {
                        linkIdByXY = MapQuestHandler.requestLinkId(latitude, longitude);

                        String sql1 = "UPDATE grids SET linkId=:linkIdParam WHERE x=:xParam AND y=:yParam";
                        mConnection.createQuery(sql1)
                                .addParameter("linkIdParam", linkIdByXY)
                                .addParameter("xParam", x)
                                .addParameter("yParam", y)
                                .executeUpdate();


                    } catch (IOException ioe) {
                        ioe.printStackTrace();
                    }
                }

                String sql2 = "UPDATE grids SET alarm=alarm+:crimeTypeWeightParam*10000/AADT WHERE x=:xParam AND y=:yParam";
                mConnection.createQuery(sql2)
                        .addParameter("crimeTypeWeightParam", crimeTypeWeight)
                        .addParameter("xParam", x)
                        .addParameter("yParam", y)
                        .executeUpdate();
            }

            String sqlUpdateCrimes = "insert into crimes(date, linkId, address, latitude, longitude, type) "
                    + "SELECT * FROM (SELECT :dateParam, :linkIdParam, :addressParam, :latitudeParam, :longitudeParam, :typeParam) "
                    + "WHERE NOT EXISTS (SELECT * FROM crimes WHERE date = :dateParam AND linkId = :linkIdParam "
                    + "AND type = :typeParam);";

            Query query = mConnection.createQuery(sqlUpdateCrimes);
            query.addParameter("dateParam", date).addParameter("linkIdParam", linkIdByXY)
                    .addParameter("addressParam", address).addParameter("latitudeParam", latitude)
                    .addParameter("longitudeParam", longitude).addParameter("typeParam", type)
                    .executeUpdate();

        }

    }

    /**
     * Method to update all traffic records from source into the Grids table. This method is ensured to be run only once
     * in the application's lifetime because according to our observation on the source, the source library is not likely
     * to be updated in the foreseeable future.
     * @throws IOException
     */
    private void updateTraffics() throws IOException {
        /*
        Make sure the grids table only get updated once.
         */
        String sqlQueryLog = "SELECT updatecount FROM updatelog WHERE sourcename='traffic';";
        Integer trafficUpdateCount = mConnection.createQuery(sqlQueryLog).executeScalar(Integer.class);

        /*
        If the grids table has never been updated with the traffics source library, we pull the traffics data from the source.
         */
        if (trafficUpdateCount == null) {
            ArrayList<Object> trafficList = TrafficAPIHandler.preProcessTrafficData();
            for (Object trafficObj : trafficList ) {
                Map<String, Object> trafficEntry = (Map<String, Object>) trafficObj;

                Map<String, Object> trafficEntryProperties = (Map<String, Object>) trafficEntry.get("properties");
                int AADT = (int) trafficEntryProperties.get("AADT_2014");
                /*
                The above AADT value is shared by a list of coordinates, as fetched below;
                 */
                Map<String, Object> trafficEntryGeometry = (Map<String, Object>) trafficEntry.get("geometry");
                ArrayList<Object> trafficCoordinatesList = (ArrayList<Object>) trafficEntryGeometry.get("coordinates");

                for (Object coordinate : trafficCoordinatesList) {
                    ArrayList<Double> coordinateSingleList = (ArrayList<Double>) coordinate;
                    double latitude = coordinateSingleList.get(1);
                    double longitude = coordinateSingleList.get(0);

                    //Get the grid coordinate of this geo-coordinate;
                    Grid grid = new Grid (latitude, longitude);
                    int x = grid.getX();
                    int y = grid.getY();

                    //Check to see if this grid has been updated with traffic data;
                    String sqlQueryGrid = " SELECT AADT FROM grids WHERE x=:xParam AND y=:yParam;";
                    Integer aadtInGrids = mConnection.createQuery(sqlQueryGrid)
                            .addParameter("xParam", x)
                            .addParameter("yParam", y)
                            .executeScalar(Integer.class);

                    //If this grid has never been updated with traffic data, insert a new tuple for this grid;
                    if ( aadtInGrids == null ) {
                        String sqlInsertCoordinate = "INSERT INTO grids "
                                + " VALUES(:xParam, :yParam, 0, 0, :aadtParam); ";
                                //TODO figure out whether these update values are consistent with updateCrimes's operation;

                        mConnection.createQuery(sqlInsertCoordinate)
                                .addParameter("xParam", x)
                                .addParameter("yParam", y)
                                .addParameter("aadtParam", AADT)
                                .executeUpdate();
                        continue;
                    }

                    /*
                    If this grid has already been updated, with traffic data, add the AADT value for the current grid
                    into the tuple's previous AADT value;
                     */
                    String sqlUpdateGrid = " UPDATE grids SET AADT=AADT+:aadtParam WHERE x=:xParam AND y=:yParam; ";
                    mConnection.createQuery(sqlUpdateGrid)
                            .addParameter("aadtParam", AADT)
                            .addParameter("xParam", x)
                            .addParameter("yParam", y)
                            .executeUpdate();
                }
            }

            /*
            Leave record in the log so that the update for traffic data never get performed again.
             */
            String sqlUpdateLogCounter = " INSERT INTO updatelog VALUES('traffic', 1); ";
            mConnection.createQuery(sqlUpdateLogCounter).executeUpdate();
        }
    }

    /**
     * Based on the type (of a crime entry) as described by the passed in String, we return a corresponding value that
     * is appropriate for the particular crime type;
     * @param type The crime type.
     * @return The weight value for this type of crime.
     */
    private int getCrimeTypeWeight(String type) {
        String typeAllCap = type.toUpperCase();
        if (typeAllCap.contains("ASSAULT")) {
            if (typeAllCap.contains("THREAT")) {
                return 3;
            } else if (typeAllCap.contains("COMMON")) {
                return 9;
            } else if (typeAllCap.contains("AGG")) {
                return 11;
            }
        } else if (typeAllCap.contains("ROBBERY")) {
            if (typeAllCap.contains("STREET"))  {
                return 10;
            } else {
                return 8;
            }
        } else if (typeAllCap.contains("SHOOTING")) {
            return 16;
        } else if (typeAllCap.contains("RAPE")) {
            return 20;
        } else if (typeAllCap.contains("THEFT")) {
            return 7;
        } else if (typeAllCap.contains("HOMICIDE")) {
            return 25;
        }
        return 0;
    }

    /**
     * A method that examine the coordinate's eligibility for update.
     * TODO Maybe this method can be refactored as abstract, which is implemented by sunclasses, among which there is TestUpdater which does what is done here, and also RealUpdater which defines less intentionally restrictive ranges.
     * @param latitude
     * @param longitude
     * @return boolean value denoting whether the coordinate is eligible for the updater's consideration.
     */
    private boolean getLocationRange(int latitude, int longitude) {
        return  (latitude < 39.353414) && (latitude > 39.282497) && (longitude < -76.549413) && (longitude > -76.673241);
    }

    private int getGridAADT(int x, int y) {
        double leftAADT = discoverClosestAADT(x, y, -1, 0, 10);
        double rightAADT = discoverClosestAADT(x,y, 1, 0, 10);
        double upAADT = discoverClosestAADT(x, y, 0, 1, 10);
        double downAADT = discoverClosestAADT(x, y, 0, -1, 10);
        return (int) (leftAADT + rightAADT + upAADT + downAADT);
    }

    private double discoverClosestAADT(int x, int y, int xIncrement, int yIncrement, int maxDistanceCounter) {
        if (maxDistanceCounter ==0 ) {
            return 1;
        }
        String sqlFetchAADT = "SELECT AADT FROM grids WHERE x=:xParam AND y=:yParam";
        Integer aadt = mConnection.createQuery(sqlFetchAADT)
                .addParameter("xParam", x)
                .addParameter("yParam", y)
                .executeScalar(Integer.class);
        if (aadt != null) {
            return aadt;
        }
        return 0.8* discoverClosestAADT(x+xIncrement, y+yIncrement, xIncrement, yIncrement, maxDistanceCounter-1);
    }



}
