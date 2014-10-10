//
//  AppDelegate.h
//  BookReader
//
//  Created by Gauri Tikekar on 11/15/12.
//  Copyright (c) 2012 TeddyTab. All rights reserved.
//

#import "BRActivityStatDB.h"
#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic) BRActivityStatDB *statDB;

@property NSString *platform;
@property NSString *language;
@property NSString *version;
@property CGFloat aspectRatio;

-(NSString*) getScoreLetter;

//For getting detailed stacktrace for exception
void uncaughtExceptionHandler(NSException *exception);

@end
