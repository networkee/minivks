#import <UIKit/UIKit.h>
#import "external.h"

%hook AFHTTPClient

-(id) initWithBaseURL:(id)arg1
{
    AFHTTPClient *client = %orig;
    if(client) {
        NSString *format = @"com.vk.vkclient/%@ (unknown, %@ %@, %@, Scale/%f)";
        id buildNum = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
        id sysName = [[UIDevice currentDevice] systemName];
        id sysVersion = [[UIDevice currentDevice] systemVersion];
        id modelName = [[UIDevice currentDevice] model];
        float screenScale = [[UIScreen mainScreen] scale];
        NSString *uaString = [NSString stringWithFormat:format, buildNum, sysName, sysVersion, modelName, screenScale];
        [client setDefaultHeader:@"User-Agent" value:uaString];
    }
    return client;
}

%end

%hook VKVideo
-(BOOL) content_restricted
{
    return FALSE;
}
%end

%hook VKAccountGlobalSetting
-(BOOL) settingAvailable
{
    if([((NSString*)[self performSelector:@selector(settingName)]) isEqualToString:@"audio_background_limit"]) return FALSE;
    return %orig;
}
%end

%hook VKAudioQueuePlayer
-(BOOL) musicSubscriptionActive { return TRUE; }
%end
