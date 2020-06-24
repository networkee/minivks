@interface VKSResponder : NSObject

+(NSString*) getAlternateResponseFor:(NSString*)method parameters:(NSString*)params;
+(NSString*) getCountersJsCode;
+(NSString*) getJsonStringFromResponseData:(NSData*)data;
+(NSString*) defaultResponseForMethod:(NSString*)method;
+(NSString*) getCachedResponseForMethod:(NSString*)method;
@end
