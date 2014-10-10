//
//  AppDelegate.m
//  BookReader
//
//  Created by Gauri Tikekar on 11/15/12.
//  Copyright (c) 2012 TeddyTab. All rights reserved.
//

#import "AppDelegate.h"
#import "Utility.h"
#import "BRCategoryScore.h"
#import "GAI.h"
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation AppDelegate


#define REGISTER_URL "http://www.teddytab.com/actions/register"

//For getting detailed stacktrace for exception
void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"Call Stack: %@", exception.callStackSymbols);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Added by Gauri:Google Analytics related code started
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;

    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 60;

    // Optional: set Logger to VERBOSE for debug information.
    // [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];

    // Initialize tracker.
    //id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:@"UA-43630404-1"];
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-43630404-1"];
    // Google Analytics related code ended
        
    //For getting detailed stacktrace for exception
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    // Override point for customization after application launch.
    self.statDB = [BRActivityStatDB alloc];
    [self.statDB initialize];
     
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
	[self.window makeKeyAndVisible];

    CGRect screenRect = [[UIScreen mainScreen] bounds];
    self.aspectRatio = screenRect.size.height / screenRect.size.width;
    if (self.aspectRatio < 1) {
        self.aspectRatio = 1 / self.aspectRatio;
    }
    NSLog(@"Aspect ratio is %f", self.aspectRatio);

    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    self.platform = [NSString stringWithUTF8String:machine];
    free(machine);

    self.language = [[NSLocale preferredLanguages] objectAtIndex:0];
    self.version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

	// Let the device know we want to receive push notifications
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];

    return YES;
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
	NSLog(@"My token is: %@", deviceToken);

    NSString *deviceId = @"";
    const unsigned *tokenBytes = [deviceToken bytes];
    // TODO(abhi): Find a better way to get this 8 from length somewhere.
    for (int i = 0; i < 8; i++) {
        deviceId = [deviceId stringByAppendingString:[NSString stringWithFormat:@"%08x", ntohl(tokenBytes[i])]];
    }
    UIDevice *device = [UIDevice currentDevice];

    NSString *platform = [[NSString stringWithFormat:@"platform:%@", self.platform] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *model = [[NSString stringWithFormat:@"model:%@", device.model] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *version = [[NSString stringWithFormat:@"version:%@", device.systemVersion] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *timezone = [[NSString stringWithFormat:@"timezone:%@", [NSTimeZone localTimeZone].abbreviation]stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *language = [[NSString stringWithFormat:@"language:%@", self.language]stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *nsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%s?id=%@&tag=%@&tag=%@&tag=%@&tag=%@&tag=%@", REGISTER_URL, deviceId, model, version, timezone, language, platform]];
    NSLog(@"URL for register is: %@", nsUrl);
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:nsUrl];
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        if (error == nil) {
            NSLog(@"Successfully registered the device.");
        } else {
            NSLog(@"Failed to register device: %@", error);
        }
    }];
    
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	NSLog(@"Failed to get token, error: %@", error);
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(NSString *) getScoreLetter {
    NSArray *scores = [[NSMutableArray alloc] initWithArray:[_statDB getScoreCard:@"abcdbuddy"]];
    int totalAttempts = 0;
    int totalSolved = 0;
    for( int i=0; i < [scores count]; i++) {
        BRCategoryScore *score = scores[i];
        if( [score.category isEqualToString:@"PageType"] ) {
            continue;
        }
        totalAttempts = totalAttempts + score.attempts;
        totalSolved = totalSolved + score.solved;
    }
    
    int percentScore = (totalAttempts != 0) ? (100 * totalSolved) / totalAttempts : 0;
    if(percentScore >= 85) {
        return @"A+";
    } else if(percentScore >= 70) {
        return @"A";
    } else if(percentScore >= 55) {
        return @"B+";
    } else if(percentScore >= 40) {
        return @"B";
    } else if(percentScore >= 25) {
        return @"C+";
    } else if(percentScore > 0) {
        return @"C";
    }
    return @"";
}

@end
