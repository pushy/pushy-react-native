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
    // Expose custom notification listener
    Pushy.setNotificationListener = (handler) => {
        // iOS event emitter subscription
        if (Platform.OS === 'ios') {
            // Create event emitter
            const pushyEventEmitter = new NativeEventEmitter(Pushy);

            // Subscribe to new notification events
            pushyEventEmitter.addListener('Notification', handler);
        }
        // Android headless task registration
        else if (Platform.OS === 'android') {
            // Listen for push notifications via Headless JS task
            AppRegistry.registerHeadlessTask('PushyPushReceiver', () => {
                // React Native will execute the handler via Headless JS when the task is called natively
                return handler;
            });
        }
    };
}

// Expose module
export default Pushy;