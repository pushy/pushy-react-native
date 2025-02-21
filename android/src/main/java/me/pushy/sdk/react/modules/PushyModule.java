package me.pushy.sdk.react.modules;

import android.app.Activity;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.res.Resources;
import android.media.RingtoneManager;
import android.os.AsyncTask;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import org.json.JSONObject;

import me.pushy.sdk.Pushy;
import me.pushy.sdk.react.config.PushyIntentExtras;
import me.pushy.sdk.react.util.PushyMapUtils;
import me.pushy.sdk.react.util.PushyPersistence;
import me.pushy.sdk.util.PushyLogger;
import me.pushy.sdk.util.PushyStringUtils;
import me.pushy.sdk.util.exceptions.PushyException;

public class PushyModule extends ReactContextBaseJavaModule implements ActivityEventListener {
    public PushyModule(ReactApplicationContext reactContext) {
        super(reactContext);

        // Hook into activity events (onNewIntent)
        reactContext.addActivityEventListener(this);
    }

    @Override
    public String getName() {
        return "PushyModule";
    }

    @ReactMethod
    public void notify(String title, String text, ReadableMap payload) {
        // Cache app context
        Context context = getReactApplicationContext();

        // Prepare a notification with vibration, sound and lights
        Notification.Builder builder = new Notification.Builder(context)
                .setSmallIcon(getNotificationIcon(context))
                .setContentTitle(title)
                .setContentText(text)
                .setAutoCancel(true)
                .setVibrate(new long[]{0, 400, 250, 400})
                .setContentIntent(getMainActivityPendingIntent(context, payload))
                .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION));

        // Get an instance of the NotificationManager service
        NotificationManager notificationManager = (NotificationManager) context.getSystemService(context.NOTIFICATION_SERVICE);

        // Automatically configure a Notification Channel for devices running Android O+
        Pushy.setNotificationChannel(builder, context);

        // Build the notification and display it
        notificationManager.notify(text.hashCode(), builder.build());
    }

    @ReactMethod
    public void register(final Promise promise) {
        // Run network I/O in background thread
        AsyncTask.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    // Assign a unique token to this device
                    String deviceToken = Pushy.register(getCurrentActivity() != null ? getCurrentActivity() : getReactApplicationContext());

                    // Resolve the promise with the token
                    promise.resolve(deviceToken);
                }
                catch (PushyException exc) {
                    // Reject the promise with the exception
                    promise.reject(exc);
                }
            }
        });
    }

    @ReactMethod
    public void hideNotifications() {
        // Get an instance of the NotificationManager service
        NotificationManager notificationManager = (NotificationManager) getReactApplicationContext().getSystemService(getReactApplicationContext().NOTIFICATION_SERVICE);

        // Cancel all visible notifications
        notificationManager.cancelAll();
    }

    @ReactMethod
    public void listen() {
        // Call Pushy.listen() to establish a connection
        Pushy.listen(getReactApplicationContext());

        // If no intent, no notification clicked
        if (getReactApplicationContext() == null || getReactApplicationContext().getCurrentActivity() == null || getReactApplicationContext().getCurrentActivity().getIntent() == null) {
            return;
        }

        // Check whether activity was instantiated from notification
        onNotificationClicked(getReactApplicationContext().getCurrentActivity().getIntent());
    }

    @ReactMethod
    public void unregister() {
        // Unregister the device from receiving notifications
        Pushy.unregister(getReactApplicationContext());
    }

    @ReactMethod
    public void subscribe(final String topic, final Promise promise) {
        // Run network I/O in background thread
        AsyncTask.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    // Attempt to subscribe the device to topic
                    Pushy.subscribe(topic, getReactApplicationContext());

                    // Resolve the promise with success
                    promise.resolve(true);
                }
                catch (PushyException exc) {
                    // Reject the promise with the exception
                    promise.reject(exc);
                }
            }
        });
    }

    @ReactMethod
    public void unsubscribe(final String topic, final Promise promise) {
        // Run network I/O in background thread
        AsyncTask.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    // Attempt to unsubscribe the device from topic
                    Pushy.unsubscribe(topic, getReactApplicationContext());

                    // Resolve the promise with success
                    promise.resolve(true);
                }
                catch (PushyException exc) {
                    // Reject the promise with the exception
                    promise.reject(exc);
                }
            }
        });
    }

    @ReactMethod
    public void setAppId(String appId) {
        Pushy.setAppId(appId, getReactApplicationContext());
    }

    @ReactMethod
    public void togglePermissionVerification(boolean value) {
        Pushy.togglePermissionVerification(value, getReactApplicationContext());
    }

    @ReactMethod
    public void toggleDirectConnectivity(boolean value) {
        Pushy.toggleDirectConnectivity(value, getReactApplicationContext());
    }

    @ReactMethod
    public void toggleForegroundService(boolean value) {
        Pushy.toggleForegroundService(value, getReactApplicationContext());
    }

    @ReactMethod
    public void toggleNotifications(boolean value) {
        Pushy.toggleNotifications(value, getReactApplicationContext());
    }

    @ReactMethod
    public void setHeartbeatInterval(int seconds) {
        Pushy.setHeartbeatInterval(seconds, getReactApplicationContext());
    }

    @ReactMethod
    public void setJobServiceInterval(int seconds) {
        Pushy.setJobServiceInterval(seconds, getReactApplicationContext());
    }

    @ReactMethod
    public void setEnterpriseConfig(String apiEndpoint, String mqttEndpoint) {
        Pushy.setEnterpriseConfig(apiEndpoint, mqttEndpoint, getReactApplicationContext());
    }

    @ReactMethod
    public void toggleFCM(boolean value) {
        Pushy.toggleFCM(value, getReactApplicationContext());
    }

    @ReactMethod
    public void setProxyEndpoint(String proxyEndpoint) {
        Pushy.setProxyEndpoint(proxyEndpoint, getReactApplicationContext());
    }

    @ReactMethod
    public void setEnterpriseCertificate(String enterpriseCert) {
        Pushy.setEnterpriseCertificate(enterpriseCert, getReactApplicationContext());
    }

    @ReactMethod
    public void isRegistered(Promise promise) {
        promise.resolve(Pushy.isRegistered(getReactApplicationContext()));
    }

    @ReactMethod
    public void getDeviceCredentials(Promise promise) {
        promise.resolve(Pushy.getDeviceCredentials(getReactApplicationContext()));
    }

    private PendingIntent getMainActivityPendingIntent(Context context, ReadableMap payload) {
        // Get launcher activity intent
        Intent launchIntent = context.getPackageManager().getLaunchIntentForPackage(context.getApplicationContext().getPackageName());

        // Make sure to update the activity if it exists
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP);

        // Attempt to convert ReadableMap to JSON string
        String json = "{}";

        try {
            // Fail gracefully
            json = PushyMapUtils.convertMapToJson(payload).toString();
        }
        catch(Exception e) {
            // Log exception
            PushyLogger.e("Failed to convert ReadableMap into JSON string", e);
        }

        // Pass payload data into PendingIntent
        launchIntent.putExtra(PushyIntentExtras.NOTIFICATION_CLICKED, true);
        launchIntent.putExtra(PushyIntentExtras.NOTIFICATION_PAYLOAD, json);

        // Convert intent into pending intent
        return PendingIntent.getActivity(context, json.hashCode(), launchIntent, PendingIntent.FLAG_IMMUTABLE);
    }

    @ReactMethod
    public void setNotificationIcon(final String iconResourceName) {
        // Store in SharedPreferences using PushyPersistence helper
        PushyPersistence.setNotificationIcon(iconResourceName, getReactApplicationContext());
    }

    private int getNotificationIcon(Context context) {
        // Attempt to fetch icon name from SharedPreferences
        String icon = PushyPersistence.getNotificationIcon(context);

        // Did we configure a custom icon?
        if (icon != null) {
            // Cache app resources
            Resources resources = context.getResources();

            // Cache app package name
            String packageName = context.getPackageName();

            // Look for icon in drawable folders
            int iconId = resources.getIdentifier(icon, "drawable", packageName);

            // Found it?
            if (iconId != 0) {
                return iconId;
            }

            // Look for icon in mipmap folders
            iconId = resources.getIdentifier(icon, "mipmap", packageName);

            // Found it?
            if (iconId != 0) {
                return iconId;
            }
        }

        // Fallback to generic icon
        return android.R.drawable.ic_dialog_info;
    }

    void onNotificationClicked(Intent intent) {
        // No notification clicked?
        if (!intent.getBooleanExtra(PushyIntentExtras.NOTIFICATION_CLICKED, false)) {
            return;
        }

        // Extract payload and invoke notification click listener
        String payload = intent.getStringExtra(PushyIntentExtras.NOTIFICATION_PAYLOAD);

        // No payload?
        if (PushyStringUtils.stringIsNullOrEmpty(payload)) {
            return;
        }

        try {
            // Parse JSON
            JSONObject jsonObject = new JSONObject(payload);

            // Convert into React map format
            WritableMap map = PushyMapUtils.convertJsonToMap(jsonObject);

            // Pass to app via React EventEmitter
            getReactApplicationContext()
                    .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                    .emit("NotificationClick", map);
        }
        catch (Exception e) {
            // Log exception
            PushyLogger.e("Failed to parse JSON into WritableMap", e);
        }
    }

    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
        // Do nothing
        return;
    }

    @Override
    public void onNewIntent(Intent intent) {
        // Handle notification click
        onNotificationClicked(intent);
    }
}