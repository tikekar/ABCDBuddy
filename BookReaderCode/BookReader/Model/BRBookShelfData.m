//
//  BookShelfData.m
//  TeddyTab
//
//  Created by Gauri Tikekar on 10/23/12.
//  Copyright (c) 2012 Gauri Tikekar. All rights reserved.
//

#import "BRBookShelfData.h"
#import "AppDelegate.h"
#import "Book.h"
#import "BRShelfSection.h"
#import "BRShelfHeader.h"
#import "BRBookCard.h"
#import "URLCache.h"
#import "BRPurchasedBooksDB.h"

@implementation BRBookShelfData

URLCache *urlCache;

-(void) initialize {
    self.purchasedBooksDB = [BRPurchasedBooksDB alloc];
    [purchasedBooksDB initialize];
    self.myBookIds = [NSMutableArray arrayWithArray:[purchasedBooksDB getBookIds]];

    NSError *e = nil;
    AppDelegate *app = (AppDelegate *) [[UIApplication sharedApplication] delegate];

    NSString *filePath = [NSString stringWithFormat:@"http://www.abcdbuddy.com/home?aspect=%f&language=%@&version=%@", app.aspectRatio, app.language, app.version];

    urlCache = [[URLCache alloc] init];
    NSData *jsonData =[urlCache storeFile:filePath : TRUE];
    if( jsonData == nil) {
        // [self performSelectorOnMainThread:@selector(connectionSlowAlert) withObject:nil waitUntilDone:YES];
        [self connectionSlowAlert];
        return;
    }
    self.bookFeedJson = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&e];

    self.imageUrl = [self.bookFeedJson objectForKey:@"imageUrl"];
    
    sections = [[NSMutableArray alloc] init];       
   
    NSMutableArray *sectionJson = [self.bookFeedJson objectForKey:@"sections"];
    for( int i=0; i<[sectionJson count]; i++) {
        BRShelfSection *shelfSection = [BRShelfSection alloc];
        [shelfSection initialize:sectionJson[i]];
        [sections addObject:shelfSection];
    }

    headers = [[NSMutableArray alloc] init];

    NSMutableArray *headerJson = [self.bookFeedJson objectForKey:@"headers"];
    for( int i=0; i<[headerJson count]; i++) {
        BRShelfHeader *shelfHeader = [BRShelfHeader alloc];
        [shelfHeader initialize:headerJson[i]];
        [headers addObject:shelfHeader];
    }

    NSMutableArray *myBookCards = [[NSMutableArray alloc] init];
    for( int i=0; i<[self.myBookIds count]; i++) {
        BRBookCard *card = [self getBookCardByBookId:self.myBookIds[i]];
        if (card != nil) {
            [myBookCards addObject:card];
        }
    }

    //if initially no purchased books in mybooks list, then do not show the empty my books section
    if ([myBookCards count] > 0 ) {
        BRShelfSection *myshelfSection = [BRShelfSection alloc];
        [myshelfSection initWithBookCardsAndTitle:myBookCards :@"MY BOOKS"];
        [sections insertObject:myshelfSection atIndex:0];
    }
}

-(void) addProductIdsToMyBooks : (NSArray *) productIds {
    NSMutableArray *myBookCards = [[NSMutableArray alloc] init];
    for(int i=0; i<[productIds count]; i++) {
        BRBookCard *card = [self getBookCardByProductId:productIds[i]];
        if(card == nil) {
            continue;
        }
        else if(self.myBookIds != nil && [self.myBookIds containsObject:card.bookId]) {
            continue;
        }
        if([ self.myBookIds count] == 0 ) {
            BRShelfSection *myshelfSection = [BRShelfSection alloc];
            if (card != nil) {
                [myBookCards addObject:card];
            }
            [myshelfSection initWithBookCardsAndTitle:myBookCards :@"MY BOOKS"];
            [self.sections insertObject:myshelfSection atIndex:0];
        }
        else {
            BRShelfSection *myshelfSection = [self getSection:0];
            [myshelfSection.bookCards addObject:card];
        }

        [self.myBookIds addObject:card.bookId];        
        [self.purchasedBooksDB addRecord:card];
    }    
}

-(void) addBookIdsToMyBooks : (NSArray *) bookIds {
    NSMutableArray *myBookCards = [[NSMutableArray alloc] init];
    for(int i=0; i<[bookIds count]; i++) {
        BRBookCard *card = [self getBookCardByBookId:bookIds[i]];
        if(card == nil) {
            continue;
        }
        else if(self.myBookIds != nil && [self.myBookIds containsObject:card.bookId]) {
            continue;
        }
        if([ self.myBookIds count] == 0 ) {
            BRShelfSection *myshelfSection = [BRShelfSection alloc];
            if (card != nil) {
                [myBookCards addObject:card];
            }
            [myshelfSection initWithBookCardsAndTitle:myBookCards :@"MY BOOKS"];
            [self.sections insertObject:myshelfSection atIndex:0];
        }
        else {
            BRShelfSection *myshelfSection = [self getSection:0];
            [myshelfSection.bookCards addObject:card];
        }

        [self.myBookIds addObject:card.bookId];
        [self.purchasedBooksDB addRecord:card];
    }
}


-(void) updateBookCards : (NSArray *) products {
    for (SKProduct * skProduct in products) {
        BRBookCard *card = [self getBookCardByProductId:skProduct.productIdentifier];
        if (card != nil) {
            card.price = skProduct.price.stringValue;
            card.product = skProduct;
        }
    }
}

-(void) connectionSlowAlert {
    NSString *message = @"Network not available";

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];

}

-(BRBookCard *) getBookCard : (int) bookNumber : (int )section {
    BRShelfSection *shelfSection = self.sections[section];
    return shelfSection.bookCards[bookNumber];
}

-(BRBookCard *) getBookCardByBookId : (NSString *) bookId {
    for( int i=0; i<[self.sections count]; i++) {
        BRShelfSection *shelfSection = self.sections[i];
        NSArray *bookCards = shelfSection.bookCards;
        for( int j=0; j<[bookCards count]; j++) {
            BRBookCard *card = bookCards[j];
            if( [card.bookId isEqualToString:bookId]) {
                return card;
            }
        }
    }
    return nil;
}

-(BRBookCard *) getBookCardByProductId : (NSString *) productId {
    for( int i=0; i<[self.sections count]; i++) {
        BRShelfSection *shelfSection = self.sections[i];
        NSArray *bookCards = shelfSection.bookCards;
        for( int j=0; j<[bookCards count]; j++) {
            BRBookCard *card = bookCards[j];
            if( [card.productId isEqualToString:productId]) {
                return card;
            }
        }
    }
    return nil;
}


-(BRShelfSection *) getSection : (int) section {
    BRShelfSection *shelfSection = self.sections[section];
    return shelfSection;
}

-(id) getBook: (NSString *) bookId : (NSString *) bookUrl {
    Book *book = [[Book alloc] init];
    [book initialize : bookId : bookUrl];
    return book;
}

-(BOOL) isPurchased : (NSString *) bookId {
    for( int i=0; i<[self.myBookIds count]; i++) {        
        NSString *iBookId = self.myBookIds[i];
        if( [iBookId isEqualToString:bookId]) {
            return true;
        }
    }
    return false;
}

-(NSSet*) getProductIds {
    NSMutableSet *productIds = [[NSMutableSet alloc] init];
    for (int i=0; i < [self.sections count]; i++) {
        BRShelfSection *shelfSection = self.sections[i];
        NSArray *bookCards = shelfSection.bookCards;
        for (int j=0; j<[bookCards count]; j++) {
            BRBookCard *card = bookCards[j];
            if (card.productId != nil) {
                [productIds addObject:card.productId];
            }
        }
    }
    return productIds;
}

@end
