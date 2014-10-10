//
//  CategoryScore.m
//  BookReader
//
//  Created by Gauri Tikekar on 1/28/13.
//  Copyright (c) 2013 TeddyTab. All rights reserved.
//

#import "BRCategoryScore.h"

@implementation BRCategoryScore

-(void) initWithClassroom: (NSString *) classroomStr : (NSString *) dateStr : (NSString *) categoryStr : (int) attemptsNumber : (int) solvedNumber : (long) timeSpent {
    self.category = categoryStr;
    self.attempts = attemptsNumber;
    self.solved = solvedNumber;
    self.time = timeSpent;
    self.classroom = classroomStr;
    self.date = dateStr;
}

@end
