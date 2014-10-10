//
//  BookCard.h
//  BookReader
//
//  Created by Gauri Tikekar on 1/25/13.
//  Copyright (c) 2013 TeddyTab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface BRBookCard : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *thumbnailUrl;
@property (nonatomic, copy) NSString *price;
@property (nonatomic) SKProduct *product;
@property (nonatomic, copy) NSString *productId;
@property (nonatomic, copy) NSString *author;
@property (nonatomic, copy) NSString *authorUrl;
@property (nonatomic, copy) NSString *bookId;
@property (nonatomic, copy) NSString *bookUrl;
@property (nonatomic, copy) NSString *description;
@property (nonatomic, copy) NSString *longDescription;
@property (nonatomic, copy) NSString *promoLabel;
@property (nonatomic, copy) NSString *bgColorString;
@property (nonatomic, copy) UIColor *bgColor;

-(void) initialize: (id) json;
-(BOOL) isMatch: (NSString *) filter;

-(NSString *) title;
-(NSString * ) thumbnailUrl;
-(NSString *) price;
-(NSString *) productId;
-(SKProduct *) product;
-(NSString * ) author;
-(NSString * ) authorUrl;
-(NSString *) bookId;
-(NSString *) bookUrl;
-(NSString *) description;
-(NSString *) longDescription;
-(NSString *) promoLabel;
-(NSString *) bgColorString;
-(UIColor *) bgColor;

@end
