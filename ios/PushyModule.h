#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface PushyModule : RCTEventEmitter <RCTBridgeModule>
+ (void)didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
@end

