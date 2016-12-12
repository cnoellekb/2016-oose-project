package com.oose2016.group4.server;

import java.lang.Math;

/**
 * Created by vegito2002 on 12/10/16.
 */
public class Grid {
    private int x,y;

    public Grid (int x, int y) {
        this.x=x;
        this.y=y;
    }



    public Grid (double lat, double lng) {
        double latitudeDegree = lat * Math.PI / 180;
		double dx = (lng + 180) / 360 * 262144;
		double dy = (1 - (Math.log(Math.tan(latitudeDegree) + 1 / Math.cos(latitudeDegree)) / Math.PI)) / 2 * 262144;
		this.x = (int) dx;
		this.y = (int) dy;
    }

    public int getX() { return x; }
    public int getY() { return y; }
}
