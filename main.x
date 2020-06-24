#import <UIKit/UIKit.h>
#import "VKS.h"
#import "API.h"


%hook VKExternalAppAuthContainer
+ (void)checkStatus:(int)arg1 { return; }
+ (void)delete:(id)arg1 { return; }
+ (id)load:(id)arg1 { return nil; }
+ (void)save:(id)arg1 data:(id)arg2 { return; }
+ (id)getKeychainQuery:(id)arg1 { return nil; }
+ (BOOL)appAuthTokenAvailable { return FALSE; }
+ (void)requestAndSaveExternalAppAuthToken:(id)arg1 { return; }
+ (void)removeExternalAppAuthToken { return; }
%end

%hook VKReachability
+ (id)sharedAPIReachability
{
    id reach = [%c(Reachability) performSelector:@selector(reachabilityWithHostName:) withObject:@"vk.com"];
    [reach performSelector:@selector(startNotifier)];
    return reach;
}
%end

%hook AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BOOL r = %orig;
    [VKS runBlockInBackground:^{
        if(![VKS clientIsLoggedIn]) {
            NSLog(@"MINIVKS: %%ctor: Client NOT logged in! clear push settings..");
            [[VKS shared] clearPushSettings];
        } else {
            if(![[VKS shared] pushAppAuthValid]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    NSLog(@"MINIVKS: %%ctor: clientIsLoggedIn: !pushAppAuthValid");
                    [[VKS shared] initiatePushAppAuth];
                });
            } else {
                [VKS runBlockInBackground:^{
                    NSLog(@"MINIVKS: %%ctor: clientIsLoggedIn: pushAppAuthValid");
                    [[VKS shared] registerDevice];
                    [[VKS shared] performCountersUpdate];
                }];
            }
        }
    }];
    return r;
}
%end

%hook AboutViewController
- (void)viewDidLoad
{
    %orig;
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [((UIViewController*)self).view.subviews[1] addGestureRecognizer:singleFingerTap];
    [singleFingerTap release];
}

%new
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
    NSLog(@"So tweak! Much doge! VKS! Wow! No doge? I don't give a fuck");
    id appDelegate = [[UIApplication sharedApplication] delegate];
    id mainCtrl = [appDelegate performSelector:@selector(main)];
    id mainModel = [mainCtrl performSelector:@selector(main)];
    id activity = [mainModel performSelector:@selector(activity)];
    [activity performSelector:@selector(touchActivity)];
}
%end

%hook VKMMainController
- (void)logout:(BOOL)arg1
{
    NSLog(@"MINIVKS: VKMMainController.logout.arg1:%i", ((int)arg1));
    [[VKS shared] clearPushSettings];
    %orig;
}
%end

%hook AFHTTPClient
- (id)requestWithMethod:(id)method path:(NSString*)path parameters:(NSMutableDictionary*)parameters
{
    if([VKS methodNeedsAlternateToken:path])
    {
        if([[VKS shared] pushAppAuthValid]) {
            [parameters setObject:[VKS shared].alternateAccessToken forKeyedSubscript:@"access_token"];
        } else {
            return nil;
        }
    }

    if(parameters) {
        parameters = [VKS processExecuteParameters:parameters];
    }

    id r = %orig(method, path, parameters);
    return r;
}
%end

%hook VKMAuthAppSiteAction
- (void)handleCompleteAuth:(NSURL*)resultUrl
{
    NSString *bundleId = (NSString*)[self performSelector:@selector(sdk_bundle)];
    if([bundleId isEqualToString:[[NSBundle mainBundle] bundleIdentifier]])
    {
        if([resultUrl.absoluteString containsString:@"access_token="])
        {
            [[VKS shared] processCompleteAuthURL:[resultUrl copy]];
        }
        else
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [VKS showAlertWithMessage:@"You can turn the notifications on in VKSettings preferences" title:@"VKS" buttonTitle:@"OK"];
            });
        }
        id ctrl = [self performSelector:@selector(weakController)];
        [ctrl dismissViewControllerAnimated:1 completion:0];      
    }
    else
    {
        %orig;
    }
}
%end

%hook AuthModel
- (void)completeWithUserId:(id)userId token:(id)token
{
    %orig();
    NSLog(@"MINIVKS: AuthModel: completeWithUserId: called");
    [[VKS shared] initiatePushAppAuth];
}
%end

%hook VKClient
-(void) setToken:(NSString*)input
{
    if(input) [VKS shared].accessToken = [input copy];
    %orig(input);
}
%end

%hook VKConfiguration

- (id)initShared
{
    id r = %orig;
    NSLog(@"VKConfiguration initShared: %@", r);
    return r;
}
+ (id)sharedInstance
{
    id conf = [[%c(VKConfiguration) alloc] performSelector:@selector(initShared)];
    NSLog(@"VKConfiguration sharedInstance: %@", conf);
    return conf;
}

+ (id)suiteName
{
    NSString *groupId = [VKS getGroupIdForProfile:[[VKS shared] provisioningProfile]];
    //NSString *teamId = [VKS getTeamIdForProfile:[[VKS shared] provisioningProfile]];
    //NSString *hackedGroupId = [NSString stringWithFormat:@"%@.%@", teamId, groupId];
    //NSLog(@"CLIENT hacked Group Id: %@", hackedGroupId);
    //return hackedGroupId;
    return groupId;
}
%end
