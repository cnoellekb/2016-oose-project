package com.oose2016.group4.server;

public class CrimePoint {
	private int date;
	private double lat, lng;
	
	public CrimePoint(int date, double lat, double lng) {
		this.date = date;
		this.lat = lat;
		this.lng = lng;
	}
	
	public int getDate() {
		return date;
	}
	
	public double getLat() {
		return lat;
	}
	
	public double getLng() {
		return lng;
	}
}
