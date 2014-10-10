//
//  ActivityStatDB.m
//  BookReader
//
//  Created by Gauri Tikekar on 12/12/12.
//  Copyright (c) 2012 TeddyTab. All rights reserved.
//

#import "BRActivityStatDB.h"
#import <sqlite3.h>
#import "BRCategoryScore.h"
#import "Utility.h"

@implementation BRActivityStatDB

-(void) initialize {
    NSString *docsDir;
    NSArray *dirPaths;

    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    docsDir = [dirPaths objectAtIndex:0];

    //Build the path to the database file
    self.databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:@"TeddyTabBookReaderDB.db"]];


    const char *dbpath = [databasePath UTF8String];

    if( sqlite3_open(dbpath, &statDB) == SQLITE_OK) {
        char *errMsg;
        const char *sql_stmt =
        //"CREATE TABLE IF NOT EXISTS BookReaderStat ( CATEGORY TEXT PRIMARY KEY, ATTEMPTS TEXT, SOLVED TEXT, TIME TEXT)";
        "CREATE TABLE IF NOT EXISTS BookReaderStat ( CLASSROOM TEXT, DATE TEXT, CATEGORY TEXT, ATTEMPTS TEXT, SOLVED TEXT, TIME TEXT)";

        if( sqlite3_exec(statDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK) {
            NSLog( @"Failed to create table");
        }
        if( ![self checkColumnExists:@"CLASSROOM"]) {
            [self alterBookReaderStat];
        }
        sqlite3_close(statDB);
    }
    else {
        NSLog( @"Failed to open/create database");
    }

}

/* for existing apps, add columns classrom and date. We need to also remove the primary key on the column category.
 But sqlite alter table command syntax does not allow to drop columns or column constraints. So in order to do that,
 needed to implement this hack. 
 1. First get all records from BookReaderStat table.
 2. Create a new table BookReaderStat_temp.
 3. Copy all existing records in the temp table.
 4. Remove the existing BookReaderStat table.
 5. Rename the new temp table to BookReaderStat table.
 */
-(void) alterBookReaderStat {
    const char *dbpath = [self.databasePath UTF8String];
    // 1. First get all records from BookReaderStat table.
    NSArray *scores = [[NSMutableArray alloc] initWithArray:[self getOldTableScoreCard]];
    if( sqlite3_open(dbpath, &statDB) == SQLITE_OK) {
        char *errMsg;
        //2. Create a new table BookReaderStat_temp.
        const char *sql_stmt =
        "CREATE TABLE IF NOT EXISTS BookReaderStat_temp ( CLASSROOM TEXT, DATE TEXT, CATEGORY TEXT, ATTEMPTS TEXT, SOLVED TEXT, TIME TEXT)";

        if( sqlite3_exec(statDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK) {
            NSLog( @"Failed to create temp table");
        }
        else {
            //3. Copy all existing records in the temp table.
            for( int i=0; i < [scores count]; i++) {
                BRCategoryScore *score = scores[i];
                [self addRecord:@"BookReaderStat_temp":score.classroom: score.date: score.category :[NSString stringWithFormat:@"%d",score.attempts]
                               :[NSString stringWithFormat:@"%d",score.solved]
                               :[NSString stringWithFormat:@"%ld",score.time]];
            }
        }

        if( sqlite3_open(dbpath, &statDB) == SQLITE_OK) {
            //4. Remove the existing BookReaderStat table.
            const char *droptable_stmt =
            "DROP TABLE IF EXISTS BookReaderStat";

            if( sqlite3_exec(statDB, droptable_stmt, NULL, NULL, &errMsg) !=  SQLITE_OK) {
               // NSLog( @"Failed to drop table");
                NSLog(@"Error: %s", errMsg);
            }

            //5. Rename the new temp table to BookReaderStat table.

            const char *renametable_stmt =
            "ALTER TABLE BookReaderStat_temp RENAME TO BookReaderStat";

            if( sqlite3_exec(statDB, renametable_stmt, NULL, NULL, &errMsg) != SQLITE_OK) {
               // NSLog( @"Failed to rename table");
                NSLog(@"Error: %s", errMsg);
            }

            sqlite3_close(statDB);
        }
    }

}


-(BOOL)checkColumnExists:(NSString *) columnName
{
    const char *sql = "PRAGMA table_info(BookReaderStat)";
    sqlite3_stmt *stmt;

    if (sqlite3_prepare_v2(statDB, sql, -1, &stmt, NULL) != SQLITE_OK)
    {
        return NO;
    }

    while(sqlite3_step(stmt) == SQLITE_ROW)
    {

        NSString *fieldName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmt, 1)];
        if([columnName isEqualToString:fieldName])
            return YES;
    }
    
    return NO;
}

-(void) incrementColumn : (NSString *) colName : (NSString *) forClassroom : (NSString*) forCategory {
    
    sqlite3_stmt *st;
    const char *dbpath = [self.databasePath UTF8String];
    NSString *colValue = @"0";

    NSString *forDate = [Utility getDate:@"YYYY-MM-dd"];

    if(sqlite3_open(dbpath, &statDB) == SQLITE_OK) {

        const char *select_stmt = [[NSString stringWithFormat:@"select %@ from BookReaderStat where CLASSROOM = \"%@\" and DATE = \"%@\" and CATEGORY = \"%@\"", colName, forClassroom, forDate, forCategory] UTF8String];

        int count = 0;
        if(sqlite3_prepare_v2(statDB, select_stmt, -1, &st, nil)==SQLITE_OK){

        if( sqlite3_step(st) == SQLITE_ROW)
        {
            if (sqlite3_column_text(st, 0) != NULL)
            {
                colValue = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text( st, 0)];
                count = 1;
            }
                                
        }
            
        }
        if( count == 0) {
            [self addRecord:@"BookReaderStat":@"abcdbuddy" : forDate: forCategory:@"0" :@"0" :@"0.0"];
            [self incrementColumn:colName :forClassroom :forCategory];
        }
        else {
            int colValInt = [colValue intValue];
            colValInt = colValInt + 1;
            colValue = [NSString stringWithFormat:@"%d",colValInt];
              char *errMsg;
            NSString *updateSQL = [NSString stringWithFormat: @"UPDATE BookReaderStat SET %@ = \"%@\" WHERE  CLASSROOM = \"%@\" and DATE = \"%@\" and CATEGORY = \"%@\"", colName, colValue, forClassroom, forDate, forCategory];
            const char *update_stmt = [updateSQL UTF8String];
            if( sqlite3_exec(statDB, update_stmt, NULL, NULL, &errMsg) == SQLITE_OK) {
                //worked
               //NSLog( @"Record updated");
            }
            else {
                NSLog(@"Update failed: %s", errMsg);

            }
        }
        sqlite3_finalize(st);
        sqlite3_close(statDB);
    }
}

-(void) addTime : (NSString *) forClassroom : (NSString*) forCategory : (long) timeVal{

    sqlite3_stmt *st;
    const char *dbpath = [self.databasePath UTF8String];
    NSString *colValue = @"0";

    NSString *forDate = [Utility getDate:@"YYYY-MM-DD"];

    if(sqlite3_open(dbpath, &statDB) == SQLITE_OK) {

        const char *select_stmt = [[NSString stringWithFormat:@"select TIME from BookReaderStat where CLASSROOM = \"%@\" and DATE = \"%@\" and CATEGORY = \"%@\"", forClassroom, forDate, forCategory] UTF8String];

        int count = 0;
        if(sqlite3_prepare_v2(statDB, select_stmt, -1, &st, nil)==SQLITE_OK){

            if( sqlite3_step(st) == SQLITE_ROW)
            {
                if (sqlite3_column_text(st, 0) != NULL)
                {
                    colValue = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text( st, 0)];
                    count = 1;                 
                }

            }

        }
        if( count == 0) {
            [self addRecord:@"BookReaderStat" :@"abcdbuddy" : forDate : forCategory :@"0" :@"0" :@"0.0"];
            [self addTime:forClassroom: forCategory :timeVal];
        }
        else {
            colValue = [NSString stringWithFormat:@"%ld", [colValue intValue] + timeVal];
            char *errMsg;
            NSString *updateSQL = [NSString stringWithFormat: @"UPDATE BookReaderStat SET TIME = \"%@\" WHERE CLASSROOM = \"%@\" and DATE = \"%@\" and CATEGORY = \"%@\"", colValue, forClassroom, forDate, forCategory];
            const char *update_stmt = [updateSQL UTF8String];
            if( sqlite3_exec(statDB, update_stmt, NULL, NULL, &errMsg) == SQLITE_OK) {
                //worked
                //NSLog( @"Record updated");
            }
            else {
                NSLog(@"Update failed: %s", errMsg);

            }
        }

        sqlite3_finalize(st);
        sqlite3_close(statDB);
    }
}


-(void) addRecord : (NSString *) tableName : (NSString *) classroom : (NSString *) date :(NSString*) category : (NSString *) attempts : (NSString *)solved : (NSString *) time {
   
    const char *dbpath = [self.databasePath UTF8String];
    char *errMsg;
    if([classroom isEqualToString:@""]) {
        classroom = @"abcdbuddy";
    }

    if([date isEqualToString:@""]) {
        date = [Utility getDate:@"YYYY-MM-dd"];
    }

    if(sqlite3_open(dbpath, &statDB) == SQLITE_OK) {
        NSString *insertSQL = [NSString stringWithFormat:@"INSERT INTO \"%@\" (CLASSROOM, DATE, CATEGORY, ATTEMPTS, SOLVED, TIME) VALUES (\"%@\",\"%@\",\"%@\",\"%@\", \"%@\", \"%@\")", tableName, classroom, date, category, attempts, solved, time];
        const char *insert_stmt = [insertSQL UTF8String];
        
        if( sqlite3_exec(statDB, insert_stmt, NULL, NULL, &errMsg) == SQLITE_OK) {
                //worked
            NSLog( @"Record added");
        }
        else {
            NSLog(@"Error: %s", errMsg);

        }
        sqlite3_close(statDB);
    }
}

-(void) clearScoreData {
    const char *dbpath = [self.databasePath UTF8String];
    NSString *query = @"delete from BookReaderStat";
    const char *sqlStatement = [query UTF8String];
    sqlite3_stmt *compiledStatement;
    if(sqlite3_open(dbpath, &statDB) == SQLITE_OK) {
        if(sqlite3_prepare_v2(statDB, sqlStatement, -1, &compiledStatement, NULL) == SQLITE_OK) {
            // Loop through the results and add them to the feeds array
            while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
            // Read the data from the result row
                NSLog(@"result is here");
            }

            // Release the compiled statement from memory
            sqlite3_finalize(compiledStatement);
        }
        sqlite3_close(statDB);
    }
}

-(NSArray *) getScoreCard : (NSString *) classroom{
	// Setup the database object
    const char *dbpath = [self.databasePath UTF8String];

	// Init the scores Array
	NSMutableArray *scores = [[NSMutableArray alloc] init];

	// Open the database from the users filessytem
	if(sqlite3_open(dbpath, &statDB) == SQLITE_OK) {
		// Setup the SQL Statement and compile it for faster access
		const char *sqlStatement = [[NSString stringWithFormat:@"select  CLASSROOM, DATE, CATEGORY, ATTEMPTS, SOLVED, TIME from BookReaderStat where CLASSROOM = \"%@\"", classroom] UTF8String];
        //const char *sqlStatement = "select * from BookReaderStat";

		sqlite3_stmt *compiledStatement;
        if(sqlite3_prepare_v2(statDB, sqlStatement, -1, &compiledStatement, nil)==SQLITE_OK){

			// Loop through the results and add them to the feeds array
			while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
				// Read the data from the result row
            NSString *classroom = sqlite3_column_text(compiledStatement, 0)==nil?@"":[NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 0)];
                NSString *date = sqlite3_column_text(compiledStatement, 1)==nil?@"":[NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];
				NSString *category = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 2)];

				NSString *attempts = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 3)];
				NSString *solved = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 4)];
                NSString *time = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 5)];

                BRCategoryScore *score = [[BRCategoryScore alloc] init];
                [score initWithClassroom:classroom:date:category:[attempts intValue]:[solved intValue]:[time longLongValue]];
				[scores addObject:score];

				
			}
		}
		// Release the compiled statement from memory
		sqlite3_finalize(compiledStatement);
        
	}
	sqlite3_close(statDB);
    return scores;
    
}

// This is temporarily needed for accessing records from old BookReaderStat table without classroom and date
-(NSArray *) getOldTableScoreCard {
	// Setup the database object
    const char *dbpath = [self.databasePath UTF8String];

	// Init the scores Array
	NSMutableArray *scores = [[NSMutableArray alloc] init];

	// Open the database from the users filessytem
	if(sqlite3_open(dbpath, &statDB) == SQLITE_OK) {
		// Setup the SQL Statement and compile it for faster access
		const char *sqlStatement = "select CATEGORY, ATTEMPTS, SOLVED, TIME from BookReaderStat";
		sqlite3_stmt *compiledStatement;
        if(sqlite3_prepare_v2(statDB, sqlStatement, -1, &compiledStatement, nil)==SQLITE_OK){

			// Loop through the results and add them to the feeds array
			while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
				// Read the data from the result row
                NSString *classroom = @"abcdbuddy";
				NSString *category = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 0)];
                NSString *date = [Utility getDate:@"YYYY-MM-dd"];
				NSString *attempts = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];
				NSString *solved = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 2)];
                NSString *time = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 3)];

                BRCategoryScore *score = [[BRCategoryScore alloc] init];
                [score initWithClassroom:classroom:date:category:[attempts intValue]:[solved intValue]:[time longLongValue]];
				[scores addObject:score];


			}
		}
		// Release the compiled statement from memory
		sqlite3_finalize(compiledStatement);

	}
	sqlite3_close(statDB);
    return scores;
    
}

-(void) removeDB {
    NSString *docsDir;
    NSArray *dirPaths;
    NSError *error;
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    docsDir = [dirPaths objectAtIndex:0];

    //Build the path to the database file
    databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:@"TeddyTabBookReaderDB.db"]];
    NSFileManager *filemgr = [NSFileManager defaultManager];
    if( [filemgr fileExistsAtPath:databasePath] == YES) {
        //const char *dbpath = [databasePath UTF8String];
        [filemgr removeItemAtPath:databasePath error:&error];
    }
}

@end
