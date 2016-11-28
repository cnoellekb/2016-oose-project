package com.oose2016.group4.server;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.ProtocolException;
import java.net.URL;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;

import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.sql2o.Connection;
import org.sql2o.Query;
import org.sql2o.Sql2o;
import org.sql2o.Sql2oException;

import com.google.gson.Gson;

/**
 * Query the database
 */
public class SurvivalService {
	private Sql2o db;
	private String MAPQUEST_KEY = "afbtgu28aAJW4kgGbc8yarMCZ3LdWWbh";
	private String mapquestEndpoint = "http://www.mapquestapi.com/directions/v2/findlinkid";

	private static Logger logger = LoggerFactory.getLogger(SurvivalService.class);

	public SurvivalService(DataSource dataSource) {
		db = new Sql2o(dataSource);
	}

	public Sql2o getDb() {
		return db;
	}
	
	/**
	 * Get linkIds to avoid
	 * @param from top left coordinate
	 * @param to bottom right coordinate
	 * @return linkIds
	 */
	public AvoidLinkIds getAvoidLinkIds(Coordinate from, Coordinate to) {
		try (Connection conn = db.open()) {
			int[] red = fetchLinkIds(conn, from, to, "count > 50");
			int[] yellow = fetchLinkIds(conn, from, to, "count > 10 AND count <= 50");
			return new AvoidLinkIds(red, yellow);
		} catch (Sql2oException e) {
			logger.error("Failed to fetch linkIds", e);
			return null;
		} catch (NullPointerException e) {
			logger.error("Null pointer, failed to fetch linkIds", e);
			return null;
		}
	}

	/**
	 * Create and execute database query
	 * @param conn database connection
	 * @param from top left coordinate
	 * @param to bottom right coordinate
	 * @param predicate condition
	 * @return array of linkIds
	 * @throws Sql2oException when query fails
	 */
	private int[] fetchLinkIds(Connection conn, Coordinate from, Coordinate to, String predicate)
			throws Sql2oException, NullPointerException {
		String sql = "SELECT linkId, COUNT(linkId) AS count FROM crimes WHERE "
				+ "latitude >= :fromLat AND latitude <= :toLat AND "
				+ "longitude >= :fromLng AND longitude <= :toLng GROUP BY linkId HAVING " + predicate
				+ " ORDER BY count DESC LIMIT 20";
		Query abc = conn.createQuery(sql);
		abc = abc.addParameter("fromLat", from.getLatitude())
				.addParameter("toLat", to.getLatitude()).addParameter("fromLng", from.getLongitude())
				.addParameter("toLng", to.getLongitude());
		List<AvoidLinkIds.LinkId> results =  abc.executeAndFetch(AvoidLinkIds.LinkId.class);
		int size = results.size();
		int[] linkIds = new int[size];
		for (int i = 0; i < size; i++) {
			linkIds[i] = results.get(i).getLinkId();
		}
		return linkIds;
	}
	
	/**
	 * Retrieve all the crimes in the database within a certain time, latitude and longitude 
	 * range.
	 * @param from starting crime point
	 * @param to ending crime point
	 * @param timeOfDay the time of day
	 * @return the results of our query to the database
	 */
	public List<Crime> getCrimes(CrimePoint from, CrimePoint to, int timeOfDay) {
		try (Connection conn = db.open()) {
			String sql = "SELECT date, address, latitude, longitude, type FROM crimes WHERE "
					+ "latitude >= :fromLat AND latitude <= :toLat AND date >= :fromDate AND "
					+ "longitude >= :fromLng AND longitude <= :toLng AND date <= :toDate;";
					//+ "time = :timeOfDay"; TODO figure out what to do with this
			Query query = conn.createQuery(sql);
			query.addParameter("fromLat", from.getLat()).addParameter("toLat", to.getLat())
				.addParameter("fromLng", from.getLng()).addParameter("toLng", to.getLng())
				.addParameter("fromDate", from.getDate()).addParameter("toDate", to.getDate());
				//.addParameter("timeOfDay", timeOfDay);
			List<Crime> results = query.executeAndFetch(Crime.class);
			return results;
		} catch (Sql2oException e) {
			logger.error("Failed to get crimes", e);
			return null;
		}	
	}
	
	/**
	 * Creates or updates the server.db database that holds all of the crime data.
	 * Only includes data that has all of the fields we need and doesn't have a matching
	 * compound primary key in the existing data: (date, linkId, type).
	 */
	public void updateDB() {
		try (Connection conn = db.open()){
			String sql1 = "CREATE TABLE IF NOT EXISTS crimes "
					+ "(date INTEGER NOT NULL, linkId INTEGER NOT NULL, address TEXT NOT NULL, "
					+ "latitude REAL NOT NULL, longitude REAL NOT NULL, "
					+ "type TEXT, PRIMARY KEY (date, linkId, type));";
			conn.createQuery(sql1).executeUpdate();
			String s = getCrimeData();
			ArrayList<Object> crimeList = new Gson().fromJson(s, ArrayList.class);
			for (Object crimeObj: crimeList) { 
				Map<String, Object> crime = (Map<String,Object>) crimeObj;
				
				if (!crime.containsKey("crimedate") || !crime.containsKey("description") 
						|| !crime.containsKey("inside_outside") || !crime.containsKey("location")
						|| !crime.containsKey("location_1")) 
					continue;
				
				String dateStr = (String) crime.get("crimedate");
				LocalDate dateLocal = LocalDate.parse(dateStr, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
				int date = 86400 * (int) dateLocal.toEpochDay();
				//String time = (String) crime.get("crimetime");
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
				
				Query query = conn.createQuery(sql);
				query.addParameter("dateParam", date).addParameter("linkIdParam", linkid)
					.addParameter("addressParam", address).addParameter("latitudeParam", latitude)
					.addParameter("longitudeParam", longitude).addParameter("typeParam", type)
					.executeUpdate();
			}								
		} catch (IOException e) {
			e.printStackTrace();
		} catch (Sql2oException e) {
			logger.error("Failed to get crimes", e);
		}
	}
	
	/**
	 * GETs crime data from Open Baltimore database
	 * @return The JSON containing a list of crimes
	 * @throws IOException
	 */
	private String getCrimeData() throws IOException {
		String url = "https://data.baltimorecity.gov/resource/4ih5-d5d5.json";
		return makeGetRequest(url);
	}
	
	/**
	 * GETs the linkId associated with a particular crime's coordinates.
	 * @param lat latitude
	 * @param lng longitude
	 * @return the linkId of that crime
	 * @throws IOException if GET request doesn't work
	 */
	private int requestLinkId(double lat, double lng) throws IOException {
		String url = mapquestEndpoint + "?key=" + MAPQUEST_KEY + "&lat=" + lat + "&lng=" + lng;
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
