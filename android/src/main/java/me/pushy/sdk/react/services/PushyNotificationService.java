package me.pushy.sdk.react.services;

import android.annotation.SuppressLint;
import android.app.Application;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import com.facebook.react.HeadlessJsTaskService;
import com.facebook.react.bridge.Arguments;

import com.facebook.react.jstasks.HeadlessJsTaskConfig;

import java.lang.reflect.Field;

import me.pushy.sdk.react.config.PushyHeadlessJSConfig;
import me.pushy.sdk.util.PushyLogger;

public class PushyNotificationService extends HeadlessJsTaskService {
    @SuppressLint("DiscouragedPrivateApi")
    public PushyNotificationService(Context context) {
        super();

        // Inject synthetic context
        attachBaseContext(context);

        // Get Application context object
        Application app = (Application) context.getApplicationContext();

        // Use reflection to override the private mApplication field in Service superclass
        // To resolve NullPointerException errors when launching the service directly using onStartCommand()
        Field field;

        try {
            // Get privately declared field
            field = Service.class.getDeclaredField("mApplication");
        } catch (NoSuchFieldException e) {
            // Log exception
            PushyLogger.e("Failed to fetch declared field mApplication of Service superclass", e);
            return;
        }

        // Make it accessible
        field.setAccessible(true);

        try {
            // Set a new Application value
            field.set(this, app);
        } catch (IllegalAccessException e) {
            // Log exception
            PushyLogger.e("Failed to override mApplication field of Service superclass", e);
        }
    }

    @Override
    public HeadlessJsTaskConfig getTaskConfig(Intent intent) {
        // Get extras bundle to provide to task
        Bundle extras = intent.getExtras();

        // No push payload?
        if (extras == null) {
            return null;
        }

        // Return task config
        return new HeadlessJsTaskConfig(PushyHeadlessJSConfig.PUSH_RECEIVER_HEADLESS_TASK_NAME, Arguments.fromBundle(extras), 5000, PushyHeadlessJSConfig.PUSH_RECEIVER_HEADLESS_TASK_FOREGROUND);
    }
}