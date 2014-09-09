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


import java.sql.ResultSet;

public interface IBaseJdbcExecutor {
    ResultSet executeQuery(String sql);
    public void setAutoCommit(boolean autoCommit);
    public void deleteTableData(String tableName) ;
    public void migrateData(String fromTable, String toTable);
    public long getTableRowCount(String tableName);
    public void executeUpdate(String sql);
    public void beginBatch(String sql);
    public void addBatch(Object[] array);
    public void executeBatch(boolean commit);
    public void endBatch() ;
    public String getPrimaryKey(String table);
    public String[] getQueryColumns(String query);
    public boolean existTable(String table);
    public String qualify(String name, String qualifier);
    public String[] dequalify(String name);
    public String delimitIdentifier(String name);
    public void close();

}
