//
//  RootViewController.h
//  BookReader
//
//  Created by Gauri Tikekar on 11/15/12.
//  Copyright (c) 2012 TeddyTab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "BRBookShelfData.h"
#import "BookViewController.h"
#import "BRInAppPurchaseManager.h"
#import "BRBookCard.h"
#import "BRShelfHeader.h"
#import "GAITrackedViewController.h"

@interface BRRootViewController : GAITrackedViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;

@property (weak, nonatomic) IBOutlet UIButton *searchButton;

@property (weak, nonatomic) IBOutlet UITextField *searchBox;
@property AppDelegate *app;

@property(nonatomic, strong) NSMutableDictionary *thumbnailCards;

@property double tipsTimeStamp;

@property (weak, nonatomic) IBOutlet UIButton *headerTextBtn;
@property (weak, nonatomic) IBOutlet UIButton *headerImageBtn;

@property (weak, nonatomic) IBOutlet UIButton *scoreBtn;

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@property BRBookShelfData *bookShelfData;
@property BRInAppPurchaseManager *purchaseManager;
@property BRShelfHeader *currentHeader;

@property (strong, nonatomic) BookViewController *bookViewController;

-(void) initializeBookShelf;
-(void) openBook : (NSString *) bookId : (NSString* ) bookUrl;
-(void) purchaseBook : (BRBookCard *) bookCard;
-(void) openMathDialog;

@end