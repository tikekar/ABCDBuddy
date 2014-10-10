//
//  BookViewController.m
//  BookReader
//
//  Created by Gauri Tikekar on 11/15/12.
//  Copyright (c) 2012 TeddyTab. All rights reserved.
//

#import "BookViewController.h"
#import "BookModelController.h"
#import <QuartzCore/QuartzCore.h>
#import "Utility.h"

@interface BookViewController ()

@end

@implementation BookViewController

@synthesize activity, modelController, childPages, currentPageController, currentPageNumber;

-(void) closeBook {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.screenName = self.modelController.book.bookId;
    UIViewController *startingViewController = [self.modelController viewControllerAtIndex:0 storyboard:self.storyboard];
    // Added this check to avoid the crash found by Apple team while testing version 1.4 with iOS7.
    // Read full comment in RootViewController openBookInSameThread method.
    // Main null check happens there. This nil check is just to avoid crash, but will open a blank window.
    // So this is not enough.
    if (startingViewController == nil) {
        return;
    }
    
    [self addChildViewController:startingViewController];
    [self.view insertSubview:startingViewController.view atIndex:0];
 
    self.currentPageController = startingViewController;
}

-(void) reloadCurrentPage {
    UIViewController *viewController = [self.modelController viewControllerAtIndex:self.currentPageNumber storyboard:self.storyboard];

    [self addChildViewController:viewController];

    [self.view insertSubview:viewController.view atIndex:0];
   
    if (self.currentPageController) {
        [self.currentPageController.view removeFromSuperview];
        [self.currentPageController removeFromParentViewController];

    }
    self.currentPageController = viewController;
 
}

-(void) goToPage : (int) pageNumber : (NSString *) effect {

    if( [effect isEqualToString:@"slide"]) {
        [self slideToPage:pageNumber];
    }
    else if( [effect isEqualToString:@"slidedown"]) {
        [self slideDownToPage:pageNumber];
    }
    else if( [effect isEqualToString:@"zoom"]) {
        [self zoomAnimate:pageNumber];
    }
    else  if( [effect isEqualToString:@"none"]) {        
        UIViewController *viewController = [self.modelController viewControllerAtIndex:pageNumber storyboard:self.storyboard];

        [self addChildViewController:viewController];

        [self.view insertSubview:viewController.view atIndex:0];


        if (self.currentPageController) {
            [self.currentPageController.view removeFromSuperview];
            [self.currentPageController removeFromParentViewController];

        }
        self.currentPageController = viewController;
        
    }
}

-(void) slideToPage : (int) pageNumber {
    UIViewController *viewController = [self.modelController viewControllerAtIndex:pageNumber storyboard:self.storyboard];

    bool forward = pageNumber > self.currentPageNumber;

    [self addChildViewController:viewController];

    [self.view insertSubview:viewController.view atIndex:0];

    CGRect screenFrame = [Utility getScreenBoundsForOrientation];
    int xVal = screenFrame.size.width + 2;
    if( !forward ) {
        xVal = -xVal;
    }
    [viewController.view setTransform:CGAffineTransformMakeTranslation(xVal, 0)];

    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{

        [self.currentPageController.view setTransform:CGAffineTransformMakeTranslation(-xVal, 0)];
        [viewController.view setTransform:CGAffineTransformMakeTranslation(0, 0)];

    }completion:^(BOOL done) {
        if (self.currentPageController) {
            [self.currentPageController.view removeFromSuperview];
            [self.currentPageController removeFromParentViewController];

        }
        self.currentPageController = viewController;
        self.currentPageNumber = pageNumber;

    }];

}

-(void) slideDownToPage : (int) pageNumber {
    UIViewController *viewController = [self.modelController viewControllerAtIndex:pageNumber storyboard:self.storyboard];

    bool forward = pageNumber > self.currentPageNumber;

    [self addChildViewController:viewController];

    [self.view insertSubview:viewController.view atIndex:0];

    CGRect screenFrame = [Utility getScreenBoundsForOrientation];
    int yVal = screenFrame.size.height + 2;
    if( !forward ) {
        yVal = -yVal;
    }
    [viewController.view setTransform:CGAffineTransformMakeTranslation(0, yVal)];

    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{

        [self.currentPageController.view setTransform:CGAffineTransformMakeTranslation(0, -yVal)];
        [viewController.view setTransform:CGAffineTransformMakeTranslation(0, 0)];

    }completion:^(BOOL done) {
        if (self.currentPageController) {
            [self.currentPageController.view removeFromSuperview];
            [self.currentPageController removeFromParentViewController];

        }
        self.currentPageController = viewController;
        self.currentPageNumber = pageNumber;
        
    }];
    
}


-(void) zoomAnimate : (int) pageNumber {
    UIViewController *viewController = [self.modelController viewControllerAtIndex:pageNumber storyboard:self.storyboard];

    [self addChildViewController:viewController];

    [self.view insertSubview:viewController.view atIndex:0];


    viewController.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.001, 0.001);

    [UIView animateWithDuration:0.1 animations:^{
        viewController.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1.0 animations:^{
            viewController.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                viewController.view.transform = CGAffineTransformIdentity;
            }completion:^(BOOL done) {
               
                if (self.currentPageController) {
                    [self.currentPageController.view removeFromSuperview];
                    [self.currentPageController removeFromParentViewController];

                }
                self.currentPageController = viewController;
                self.currentPageNumber = pageNumber;
                
            }];
           
        }];
    }];

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// for iOS 6
- (BOOL)shouldAutorotate {
    return NO;
}

// for iOS 6
-(NSUInteger)supportedInterfaceOrientations {

    if( [[self.modelController getBookOrientation] isEqualToString:@"portrait"]) {
        return 2;
    }
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

// for BalloonGame app for iOS 5
- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation {
    if (interfaceOrientation == UIInterfaceOrientationPortrait
        || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        return NO;
    }
    return YES;
}


@end
