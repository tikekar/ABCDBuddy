//
//  PurchasedBooksDB.h
//  BookReader
//
//  Created by Gauri Tikekar on 1/31/13.
//  Copyright (c) 2013 TeddyTab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "BRBookCard.h"

@interface BRPurchasedBooksDB : NSObject

@property (nonatomic) sqlite3 *bookReaderDB;
@property (strong, nonatomic) NSString *databasePath;

-(NSString *) databasePath;

-(void) initialize;
-(NSArray *) getBookIds;
-(void) addRecord : (BRBookCard *) bookCard;
@end
