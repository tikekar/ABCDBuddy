//
//  CategoryScore.h
//  BookReader
//
//  Created by Gauri Tikekar on 1/28/13.
//  Copyright (c) 2013 TeddyTab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BRCategoryScore : NSObject

@property (nonatomic) NSString *classroom;
@property (nonatomic) NSString *category;
@property (nonatomic) NSString *date;
@property (nonatomic) int attempts;
@property (nonatomic) int solved;
@property (nonatomic) long time;

-(void) initWithClassroom: (NSString *) classroomStr : (NSString *) dateStr : (NSString *) categoryStr : (int) attemptsNumber : (int) solvedNumber : (long) timeSpent;

@end
