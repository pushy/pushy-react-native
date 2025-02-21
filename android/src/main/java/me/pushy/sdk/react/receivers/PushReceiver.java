package me.pushy.sdk.react.receivers;

import android.content.Intent;
import android.content.Context;
import android.content.BroadcastReceiver;
import android.os.Handler;
import android.os.Looper;

import me.pushy.sdk.react.services.PushyNotificationService;

public class PushReceiver extends BroadcastReceiver {
    static PushyNotificationService mNotificationService;

    @Override
    public void onReceive(final Context context, final Intent intent) {
        // Run on main UI thread
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            @Override
            public void run() {
                // Instantiate static notification service class
                if (mNotificationService == null) {
                    mNotificationService = new PushyNotificationService(context);
                }

                // Execute onStartCommand without actually starting the service (Android O Background Execution Limits)
                mNotificationService.onStartCommand(intent, 0, 0);
            }
        });
    }
}