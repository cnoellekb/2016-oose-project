package com.oose2016.group4.server;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

public abstract class RequestHandler {
	
	/**
	 * Takes in any url (assumed to include endpoint and params) and makes a 
	 * GET request.
	 * @param url compose of endpoint and any potential parameters
	 * @return the response object as a JSON 
	 * @throws IOException if GET request doesn't work
	 */
	protected static String makeGetRequest(String url) throws IOException {
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
