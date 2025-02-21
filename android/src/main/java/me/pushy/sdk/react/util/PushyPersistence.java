package me.pushy.sdk.react.util;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

public class PushyPersistence {
    public static final String NOTIFICATION_ICON = "pushyNotificationIcon";

    private static SharedPreferences getSettings(Context context) {
        // Get default app SharedPreferences
        return PreferenceManager.getDefaultSharedPreferences(context);
    }

    public static void setNotificationIcon(String icon, Context context) {
        // Store notification icon in SharedPreferences
        getSettings(context).edit().putString(PushyPersistence.NOTIFICATION_ICON, icon).commit();
    }

    public static String getNotificationIcon( Context context) {
        // Get notification icon from SharedPreferences
        return getSettings(context).getString(PushyPersistence.NOTIFICATION_ICON, null);
    }

}
