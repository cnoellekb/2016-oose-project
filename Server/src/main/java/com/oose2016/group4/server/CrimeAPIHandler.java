package com.oose2016.group4.server;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;

import com.google.gson.Gson;

public class CrimeAPIHandler extends RequestHandler {
	private static String URL_CRIME_SOURCE = "https://data.baltimorecity.gov/resource/4ih5-d5d5.json";
	
	/**
     * Fetch raw crime data from data.baltimorecity.gov and transform the result into proper form to store.
     * @return the crime data in an ArrayList
     * @throws IOException
     */
    protected static ArrayList<Object> preProccessCrimeData() throws IOException {
        String stringResult = makeGetRequest(URL_CRIME_SOURCE);
        return new Gson().fromJson(stringResult, ArrayList.class);
    };
}
