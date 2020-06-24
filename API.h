#import <UIKit/UIKit.h>

@interface API : NSObject

+(NSString*) requestPushAppIdFor:(NSString*)bundleId error:(int*)error;
+(API*) sharedInstance;
@end
