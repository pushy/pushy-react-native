import { Platform, AppRegistry, NativeModules, NativeEventEmitter } from 'react-native';

// Expose all native PushyModule methods
const Pushy = NativeModules.PushyModule;

// Pushy module not loaded?
if (!Pushy) {
    // Are we running on an Android device?
    if (Platform.OS === 'android') {
        // Log fatal error
        console.error('Pushy native module not loaded, please include the PushyPackage() declaration within your app\'s MainApplication.getPackages() implementation.');
    }
    else if (Platform.OS === 'ios') {
        // Log fatal error
        console.error('Pushy native module not loaded, please make sure to run "react-native link pushy-react-native" to link the native library to your project.');
    }
}
else {
    // Android: Define placeholder methods for RN built in Event Emitter calls
    if (Platform.OS === 'android') {
        Pushy.addListener = () => {};
        Pushy.removeListeners = () => {};
    }

    // Create event emitter
    const pushyEventEmitter = new NativeEventEmitter(Pushy);

    // Expose custom notification listener
    Pushy.setNotificationListener = (handler) => {
        // iOS event emitter subscription
        if (Platform.OS === 'ios') {
            // Remove previously set listeners
            pushyEventEmitter.removeAllListeners('Notification');

            // Subscribe to new notification events
            pushyEventEmitter.addListener('Notification', handler);
        }
        // Android headless task registration
        else if (Platform.OS === 'android' && !Pushy.headlessTaskRegistered) {
            // Only call AppRegistry.registerHeadlessTask() once
            Pushy.headlessTaskRegistered = true;

            // Listen for push notifications via Headless JS task
            AppRegistry.registerHeadlessTask('PushyPushReceiver', () => {
                // React Native will execute the handler via Headless JS when the task is called natively
                return handler;
            });
        }
    };

    // Expose custom notification click listener
    Pushy.setNotificationClickListener = (handler) => {
        // Remove previously set listeners
        pushyEventEmitter.removeAllListeners('NotificationClick');

        // Subscribe to new notification events
        pushyEventEmitter.addListener('NotificationClick', handler);
    };
}

// Android: Define placeholder method(s) for iOS-only functionality
if (Platform.OS === 'android') {
    Pushy.setBadge = () => {};
    Pushy.toggleInAppBanner = () => {};
    Pushy.toggleIgnorePushPermissionDenial = () => {};
}

// iOS: Define placeholder method(s) for Android-only functionality
if (Platform.OS === 'ios') {
    Pushy.toggleFCM = () => {};
    Pushy.setNotificationIcon = () => {};
    Pushy.setHeartbeatInterval = () => {};
    Pushy.setEnterpriseCertificate = () => {};
    Pushy.toggleForegroundService = () => {};
    Pushy.toggleDirectConnectivity = () => {};
    Pushy.togglePermissionVerification = () => {};
}

// Expose module
export default Pushy;