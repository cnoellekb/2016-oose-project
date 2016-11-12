package com.oose2016.group4.server;

import java.util.Map;

public interface RequestHandler {
	Answer process(Map<String, String> urlParams);
}