package com.oose2016.group4.server;

import com.google.gson.Gson;

import org.sql2o.Connection;
import org.sql2o.Sql2o;
import org.sqlite.SQLiteDataSource;

import spark.Spark;
import spark.utils.IOUtils;

import java.io.IOException;
import java.io.OutputStreamWriter;
import java.lang.reflect.Type;
import java.net.URL;
import java.net.HttpURLConnection;
import java.util.LinkedList;
import java.util.List;

import org.junit.*;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;

import static org.junit.Assert.*;

public class TestServer {
	SQLiteDataSource dSource;
	// ------------------------------------------------------------------------//
	// Setup
	// ------------------------------------------------------------------------//
	@InjectMocks private MockConnection mockConnection;
	@Mock private Connection connection;

	
	@Before
	public void setup() throws Exception {
		// Clear the database and then start the server
		dSource = clearDB();

		// Start the main server
		Bootstrap.main(null);
		Spark.awaitInitialization();
		MockitoAnnotations.initMocks(this);

	}

	@Test
	public void testGetLatLong() throws Exception {
		Coordinate c = new Coordinate(0.5, 0.7);
		assertEquals(0.5, c.getLatitude(), 0);
		assertEquals(0.7, c.getLongitude(), 0);
	}
	
	@Test
	public void testSortAndExpand() throws Exception {
		//c1 < c2
		Coordinate c1 = new Coordinate(0.5, 0.7);
		Coordinate c2 = new Coordinate(0.9, 1.1);
		Coordinate.sortAndExpand(c1, c2);
		assertEquals(0.49, c1.getLatitude(), 0);
		assertEquals(0.6886, c1.getLongitude(), 0.01);
		assertEquals(0.91, c2.getLatitude(), 0);
		assertEquals(1.11608, c2.getLongitude(), 0.01);

		//c3 > c4
		Coordinate c3 = new Coordinate(0.9, 1.1);
		Coordinate c4 = new Coordinate(0.5, 0.7);
		Coordinate.sortAndExpand(c3, c4);
		assertEquals(0.49, c3.getLatitude(), 0);
		assertEquals(0.6886, c3.getLongitude(), 0.01);
		assertEquals(0.91, c4.getLatitude(), 0);
		assertEquals(1.11608, c4.getLongitude(), 0.01);
		
		//c5.lat < c6.lat; c5.long > c6.long
		Coordinate c5 = new Coordinate(0.5, 1.1);
		Coordinate c6 = new Coordinate(0.9, 0.7);
		Coordinate.sortAndExpand(c5, c6);
		assertEquals(0.49, c5.getLatitude(), 0);
		assertEquals(0.6886, c5.getLongitude(), 0.01);
		assertEquals(0.91, c6.getLatitude(), 0);
		assertEquals(1.11608, c6.getLongitude(), 0.01);
		
		//c7.lat > c8.lat; c5.long < c6.long
		Coordinate c7 = new Coordinate(0.9, 0.7);
		Coordinate c8 = new Coordinate(0.5, 1.1);
		Coordinate.sortAndExpand(c7, c8);
		assertEquals(0.49, c7.getLatitude(), 0);
		assertEquals(0.6886, c7.getLongitude(), 0.01);
		assertEquals(0.91, c8.getLatitude(), 0);
		assertEquals(1.11608, c8.getLongitude(), 0.01);
	}

	/*
	@Test
	public void testFetchLinkIds() throws Exception {
		String predicate = "count > 2";
		String sql = "SELECT linkId, COUNT(linkId) AS count FROM crimes WHERE "
				+ "latitude >= :fromLat AND latitude <= :toLat AND "
				+ "longitude >= :fromLng AND longitude <= :toLng GROUP BY linkId HAVING " + predicate;
		
		Coordinate from = new Coordinate(0.5, 0.7);
		Coordinate to = new Coordinate(0.9, 1.1);

		//int[] red = {};
		//int[] yellow = {};
		//AvoidLinkIds outerObject = new AvoidLinkIds(red, yellow);
		AvoidLinkIds.LinkId innerObject1 = new AvoidLinkIds.LinkId();
		innerObject1.setLinkId(1);
		AvoidLinkIds.LinkId innerObject2 = new AvoidLinkIds.LinkId();
		innerObject2.setLinkId(2);
		AvoidLinkIds.LinkId innerObject3 = new AvoidLinkIds.LinkId();
		innerObject3.setLinkId(3);

		List<AvoidLinkIds.LinkId> list= new LinkedList<>();
		list.add(innerObject1);
		list.add(innerObject2);
		list.add(innerObject3);
		
		Mockito.when(connection.createQuery(sql).addParameter("fromLat", from.getLatitude())
				.addParameter("toLat", to.getLatitude()).addParameter("fromLng", from.getLongitude())
				.addParameter("toLng", to.getLongitude()).executeAndFetch(AvoidLinkIds.LinkId.class))
				.thenReturn(list);
		
		SurvivalService s = new SurvivalService(dSource); 
		Sql2o database = s.getDb(); 
		
		s.getAvoidLinkIds(Coordinate from, Coordinate to)
		s.fetchLinkIds(connection, from, to, "count > 2");
	} */
	
	
	@After
	public void tearDown() {
		// Stop the server
		clearDB();
		Spark.stop();
	}

	// ------------------------------------------------------------------------//
	// Tests
	// ------------------------------------------------------------------------//
	@Test
	public void test() throws Exception {
		TestServer t = new TestServer();
		t.setup();
		t.testGetLatLong();
		t.testSortAndExpand();
		t.tearDown();
	}

	// ------------------------------------------------------------------------//
	// Generic Helper Methods and classes
	// ------------------------------------------------------------------------//
	private Response request(String method, String path, String json) {
		try {
			URL url = new URL("http", "localhost", Bootstrap.PORT, path);
			System.out.println(url);
			HttpURLConnection http = (HttpURLConnection) url.openConnection();
			http.setRequestMethod(method);
			http.setDoInput(true);
			if (json != null) {
				http.setDoOutput(true);
				http.setRequestProperty("Content-Type", "application/json");
				OutputStreamWriter output = new OutputStreamWriter(http.getOutputStream());
				output.write(json);
				output.flush();
				output.close();
			}

			int responseCode = http.getResponseCode();
			String responseBody;
			try {
				responseBody = IOUtils.toString(http.getInputStream());
			} catch (Exception e) {
				responseBody = IOUtils.toString(http.getErrorStream());
			}
			return new Response(responseCode, responseBody);
		} catch (IOException e) {
			e.printStackTrace();
			fail("Sending request failed: " + e.getMessage());
			return null;
		}
	}

	private static class Response {
		public String content;
		public int httpStatus;

		public Response(int httpStatus, String content) {
			this.content = content;
			this.httpStatus = httpStatus;
		}

		public <T> T getContentAsObject(Type type) {
			return new Gson().fromJson(content, type);
		}
	}

	// ------------------------------------------------------------------------//
	// Dots Specific Helper Methods and classes
	// ------------------------------------------------------------------------//
	private SQLiteDataSource clearDB() {
		SQLiteDataSource dataSource = new SQLiteDataSource();
		dataSource.setUrl("jdbc:sqlite:dots.db");

		Sql2o db = new Sql2o(dataSource);

		try (Connection conn = db.open()) {
			String sql = "DROP TABLE IF EXISTS boards";
			conn.createQuery(sql).executeUpdate();
		}
		
		return dataSource;
	}
}
