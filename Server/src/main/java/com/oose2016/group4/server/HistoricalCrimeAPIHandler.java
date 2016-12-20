package com.oose2016.group4.server;

import com.google.gson.Gson;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Map;

/**
 * Created by vegito2002 on 12/20/16.
 */
public class HistoricalCrimeAPIHandler extends CrimeAPIHandler {
    private static String URL_CRIME_SOURCE = "https://data.baltimorecity.gov/api/views/wsfq-mvij/rows.json";

    private ArrayList<Object> parseStringResult(String stringResult) {
        Map<String, Object> mapResponse = new Gson().fromJson(stringResult, Map.class);
        ArrayList<Object> listResponce = (ArrayList<Object>)mapResponse.get("data");
        return listResponce;
    }

}
