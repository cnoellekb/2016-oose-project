package com.oose2016.group4.server;

import com.google.gson.Gson;
//import com.todoapp.Todo;
//import com.todoapp.TestTodoServer.Response;

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
import java.util.Arrays;

import org.junit.*;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import static org.junit.Assert.*;
import org.testng.annotations.Test;

public class ServerTest {
	SQLiteDataSource dSource;
	// ------------------------------------------------------------------------//
	// Setup - based on To-Do server unit tests.
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

	@Test
	public void testGetAvoidLinkIds() throws Exception {
		SurvivalService s = new SurvivalService(dSource);
		
		Coordinate from = new Coordinate(38.987194, -76.945999);
		Coordinate to = new Coordinate(39.004611, -76.875671);
		int[] red = s.getAvoidLinkIds(from, to).getRed();
		int[] yellow = s.getAvoidLinkIds(from, to).getYellow();
		
		int[] redTarget = {39664759};
		int[] yellowTarget = {39303826, 39484084, 39643466, 39643812, 39651557, 39659946}; 

		assertTrue(Arrays.equals(red, redTarget));
		assertTrue(Arrays.equals(yellow, yellowTarget));
	} 

	/**
	 * Code based on To-Do server test.
	 */
	@Test
	public void testSetupEndpoints() {
		SurvivalService s = new SurvivalService(dSource);
		SurvivalController controller = new SurvivalController(s);
		
		Response r = request("GET", "/avoidLinkIds", "fromLat=38.987194&toLat=39.004611&fromLng=-76.945999&toLng=-76.875671");
        assertEquals("Failed to get todo", 200, r.httpStatus);
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
		dataSource.setUrl("jdbc:sqlite:server.db"); //dots.db

		Sql2o db = new Sql2o(dataSource);

		try (Connection conn = db.open()) {
			String sql = "DROP TABLE IF EXISTS boards";
			conn.createQuery(sql).executeUpdate();
		}
		
		return dataSource;
	}
}
