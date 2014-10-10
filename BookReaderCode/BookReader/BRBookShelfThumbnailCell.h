//
//  BookShelfThumbnailCell.h
//  BookReader
//
//  Created by Gauri Tikekar on 1/7/13.
//  Copyright (c) 2013 TeddyTab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BRRootViewController.h"
#import "BRBookCard.h"

@interface BRBookShelfThumbnailCell : UICollectionViewCell

@property (nonatomic) IBOutlet UIProgressView *progressView;
@property (weak) IBOutlet UIButton *bookPriceBtn;
@property (weak, nonatomic) IBOutlet UILabel *bookDescriptionLbl;
@property (weak, nonatomic) IBOutlet UIButton *thumbnailBtn;
@property (weak, nonatomic) IBOutlet UITextView *detailsText;

//http://stackoverflow.com/questions/821692/what-does-the-property-nonatomic-mean
@property  NSString *percentage; //removed the nonatomic declaration. Most probably that throws that malloc error

@property (strong) BRRootViewController *rootViewController;

@property (weak, nonatomic) IBOutlet UILabel *promoLabel;
@property (nonatomic) NSTimer *timer;

@property BOOL isPurchased;
@property (strong) BRBookCard *card;

-(void) setBookCard:(BRBookCard *)card;

-(void) showDownloadingIndicator;
-(void) hideDownloadingIndicator;

@end
