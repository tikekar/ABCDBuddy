//
//  ShelfHeader.m
//  ABCD Buddy
//
//  Created by Gauri Tikekar on 8/28/13.
//
//

#import "BRShelfHeader.h"
#import "Utility.h"

@implementation BRShelfHeader

-(void) initialize: (id) json {
    self.imageUrl = [json objectForKey:@"imageurl"];
    self.headerText = [json objectForKey:@"text"];
    self.hyperlink = [json objectForKey:@"hyperlink"];
    self.frequency = [json objectForKey:@"frequency"];

}

-(BOOL) isFrequencyInRange: (int) frequencyNumber {
    int minFrequency = [Utility getMinNumber:self.frequency];
    int maxFrequency = [Utility getMaxNumber:self.frequency];

    if( frequencyNumber >= minFrequency && frequencyNumber <= maxFrequency )
    {
        return TRUE;
    }
    return FALSE;

}

@end
