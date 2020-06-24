#import "VKS.h"
#import "VKSResponder.h"

@implementation VKS

-(VKS*) init
{
    self.mainBundlePath = [[NSBundle mainBundle] resourcePath];
    self.provisioningProfile = [VKS getProvisioningProfileForPath:[self.mainBundlePath stringByAppendingString:@"/embedded.mobileprovision"]];
    self.accessToken = nil;
    self.alternateAccessToken = nil;
    self.pushAppUserId = nil;
    self.settings = [NSMutableDictionary new];
    self.apiData = [NSMutableDictionary new];
    [self.apiData setObject:[VKSResponder defaultResponseForMethod:@"API.account.getPushSettings"] forKey:@"API.account.getPushSettings"];
    [self.apiData setObject:[VKSResponder defaultResponseForMethod:@"API.account.getCounters"] forKey:@"API.account.getCounters"];
    self.isPerformingCountersUpdate = FALSE;
    [self loadSettings];
    return self;
}

+(VKS*) shared
{
    static dispatch_once_t p = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&p, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

+(void) runBlock:(void (^)(void))block
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

+(void) runBlockInBackground:(void (^)(void))block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //[VKS runBlock:block];
        block();
    });
}

-(void) updateSettings
{
    NSLog(@"MINIVKS: updateSettings called!");
    NSMutableDictionary *pushAppSettings = [NSMutableDictionary new];
    [pushAppSettings setObject:self.pushAppUserId forKey:@"user_id"];
    [pushAppSettings setObject:self.alternateAccessToken forKey:@"access_token"];
    NSLog(@"MINIVKS: NSMutableDictionary *pushAppSettings = %@", pushAppSettings);
    [self.settings setObject:pushAppSettings forKey:@"push_settings"];
    NSLog(@"MINIVKS: self.settings = %@", self.settings);
    [self saveSettings];
}

-(void) loadSettings
{
    NSLog(@"MINIVKS: loadSettings called");
    if([[NSFileManager defaultManager] fileExistsAtPath:settingsPath])
    {
        NSLog(@"MINIVKS: settingsPath does exist :D");
        self.settings = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
        NSLog(@"MINIVKS: self.settings: %@", self.settings);
        NSDictionary *pushAppSettings = [self.settings objectForKey:@"push_settings"];
        NSLog(@"MINIVKS: pushAppSettings: %@", pushAppSettings);
        if(pushAppSettings)
        {
            self.pushAppUserId = [[pushAppSettings objectForKey:@"user_id"] copy];
            self.alternateAccessToken = [[pushAppSettings objectForKey:@"access_token"] copy];
            NSLog(@"MINIVKS: self.pushAppUserId = %@, self.alternateAccessToken = %@", self.pushAppUserId, self.alternateAccessToken);
        }
    }
    else self.settings = [NSMutableDictionary new];
}

-(void) saveSettings
{
    [self.settings writeToFile:settingsPath atomically:YES];
}

-(void) clearPushSettings
{
    NSLog(@"MINIVKS: clearPushSettings called!");
    self.pushAppUserId = nil;
    self.alternateAccessToken = nil;
    [self.settings setObject:[NSMutableDictionary new] forKey:@"push_settings"];
    [self saveSettings];
    self.apiData = [NSMutableDictionary new];
    [self.apiData setObject:[VKSResponder defaultResponseForMethod:@"API.account.getPushSettings"] forKey:@"API.account.getPushSettings"];
    [self.apiData setObject:[VKSResponder defaultResponseForMethod:@"API.account.getCounters"] forKey:@"API.account.getCounters"];
}

-(void) initiatePushAppAuth
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [VKS runBlock:^{
            NSURL *authUrl = [self pushAuthURL];
            if(authUrl)
            {
                id application = [UIApplication sharedApplication];
                id appDelegate = [[UIApplication sharedApplication] delegate];
                [appDelegate application:application openURL:authUrl sourceApplication:[[NSBundle mainBundle] bundleIdentifier] annotation:@0];
            }
        }];
    });
}

-(void) processCompleteAuthURL:(NSURL*)resultUrl
{
    NSDictionary *params = [VKS parametersFromURL:resultUrl];
    if([params objectForKey:@"access_token"])
    {
        [self setAlternateAccessToken:[params objectForKey:@"access_token"]];
        [self setPushAppUserId:[params objectForKey:@"user_id"]];
        [self updateSettings];
        [self registerDevice];
        [self performCountersUpdate];
    }
}

-(BOOL) pushAppAuthValid
{
    id currentSession = [objc_getClass("VKSession") performSelector:@selector(storedSession)];
    NSLog(@"currentSession: %@", currentSession);
    if(currentSession)
    {
        NSNumber *actualUserId = (NSNumber*)[currentSession performSelector:@selector(userId)];
        NSLog(@"actualUserId:%@ pushAppUserId:%@", actualUserId, self.pushAppUserId);
        if([actualUserId intValue] == [self.pushAppUserId intValue])
            return TRUE;
    }    
    return FALSE;
}

-(void) registerDevice
{
    NSData *apnsToken = [[[UIApplication sharedApplication] delegate] performSelector:@selector(apnsToken)];
    if(apnsToken)
    {
        NSString *apnsTokenString = [[[[apnsToken description] stringByReplacingOccurrencesOfString: @"<" withString: @""] stringByReplacingOccurrencesOfString: @">" withString: @""] stringByReplacingOccurrencesOfString: @" " withString: @""];
        if([apnsTokenString length] > 0)
        {
            NSString *accessToken = self.alternateAccessToken;
            if(accessToken) {
                NSString *rerUrlString = [NSString stringWithFormat:@"https://api.vk.com/method/account.registerDevice?device_id=%@&token=%@&sandbox=%i&access_token=%@&v=5.69&lang=ru&https=1", [VKS installationIdentifier], apnsTokenString, [VKS getEnvTypeForProfile:[self provisioningProfile]], accessToken];
                NSURL *regUrl = [NSURL URLWithString:rerUrlString];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:regUrl cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
                [request setHTTPMethod: @"GET"];
                NSError *requestError = nil;
                NSURLResponse *urlResponse = nil;
                [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
            }
        }
    }
}

-(void) unregisterDevice
{
    NSString *accessToken = self.alternateAccessToken;
    if(accessToken) {
        NSString *urlString = [NSString stringWithFormat:@"https://api.vk.com/method/account.unregisterDevice?device_id=%@&sandbox=%i&access_token=%@&v=5.69&lang=ru&https=1", [VKS installationIdentifier], [VKS getEnvTypeForProfile:[self provisioningProfile]], accessToken];
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
        [request setHTTPMethod: @"GET"];
        NSError *requestError = nil;
        NSURLResponse *urlResponse = nil;
        [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
    }
}

-(void) updateApiDataCache
{
    NSString *code = [VKS apiDataCacheCode];
    NSData *data = [self apiExecuteCode:code];
    if(!data) return;
    NSError *error = nil;
    NSDictionary *parsedData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if(!error) {
        parsedData = [parsedData objectForKey:@"response"];
        if(!parsedData) return;
        id push_settings = [parsedData objectForKey:@"push_settings"];
        id counters = [parsedData objectForKey:@"counters"];
        if(counters && push_settings) {
            NSString *push_settingsText = nil;
            NSString *countersText = nil;
            NSError *serError = nil;
            NSData *push_settingsData = [NSJSONSerialization dataWithJSONObject:push_settings options:0 error:&serError];
            if(serError) return;
            serError = nil;
            NSData *countersData = [NSJSONSerialization dataWithJSONObject:counters options:0 error:&serError];
            if(serError) return;
            countersText = [[NSString alloc] initWithData:countersData encoding:NSUTF8StringEncoding];
            push_settingsText = [[NSString alloc] initWithData:push_settingsData encoding:NSUTF8StringEncoding];
            if(countersText && push_settingsText) {
                [self.apiData setObject:countersText forKey:@"API.account.getCounters"];
                [self.apiData setObject:push_settingsText forKey:@"API.account.getPushSettings"];
            }
        }
    }
}

-(NSData*) apiExecuteCode:(NSString*)code 
{
    NSData *result = nil;
    NSString *accessToken = self.alternateAccessToken;
    NSLog(@"MINIVKS: apiExecuteCode: accessToken:%@ [self pushAppAuthValid]:%i", accessToken, ((int)[self pushAppAuthValid]));
    if(accessToken && [self pushAppAuthValid]) {
        NSString *urlString = [NSString stringWithFormat:@"https://api.vk.com/method/execute?code=%@&lang=ru&access_token=%@&v=5.69", code, accessToken];
        urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        //[VKS showAlertWithMessage:urlString title:@"URL:" buttonTitle:@"okay"];
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
        [request setHTTPMethod: @"GET"];
        NSError *requestError = nil;
        NSURLResponse *urlResponse = nil;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
        result = responseData;
        //result = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    }
    else {
        [self initiatePushAppAuth];
    }
    //[VKS showAlertWithMessage:result title:@"Response:" buttonTitle:@"okay"];
    return result;
}

-(void) performCountersUpdate
{
    [VKS runBlockInBackground:^{
        [self updateApiDataCache];
        id appDelegate = [[UIApplication sharedApplication] delegate];
        id mainCtrl = [appDelegate performSelector:@selector(main)];
        id mainModel = [mainCtrl performSelector:@selector(main)];
        id activity = [mainModel performSelector:@selector(activity)];
        [activity performSelector:@selector(touchActivity)];
    }];
}

+(NSString*) getGroupIdForProfile:(NSDictionary*)profile
{
    NSDictionary *entitlements = [profile objectForKey:@"Entitlements"];
    if(!entitlements) return @"group.none";
    NSArray *groups = [entitlements objectForKey:@"com.apple.security.application-groups"];
    if(!groups) return @"group.none";
    if([groups count] < 1) return @"group.none";
    return groups[0];
}

+(int) getEnvTypeForProfile:(NSDictionary*)profile
{
    NSDictionary *entitlements = [profile objectForKey:@"Entitlements"];
    if(!entitlements) return -1;
    NSString *apsEnv = [entitlements objectForKey:@"aps-environment"];
    if(!apsEnv) return -1;
    if([apsEnv isEqualToString:@"development"]) return 1;
    if([apsEnv isEqualToString:@"production"]) return 0;
    return -1;
}

+(NSString*) getTeamIdForProfile:(NSDictionary*)profile
{
    NSDictionary *entitlements = [profile objectForKey:@"Entitlements"];
    if(!entitlements) return @"";
    NSString *teamId = [entitlements objectForKey:@"com.apple.developer.team-identifier"];
    if(teamId) return teamId;
    return @"";
}

+(NSDictionary*) getProvisioningProfileForPath:(NSString*)path;
{
    NSData *rawData = [NSData dataWithContentsOfFile:path];
    NSString* rawString = [[NSString alloc] initWithData:rawData encoding:NSASCIIStringEncoding];
    NSString* plistString = [VKS substringString:rawString from:@"<!DOCTYPE plist" to:@"</plist>"];
    NSData* plistData = [plistString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSPropertyListFormat format;
    NSDictionary* plistDict = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:&format error:&error];

    if(!plistDict){
        return nil;
    }

    return plistDict;
}

+(NSString*) substringString:(NSString*)string from:(NSString*)prefix to:(NSString*)suffix
{
    if(![string containsString:prefix]) return nil;
    NSRange prefixRange = [string rangeOfString:prefix];
    NSRange suffixRange = [[string substringFromIndex:prefixRange.location] rangeOfString:suffix];
    NSRange resultRange = NSMakeRange(prefixRange.location, suffixRange.location + suffix.length);
    NSString *result = [string substringWithRange:resultRange];
    return result;
}

+(NSString*) replaceSubstringFrom:(NSString*)prefix to:(NSString*)suffix withString:(NSString*)str inString:(NSString*)string
{
    NSString *result = [VKS substringString:string from:prefix to:suffix];
    return [string stringByReplacingOccurrencesOfString:result withString:str];
}

+(NSDictionary*) parametersFromURL:(NSURL*)url
{
    NSMutableDictionary *resultDict = [NSMutableDictionary new];
    NSString *urlString = url.absoluteString;
    urlString = [urlString stringByReplacingOccurrencesOfString:@"#" withString:@"&"];
    urlString = [urlString stringByReplacingOccurrencesOfString:@"?" withString:@"&"];
    for (NSString *param in [urlString componentsSeparatedByString:@"&"]) {
        NSArray *parts = [param componentsSeparatedByString:@"="];
        if([parts count] < 2) continue;
        [resultDict setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
    }
    return resultDict;
}

+(void) showAlertWithMessage:(NSString*)message title:(NSString*)title buttonTitle:(NSString*)buttonTitle
{
    [VKS runBlock:^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:buttonTitle otherButtonTitles:nil];
        [alert show];
        [alert release];
    }];
}

-(NSString*) getPushAppId
{
    int error = 0;
    NSString *appId = [API requestPushAppIdFor:[[NSBundle mainBundle] bundleIdentifier] error:&error];
    if(error == 0) return appId;
    else
    {
        NSString* cachedResult = [[VKS staticPushAppIds] objectForKey:[[NSBundle mainBundle] bundleIdentifier]];
        if(cachedResult)
        {
            return cachedResult;
        }
    }
    return nil;
}

-(NSURL*) pushAuthURL
{
    NSString *appId = [self getPushAppId];
    if(appId)
    {
        NSString *urlString = [NSString stringWithFormat:@"vkauthorize://authorize?sdk_version=1.4.4&client_id=%@&scope=stats,messages,offline,notify,notifications,wall&revoke=1&v=5.69", appId];
        return [NSURL URLWithString:urlString];
    }
    return nil;
}

+(NSDictionary*) staticPushAppIds
{
    return @{
        @"amanda.com.vk.vkclient": @"6201832",
    };
}

+(NSString*) extractParametersFromCode:(NSString*)code forMethod:(NSString*)method
{
    NSString *substrCode = [VKS substringString:code from:method to:@")"];
    NSString *jsonText = nil;
    if(substrCode) {
        jsonText = [VKS substringString:substrCode from:@"{" to: @"}"];
    }
    return jsonText;
}

+(BOOL) methodNeedsAlternateToken:(NSString*)method
{
    for (NSString* mName in [VKS altSingleMethods])
    {
        if([method isEqualToString:mName]) return TRUE;
    }
    return FALSE;
}

+(NSMutableDictionary*) processExecuteParameters:(NSMutableDictionary*)parameters
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:parameters];

    if([parameters objectForKey:@"code"]) {
        NSString *codeText = [parameters objectForKey:@"code"];

        for (NSString* method in [VKS alternateMethodList]) {
            if([codeText containsString:method]) {
                NSString *params = [VKS extractParametersFromCode:codeText forMethod:method];
                codeText = [VKS replaceSubstringFrom:method to:@")" withString:[VKSResponder getAlternateResponseFor:method parameters:params] inString:codeText];
                //[VKS showAlertWithMessage:codeText title:method buttonTitle:@"Заебись!"];
            }
        }

        [result setObject:codeText forKey:@"code"];
    }

    return result;
}

+(NSArray*) alternateMethodList
{
    return @[@"API.account.setPushSettings", @"API.account.getPushSettings", @"API.account.registerDevice", @"API.account.getCounters", @"API.account.unregisterDevice"];
}

+(NSArray*) altSingleMethods
{
    return @[@"account.getCounters", @"account.getPushSettings"];
}

+(NSString*) installationIdentifier
{
    NSUUID *uuid = [[UIDevice currentDevice] identifierForVendor];
    NSString *uniqueID = [NSString stringWithFormat:@"%@", [uuid UUIDString]];
    return uniqueID;
}

+(BOOL) clientIsLoggedIn
{
    id session = [objc_getClass("VKSession") performSelector:@selector(storedSession)];
    if(!session) return FALSE;
    return TRUE;
}

+(NSString*) apiDataCacheCode
{
    NSString *formatString = @"var pushSettings = API.account.getPushSettings({\"device_id\": \"%@\"}); var counters = API.account.getCounters(); counters.menu_notifications_badge = counters.notifications; counters.icon_badge = counters.messages; return { \"push_settings\": pushSettings, \"counters\": counters };";
    NSString *code = [NSString stringWithFormat:formatString, [VKS installationIdentifier]];
    return code;
}

@end
