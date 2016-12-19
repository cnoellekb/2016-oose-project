package com.oose2016.group4.server;

/**
 * Coordinate in latitude and longitude
 */
public class Coordinate {
	private double latitude, longitude;

	public double getLatitude() {
		return latitude;
	}

	public double getLongitude() {
		return longitude;
	}

	public Coordinate(double latitude, double longitude) throws Exception {
		if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
			throw new Exception("Not valid coordinate");
		}
		this.latitude = latitude;
		this.longitude = longitude;
	}

	/**
	 * Sort coordinates and expand a bit
	 * @param a set to top left coordinate
	 * @param b set to bottom right coordinate
	 */
	public static void sortAndExpand(Coordinate a, Coordinate b) {
		if (a.latitude < b.latitude) {
			a.latitude -= 0.01;
			b.latitude += 0.01;
		} else {
			double temp = a.latitude;
			a.latitude = b.latitude - 0.01;
			b.latitude = temp + 0.01;
		}
		if (a.longitude < b.longitude) {
			a.longitude -= 0.01 / Math.cos(Math.toRadians(a.latitude));
			b.longitude += 0.01 / Math.cos(Math.toRadians(b.latitude));
		} else {
			double temp = a.longitude;
			a.longitude = b.longitude - 0.01 / Math.cos(Math.toRadians(a.latitude));
			b.longitude = temp + 0.01 / Math.cos(Math.toRadians(b.latitude));
		}
	}
}