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
     * By default, the SDK will use method swizzling to hook into the iOS AppDelegate's APNs callbacks.
     * You can disable method swizzling by calling this method.
     *
     * @param toggle A boolean indicating whether method swizzling should be enabled.
     */
    toggleMethodSwizzling(enabled: boolean): void;

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

    setEnterpriseConfig(apiEndoint: string, mqttEndpoint: string): void;
  }

  const pushy: Pushy;
}

export default pushy;
