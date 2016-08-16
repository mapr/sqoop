package org.apache.sqoop.client.request;

import org.apache.hadoop.security.authentication.client.Authenticator;
import org.apache.hadoop.security.token.delegation.web.DelegationTokenAuthenticator;

public class MaprDelegationTokenAuthenticator extends DelegationTokenAuthenticator {
    private static Class maprAuthenticatorClass;
    static {
        try {
            maprAuthenticatorClass = MaprDelegationTokenAuthenticator.class.getClassLoader()
                    .loadClass("com.mapr.security.maprauth.MaprAuthenticator");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    public MaprDelegationTokenAuthenticator() throws IllegalAccessException, InstantiationException {
        super((Authenticator)maprAuthenticatorClass.newInstance());
    }
}