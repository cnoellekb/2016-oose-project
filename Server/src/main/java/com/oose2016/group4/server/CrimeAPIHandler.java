package com.oose2016.group4.server;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

public class CrimeAPIHandler {
	private static String crimeDataEndpoint = "https://data.baltimorecity.gov/resource/4ih5-d5d5.json"; 
	
	/**
	 * GETs crime data from Open Baltimore database
	 * @return The JSON containing a list of crimes
	 * @throws IOException
	 */
	protected static String getCrimeData() throws IOException {
		return makeGetRequest(crimeDataEndpoint);
	}
	
	/**
	 * Takes in any url (assumed to include endpoint and params) and makes a 
	 * GET request.
	 * @param url compose of endpoint and any potential parameters
	 * @return the response object as a JSON 
	 * @throws IOException if GET request doesn't work
	 */
	private static String makeGetRequest(String url) throws IOException {
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
