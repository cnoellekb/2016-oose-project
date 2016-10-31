/**
 * 
 */
package com.oose2016.group4.server;

import org.sql2o.Connection;
import org.sql2o.Query;

import static org.mockito.Mockito.*;
import org.testng.annotations.Test;
/**
 * @author Jeana Yee
 *
 */
public class MockConnection {
	@Test
	public void createQuery(String sql) {
		Connection conn = mock(Connection.class);
		Query query = mock(Query.class);
		when(conn.createQuery(sql)).thenReturn(query);
	}
}
