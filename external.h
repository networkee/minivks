@interface AFHTTPClient : NSObject <NSCoding, NSCopying>
- (void)setDefaultHeader:(NSString *)header value:(NSString *)value;
@end

@interface VKConfiguration : NSObject
- (VKConfiguration*)initShared;
+ (VKConfiguration*)sharedInstance;
@end
