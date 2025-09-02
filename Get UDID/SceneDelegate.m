//
//  SceneDelegate.m
//  Get UDID
//
//  Created by Đỗ Trung Thành on 2/9/25.
//

#import "SceneDelegate.h"
#import "ViewController.h"

@interface SceneDelegate ()

@end

@implementation SceneDelegate


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
    // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
    // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
    
    // Handle URL scheme if app was opened with one
    for (NSUserActivity *activity in connectionOptions.userActivities) {
        [self handleURLScheme:activity.webpageURL];
    }
    
    // Handle URL contexts if present
    for (UIOpenURLContext *urlContext in connectionOptions.URLContexts) {
        [self handleURLScheme:urlContext.URL];
    }
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    // Handle URL scheme when app is already running
    for (UIOpenURLContext *urlContext in URLContexts) {
        [self handleURLScheme:urlContext.URL];
    }
}

- (void)handleURLScheme:(NSURL *)url {
    if (!url) return;
    
    NSLog(@"[SCENE_DELEGATE] Received URL scheme: %@", url.absoluteString);
    
    // Check if this is our app's URL scheme
    if ([url.scheme isEqualToString:@"getudid"]) {
        // Get the main view controller and pass the URL
        UIWindowScene *windowScene = (UIWindowScene *)[[UIApplication sharedApplication].connectedScenes anyObject];
        UIWindow *window = windowScene.windows.firstObject;
        
        if ([window.rootViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navController = (UINavigationController *)window.rootViewController;
            if ([navController.topViewController isKindOfClass:[ViewController class]]) {
                ViewController *viewController = (ViewController *)navController.topViewController;
                [viewController handleURLSchemeCallback:url];
            }
        } else if ([window.rootViewController isKindOfClass:[ViewController class]]) {
            ViewController *viewController = (ViewController *)window.rootViewController;
            [viewController handleURLSchemeCallback:url];
        }
    }
}


- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
}


- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
}


@end
