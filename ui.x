#import <UIKit/UIKit.h>

%hook VKMMainController
- (void)setupTabBarControllers {
    %orig;

    UITabBarController *ctrl = (UITabBarController*)self;
    NSMutableArray *viewControllers = [[NSMutableArray alloc] initWithArray:ctrl.viewControllers];
    if([viewControllers count] == 5) {
        [viewControllers removeObjectAtIndex:1];

        [viewControllers exchangeObjectAtIndex:1 withObjectAtIndex:2];

        id model = [self performSelector:@selector(main)];
        id audioSelector = [model performSelector:@selector(selectorAudio)];
        id delegate = [self performSelector:@selector(navigationControllerDelegate)];

        UINavigationController *navCtrl = [[objc_getClass("VKMNavigationController") alloc] initWithRootViewController:audioSelector];

        [navCtrl setDelegate:delegate];

        UIImage *iconMusic = [UIImage imageNamed:@"profile/audios"];
        UIImage *selectedIconMusic = [UIImage imageNamed:@"profile/audios"];
        UITabBarItem *itemAudio = [[UITabBarItem alloc] initWithTitle:@"" image:iconMusic selectedImage:selectedIconMusic];
        [navCtrl performSelector:@selector(setTabBarItem:) withObject: itemAudio];
        navCtrl.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
        navCtrl.tabBarItem.titlePositionAdjustment = UIOffsetMake(0.0, 50.0);
        [viewControllers insertObject:navCtrl atIndex:3];
    }
    ctrl.viewControllers = viewControllers;
}
%end

%hook AudioListController
- (id)setupTitle:(id)arg1 {
    return %orig(nil);
}
%end
