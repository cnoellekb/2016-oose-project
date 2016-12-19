package com.oose2016.group4.server;

import java.io.IOException;
import java.util.List;

import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.sql2o.Connection;
import org.sql2o.Query;
import org.sql2o.Sql2o;
import org.sql2o.Sql2oException;

/**
 * Query the database
 */
public class SurvivalService {
	private Sql2o db;


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
	/**
	 * Retrieve all the crimes in the database within a certain time, latitude and longitude 
	 * range.
	 * @param from starting crime point
	 * @param to ending crime point
	 * @param timeOfDay the time of day
	 * @return the results of our query to the database
	 */
	public List<Crime> getCrimes(Crime from, Crime to, int timeOfDay, String table) {
		try (Connection conn = db.open()) {
			String sql = "SELECT date, address, latitude, longitude, type FROM :table WHERE "
					+ "latitude >= :fromLat AND latitude <= :toLat AND date >= :fromDate AND "
					+ "longitude >= :fromLng AND longitude <= :toLng AND date <= :toDate;";
					//+ "time = :timeOfDay"; TODO figure out what to do with this
			Query query = conn.createQuery(sql);
			query.addParameter("fromLat", from.getLat()).addParameter("toLat", to.getLat())
				.addParameter("fromLng", from.getLng()).addParameter("toLng", to.getLng())
				.addParameter("fromDate", from.getDate()).addParameter("toDate", to.getDate())
				.addParameter("table", table);
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
	public void updateDB(String table) {
		try (Connection conn = db.open()){
			DatabaseUpdater DatabaseUpdater = new DatabaseUpdater(conn);
			DatabaseUpdater.initialUpdate();
			DatabaseUpdater.update(table);
		} catch (IOException e) {
			e.printStackTrace();
		} catch (Sql2oException e) {
			logger.error("Failed to get crimes", e);
		}
	}
	
	public String getSafetyRating(double x, double y) {
		try (Connection conn = db.open()) {
			String sql = "SELECT SUM(alarm) FROM grids WHERE "
					+ "x <= :x + 0.0001 AND x >= :x - 0.0001 AND y <= :y + 0.0001 AND y >= :y - 0.0001;";
			Query query = conn.createQuery(sql);
			query.addParameter("x", x).addParameter("y", y);
			double result = query.executeScalar(Double.class);
			
			if (result > 200) {
				return "red";
			} else if (result > 50) {
				return "yellow";
			} else {
				return "green";
			}
			
		} catch (Sql2oException e) {
			logger.error("Failed to get crimes", e);
			return null;
		}	
	}

}