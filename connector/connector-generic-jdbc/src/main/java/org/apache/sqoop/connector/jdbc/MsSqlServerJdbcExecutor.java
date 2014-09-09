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

import org.apache.log4j.Logger;
import org.apache.sqoop.common.SqoopException;

import java.sql.DriverManager;
import java.sql.SQLException;


public class MsSqlServerJdbcExecutor extends GenericJdbcExecutor {

    private static final Logger LOG =
            Logger.getLogger(MsSqlServerJdbcExecutor.class);

    public MsSqlServerJdbcExecutor(String driver, String url,
                               String username, String password) {
        try {
            Class.forName(driver);
            connection = DriverManager.getConnection(url, username, password);

        } catch (ClassNotFoundException e) {
            throw new SqoopException(
                    GenericJdbcConnectorError.GENERIC_JDBC_CONNECTOR_0000, driver, e);

        } catch (SQLException e) {
            logSQLException(e);
            throw new SqoopException(GenericJdbcConnectorError.GENERIC_JDBC_CONNECTOR_0001, e);
        }
        LOG.info("New MsSqlServerJdbcExecutor created.");
    }


    @Override
    protected String getInsertQuery(String fromTable, String toTable) {
        return "INSERT INTO " + toTable +
                "  SELECT * FROM " + fromTable + " ";
    }
}
