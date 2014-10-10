//
//  RootViewController.m
//  BookReader
//
//  Created by Gauri Tikekar on 11/15/12.
//  Copyright (c) 2012 TeddyTab. All rights reserved.
//

#import "BRRootViewController.h"
#import "BRMathViewController.h"
#import "BookModelController.h"
#import "BookViewController.h"
#import "BRBookShelfData.h"
#import "BRBookShelfThumbnailCell.h"
#import "BRShelfSection.h"
#import "BRShelfHeader.h"
#import "BRBookCard.h"
#import "ScoreCardViewController.h"
#import "URLCache.h"
#import "Utility.h"
#import "DPConstants.h"
#import <Social/Social.h>
#import "GAI.h"
#import "GAIDictionaryBuilder.h"


@interface BRRootViewController ()
@property (strong, nonatomic) BookModelController *modelController;
@end

@implementation BRRootViewController

- (void)viewDidLoad {
    NSLog(@"RootViewController.viewDidLoad");
    [super viewDidLoad];

    [self.searchBox addTarget:self action:@selector(searchBoxDidChange)
        forControlEvents:UIControlEventEditingChanged];

    self.screenName = @"ABCD Buddy";
    _app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [self setHeaderHidden:TRUE];
    self.tipsTimeStamp = 0;
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"RootViewController.viewDidAppear");
    [super viewDidAppear:animated];

    if (self.bookShelfData == nil) {
        [self initializeBookShelf];
    }

    self.thumbnailCards = [[NSMutableDictionary alloc] init];
    self.modelController = [[BookModelController alloc] init];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOAD_COMPLETE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadComplete) name:DOWNLOAD_COMPLETE_NOTIFICATION object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:SHOW_PARENT_DIALOG_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showParentControlDialog:) name:SHOW_PARENT_DIALOG_NOTIFICATION object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:INCREMENT_COLUMN_FOR_TAG_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incrementColumnForTag:) name:INCREMENT_COLUMN_FOR_TAG_NOTIFICATION object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:ADD_TIME_FOR_TAG_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addTimeForTag:) name:ADD_TIME_FOR_TAG_NOTIFICATION object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:TRACKING_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInteraction:) name:TRACKING_NOTIFICATION object:nil];


    [self updateScore];
    
    // fixed the issue about tips area getting changed when math view controller dialog gets dismissed.
    // This was reproducible only on iPhone, because in that the mathviewcontroller does not open modally. So
    // when it gets closed, the viewdidappear of rootViewController gets called before proceedTips method.
    // The fix is that change the tips after each 5 mins.
    double currentTimeStamp = [[NSDate date] timeIntervalSince1970];
    if(currentTimeStamp - self.tipsTimeStamp > 300) {
        [self showBookShelfHeader];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:POPULATE_BOOKS_FEED_NOTIFICATION object:nil ];
}

// TODO: To be implemented for all tracking events/event types.
-(void) onUserInteraction : (NSNotification *) notification {

    if(notification != nil && [notification userInfo] != nil) {
        NSString *eventName = [[notification userInfo] valueForKey:TRACKING_EVENT_NAME];
        NSMutableDictionary *tags = [[notification userInfo] mutableCopy];
        if(eventName != nil && [@"pageload" caseInsensitiveCompare:eventName] == NSOrderedSame) {
            NSString *pageNumber = [[notification userInfo] valueForKey:@"pageNumber"];
            NSMutableDictionary *event =
            [[GAIDictionaryBuilder createEventWithCategory:@"PageLoad"
                                                    action:eventName
                                                     label:pageNumber
                                                     value:nil] build];
            [[GAI sharedInstance].defaultTracker send:event];
            [[GAI sharedInstance] dispatch];

        }
        else {
            NSString *buttonName = [[notification userInfo] valueForKey:@"objectId"];
            if( buttonName != nil) {
                NSMutableDictionary *event =
                [[GAIDictionaryBuilder createEventWithCategory:@"PageObject"
                                                        action:eventName
                                                         label:buttonName
                                                         value:nil] build];
                [[GAI sharedInstance].defaultTracker send:event];
                [[GAI sharedInstance] dispatch];
            }
        }
        
    }


}

-(void) setHeaderHidden: (BOOL) flag {
    [self.headerImageBtn setHidden:flag];
    [self.headerTextBtn setHidden:flag];
}

-(void) initializeBookShelf {
    NSLog(@"RootViewController.initializeBookShelf");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:POPULATE_BOOKS_FEED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(populateBooksFeed) name:POPULATE_BOOKS_FEED_NOTIFICATION object:nil];
    self.bookShelfData = [BRBookShelfData alloc];
    [bookShelfData initialize];
    [self loadInAppProducts];
}

-(void) loadInAppProducts {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PURCHASED_PRODUCTS_RESTORED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePurchasedBooksList:) name:PURCHASED_PRODUCTS_RESTORED_NOTIFICATION object:nil];

    self.purchaseManager = [[BRInAppPurchaseManager alloc] initWithProductIdentifiers:[self.bookShelfData getProductIds]];
    [self.purchaseManager requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
        if (success) {
            [self.bookShelfData updateBookCards:products];
            [[NSNotificationCenter defaultCenter] postNotificationName:POPULATE_BOOKS_FEED_NOTIFICATION object:nil];
        }
    }];
}

-(void) updateScore {
    NSString *currentScore =  [_app getScoreLetter];
    [self.scoreBtn  setTitle:currentScore forState:UIControlStateNormal];
    [self.scoreBtn  setTitle:currentScore forState:UIControlStateSelected];
}

- (void)updatePurchasedBooksList:(NSNotification *)notification {
    NSLog(@"Book is Purchased");
    NSMutableArray * productIdentifiers = notification.object;
    [self.bookShelfData addProductIdsToMyBooks:productIdentifiers];
    [[NSNotificationCenter defaultCenter] postNotificationName:POPULATE_BOOKS_FEED_NOTIFICATION object:nil];
}

- (void)showParentControlDialog:(NSNotification *)notification {
    BRMathViewController *mathViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MathViewController"];
    mathViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.bookViewController.currentPageController presentViewController:mathViewController animated:true completion:nil];
}

- (void)incrementColumnForTag:(NSNotification *)notification {
    NSDictionary *dictionary = [notification userInfo];
    NSString *colName = [dictionary objectForKey:@"eventType"];
    NSString *category = [dictionary objectForKey:@"tag"];
    [self.app.statDB incrementColumn:colName : @"abcdbuddy" :category];
}

- (void)addTimeForTag:(NSNotification *)notification {
    NSDictionary *dictionary = [notification userInfo];
    NSString *category = [dictionary objectForKey:@"tag"];
    NSString *timeVal = [dictionary objectForKey:@"timeMillis"];

    [self.app.statDB addTime:@"abcdbuddy" : category :[timeVal longLongValue]];
}

-(void) openMathDialog {
    BRMathViewController *mathViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MathViewController"];
    mathViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:mathViewController animated:true completion:nil];
}

- (IBAction)goToScore:(id)sender {
    ScoreCardViewController *scoreCard = [self.storyboard instantiateViewControllerWithIdentifier:@"ScoreCardViewController"];
    [self presentViewController:scoreCard animated:true completion:nil];
}

-(void) showBookShelfHeader {
    if ([self.bookShelfData.myBookIds count] == 0) {
        [self setHeaderHidden:FALSE];
        NSString *restoreString = NSLocalizedStringFromTable(@"RESTORE_PURCHASES", @"InfoPlist", nil);
        [self.headerTextBtn setTitle:restoreString forState:UIControlStateNormal];
        [self.headerTextBtn setTitle:restoreString forState:UIControlStateHighlighted];
        return;        
    }
    self.tipsTimeStamp = [[NSDate date] timeIntervalSince1970];
    int frequencyNumber = [Utility getRandomNumber:@"0:99"];
    for(int i=0;i<[self.bookShelfData.headers count]; i++) {
        BRShelfHeader *header = self.bookShelfData.headers[i];
        if( [header isFrequencyInRange:frequencyNumber]) {
            [self setHeaderHidden:FALSE];
            URLCache *urlCache = [[URLCache alloc] init];
            UIImage *urlImage = [urlCache getImage:header.imageUrl];
            [self.headerImageBtn setImage:urlImage forState:UIControlStateNormal];
            [self.headerImageBtn setImage:urlImage forState:UIControlStateHighlighted];
            [self.headerTextBtn setTitle:header.headerText forState:UIControlStateNormal];
            [self.headerTextBtn setTitle:header.headerText forState:UIControlStateHighlighted];
            self.currentHeader = header;
            break;
        }
    }
}

- (IBAction)onHeaderTextTouchDown:(id)sender {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MATH_SOLVED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proceedWithTips:) name:MATH_SOLVED_NOTIFICATION object:nil];
    [self openMathDialog];
    
}

-(void) proceedWithTips: (NSNotification *)notification {
    NSLog(@"mathsolved notification for tips area");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MATH_SOLVED_NOTIFICATION object:nil];
    NSString *solved = notification.object;
    if( [solved isEqualToString:MATH_SOLVED_FLAG]) {
        NSString *restoreString = NSLocalizedStringFromTable(@"RESTORE_PURCHASES", @"InfoPlist", nil);
        if ([self.headerTextBtn titleForState:UIControlStateNormal] == restoreString) {
            [self.purchaseManager restoreCompletedTransactions];
            [self setHeaderHidden:TRUE];
            return;
        }
        if( self.currentHeader != nil && self.currentHeader.hyperlink != nil) {
            if( [self.currentHeader.hyperlink hasPrefix:@"share:"]) {
                [self openSharingDialog:[self.currentHeader.hyperlink substringFromIndex:6]];
            }
            else {
                [[UIApplication sharedApplication]
                 openURL:[NSURL URLWithString:self.currentHeader.hyperlink]];
            }
        }
    }
}

-(void) openSharingDialog: (NSString*) service {
    NSLog(@"Sharing with service %@ others are facebook %@, twitter %@", service, SLServiceTypeFacebook, SLServiceTypeTwitter);
    SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:service];
    [controller setInitialText:@"Kids love learning and playing in ABCD Buddy books app! Get it free from http://www.abcdbuddy.com/go/ios"];
    [controller addURL:[NSURL URLWithString:@"http://www.abcdbuddy.com"]];
    [self presentViewController:controller animated:YES completion:Nil];
}


/* Open book after download is finished */
-(void) downloadComplete {
   // NSLog( @"rootview  downloadComplete");
    /*Requires this. Otherwise renderText throws error - Tried to obtain the web lock from a thread other than the main thread or the web thread. This may be a result of calling to UIKit from a secondary thread. Crashing now...*/
    //Rendering of UI needs to be performed in main thread.
    [self performSelectorOnMainThread:@selector(openBookInSameThread) withObject:nil waitUntilDone:NO];

}

-(void) openBookInSameThread {
    // Added this check to avoid the crash found by Apple team while testing version 1.4 with iOS7.
    // This was reproducible when two thumbnail free buttons were clicked together.
    // It tried to open both books. The first one opened, but the other one threw exception and app crashed.
    if ([self.modelController.book getPagesCount] <= 0) {
        NSLog( @"Found the crash location");
        return;
    }
    self.bookViewController = [[BookViewController alloc] init];
    self.bookViewController.modelController = self.modelController;

    [self presentViewController:self.bookViewController animated:true completion:nil];
}

-(void) populateBooksFeed {
    [backgroundImage image];
    URLCache *urlCache = [[URLCache alloc] init];
    UIImage *urlImage = [urlCache getImage:self.bookShelfData.imageUrl];
    if (urlImage != nil) {
        [self.backgroundImage setImage:urlImage];
    }

    for( int i=0; i<[self.bookShelfData.sections count]; i++) {
        NSMutableArray *thumbnailsArray = [[NSMutableArray alloc] init];
        BRShelfSection *iSection = [self.bookShelfData getSection:i];
        for( int j=0; j<[iSection.bookCards count]; j++) {
            BRBookCard *card = iSection.bookCards[j];
            if([card isMatch:self.searchBox.text]) {
                [thumbnailsArray addObject:card];
            }
        }
        NSString *iKey = [NSString stringWithFormat:@"%d", i];

        if (thumbnailsArray.count > 0) {
            [self.thumbnailCards setObject:thumbnailsArray forKey:iKey];
        }
        
    }
    [self.collectionView reloadData];
}

-(void) purchaseBook : (BRBookCard *) bookCard {
    // When offline mode then product will be nil.
    if(bookCard.product == nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Could not purchase product from App Store."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];

        [alert show];
    }
    else {
        [self.purchaseManager buyProduct:bookCard.product];    
    }
}

-(void) openBook : (NSString *) bookId : (NSString *) bookUrl{
    self.modelController.book = [self.bookShelfData getBook:bookId : bookUrl];
    [self.modelController downloadBook: DOWNLOAD_COMPLETE_NOTIFICATION : @"updateProgress"];
}

- (IBAction)onSearchButtonClick:(id)sender {
    if ([self.searchBox isHidden]) {
        [self.searchBox setHidden:FALSE];
        [self.searchBox becomeFirstResponder];        
    }
    else {
        [self.searchBox setHidden:TRUE];
        [self.searchBox setText:@""];
        [self.searchBox resignFirstResponder];
        [self searchBoxDidChange];
    }
}

- (void)searchBoxDidChange {
    self.thumbnailCards = [[NSMutableDictionary alloc] init];
    [[NSNotificationCenter defaultCenter] postNotificationName:POPULATE_BOOKS_FEED_NOTIFICATION object:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(NSUInteger)supportedInterfaceOrientations{
    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType hasPrefix:@"iPad"]) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    NSString *iKey = [NSString stringWithFormat:@"%d", (int) section];
    NSArray *arr = [self.thumbnailCards objectForKey:iKey];
    return [arr count];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return [self.bookShelfData.sections count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BRBookShelfThumbnailCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"BookCell" forIndexPath:indexPath];
    
    NSString *iKey = [NSString stringWithFormat:@"%d", (int) indexPath.section];
    if( [self.thumbnailCards count] > 0) {
        NSArray *arr = [self.thumbnailCards objectForKey:iKey];
        BRBookCard *card = arr[indexPath.item];
        cell.rootViewController = self;
        [cell setBookCard:card];
    }
    return cell;
}

- (UICollectionReusableView *)collectionView:
 (UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
 {
     UICollectionReusableView *myView =
     [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"sectionHeader" forIndexPath:indexPath];

     UILabel *sectionLabel = myView.subviews[0];
     BRShelfSection *iSection = [self.bookShelfData getSection:(int)indexPath.section];
     [sectionLabel setText:iSection.title];
     return myView;
 }

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Select Item
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Deselect item
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {    
    return UIEdgeInsetsMake(10, 10, 30, 10);
}


@end
