package com.oose2016.group4.server;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

public class CrimeAPIHandler extends RequestHandler {
	private static String crimeDataEndpoint = "https://data.baltimorecity.gov/resource/4ih5-d5d5.json"; 
	
	/**
	 * GETs crime data from Open Baltimore database
	 * @return The JSON containing a list of crimes
	 * @throws IOException
	 */
	protected static String getCrimeData() throws IOException {
		return makeGetRequest(crimeDataEndpoint);
	}	
}
