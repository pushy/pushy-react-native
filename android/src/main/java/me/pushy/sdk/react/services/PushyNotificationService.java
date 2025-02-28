package me.pushy.sdk.react.services;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import com.facebook.react.HeadlessJsTaskService;
import com.facebook.react.ReactApplication;
import com.facebook.react.ReactHost;
import com.facebook.react.ReactNativeHost;
import com.facebook.react.bridge.Arguments;

import com.facebook.react.bridge.ReactContext;
import com.facebook.react.jstasks.HeadlessJsTaskConfig;

import java.util.Objects;

import me.pushy.sdk.react.config.PushyHeadlessJSConfig;

public class PushyNotificationService extends HeadlessJsTaskService {

    public PushyNotificationService(Context context) {
        super();

        // Inject synthetic context
        attachBaseContext(context);
    }

    @Override
    protected ReactNativeHost getReactNativeHost() {
        // Override implementation as original getReactNativeHost throws NullReferenceException
        return ((ReactApplication) getApplicationContext()).getReactNativeHost();
    }

    protected ReactContext getReactContext() {
        return Objects.requireNonNull(((ReactApplication) getApplicationContext()).getReactHost()).getCurrentReactContext();
    }

    protected ReactHost getReactHost() {
        return ((ReactApplication) getApplicationContext()).getReactHost();
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