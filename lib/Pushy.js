import { AppRegistry, NativeModules } from 'react-native';

// Expose all native PushyModule methods
const Pushy = NativeModules.PushyModule;

// Pushy module not loaded?
if (!Pushy) {
    // Log fatal error
    console.error('Pushy native module not loaded, please include the PushyPackage() declaration within your app\'s MainApplication.getPackages() implementation.');
}
else {
    // Expose custom notification listener
    Pushy.setNotificationListener = (handler) => {
        // Listen for push notifications via Headless JS task
        AppRegistry.registerHeadlessTask('PushyPushReceiver', () => {
            // React Native will execute the handler via Headless JS when the task is called natively
            return handler;
        });
    };
}

// Expose module
export default Pushy;