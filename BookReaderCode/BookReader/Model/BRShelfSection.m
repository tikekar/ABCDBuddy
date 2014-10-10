//
//  ShelfSection.m
//  BookReader
//
//  Created by Gauri Tikekar on 1/25/13.
//  Copyright (c) 2013 TeddyTab. All rights reserved.
//

#import "BRShelfSection.h"
#import "BRBookCard.h"

@implementation BRShelfSection

-(void) initialize: (id) json {
    self.title = [json objectForKey:@"title"];
    NSArray *bookCardsJson = [json objectForKey:@"books"];

    bookCards = [[NSMutableArray alloc] init];

    for( int i=0; i<[bookCardsJson count]; i++) {
        BRBookCard *bookCard = [BRBookCard alloc];
        [bookCard initialize:bookCardsJson[i]];
        [bookCards addObject:bookCard];
    }

}

-(void) initWithBookCardsAndTitle : (NSMutableArray *) cards : (NSString *) sectionTitle {
    bookCards = [[NSMutableArray alloc] init];

    self.title = sectionTitle;
    bookCards = cards;
}

@end
