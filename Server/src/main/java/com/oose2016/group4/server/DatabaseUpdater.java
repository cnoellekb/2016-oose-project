package com.oose2016.group4.server;


import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Map;

import org.sql2o.Connection;

import java.util.List;

public class DatabaseUpdater {
    private static String SQL_INITIATE_TABLE_CRIMES = "CREATE TABLE IF NOT EXISTS crimes "
            + "(date INTEGER NOT NULL, linkId INTEGER NOT NULL, address VARCHAR(100) NOT NULL, "
            + "latitude REAL NOT NULL, longitude REAL NOT NULL, "
            + "type VARCHAR(100), PRIMARY KEY (date, linkId, type, latitude, longitude));";

    private static String SQL_INITIATE_LINKID_GRID = "CREATE TABLE IF NOT EXISTS grids "
            + "(x INTEGER NOT NULL, y INTEGER NOT NULL, linkId INTEGER NOT NULL, alarm REAL NOT NULL, AADT INTEGER NOT NULL, "
            + " PRIMARY KEY (x, y));";

    private static String SQL_INITIATE_UPDATE_LOG =
            "CREATE TABLE IF NOT EXISTS updatelog "
                    + "(sourcename VARCHAR(50) NOT NULL, updatecount INTEGER NOT NULL);";

    private static String SQL_DB_NOSYNC = " PRAGMA synchronous=OFF; ";

    private static int TYPE_WEIGHT_FACTOR = 100000;

    private Connection mConnection;

    public DatabaseUpdater(Connection conn) {
        mConnection = conn;
    }

    /**
     * Execute the initial SQL query to make sure of the table existing before updating tuples into it
     */
    protected void initialUpdate() {
        mConnection.createQuery(SQL_INITIATE_TABLE_CRIMES).executeUpdate();
        mConnection.createQuery(SQL_INITIATE_LINKID_GRID).executeUpdate();
        mConnection.createQuery(SQL_INITIATE_UPDATE_LOG).executeUpdate();
        mConnection.createQuery(SQL_DB_NOSYNC).executeUpdate();
    }

    /**
     * Main task of the DatabaseUpdater class
     * TODO consider making bot updateTraffics and updateCrimes abstract so that we have an Template Method pattern;
     *
     * @throws IOException
     */
    public void update(String table) throws IOException {
        updateTraffics();
        updateHistoricalCrimes();
        updateCrimes();
    }


    /**
     * The heavy weight of the updateDB operation. Fetches data from crime library, parse each record and process appropriately.
     * updateTraffics has to be executed after updateCrimes.
     *
     * @throws IOException
     */
    private void updateCrimes() throws IOException {

        String sqlQueryUpdateCounter = " SELECT updatecount FROM updatelog WHERE sourcename='crime'; ";
        Integer crimeUpdateCount = mConnection.createQuery(sqlQueryUpdateCounter).executeScalar(Integer.class);
        System.out.println("Feched crimes update count");

        /*
        Initialize the tuple in updatelog for crimes if it is not there yet.
         */
        if (crimeUpdateCount == null) {
            String sqlInitializeCount = " INSERT INTO updatelog VALUES ( 'crime', 0); ";
            mConnection.createQuery(sqlInitializeCount).executeUpdate();
            System.out.println("This is the first update from crime source, crimes update count initialized.");
        }

        ArrayList<Object> crimeList = CrimeAPIHandler.preProccessCrimeData();
        System.out.println("ArrayList data fetched from the crime source.");

        /*
        Get the date of the most recent crime record of last updateDB operation.
        Ditch those records that has already been previously updated into the database to reduce the workload of this updateDB.
         */
        String sqlDate = "SELECT MAX(date) FROM crimes";
        Object dateLastUpdateObj = mConnection.createQuery(sqlDate).executeScalar(Integer.class);
        int dateLastUpdate = 0;
        if (dateLastUpdateObj != null) dateLastUpdate = (Integer) dateLastUpdateObj;
        System.out.println("Date of last update fetched.");

        int counter = 0;
        System.out.printf("new crimes counter: 0%n");

        String sqlFetchGridsTable = "SELECT * FROM grids; ";
        List<Grid> gridList = mConnection.createQuery(sqlFetchGridsTable).executeAndFetch(Grid.class);
        System.out.println("Grids table fetched from database");

        for (Object crimeEntry : crimeList) {
            counter ++;
            System.out.printf("new crimes counter: %d%n", counter);

            Map<String, Object> crime = (Map<String, Object>) crimeEntry;

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
            if (date <= dateLastUpdate) continue;

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
            if (location_1 == null) continue;

            ArrayList<Double> a = (ArrayList<Double>) location_1.get("coordinates");
            double latitude = a.get(1);
            double longitude = a.get(0);

            System.out.printf("This crime record is for latitude: %f and longtitude:%f%n", latitude,longitude);

            /*
            We only take into consideration crime records that occurs in a relative small area around Homewood. This is enough
            to display the essence of the project and necessary to cope with MapQuest's access restrictions on non-commercial users.
             */

            /*
            If the coordinate of this crime data entry does not satisfy our location range restriction, ditch the record;
             */
            if (!isCoordinateEligibleForCrimeUpdate(latitude, longitude)) continue;
            System.out.println("This location is eligible for update");

            //Map the coordinates to grid coordinates;
            Grid grid = new Grid(latitude, longitude);
            int x = grid.getX();
            int y = grid.getY();
            System.out.printf("Trying to find grid(%d,%d) in the grids list%n",x,y);

            Grid gridFound = fetchGridByXY(x,y,gridList);

            int linkIdByXY = gridFound.getLinkId();

            if (linkIdByXY < 0 ) {
                /*
                This grid has not been updated either by traffic source or crimes source.
                 */
                System.out.printf("There previously was not grid(%d,%d) in the database%n",x,y);
                linkIdByXY = MapQuestHandler.requestLinkId(latitude, longitude);
                System.out.printf("The linkId requested from MapQuest is %d%n",linkIdByXY);

                /*
                Since this grid has never been discovered by either updateCrimes or updateTraffic, we have to calculate
                the AADT value (the traffic factor) for this grid. Then we can update the grids table with due accommodation
                 of this crime record.
                */
                int aadtToAdd = getApproximateGridAADT(x, y);
                System.out.printf("The approximate AADT for this grid is %d%n", aadtToAdd);
                System.out.printf("The type of this crime is %s and its type weight is %d%n", type, crimeTypeWeight);

                double alarmToAdd = crimeTypeWeight * TYPE_WEIGHT_FACTOR/aadtToAdd;

                Grid gridToAdd = new Grid(x,y,linkIdByXY,alarmToAdd, aadtToAdd);

                gridList.add(gridToAdd);
                System.out.printf("New grid added with alarm %f%n", alarmToAdd);

            } else {
                /*
                In this situation, the grid has been discovered by at least one traffic update, but may or may not have been
                discovered by a crimes  update;
                 */
                if (linkIdByXY == 0) {
                    /*
                    In this situation, the grid also has never been discovered by any crimes update. That is saying, no
                    crime record has existed on this grid. Until now :(
                     */
                    System.out.printf("There previously was a grid (%d,%d) in the databse, but this grid not yet contain any crime%n", x,y);
                    linkIdByXY = MapQuestHandler.requestLinkId(latitude, longitude);
                    System.out.printf("The new linkId requested from MapQuest is %d%n", linkIdByXY);

                    gridFound.setLinkId(linkIdByXY);
                    System.out.println("Set the linkId for the grid");

                }

                /*
                Either way, since this grid has been discovered already, we have to update it with this crime record's weight.
                 */
                double previousAlarm = gridFound.getAlarm();
                System.out.printf("The alarm for the found grid before updating is %f%n", previousAlarm);
                System.out.printf("The AADT for the found grid is %d%n", gridFound.getAADT());

                gridFound.setAlarm(previousAlarm + crimeTypeWeight * TYPE_WEIGHT_FACTOR / gridFound.getAADT());
                System.out.printf("Alarm value for the grid has been updated to %f%n", gridFound.getAlarm());

            }

            /*
            Store the crime data entry into table crimes for future reference. For example, to keep track of all updated
            crime records' dates so that next updateCrimes only consider the new records;
             */

            /*
            Check if there has been a duplicate record already in the database, and if not, insert this crime entry to the
            crimes table;
             */
            String sqlQueryCrimesPrimaryKey = " SELECT date FROM crimes WHERE "
                    + " date= :dateParam AND "
                    + " linkId= :linkIdParam AND "
                    + " type= :typeParam AND "
                    + " latitude= :latParam AND "
                    + " longitude= :lngParam; ";
            Integer datePrevious = mConnection.createQuery(sqlQueryCrimesPrimaryKey)
                    .addParameter("dateParam", date)
                    .addParameter("linkIdParam", linkIdByXY)
                    .addParameter("typeParam", type)
                    .addParameter("latParam", latitude)
                    .addParameter("lngParam", longitude)
                    .executeScalar(Integer.class);

            if (datePrevious == null) {
                String sqlInsertToCrimes = " INSERT INTO crimes "
                        + " VALUES( :dateParam, :linkIdParam, :addressParam, :latParam, :lngParam, :typeParam); ";

                mConnection.createQuery(sqlInsertToCrimes)
                        .addParameter("dateParam", date)
                        .addParameter("linkIdParam", linkIdByXY)
                        .addParameter("addressParam", address)
                        .addParameter("typeParam", type)
                        .addParameter("latParam", latitude)
                        .addParameter("lngParam", longitude)
                        .executeUpdate();
            }
        }
        putGridsListBackToDB(gridList);
        /*
        Update log.
         */
        String sqlUpdateCounter = " UPDATE updatelog SET updatecount= updatecount+1 WHERE sourcename='crime'; ";
        mConnection.createQuery(sqlUpdateCounter).executeUpdate();
    }

    /**
     * Method to update all traffic records from source into the Grids table. This method is ensured to be run only once
     * in the application's lifetime because according to our observation on the source, the source library is not likely
     * to be updated in the foreseeable future.
     *
     * @throws IOException
     */
    private void updateTraffics() throws IOException {
        /*
        Make sure the grids table only get updated once. If there is a count value for 'traffic' in the log, it means updateTraffic
        has been executed before. Abort this invocation.
         */
        String sqlQueryLog = "SELECT updatecount FROM updatelog WHERE sourcename='traffic';";
        Integer trafficUpdateCount = mConnection.createQuery(sqlQueryLog).executeScalar(Integer.class);

        /*
        If the grids table has never been updated with the traffics source library, we pull the traffics data from the source.
         */
        if (trafficUpdateCount == null) {
            System.out.printf("traffic count is : %d.%n", trafficUpdateCount);
            int counter = 0;
            System.out.printf("counter: %d%n", counter);

            ArrayList<Object> trafficList = TrafficAPIHandler.preProcessTrafficData();
            for (Object trafficObj : trafficList) {

                Map<String, Object> trafficEntry = (Map<String, Object>) trafficObj;
                Map<String, Object> trafficEntryProperties = (Map<String, Object>) trafficEntry.get("properties");

                Double d = (Double) trafficEntryProperties.get("AADT_2014");
                double AADT_dbl = (double) d;
                int AADT = (int) AADT_dbl;
                System.out.printf("AADT: %d%n", AADT);

                /*
                if this point is on highway, ditch the point, since highway data is not useful for pedestrian guidance reference.
                */
                if (AADT > 50000) continue;

                /*
                The above AADT value is shared by a list of coordinates, as fetched below;
                 */
                Map<String, Object> trafficEntryGeometry = (Map<String, Object>) trafficEntry.get("geometry");
                ArrayList<Object> trafficCoordinatesList = (ArrayList<Object>) trafficEntryGeometry.get("coordinates");

                for (Object coordinate : trafficCoordinatesList) {

                    counter++;
                    System.out.printf("counter: %d%n", counter);

                    ArrayList<Object> coordinateSingleList = (ArrayList<Object>) coordinate;

                    Object latitudeObj = coordinateSingleList.get(1);
                    Object longitudeObj = coordinateSingleList.get(0);

                    if (!(latitudeObj instanceof Double) || !(longitudeObj instanceof Double)) {
                        System.out.println("Not double");
                        continue;
                    }

                    Double latitude = (Double) latitudeObj;
                    Double longitude = (Double) longitudeObj;

                    double lat = (double) latitude;
                    double lng = (double) longitude;

                    if (!isCoordinateEligibleForTrafficUpdate(lat, lng)) continue;

                    //Get the grid coordinate of this geo-coordinate;
                    Grid grid = new Grid(latitude, longitude);
                    int x = grid.getX();
                    int y = grid.getY();

                    //Check to see if this grid has been updated with traffic data;
                    String sqlQueryGrid = " SELECT AADT FROM grids WHERE x= :xParam AND y= :yParam;";
                    Integer aadtInGrids = mConnection.createQuery(sqlQueryGrid)
                            .addParameter("xParam", x)
                            .addParameter("yParam", y)
                            .executeScalar(Integer.class);

                    //If this grid has never been updated with traffic data, insert a new tuple for this grid;
                    if (aadtInGrids == null) {
                        String sqlInsertCoordinate = "INSERT INTO grids "
                                + " VALUES(:xParam, :yParam, 0, 0, :aadtParam); ";

                        mConnection.createQuery(sqlInsertCoordinate)
                                .addParameter("xParam", x)
                                .addParameter("yParam", y)
                                .addParameter("aadtParam", AADT)
                                .executeUpdate();
                    } else {
                        /*
                        If this grid has already been updated, with traffic data, update the AADT for this grid if the new
                        value is larger than the previous value;
                         */

                        int aadtNew = Math.max(AADT, aadtInGrids);

                        String sqlUpdateGrid = " UPDATE grids SET AADT = :aadtParam WHERE x= :xParam AND y= :yParam; ";
                        mConnection.createQuery(sqlUpdateGrid)
                                .addParameter("aadtParam", aadtNew)
                                .addParameter("xParam", x)
                                .addParameter("yParam", y)
                                .executeUpdate();

                    }

                }

            }

            /*
            Leave record in the log so that the update for traffic data never get performed again.
             */
            String sqlUpdateLogCounter = " INSERT INTO updatelog VALUES('traffic', 1); ";
            mConnection.createQuery(sqlUpdateLogCounter).executeUpdate();
        }
    }

    private void updateHistoricalCrimes() throws IOException {

        String sqlQueryLogHistorical = "SELECT updatecount FROM updatelog WHERE sourcename='historical';";
        Integer historicalUpdateCount = mConnection.createQuery(sqlQueryLogHistorical).executeScalar(Integer.class);
        System.out.println("historical update count fetched.");

        if (historicalUpdateCount == null) {
            System.out.println("start updating historical data.");

            String sqlFetchHistoricalCrimes = " SELECT * from crimes; ";
            List<Crime> crimeListHistorical = mConnection.createQuery(sqlFetchHistoricalCrimes).executeAndFetch(Crime.class);
            System.out.println("historical crimes data fetched into memory.");

            String sqlFetchGridsTable = " SELECT * from grids; ";
            List<Grid> gridList = mConnection.createQuery(sqlFetchGridsTable).executeAndFetch(Grid.class);
            System.out.println("grids table with no crime record fetched into memory");

            int counter = 0;
            System.out.printf("Historical counter: %d%n", counter);

            for (Crime crimeObj : crimeListHistorical) {
                Grid crimeGrid = new Grid(crimeObj.getLat(), crimeObj.getLng());

                counter++;
                System.out.printf("historical counter: %d%n", counter);

                int x = crimeGrid.getX();
                int y = crimeGrid.getY();
                System.out.printf("x is %d and y is %d%n", x, y);

                Grid gridFoundInTable = fetchGridByXY(x, y, gridList);
                System.out.println("Is this grid in previously in grids table?");
                if (gridFoundInTable.getX() > 0) {
                    System.out.printf("There previously was grid (%d,%d) in the grids table.%n", x, y);
                    gridFoundInTable.setLinkId(crimeObj.getLinkId());
                    System.out.printf("Change its linkId to this crime record's linkId:%d%n", crimeObj.getLinkId());
                    double previousAlarm = gridFoundInTable.getAlarm();
                    System.out.printf("Before this crime record, the alarm for grid (%d,%d) is %f. The AADT is %d%n", x, y, previousAlarm, gridFoundInTable.getAADT());
                    System.out.printf("The type weight for this crime is %d%n", getCrimeTypeWeight(crimeObj.getType()));
                    gridFoundInTable.setAlarm(getCrimeTypeWeight(crimeObj.getType()) * TYPE_WEIGHT_FACTOR / gridFoundInTable.getAADT() + previousAlarm);
                    System.out.printf("Change the grid's alarm to %f.%n", gridFoundInTable.getAlarm());
                } else {
                    System.out.printf("There previously was not a grid (%d,%d) in the grids table.%n", x, y);
                    int aadtToAdd = getApproximateGridAADT(x, y);
                    System.out.printf("The approximate AADT for this grid is %d%n", aadtToAdd);
                    System.out.printf("The type for this crime is %s and the weight for this crime is %d%n", crimeObj.getType(), getCrimeTypeWeight(crimeObj.getType()));
                    double alarmToAdd = getCrimeTypeWeight(crimeObj.getType()) * TYPE_WEIGHT_FACTOR / aadtToAdd;
                    Grid gridToAdd = new Grid(x, y, crimeObj.getLinkId(), alarmToAdd, aadtToAdd);
                    gridList.add(gridToAdd);
                    System.out.printf("New grid added to the list, with the alarm value of %f%n", alarmToAdd);
                }
            }
            System.out.printf("There are currently %d grids in the grid list%n", gridList.size());
            putGridsListBackToDB(gridList);
            String sqlUpdateLogCounterHistorical = " INSERT INTO updatelog VALUES('historical', 1); ";
            mConnection.createQuery(sqlUpdateLogCounterHistorical).executeUpdate();
        }


    }



    private void putGridsListBackToDB(List<Grid> gridList) {

        String sqlClearGridsTable = " DELETE FROM grids; ";
        mConnection.createQuery(sqlClearGridsTable).executeUpdate();

        int counter = 0;
        System.out.println("Start putting grid list back into db");

        for (Grid eachGrid : gridList) {
            counter++;
            System.out.printf("Insert counter: %d%n", counter);

//                if ( eachGrid.getLinkId()==0) continue;

//                System.out.printf("Grid(%d,%d,%d,%f,%d) %n",eachGrid.getX(),eachGrid.getY(), eachGrid.getLinkId(),eachGrid.getAlarm(),eachGrid.getAADT());

            String sqlInsertNewGridsTable = " INSERT INTO grids VALUES "
                    + " ( :xParam, :yParam, :linkIdParam, :alarmParam, :aadtParam ); ";
            mConnection.createQuery(sqlInsertNewGridsTable)
                    .addParameter("xParam", eachGrid.getX())
                    .addParameter("yParam", eachGrid.getY())
                    .addParameter("linkIdParam", eachGrid.getLinkId())
                    .addParameter("alarmParam", eachGrid.getAlarm())
                    .addParameter("aadtParam", eachGrid.getAADT())
                    .executeUpdate();
        }
    }

    private Grid fetchGridByXY(int x, int y, List<Grid> gridList ) {
        for (Grid eachGrid : gridList ) {
            if ((eachGrid.getX() == x) && (eachGrid.getY() == y)) return eachGrid;
        }
        Grid nullGrid = new Grid();
        nullGrid.setLinkId(-1);
        return nullGrid;
    }

    /**
     * Based on the type (of a crime entry) as described by the passed in String, we return a corresponding value that
     * is appropriate for the particular crime type;
     *
     * @param type The crime type.
     * @return The weight value for this type of crime.
     */
    public int getCrimeTypeWeight(String type) {
        String typeAllCap = type.toUpperCase();
        if (typeAllCap.contains("ASSAULT")) {
            if (typeAllCap.contains("THREAT")) {
                return 3;
            } else if (typeAllCap.contains("COMMON")) {
                return 9;
            } else if (typeAllCap.contains("AGG")) {
                return 11;
            }
        } else if (typeAllCap.contains("AUTO") || typeAllCap.contains("ARSON") || typeAllCap.contains("RESIDENCE") || typeAllCap.contains("BURGLARY")) {
            return 1;
        } else if (typeAllCap.contains("ROBBERY")) {
            if (typeAllCap.contains("STREET")) {
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
        } else if (typeAllCap.contains("LARCENY")) {
            return 5;
        }
        return 0;
    }

    /**
     * A method that examine the coordinate's eligibility for update.
     * TODO Maybe this method can be refactored as abstract, which is implemented by sunclasses, among which there is TestUpdater which does what is done here, and also RealUpdater which defines less intentionally restrictive ranges.
     *
     * @param latitude
     * @param longitude
     * @return boolean value denoting whether the coordinate is eligible for the updater's consideration.
     */
    private boolean isCoordinateEligibleForCrimeUpdate(double latitude, double longitude) {
        return (latitude < 39.353414) && (latitude > 39.282497) && (longitude < -76.549413) && (longitude > -76.673241);
    }

    private boolean isCoordinateEligibleForTrafficUpdate(double latitude, double longitude) {
        return (latitude < 41.62974) && (latitude > 39.2004) && (longitude < -76.51783) && (longitude > -76.71136);
    }

    /**
     * For grids that has not been discovered by traffic updates before but is currently being discovered by crime update;
     * this algorithm calculates the approximate AADT value for the grid, based on the AADT values around this new grid.
     *
     * @param x x index of the to be discovered grid
     * @param y y index of the to be discovered grid
     * @return The AADT value for the grid.
     */
    private int getApproximateGridAADT(int x, int y) {
        double leftAADT = discoverClosestAADT(x, y, -1, 0, 10);
        System.out.printf("Cloeset AADT on the left is %f%n", leftAADT);
        double rightAADT = discoverClosestAADT(x, y, 1, 0, 10);
        System.out.printf("Cloeset AADT on the right is %f%n", rightAADT);
        double upAADT = discoverClosestAADT(x, y, 0, 1, 10);
        System.out.printf("Cloeset AADT on the up is %f%n", upAADT);
        double downAADT = discoverClosestAADT(x, y, 0, -1, 10);
        System.out.printf("Cloeset AADT on the down is %f%n", downAADT);
        //sum up the influences of the closest grids which has its own AADT values from all four directions.
        int rawAADT = (int) (leftAADT + rightAADT + upAADT + downAADT) * 1/3;
        if (rawAADT == 0) rawAADT++;
        return rawAADT;
    }

    /**
     * Helper method for getApproximateGridAADT. Recursive in nature;
     *
     * @param x                  grid x index
     * @param y                  grid y index
     * @param xIncrement         Gave xIncrement a separate argument to increase method's reusablity
     * @param yIncrement         Gave yIncrement a separate argument to increase method's reusablity
     * @param maxDistanceCounter A counter to to prevent the algorithm from going too far thus affecting performance
     * @return
     */
    private double discoverClosestAADT(int x, int y, int xIncrement, int yIncrement, int maxDistanceCounter) {
        System.out.printf("Discovering cloeset AADT for (%d,%d)%n", x,y);
        //If reached max distance of the exploration, return lowest value for AADT;
        if (maxDistanceCounter == 0) {
            System.out.printf("Max depth reached, reaching AADT for (%d,%d) as 1%n", x,y);
            return 1;
        }

        String sqlFetchAADT = "SELECT AADT FROM grids WHERE x= :xParam AND y= :yParam";
        Integer aadt = mConnection.createQuery(sqlFetchAADT)
                .addParameter("xParam", x)
                .addParameter("yParam", y)
                .executeScalar(Integer.class);
//        System.out.printf("aadt is %d", aadt);

        //If this (x,y) grid has AADT value, return;
        if (aadt != null) {
            System.out.printf("Found one closest AADT: %d%n", aadt);
            return aadt;
        }
        System.out.printf("No AADT for grid (%d,%d), digging further at (%d,%d)%n", x, y, x+xIncrement,y+yIncrement);
        //Look further if otherwise. Gave the result of next iteration a coefficient of 0.8 to indicate distance's influence on AADT values.
        return 0.8 * discoverClosestAADT(x + xIncrement, y + yIncrement, xIncrement, yIncrement, maxDistanceCounter - 1);
    }


    public void test() throws IOException {
//        String sqlQueryLog = "SELECT updatecount FROM updatelog WHERE sourcename='traffic';";
//        Integer trafficUpdateCount = mConnection.createQuery(sqlQueryLog).executeScalar(Integer.class);
//
//        String sqlInitiateTestTable = " CREATE TABLE IF NOT EXISTS test "
//                + " (name VARCHAR(50) NOT NULL, data INTEGER NOT NULL, PRIMARY KEY(name)); ";
//        mConnection.createQuery(sqlInitiateTestTable).executeUpdate();
//
//        int data = 1;
//        if( trafficUpdateCount == null ) data = 0;
//
//        String sqlStoreTestData = " INSERT INTO test "
//                + " VALUES( 'testTrafficCount', :dataParam); ";
//        mConnection.createQuery(sqlStoreTestData)
//                .addParameter("dataParam", data)
////                .executeUpdate();
//        ArrayList<Object> crimeList = CrimeAPIHandler.preProccessCrimeData();
//
//        String sql = " CREATE TABLE IF NOT EXISTS testcrime (latitude REAL NOT NULL, longitude REAL NOT NULL); ";
//        mConnection.createQuery(sql).executeUpdate();
//
//        for (Object crimeEntry : crimeList) {
//            Map<String, Object> crime = (Map<String, Object>) crimeEntry;
////            System.out.print(1);
//
//            String dateStr = (String) crime.get("crimedate");
////            System.out.print(2);
//
//            LocalDate dateLocal = LocalDate.parse(dateStr, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
////            System.out.print(3);
//
//            int date = 86400 * (int) dateLocal.toEpochDay();
////            System.out.print(4);
//
//
//
//            String type = (String) crime.get("description");
////            System.out.print(5);
//
//
//
//            int crimeTypeWeight = getCrimeTypeWeight(type);
////            System.out.print(6);
//
//
//            String inOut = (String) crime.get("inside_outside");
////            System.out.print(7);
//
//
//            String address = (String) crime.get("location");
////            System.out.print(8);
//
//            Map<String, Object> location_1 = (Map<String, Object>) crime.get("location_1");
//            if (location_1 == null) continue;
////            System.out.print(9);
//
//
//            ArrayList<Object> a = (ArrayList<Object>) location_1.get("coordinates");
////            System.out.print(10);
//
//            Object latitudeObj = a.get(1);
//            Object longitudeObj = a.get(0);
//
////            if (!(latitudeObj instanceof Double) || !(longitudeObj instanceof Double)) continue;
////            System.out.print(11);
//
//            Double latitude = (Double) latitudeObj;
//            Double longitude = (Double) longitudeObj;
//
//            String sqlInsertCoordinate = " INSERT INTO testcrime VALUES ( :latParam, :lngParam);";
//            mConnection.createQuery(sqlInsertCoordinate)
//                    .addParameter("latParam", latitude)
//                    .addParameter("lngParam", longitude)
//                    .executeUpdate();

//        String sql = " CREATE TABLE IF NOT EXISTS testcrime (latitude REAL NOT NULL, longitude REAL NOT NULL); ";
//        mConnection.createQuery(sql).executeUpdate();
//        System.out.println(1);
//        int counter = 0;
//
//        ArrayList<Object> crimeList = HistoricalCrimeAPIHandler.preProccessCrimeData();
//        System.out.println(2);
//
//        for ( Object crimeObj: crimeList) {
//
//            counter ++;
//            System.out.printf("counter: %d%n", counter);
//            ArrayList<Object> listCrimeData = (ArrayList<Object>) crimeObj;
//
//            String dateStr = (String) listCrimeData.get(8);
//            LocalDate dateLocal = LocalDate.parse(dateStr, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
//            int date = 86400 * (int) dateLocal.toEpochDay();
//
//            String type = (String) listCrimeData.get(12);
//            String inOut = (String) listCrimeData.get(13);
//            String address = (String) listCrimeData.get(11);
//
//            ArrayList<Object> listCoordinate = (ArrayList<Object>) listCrimeData.get(18);
//            double latitude = (Double) listCoordinate.get(1);
//            double longitude = (Double) listCoordinate.get(2);
//
//            String sqlInsertCoordinate = " INSERT INTO testcrime VALUES ( :latParam, :lngParam);";
//            mConnection.createQuery(sqlInsertCoordinate)
//                    .addParameter("latParam", latitude)
//                    .addParameter("lngParam", longitude)
//                    .executeUpdate();

//        }
        int x = 75316;
        int y= 99915;

        String sqlFetchAADT = "SELECT AADT FROM grids WHERE x= :xParam AND y= :yParam";
        Integer aadt = mConnection.createQuery(sqlFetchAADT)
                .addParameter("xParam", x)
                .addParameter("yParam", y)
                .executeScalar(Integer.class);
        System.out.printf("aadt is %d", aadt);

    }


}
