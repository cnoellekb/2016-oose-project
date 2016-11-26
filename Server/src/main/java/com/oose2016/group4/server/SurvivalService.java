package com.oose2016.group4.server;

import java.util.ArrayList;
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
			int[] red = fetchLinkIds(conn, from, to, "count > 2");
			int[] yellow = fetchLinkIds(conn, from, to, "count = 2");
			return new AvoidLinkIds(red, yellow);
		} catch (Sql2oException e) {
			logger.error("Failed to fetch linkIds", e);
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
			throws Sql2oException {
		String sql = "SELECT linkId, COUNT(linkId) AS count FROM crimes WHERE "
				+ "latitude >= :fromLat AND latitude <= :toLat AND "
				+ "longitude >= :fromLng AND longitude <= :toLng GROUP BY linkId HAVING " + predicate;
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
	 * @return
	 * @throws Sql2oException
	 */
	public List<Crime> getCrimes(CrimePoint from, CrimePoint to, int timeOfDay) throws Sql2oException {
		try (Connection conn = db.open()) {
			String sql = "SELECT date, address, latitude, longitude, type FROM crimes WHERE "
					+ "latitude >= :fromLat AND latitude <= :toLat AND date >= :fromDate AND "
					+ "longitude >= :fromLng AND longitude <= :toLng AND date <= :toDate;";
					//+ "time = :timeOfDay"; TODO figure out what to do with this
			Query query = conn.createQuery(sql);
			query.addParameter("fromLat", from.getLat()).addParameter("toLat", to.getLat())
				.addParameter("fromLng", from.getLng()).addParameter("toLng", to.getLng())
				.addParameter("fromDate", from.getDate()).addParameter("toDate", to.getDate())
				.addParameter("timeOfDay", timeOfDay);
			List<Crime> results = query.executeAndFetch(Crime.class);
			return results;
		} catch (Sql2oException e) {
			logger.error("Failed to get crimes", e);
			return null;
		}	
	}
}
