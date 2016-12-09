package com.oose2016.group4.server;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Map;

import com.google.gson.Gson;

public class MapQuestHandler extends RequestHandler {
	private static String MAPQUEST_KEY = "afbtgu28aAJW4kgGbc8yarMCZ3LdWWbh";
	private static String mapquestEndpoint = "http://www.mapquestapi.com/directions/v2/findlinkid";
	
	/**
	 * GETs the linkId associated with a particular crime's coordinates.
	 * @param lat latitude
	 * @param lng longitude
	 * @return the linkId of that crime
	 * @throws IOException if GET request doesn't work
	 */
	protected static int requestLinkId(double lat, double lng) throws IOException {
		String url = mapquestEndpoint + "?key=" + MAPQUEST_KEY + "&lat=" + lat + "&lng=" + lng;
		String response = makeGetRequest(url);
		Map<String, Object> resp = new Gson().fromJson(response, Map.class);
		double linkiddble = (double) resp.get("linkId");
		int linkid = (int) linkiddble;
		return linkid;
	}
}
