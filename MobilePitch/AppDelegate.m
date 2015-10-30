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
#import "PitchSubmissionController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // Main navigation controller
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[SplashViewController alloc] init]];
    
    // Disable edge swiping. Doesn't make sense here, and there's too much risk it could mess something up
    navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    PitchSubmissionController *psc = [[PitchSubmissionController alloc] init];
    NSUInteger identifier = [psc generateUniqueIdentifier];
    [psc queueVideoAtURL:[NSURL URLWithString:@""] identifier:identifier];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:@"Brian" forKey:@"first_name"];
    [parameters setObject:@"Anglin" forKey:@"last_name"];
    [parameters setObject:@"banglin@usc.edu" forKey:@"email"];
    [parameters setObject:@"SparkSC" forKey:@"student_org"];
    [parameters setObject:@"Engineering" forKey:@"college"];
    [parameters setObject:@"2018" forKey:@"grad_year"];
    [parameters setObject:@"Moblie App for Pankcake Delivery" forKey:@"pitch_title"];
    
    // Must be one of the following:
    // Music, Film, Environment, Education, Tech & Hardware, Web & Software, Consumer Products & Small Business, Health, University Improvements, Mobile, Research, Video Games
    [parameters setObject:@"Music" forKey:@"pitch_category"];
    [parameters setObject:@"This is just a sort descrpition of how dope this will be" forKey:@"pitch_short_description"];
    
    [psc queueFormSubmissionWithDictionary:[parameters copy] identifier:identifier];
    
    [psc startProcessingQueue];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:navigationController];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
