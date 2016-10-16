package com.oose2016.group4.server;

public class LinkIds {
	public static class LinkId {
		private int linkId, count;

		public int getLinkId() {
			return linkId;
		}

		public int getCount() {
			return count;
		}
	}

	@SuppressWarnings("unused")
	private int[] red, yellow;

	public LinkIds(int[] red, int[] yellow) {
		this.red = red;
		this.yellow = yellow;
	}
}
