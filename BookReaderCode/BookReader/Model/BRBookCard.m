//
//  BookCard.m
//  BookReader
//
//  Created by Gauri Tikekar on 1/25/13.
//  Copyright (c) 2013 TeddyTab. All rights reserved.
//

#import "BRBookCard.h"
#import "AppDelegate.h"

@implementation BRBookCard

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

-(void) initialize: (id) json {

    self.title = [json objectForKey:@"title"];
    self.author = [json objectForKey:@"author"];

    self.authorUrl = [json objectForKey:@"authorUrl"] != nil ? [json objectForKey:@"authorUrl"] : @"";

    self.price = [json objectForKey:@"price"];
    if (self.price == nil) {
        self.price = @"0";
    }
    self.thumbnailUrl = [json objectForKey:@"tbUrl"];
    self.bookId = [json objectForKey:@"id"];

    AppDelegate *app = (AppDelegate *) [[UIApplication sharedApplication] delegate];

    if (app.aspectRatio < 1.5) {
        if( [json objectForKey:@"url"] != nil) {
            self.bookUrl = [json objectForKey:@"url"];
        }
    }
    else {
        if( [json objectForKey:@"urlWide"] != nil) {
            self.bookUrl = [json objectForKey:@"urlWide"];
        } else if( [json objectForKey:@"url"] != nil) {
            self.bookUrl = [json objectForKey:@"url"];
        }
    }

    self.productId = [json objectForKey:@"productId"];
    self.description = [json objectForKey:@"description"];
    
    self.longDescription = @"";
    if( [json objectForKey:@"longDescription"] != nil ){
        self.longDescription = [json objectForKey:@"longDescription"];
    }
    self.promoLabel = @"";
    if( [json objectForKey:@"promoLabel"] != nil ){
        self.promoLabel = [json objectForKey:@"promoLabel"];
    }

    NSString *colorStr = [json objectForKey:@"color"];

    if( colorStr != nil ) {
        bgColorString = colorStr;
        NSScanner *scanner = [NSScanner scannerWithString:colorStr];
        unsigned hex;
        [scanner scanHexInt:&hex];
        bgColor = UIColorFromRGB(hex);
    }
    else {
        bgColor = [UIColor whiteColor];
        bgColorString = @"FFFFFF";
    }

}

-(BOOL) isMatch: (NSString *) originalFilter {
    if (originalFilter == nil || [originalFilter isEqualToString:@""]) {
        return TRUE;
    }
    NSString* filter = [originalFilter stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([self.title rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound ||
        [self.description rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound ||
        [self.longDescription rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound ||
        [self.author rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound ||
        [self.promoLabel rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound ||
        [self.bookId rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound) {
        return TRUE;
    }
    return FALSE;
}

@end
