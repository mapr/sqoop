/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.apache.sqoop.connector.jdbc;

import junit.framework.TestCase;

public class CommonJdbcExecutorTest extends TestCase {
  private final String table;
  private final String emptyTable;
  private final IBaseJdbcExecutor executor;

  private static final int START = -50;
  private static final int NUMBER_OF_ROWS = 974;

  public CommonJdbcExecutorTest() {
    table = getClass().getSimpleName().toUpperCase();
    emptyTable = table + "_EMPTY";
    executor = new CommonJdbcExecutor(GenericJdbcTestConstants.DRIVER,
      GenericJdbcTestConstants.URL, null, null);
  }

  @Override
  public void setUp() {
    if(executor.existTable(emptyTable)) {
      executor.executeUpdate("DROP TABLE " + emptyTable);
    }
    executor.executeUpdate("CREATE TABLE "
      + emptyTable + "(ICOL INTEGER PRIMARY KEY, VCOL VARCHAR(20))");

    if(executor.existTable(table)) {
      executor.executeUpdate("DROP TABLE " + table);
    }
    executor.executeUpdate("CREATE TABLE "
      + table + "(ICOL INTEGER PRIMARY KEY, VCOL VARCHAR(20))");

    for (int i = 0; i < NUMBER_OF_ROWS; i++) {
      int value = START + i;
      String sql = "INSERT INTO " + table
        + " VALUES(" + value + ", '" + value + "')";
      executor.executeUpdate(sql);
    }
  }

  @SuppressWarnings("unchecked")
  public void testDeleteTableData() throws Exception {
    executor.deleteTableData(table);
    assertEquals("Table " + table + " is expected to be empty.",
      0, executor.getTableRowCount(table));
  }

  @SuppressWarnings("unchecked")
  public void testMigrateData() throws Exception {
    assertEquals("Table " + emptyTable + " is expected to be empty.",
      0, executor.getTableRowCount(emptyTable));
    assertEquals("Table " + table + " is expected to have " +
      NUMBER_OF_ROWS + " rows.", NUMBER_OF_ROWS,
      executor.getTableRowCount(table));

    executor.migrateData(table, emptyTable);

    assertEquals("Table " + table + " is expected to be empty.", 0,
      executor.getTableRowCount(table));
    assertEquals("Table " + emptyTable + " is expected to have " +
      NUMBER_OF_ROWS + " rows.", NUMBER_OF_ROWS,
      executor.getTableRowCount(emptyTable));
  }

  @SuppressWarnings("unchecked")
  public void testGetTableRowCount() throws Exception {
    assertEquals("Table " + table + " is expected to be empty.",
      NUMBER_OF_ROWS, executor.getTableRowCount(table));
  }
}
