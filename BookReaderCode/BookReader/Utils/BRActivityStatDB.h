//
//  ActivityStatDB.h
//  BookReader
//
//  Created by Gauri Tikekar on 12/12/12.
//  Copyright (c) 2012 TeddyTab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface BRActivityStatDB : NSObject

@property (nonatomic) sqlite3 *statDB;
@property (strong, nonatomic) NSString *databasePath;


-(NSString *) databasePath;

-(void) initialize;

-(void) removeDB;
-(void) clearScoreData;

-(void) incrementColumn : (NSString *) colName : (NSString *) forClassroom : (NSString*) forCategory;
-(void) addTime : (NSString *) forClassroom : (NSString*) forCategory : (long) timeVal;

-(NSArray *) getScoreCard: (NSString *) classroom;

@end
