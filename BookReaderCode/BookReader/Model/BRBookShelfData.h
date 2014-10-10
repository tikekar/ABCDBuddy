//
//  BookShelfData.h
//  TeddyTab
//
//  Created by Gauri Tikekar on 10/23/12.
//  Copyright (c) 2012 Gauri Tikekar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BRBookCard.h"
#import "BRShelfSection.h"
#import "BRPurchasedBooksDB.h"

@interface BRBookShelfData : NSObject

@property (nonatomic, copy) NSMutableDictionary *bookFeedJson;

@property (nonatomic) NSMutableArray *myBookIds;
@property (nonatomic) BRPurchasedBooksDB *purchasedBooksDB;
@property (nonatomic, copy) NSMutableArray *sections;
@property (nonatomic, copy) NSMutableArray *headers;
@property (nonatomic, copy) NSString *imageUrl;

-(void) initialize;

-(id) getBook: (NSString *) bookId : (NSString *) bookUrl;

-(BRBookCard *) getBookCard : (int) bookNumber : (int )section;
-(BRShelfSection *) getSection : (int) section;

-(NSSet*) getProductIds;
-(BOOL) isPurchased : (NSString *) bookId;
-(void) updateBookCards : (NSArray *) products;
-(void) addProductIdsToMyBooks : (NSArray *) productIds;
-(void) addBookIdsToMyBooks : (NSArray *) bookIds;

@end

