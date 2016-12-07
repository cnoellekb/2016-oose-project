package com.oose2016.group4.server;

import java.util.Date;

public class Crime {
	private int date, linkid;
	private String address, type;
	private double latitude, longitude;
	
	public Crime(int date, String address, String type, double latitude, double longitude, int linkid) {
		this.date = date;
		this.address = address;
		this.type = type;
		this.latitude = latitude;
		this.longitude = longitude;
		this.linkid = linkid;
	}
	
	public int getDate() {
		return date;
	}
	
	public String getAddress() {
		return address;
	}
	
	public double getLat() {
		return latitude;
	}
	
	public double getLng() {
		return longitude;
	}
	
	public String getType() {
		return type;
	}
	
	public double getLinkId() {
		return linkid;
	}
}
