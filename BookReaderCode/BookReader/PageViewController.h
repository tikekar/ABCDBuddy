//
//  BookPageViewController.h
//  BookReader
//
//  Created by Gauri Tikekar on 11/15/12.
//  Copyright (c) 2012 TeddyTab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Page.h"
#import "URLCache.h"
#import "Book.h"
#import "GAITrackedViewController.h"

@interface PageViewController : GAITrackedViewController

@property ( strong, nonatomic) Book *book;

@property ( strong, nonatomic) NSMutableArray *timers;

@property (nonatomic) NSDate *pageLoadTime;

//This was added for especially stoping background music.
//We store the animationRunners for all running animations;
@property ( strong, nonatomic) NSMutableDictionary *runningAnimations;

//This is to fix the two times clicking on the running chain animation object.
@property ( strong, nonatomic) NSMutableDictionary *runningChains;

@property URLCache *urlCache;

@property Page *modelPage;

@property NSUInteger pageNumber;

//This is for counter. If same button clicked two times or same animation chain occured two times, the counter should not increase for any "Find Objects" //Activity.
@property (nonatomic) NSMutableDictionary *occurredEvents;

@property NSMutableDictionary *toyObjects;

@property NSMutableDictionary *toyButtons;

@property NSMutableDictionary *eventAnims;

@property NSMutableDictionary *pageUIImages;

-(void) render;


@end
