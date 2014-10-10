//
//  ShelfHeader.h
//  ABCD Buddy
//
//  Created by Gauri Tikekar on 8/28/13.
//
//

#import <Foundation/Foundation.h>

@interface BRShelfHeader : NSObject

@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, copy) NSString *headerText;
@property (nonatomic, copy) NSString *hyperlink;
@property (nonatomic, copy) NSString *frequency;

-(void) initialize: (id) json;
-(BOOL) isFrequencyInRange : (int) frequencyNumber;

-(NSString *) imageUrl;
-(NSString *) headerText;
-(NSString *) hyperlink;
-(NSString *) frequency;

@end
