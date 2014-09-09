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


public class JdbcExecutorFactory {
    private static String EMPTY_STRING = "";
    private static String SQLSERVER = "sqlserver";

    public static IBaseJdbcExecutor build(String driver, String url,
                                         String username, String password){

        if(isMsSqlServer(url)){
            return new MsSqlServerJdbcExecutor(driver, url, username, password);
        }
        return new CommonJdbcExecutor(driver, url, username, password);
    }

    private static boolean isMsSqlServer(String url){
        if(url == null || EMPTY_STRING.equals(url)){
            return false;
        }
        return (url.toLowerCase().contains(SQLSERVER));
    }
}
