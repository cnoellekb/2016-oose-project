package com.oose2016.group4.server;

/**
 * LinkIds to avoid
 */
public class AvoidLinkIds {
	public static class LinkId {
		private int linkId, count;

		public int getLinkId() {
			return linkId;
		}

		public int getCount() {
			return count;
		}
		
		public void setLinkId(int id) {
			linkId = id;
		}
	}

	@SuppressWarnings("unused")
	private int[] red, yellow;

	public AvoidLinkIds(int[] red, int[] yellow) {
		this.red = red;
		this.yellow = yellow;
	}

	
	public int[] getRed() {
		return this.red;
	}
	
	public int[] getYellow() {
		return this.yellow;
	}
}
