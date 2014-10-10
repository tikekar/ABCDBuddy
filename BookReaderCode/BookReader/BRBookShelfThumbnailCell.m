//
//  BookShelfThumbnailCell.m
//  BookReader
//
//  Created by Gauri Tikekar on 1/7/13.
//  Copyright (c) 2013 TeddyTab. All rights reserved.
//

#import "BRBookShelfThumbnailCell.h"
#import "URLCache.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "DPConstants.h"
#import <QuartzCore/QuartzCore.h>


@implementation BRBookShelfThumbnailCell

- (void)prepareForReuse {
    [self hideDownloadingIndicator];

    self.detailsText.hidden = TRUE;
    self.thumbnailBtn.hidden = FALSE;
    self.thumbnailBtn.enabled = TRUE;

    self.bookPriceBtn.hidden = FALSE;
    self.bookPriceBtn.selected = FALSE;
    self.bookPriceBtn.enabled = TRUE;
}

-(void) setBookCard:(BRBookCard *)card {
    self.card = card;
    self.isPurchased = [self.rootViewController.bookShelfData isPurchased:self.card.bookId];
    [self hideDownloadingIndicator];
    [self setImageUrl:self.card.thumbnailUrl];
    [self.bookDescriptionLbl setText:self.card.description];
    [self.detailsText setText:[NSString stringWithFormat:@"%@\n%@\n\n%@", self.card.author, self.card.authorUrl, self.card.longDescription]];
    [self.promoLabel setText:self.card.promoLabel];

    NSString *freeString = NSLocalizedStringFromTable(@"FREE", @"InfoPlist", nil);
    
    if( isPurchased ) {
        self.bookPriceBtn.hidden = TRUE;
    } else if( [self.card.price isEqualToString:@"0"]) {
        [self.bookPriceBtn setTitle:freeString forState:UIControlStateNormal];
    } else if( ![self.card.price isEqualToString:@"0"]) {
        NSString *str = [NSString stringWithFormat:@"$%@", self.card.price];
        [self.bookPriceBtn setTitle:str forState:UIControlStateNormal];
    }

    UIColor *bgColor = self.card.bgColor;
    [self setBackgroundColor:bgColor];

    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textViewTapped:)];
    [self.detailsText addGestureRecognizer:gestureRecognizer];
}

- (IBAction)onPriceClick:(id)sender {
    if( self.card.productId != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MATH_SOLVED_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parentValidated:) name:MATH_SOLVED_NOTIFICATION object:nil];
        [self.rootViewController openMathDialog];
    }
    else {
            self.isPurchased = TRUE;
            NSMutableArray *bookIdsArray = [[NSMutableArray alloc] init];
            [bookIdsArray addObject:self.card.bookId];
            [self.rootViewController.bookShelfData addBookIdsToMyBooks:bookIdsArray];
            [self startDownloading];

    }
    [self dispatch:@"Price":self.card.price];
        
}

-(void) parentValidated: (NSNotification *)notification {
    NSLog(@"mathSolvednotification for in app purchase");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MATH_SOLVED_NOTIFICATION object:nil];
    NSString *solved = notification.object;
    if( [solved isEqualToString:MATH_SOLVED_FLAG]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:INAPP_PRODUCT_PURCHASED_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bookPurchased:) name:INAPP_PRODUCT_PURCHASED_NOTIFICATION object:nil];
        [self.rootViewController purchaseBook:self.card];
    }
}


- (IBAction)onThumbnailClick:(id)sender {
    if( isPurchased ) {
        [self startDownloading];
    }
    else {
        [UIButton beginAnimations:nil context:nil];
        [UIButton setAnimationDuration:0.5];
        [UIButton setAnimationBeginsFromCurrentState:YES];
        [UIButton setAnimationTransition:UIViewAnimationTransitionCurlUp
                                 forView:self.thumbnailBtn cache:YES];

        self.thumbnailBtn.hidden = TRUE;
        self.detailsText.hidden = FALSE;
        [UIButton commitAnimations];
    }
    [self dispatch:@"BookCard":self.card.title];
}

// Google Analytics dispatch event
- (void)dispatch : (NSString*) eventCategory :(NSString*) buttonName {
    if(buttonName != nil) {
        NSMutableDictionary *event =
        [[GAIDictionaryBuilder createEventWithCategory:eventCategory
                                                action:@"touchdown"
                                                 label:buttonName
                                                 value:nil] build];
        [[GAI sharedInstance].defaultTracker send:event];
        [[GAI sharedInstance] dispatch];
    }
}


-(void) textViewTapped:(UITapGestureRecognizer *) sender {
    [UIButton beginAnimations:nil context:nil];
    [UIButton setAnimationDuration:0.5];
    [UIButton setAnimationBeginsFromCurrentState:YES];
    [UIButton setAnimationTransition:UIViewAnimationTransitionCurlDown
                             forView:self.thumbnailBtn cache:YES];
    self.detailsText.hidden = TRUE;
    self.thumbnailBtn.hidden = FALSE;
    [UIButton commitAnimations];
}

- (void)bookPurchased:(NSNotification *)notification {
    NSLog(@"Book is Purchased");
    NSString * productIdentifier = notification.object;
    if([self.card.productId isEqualToString:productIdentifier]) {
        self.isPurchased = TRUE;
         NSMutableArray *productIdsArray = [[NSMutableArray alloc] init];
        [productIdsArray addObject:productIdentifier];
        [self.rootViewController.bookShelfData addProductIdsToMyBooks:productIdsArray];
        [self startDownloading];
    }
}

-(void) startDownloading {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOAD_COMPLETE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"updateProgress" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadComplete) name:DOWNLOAD_COMPLETE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress:) name:@"updateProgress" object:nil];
    
    [self bounce];
    [self showDownloadingIndicator];

    self.thumbnailBtn.enabled = FALSE;

    // make opening book call asynchronous. Because else the bouncing happens late.
    NSOperationQueue *queue = [NSOperationQueue new];
    NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                        initWithTarget:self
                                        selector:@selector(openBook)
                                        object:nil];

    [queue addOperation:operation];
}

-(void) openBook {
    [self.rootViewController openBook:self.card.bookId : self.card.bookUrl];
}

-(void) showDownloadingIndicator {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.5
                                target:self
                                selector:@selector(startCounter)
                                userInfo:nil
                                repeats:YES];

    [self.progressView setHidden:FALSE];
}

-(void) startCounter {
    NSString *lblVal = [NSString stringWithFormat:@"%f", [self.percentage floatValue]*100];
    lblVal = [NSString stringWithFormat:@"%d", [lblVal intValue]];
    lblVal = [lblVal stringByAppendingString:@"%"];
    self.progressView.progress = [self.percentage floatValue];
}

-(void) hideDownloadingIndicator {
    self.progressView.hidden = TRUE;
    self.thumbnailBtn.enabled = TRUE;
    if( self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

-(void) downloadComplete {
    self.bookPriceBtn.enabled = TRUE;
    [self performSelectorOnMainThread:@selector(hideDownloadingIndicator) withObject:nil waitUntilDone:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOAD_COMPLETE_NOTIFICATION object:nil];
}

-(void) updateProgress :(NSNotification *)notification {
    NSDictionary *dictionary = [notification userInfo];
    NSString *increment = [[dictionary allKeys] objectAtIndex:0];
    float counterVal = [self.percentage floatValue];
    counterVal = counterVal + [increment doubleValue];
    self.percentage = [NSString stringWithFormat:@"%f", counterVal];
    if( counterVal >= 1.0 ){
        [self hideDownloadingIndicator];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"updateProgress" object:nil];
    }
}

-(void) setImageUrl : (NSString *) url {
    URLCache *urlCache = [[URLCache alloc] init];
    UIImage *urlImage = [urlCache getImage:url];
    
    thumbnailBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    thumbnailBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    [thumbnailBtn setContentMode:UIViewContentModeScaleAspectFill];
    thumbnailBtn.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    [thumbnailBtn setBackgroundImage:urlImage forState:UIControlStateNormal];
    [thumbnailBtn setBackgroundImage:urlImage forState:UIControlStateSelected];
    [thumbnailBtn setBackgroundImage:urlImage forState:UIControlStateHighlighted];

}

// To add dropdown shadow.
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.borderWidth = 1.0f;
    //self.layer.cornerRadius = 8.0f;
    self.layer.masksToBounds = NO;
    self.layer.shadowOffset = CGSizeMake(2, 2);
    self.layer.shadowRadius = 2;
    self.layer.shadowOpacity = 0.5;

    //Not sure if required. But websites say that dding the following line can improve performance as long as your view is visibly rectangular: Need to take a look
    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
}

-(void) bounce  {
    float ydelta = -20;

    UIBezierPath *customPath = [UIBezierPath bezierPath];

    [customPath moveToPoint:CGPointMake(self.center.x, self.center.y)];
    [customPath addQuadCurveToPoint:CGPointMake(self.center.x, self.center.y + ydelta ) controlPoint:CGPointMake(self.center.x, self.center.y + ydelta) ];

    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.duration = 0.3;
    pathAnimation.repeatCount = 1;
    pathAnimation.path = customPath.CGPath;
    pathAnimation.calculationMode = kCAAnimationLinear;
    pathAnimation.autoreverses = true;

    pathAnimation.delegate = self;

    [self.layer addAnimation:pathAnimation forKey:@"movingAnimation"];
    
}

@end
