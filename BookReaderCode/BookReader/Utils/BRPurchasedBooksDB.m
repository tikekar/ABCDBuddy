//
//  ActivitybookReaderDB.m
//  BookReader
//
//  Created by Gauri Tikekar on 12/12/12.
//  Copyright (c) 2012 TeddyTab. All rights reserved.
//

#import "BRPurchasedBooksDB.h"
#import <sqlite3.h>
#import "BRCategoryScore.h"
#import "BRBookCard.h"

@implementation BRPurchasedBooksDB

-(void) initialize {
    NSString *docsDir;
    NSArray *dirPaths;

    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    docsDir = [dirPaths objectAtIndex:0];

    //Build the path to the database file
    self.databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:@"TeddyTabBookReaderDB.db"]];

    [self createTable];

}

-(void) createTable  {
    const char *dbpath = [self.databasePath UTF8String];

    if( sqlite3_open(dbpath, &bookReaderDB) == SQLITE_OK) {
        char *errMsg;
        const char *sql_stmt =
        "CREATE TABLE IF NOT EXISTS PurchasedBooks ( BOOKID TEXT PRIMARY KEY )";
      
        if( sqlite3_exec(bookReaderDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK) {
            NSLog( @"Failed to create table");
        }
        sqlite3_close(bookReaderDB);
    }
    else {
        NSLog( @"Failed to open/create database");
    }

}

-(void) addRecord : (BRBookCard *) bookCard {

    const char *dbpath = [self.databasePath UTF8String];
    
    char *errMsg;
    if(sqlite3_open(dbpath, &bookReaderDB) == SQLITE_OK) {
        NSString *insertSQL = [NSString stringWithFormat:@"INSERT INTO PurchasedBooks (BOOKID ) VALUES (\"%@\")", bookCard.bookId ];
        const char *insert_stmt = [insertSQL UTF8String];

        if( sqlite3_exec(bookReaderDB, insert_stmt, NULL, NULL, &errMsg) == SQLITE_OK) {
            //worked
            NSLog( @"Record added");
        }
        else {
            NSLog(@"Error: %s", errMsg);

        }
        sqlite3_close(bookReaderDB);
    }
}

-(NSArray *) getBookIds {
	// Setup the database object
    const char *dbpath = [self.databasePath UTF8String];

	// Init the scores Array
	NSMutableArray *bookIds = [[NSMutableArray alloc] init];

	// Open the database from the users filessytem
	if(sqlite3_open(dbpath, &bookReaderDB) == SQLITE_OK) {
		// Setup the SQL Statement and compile it for faster access
		const char *sqlStatement = "select BOOKID from PurchasedBooks";
		sqlite3_stmt *compiledStatement;
        if(sqlite3_prepare_v2(bookReaderDB, sqlStatement, -1, &compiledStatement, nil)==SQLITE_OK){

			// Loop through the results and add them to the feeds array
			while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
				// Read the data from the result row
				NSString *boodId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 0)];
				[bookIds addObject:boodId];
			}
		}
		// Release the compiled statement from memory
		sqlite3_finalize(compiledStatement);

	}
	sqlite3_close(bookReaderDB);
    return bookIds;
    
}

@end
