package com.oose2016.group4.server;

import java.util.Date;

public class Crime {
	private Date date;
	private String addr, type;
	private double lat, lng;
	
	public Crime(Date date, String addr, double lat, double lng, String type) {
		this.date = date;
		this.addr = addr;
		this.lat = lat;
		this.lng = lng;
		this.type = type;
	}
	
	public Date getDate() {
		return date;
	}
	
	public String getAddress() {
		return addr;
	}
	
	public double getLat() {
		return lat;
	}
	
	public double getLng() {
		return lng;
	}
	
	public String getType() {
		return type;
	}
}
