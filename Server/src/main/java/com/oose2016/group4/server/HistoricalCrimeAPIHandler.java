package com.oose2016.group4.server;

import com.google.gson.Gson;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Map;

/**
 * Created by vegito2002 on 12/20/16.
 */
public class HistoricalCrimeAPIHandler extends RequestHandler {
    private static String URL_CRIME_SOURCE = "https://data.baltimorecity.gov/api/views/wsfq-mvij/rows.json";

    public static ArrayList<Object> preProccessCrimeData() throws IOException {
        System.out.printf("entering preprocessing data.");
        String stringResult = makeGetRequest(URL_CRIME_SOURCE);
        System.out.println("string data successfully fetched.");
        Map<String, Object> mapResponse = new Gson().fromJson(stringResult, Map.class);
        System.out.println("map formatted data successfully fetched.");
        ArrayList<Object> listResponce = (ArrayList<Object>)mapResponse.get("data");
        System.out.println("ArrayList formatted data successfully fetched.");
        return listResponce;
    }

}
