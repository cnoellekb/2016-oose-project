package com.oose2016.group4.server;

import java.lang.Math;
import java.math.BigDecimal;

/**This class is used to map latitudes and longitudes in double type into grids on the map, which is plotted with
 * int type indices x and y.
 * This is an effective measure to cope with MapQuest's restrictions on non-commercial user licenses.
 * Created by vegito2002 on 12/10/16.
 */
public class Grid {
    private int x,y;
    private int mLinkId;
    private float mAlarm;
    private int mAADT;

    public Grid (int x, int y) {
        this.x=x;
        this.y=y;
        mLinkId = 0;
        mAlarm = 0;
        mAADT = 0;
    }

    /**
     * The major purpose of this class: mapping actually geographical coordinates
     * to integer-formatted grid coordinates.
     * @param lat
     * @param lng
     */
    public Grid (double lat, double lng) {
        double latitudeDegree = lat * Math.PI / 180;
		double dx = (lng + 180) / 360 * 262144;
		double dy = (1 - (Math.log(Math.tan(latitudeDegree) + 1 / Math.cos(latitudeDegree)) / Math.PI)) / 2 * 262144;
		this.x = (int) dx;
		this.y = (int) dy;
        mLinkId = 0;
        mAlarm = 0;
        mAADT = 0;
    }


    public int getX() { return x; }
    public int getY() { return y; }
}
