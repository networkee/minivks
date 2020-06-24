#import "VKSResponder.h"
#import "VKS.h"

@implementation VKSResponder

+(NSString*) getAlternateResponseFor:(NSString*)method parameters:(NSString*)params
{
    if([method isEqualToString:@"API.account.registerDevice"]) {
        [VKS runBlockInBackground:^{
            [[VKS shared] registerDevice];
        }];
        return @"1";
    }
    else if([method isEqualToString:@"API.account.setPushSettings"]) {
        [VKS runBlockInBackground:^{
            NSString *code = [NSString stringWithFormat:@"return %@(%@);", method, params];
            [[VKS shared] apiExecuteCode:code];
            [[VKS shared] updateApiDataCache];
        }];
        return @"1";
    }
    else if([method isEqualToString:@"API.account.getPushSettings"]) {
        return [VKSResponder getCachedResponseForMethod:method];
    }
    else if([method isEqualToString:@"API.account.getCounters"]) {
        if([VKS shared].isPerformingCountersUpdate == FALSE) {
            [VKS shared].isPerformingCountersUpdate = TRUE;
            [VKS runBlockInBackground:^{
                [[VKS shared] performCountersUpdate];
            }];
        } else {
            [VKS shared].isPerformingCountersUpdate = FALSE;
        }
        return [VKSResponder getCachedResponseForMethod:method];
    }
    else if([method isEqualToString:@"API.account.unregisterDevice"]) {
        [VKS runBlockInBackground:^{
            [[VKS shared] unregisterDevice];
        }];
        return @"1";
    }
    else return @"0";
}

+(NSString*) getCountersJsCode
{
    return @"var counters = API.account.getCounters(); counters.icon_badge = counters.messages; counters.menu_notifications_badge = counters.notifications; return counters;";
}

+(NSString*) getJsonStringFromResponseData:(NSData*)data
{
    NSString *responseText = @"";
    NSError *error = nil;
    NSDictionary *parsedData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if(!error) {
        id response = [parsedData objectForKey:@"response"];
        if(response) {
            NSError *serError = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:response options:0 error:&serError];
            if(!serError) responseText = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
    }
    return responseText;
}

+(NSString*) defaultResponseForMethod:(NSString*)method
{
    if([method isEqualToString:@"API.account.getPushSettings"]) return @"{\"subscribe\":\"\",\"conversations\":{\"count\":0,\"items\":[]}}";
    if([method isEqualToString:@"API.account.getCounters"]) return @"{\"friends\":0,\"messages\":0}";
    return @"";
}

+(NSString*) getCachedResponseForMethod:(NSString*)method
{
    NSString *jsonText = nil;
    NSDictionary *apiData = [[VKS shared] apiData];
    if(apiData) {
        NSString *object = [apiData objectForKey:method];
        if(object) {
            jsonText = object;
        }
    }
    return jsonText;
}

@end
