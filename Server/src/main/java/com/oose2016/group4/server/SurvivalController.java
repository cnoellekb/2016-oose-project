package com.oose2016.group4.server;

import static spark.Spark.get;

import java.util.Collections;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Setup the web server and handle all requests and responses.
 */
public class SurvivalController {
	private static final String API_CONTEXT = "/v1";

	private SurvivalService survivalService;

	private final Logger logger = LoggerFactory.getLogger(SurvivalController.class);

	public SurvivalController(SurvivalService survivalService) {
		this.survivalService = survivalService;
		setupEndpoints();
	}

	/**
	 * Setup handlers for all request paths.
	 */
	private void setupEndpoints() {
		/**
		 * Retrieve linkIDs to Avoid
		 */
		get(API_CONTEXT + "/avoidLinkIds", "application/json", (request, response) -> {
			try {
				double fromLat = Double.parseDouble(request.queryParams("fromLat"));
				double fromLng = Double.parseDouble(request.queryParams("fromLng"));
				double toLat = Double.parseDouble(request.queryParams("toLat"));
				double toLng = Double.parseDouble(request.queryParams("toLng"));
				//int timeOfDay = Integer.parseInt(request.queryParams("timeOfDay"));
				Coordinate from = new Coordinate(fromLat, fromLng);
				Coordinate to = new Coordinate(toLat, toLng);
				Coordinate.sortAndExpand(from, to);
				response.status(200);
				return survivalService.getAvoidLinkIds(from, to);
			} catch (Exception e) {
				logger.info("Invalid request", e);
				response.status(400);
				return Collections.EMPTY_MAP;
			}
		}, new JsonTransformer());
		
		
		/**
		 * Get Crime List.
		 */
		get(API_CONTEXT + "/crimes", "application/json", (request, response) -> {
			try {
				double fromLat = Double.parseDouble(request.queryParams("fromLat"));
				double fromLng = Double.parseDouble(request.queryParams("fromLng"));
				double toLat = Double.parseDouble(request.queryParams("toLat"));
				double toLng = Double.parseDouble(request.queryParams("toLng"));
				int timeOfDay = Integer.parseInt(request.queryParams("timeOfDay"));
				int fromDate = Integer.parseInt(request.queryParams("fromDate"));
				int toDate = Integer.parseInt(request.queryParams("toDate"));
				//types: <Comma separated Strings>
				//get array of crimes (int date, String addr, double lat, double lng, String type
				Crime from = new Crime(fromDate, fromLat, fromLng);
				Crime to = new Crime(toDate, toLat, toLng);
				response.status(200);
				return survivalService.getCrimes(from, to, timeOfDay, "crimes");
			} catch (Exception e) {
				logger.info("Invalid request", e);
				response.status(404); //unsupported location
				return Collections.EMPTY_MAP;
			}
		}, new JsonTransformer());
		
		/**
		 * Do some data preprocessing for database.
		 */
		get(API_CONTEXT + "/update/db", "application/json", (request, response) -> {
			survivalService.updateDB("crimes");
			return Collections.EMPTY_MAP;
		}, new JsonTransformer());
		
		/**
		 * 
		 */
		get(API_CONTEXT + "/safety/rating", "application/json", (request, response) -> {
			double lat = Double.parseDouble(request.queryParams("lat"));
			double lng = Double.parseDouble(request.queryParams("lng"));
			return survivalService.getSafetyRating(lat,lng);
		}, new JsonTransformer());
	}

}