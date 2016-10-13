package com.oose2016.group4.server;

import java.util.List;

import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.sql2o.Connection;
import org.sql2o.Sql2o;
import org.sql2o.Sql2oException;

public class SurvivalService {
	private Sql2o db;

	private static Logger logger = LoggerFactory.getLogger(SurvivalService.class);

	public SurvivalService(DataSource dataSource) {
		db = new Sql2o(dataSource);
	}

	public LinkIds getAvoidLinkIds(Coordinate from, Coordinate to) {
		try (Connection conn = db.open()) {
			int[] red = fetchLinkIds(conn, from, to, "count > 2");
			int[] yellow = fetchLinkIds(conn, from, to, "count = 2");
			return new LinkIds(red, yellow);
		} catch (Sql2oException e) {
			logger.error("Failed to fetch linkIds", e);
			return null;
		}
	}

	private int[] fetchLinkIds(Connection conn, Coordinate from, Coordinate to, String predicate)
			throws Sql2oException {
		String sql = "SELECT linkId, COUNT(linkId) AS count FROM crimes WHERE "
				+ "latitude >= :fromLat AND latitude <= :toLat AND "
				+ "longitude >= :fromLng AND longitude <= :toLng GROUP BY linkId HAVING " + predicate;
		List<LinkIds.LinkId> results = conn.createQuery(sql).addParameter("fromLat", from.getLatitude())
				.addParameter("toLat", to.getLatitude()).addParameter("fromLng", from.getLongitude())
				.addParameter("toLng", to.getLongitude()).executeAndFetch(LinkIds.LinkId.class);
		int size = results.size();
		int[] linkIds = new int[size];
		for (int i = 0; i < size; i++) {
			linkIds[i] = results.get(i).getLinkId();
		}
		return linkIds;
	}
}
