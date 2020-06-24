#import "API.h"

@implementation API

+(API*) sharedInstance
{
    static dispatch_once_t p = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&p, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

+(NSString*) requestPushAppIdFor:(NSString*)bundleId error:(int*)error
{
    NSString *result = [NSString new];
    NSString *urlString = [NSString stringWithFormat:@"https://f0x.io/api/vks.getPushAppID/?bundleId=%@", bundleId];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
    [request setHTTPMethod: @"GET"];
    NSError *requestError = nil;
    NSURLResponse *urlResponse = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];

    if(!requestError)
    {
        NSError *dictError=nil;
        NSDictionary *parsedData = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&dictError];
        if(!dictError)
        {
            id response = [parsedData objectForKey:@"error"];
            if(response)
            {
                int errorCode = [response intValue];
                if(errorCode == 0)
                {
                    *error = 0;
                    NSDictionary *responseData = [parsedData objectForKey:@"response"];
                    NSNumber *appId = [responseData objectForKey:@"app_id"];
                    result = [[appId stringValue] copy];
                }
                else
                {
                    *error = 1;
                }
            }
            else
            {
                *error = 1;
            }
        }
        else
        {
            *error = 1;
        }
    }
    else
    {
        *error = 1;
    }
    return result;
}

@end
