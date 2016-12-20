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
    private double mAlarm;
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

    public Grid() {
        x =0 ;
        y = 0 ;
        mLinkId = 0;
        mAlarm = 0;
        mAADT = 0;
    }

    public Grid(int xArg, int yArg, int linkIdArg, double alarmArg, int aadtArg) {
        x = xArg;
        y= yArg;
        mLinkId = linkIdArg;
        mAlarm = alarmArg;
        mAADT = aadtArg;
    }

    public void setmLinkId(int mLinkId) {
        this.mLinkId = mLinkId;
    }

    public void setmAlarm(double mAlarm) {
        this.mAlarm = mAlarm;
    }

    public void setmAADT(int mAADT) {
        this.mAADT = mAADT;
    }

    public int getX() { return x; }
    public int getY() { return y; }
    public int getmLinkId() { return mLinkId; }
    public double getmAlarm() { return mAlarm; }
    public int getmAADT() { return mAADT; }

}
