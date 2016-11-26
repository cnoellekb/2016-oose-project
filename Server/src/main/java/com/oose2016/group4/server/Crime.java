package com.oose2016.group4.server;

import java.util.Date;

public class Crime {
	private Date date;
	private String address, type;
	private double latitude, longitude;
	
	public Date getDate() {
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
}
