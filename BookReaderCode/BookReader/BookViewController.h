//
//  BookViewController.h
//  BookReader
//
//  Created by Gauri Tikekar on 11/15/12.
//  Copyright (c) 2012 TeddyTab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BookModelController.h"
#import "GAITrackedViewController.h"

@interface BookViewController : GAITrackedViewController

@property UIActivityIndicatorView *activity;
@property ( strong, nonatomic) BookModelController *modelController;

@property (nonatomic) NSMutableArray *childPages;

@property (nonatomic) UIViewController *currentPageController;

@property (nonatomic) int currentPageNumber;

-(void) goToPage : (int) pageNumber : (NSString *) effect;
-(void) closeBook;
-(void) reloadCurrentPage;


@end
