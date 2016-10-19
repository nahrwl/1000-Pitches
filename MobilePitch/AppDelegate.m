//
//  AppDelegate.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/23/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "AppDelegate.h"
#import "SplashViewController.h"
#import "FormViewController.h"
#import "SubmissionManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // Main navigation controller
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[FormViewController alloc] init]];
    
    // Disable edge swiping. Doesn't make sense here, and there's too much risk it could mess something up
    navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    // Create the video submission manager ahead of time
    [[SubmissionManager sharedManager] checkUploadStatus];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:navigationController];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[SubmissionManager sharedManager] serializeObjectToDefaultFile];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    //[[SubmissionManager sharedManager] serializeObjectToDefaultFile];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that weres paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[SubmissionManager sharedManager] checkUploadStatus];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    //[[PitchSubmissionController sharedPitchSubmissionController] saveData];
    [[SubmissionManager sharedManager] serializeObjectToDefaultFile];
}
//
//#pragma mark Background Upload
//
//- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
//    NSAssert([[VideoSubmissionManager sharedManager].session.configuration.identifier isEqualToString:identifier], @"Identifiers didn't match");
//    [VideoSubmissionManager sharedManager].savedCompletionHandler = completionHandler;
//}

@end
