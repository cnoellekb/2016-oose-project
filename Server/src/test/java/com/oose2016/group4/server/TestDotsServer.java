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

import org.junit.*;
import static org.junit.Assert.*;

public class TestDotsServer {
	// ------------------------------------------------------------------------//
	// Setup
	// ------------------------------------------------------------------------//
	@Before
	public void setup() throws Exception {
		// Clear the database and then start the server
		clearDB();

		// Start the main server
		Bootstrap.main(null);
		Spark.awaitInitialization();
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
	public void test() throws Exception {
		// TODO
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
	private void clearDB() {
		SQLiteDataSource dataSource = new SQLiteDataSource();
		dataSource.setUrl("jdbc:sqlite:dots.db");

		Sql2o db = new Sql2o(dataSource);

		try (Connection conn = db.open()) {
			String sql = "DROP TABLE IF EXISTS boards";
			conn.createQuery(sql).executeUpdate();
		}
	}
}
