//
//  ShelfSection.h
//  BookReader
//
//  Created by Gauri Tikekar on 1/25/13.
//  Copyright (c) 2013 TeddyTab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BRShelfSection : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSMutableArray *bookCards;

-(void) initialize: (id) json;

-(void) initWithBookCardsAndTitle : (NSMutableArray *) cards : (NSString *) sectionTitle;

-(NSString *) title;
-(NSMutableArray *) bookCards;

@end
