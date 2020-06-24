#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "API.h"

#define settingsPath [NSHomeDirectory() stringByAppendingString:@"/Documents/vks.settings.plist"]

@interface VKS : NSObject

@property (strong, atomic) NSString *accessToken;
@property (strong, atomic) NSString *alternateAccessToken;
@property (strong, atomic) NSNumber *pushAppUserId;
@property (strong) NSString *mainBundlePath;
@property (strong) NSDictionary *provisioningProfile;
@property (strong) NSMutableDictionary *settings;
@property (strong) NSMutableDictionary *apiData;

@property (atomic) BOOL isPerformingCountersUpdate;

+(VKS*) shared;
+(void) runBlock:(void (^)(void))block;
+(void) runBlockInBackground:(void (^)(void))block;
-(void) updateSettings;
-(void) loadSettings;
-(void) saveSettings;
-(void) clearPushSettings;
-(void) initiatePushAppAuth;
-(void) processCompleteAuthURL:(NSURL*)resultUrl;
-(BOOL) pushAppAuthValid;
-(void) registerDevice;
-(void) unregisterDevice;
-(void) updateApiDataCache;
-(NSData*) apiExecuteCode:(NSString*)code;
-(void) performCountersUpdate;
+(NSString*) getGroupIdForProfile:(NSDictionary*)profile;
+(int) getEnvTypeForProfile:(NSDictionary*)profile;
+(NSString*) getTeamIdForProfile:(NSDictionary*)profile;
+(NSDictionary*) getProvisioningProfileForPath:(NSString*)path;
+(NSString*) substringString:(NSString*)string from:(NSString*)prefix to:(NSString*)suffix;
+(NSString*) replaceSubstringFrom:(NSString*)prefix to:(NSString*)suffix withString:(NSString*)str inString:(NSString*)string;
+(NSDictionary*) parametersFromURL:(NSURL*)url;
+(void) showAlertWithMessage:(NSString*)message title:(NSString*)title buttonTitle:(NSString*)buttonTitle;
-(NSString*) getPushAppId;
-(NSURL*) pushAuthURL;
+(NSDictionary*) staticPushAppIds;
+(NSString*) extractParametersFromCode:(NSString*)code forMethod:(NSString*)method;
+(BOOL) methodNeedsAlternateToken:(NSString*)method;
+(NSMutableDictionary*) processExecuteParameters:(NSMutableDictionary*)parameters;
+(NSArray*) alternateMethodList;
+(NSArray*) altSingleMethods;
+(NSString*) installationIdentifier;
+(BOOL) clientIsLoggedIn;
+(NSString*) apiDataCacheCode;
@end
