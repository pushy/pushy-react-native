// Type definitions for pushy-react-native
// Project: https://github.com/pushy/pushy-react-native
// Definitions by: Fabian Kuentzler <fabian@kuentzler.at>

declare module 'pushy-react-native' {
  interface Pushy {
    /**
     * By default, the SDK will automatically authenticate using your iOS app's Bundle ID.
     *
     * You can manually pass in your Pushy App ID (Pushy Dashboard -> Click your app -> App Settings -> App ID) to override this behavior.
     */
    setAppId(appId: string): void;

    /**
     * Starts Pushy's internal notification listening service, if necessary.
     */
    listen(): void;

    /**
     * Check if the device is registered.
     *
     * @returns A boolean indicating whether the device is registered or not.
     */
    isRegistered(): Promise<boolean>;

    /**
     * Register the device for push notifications.
     *
     * @returns The Pushy device token
     */
    register(): Promise<string>;

    /**
     * Set up the notification listener.
     *
     * This method can only be called once for your entire app lifecycle, therefore, it should not be invoked within a Component lifecycle event.
     *
     * @param callback This function will be invoked when a new push notification arrives.
     */
    setNotificationListener(callback: (data: string | object) => Promise<void>): void;

    /**
     * Set up the notification click listener.
     *
     * @param callback This function will be invoked when the user taps on a push notification.
     */
    setNotificationClickListener(callback: (data: string | object) => void): void;

    /**
     * Calling this method will result in Platform dependent behaviour.
     *
     * Android: Displays a system notification.
     *
     * iOS:     Displays an alert dialog.
     *
     * @param title The notification title.
     * @param message The notification message.
     * @param data The payload object.
     */
    notify(title: string, message: string, data: object): void;

    /**
     * Subscribe the user to a topic.
     *
     * @param topic The topic to subscribe to.
     */
    subscribe(topic: string): Promise<void>;

    /**
     * Unsubscribe the user from a topic.
     *
     * @param topic The topic to unsubscribe from.
     */
    unsubscribe(topic: string): Promise<void>;

    /**
     * Android specific.
     *
     * Toggle FCM fallback
     *
     * @param enabled A boolean indicating whether the FCM fallback should be enabled.
     */
    toggleFCM(enabled: boolean): void;

    /**
     * iOS specific.
     *
     * Toggle the In-App Banner.
     *
     * @param enabled A boolean indicating whether the In-App Banner should be enabled.
     */
    toggleInAppBanner(enabled: boolean): void;

    /**
     * iOS specific.
     *
     * Toggle ignoring push permission denial
     *
     * @param enabled A boolean indicating whether an error should not be thrown when the push permission is denied by the user.
     */
    toggleIgnorePushPermissionDenial(enabled: boolean): void;

    /**
     * iOS specific.
     *
     * By default, the SDK will use method swizzling to hook into the iOS AppDelegate's APNs callbacks.
     * You can disable method swizzling by calling this method.
     *
     * @param enabled A boolean indicating whether method swizzling should be enabled.
     */
    toggleMethodSwizzling(enabled: boolean): void;

    /**
     * iOS specific.
     *
     * By default, the SDK will register for notifications with the Apple Push Notification Service.
     * This can be disabled for on-premises Pushy Enterprise deployments making use of Local Push Connectivity to deliver notifications.
     *
     * @param enabled A boolean indicating whether APNs integration should be enabled.
     */
    toggleAPNs(enabled: boolean): void;

    /**
     * iOS specific.
     *
     * On-premises Pushy Enterprise customers can use this method to enable Local Push Connectivity.
     *
     * @param endpoint The Pushy Enterprise deployment hostname.
     * @param port The Pushy Enterprise deployment MQTTS port number.
     * @param keepAlive The desired connection keep alive interval in seconds (300 is recommended).
     * @param ssids A string array of valid Wi-FI SSIDs that have access to the on-premises Pushy Enterprise deployment.
     */
    setLocalPushConnectivityConfig(endpint: string, port: number, keepAlive: number, ssids: [String]): void;

    /**
     * iOS specific.
     *
     * Set the iOS Badge count.
     *
     * @param count The new count for the iOS Badge.
     */
    setBadge(count: number): void;

    /**
     * Android specific.
     *
     * Optionally configure a custom notification icon for incoming Android notifications
     * by placing icon file(s) in `android/app/src/main/res/drawable-*` and calling this method
     * after calling `Pushy.listen()`.
     *
     * @param icon The name of the icon file.
     */
    setNotificationIcon(icon: string): void;

    /**
     * Android specific.
     *
     * Enables foreground service mode. The SDK will create a foreground service that 
     * the Android OS will never terminate, which will ensure notification delivery in 
     * the background and low memory state.
     *
     * @param toggle A boolean indicating whether foreground service mode should be enabled.
     */
    toggleForegroundService(enabled: boolean): void;

    /**
     * Pushy Enterprise customers can use this method to enable Pushy Enterprise integration.
     *
     * @param apiEndpoint The Pushy Enterprise API hostname (string).
     * @param mqttEndpoint The Pushy Enterprise MQTTS hostname (string).
     */
    setEnterpriseConfig(apiEndoint: string, mqttEndpoint: string): void;
  }

  const pushy: Pushy;
}

export default pushy;
