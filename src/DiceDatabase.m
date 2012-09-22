//
//  DiceDatabase.m
//  Liars Dice
//
//  Created by Miller Tinkerhess on 5/3/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DiceDatabase.h"
#import <sqlite3.h>

// See http://dblog.com.au/iphone-development-tutorials/iphone-sdk-tutorial-reading-data-from-a-sqlite-database/

static NSString *databaseName() {
    return @"database.db";
}

static NSString *databasePath() {
	NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDir = [documentPaths objectAtIndex:0];
    return [documentsDir stringByAppendingPathComponent:databaseName()];
}

static void checkAndCreateDatabase() {
    // Check if the SQL database has already been saved to the users phone, if not then copy it over
	BOOL success;
    
	// Create a FileManager object, we will use this to check the status
	// of the database and to copy it over if required
	NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *dbPath = databasePath();
    
	// Check if the database has already been created in the users filesystem
	success = [fileManager fileExistsAtPath:dbPath];
    
	// If the database already exists then return without doing anything
	if(success) return;
    
	// If not then proceed to copy the database from the application to the users filesystem
    
	// Get the path to the database in the application package
    NSString *databaseAppPath = [[NSBundle mainBundle] pathForResource:@"database" ofType:@"db"];
    
	// Copy the database from the package to the users filesystem
	[fileManager copyItemAtPath:databaseAppPath toPath:dbPath error:nil];
    
	[fileManager release];
}

@implementation DiceDatabase

- (id)init
{
    self = [super init];
    if (self) {
        checkAndCreateDatabase();
    }
    return self;
}

+ (GameTime) getCurrentGameTime {
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    
    [dateFormatter setDateFormat:@"yyyy"];
    int year = [[dateFormatter stringFromDate:date] intValue];
    
    [dateFormatter setDateFormat:@"MM"];
    int month = [[dateFormatter stringFromDate:date] intValue];
    
    [dateFormatter setDateFormat:@"dd"];
    int day = [[dateFormatter stringFromDate:date] intValue];
    
    [dateFormatter setDateFormat:@"HH"];
    int hour = [[dateFormatter stringFromDate: date] intValue];
    
    [dateFormatter setDateFormat:@"mm"];
    int minute = [[dateFormatter stringFromDate:date] intValue];
    
    [dateFormatter setDateFormat:@"ss"];
    int second = [[dateFormatter stringFromDate:date] intValue];
    
    GameTime game_time = {
        year, month, day, hour, minute, second
    };
    return game_time;
}

void executeSql(const char *sqlStatement) {
    // Setup the database object
	sqlite3 *database;
    
	// Open the database from the users filessytem
	if(sqlite3_open([databasePath() UTF8String], &database) == SQLITE_OK) {
		// Setup the SQL Statement and compile it for faster access
        int error = sqlite3_exec(database, sqlStatement, NULL, NULL, NULL);
        if (error) {
            NSLog(@"Error with sql statement: %d", error);
        }
    }
}

- (void) addGameRecord:(GameRecord *)gameRecord {
    executeSql([[NSString stringWithFormat:@"insert into games (num_players, first_place, second_place, third_place, fourth_place, year, month, day, hour, minute, second) values (%d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d);",
                                     gameRecord.numPlayers,
                                     gameRecord.firstPlace,
                                     gameRecord.secondPlace,
                                     gameRecord.thirdPlace,
                                     gameRecord.fourthPlace,
                                     gameRecord.gameTime.year,
                                     gameRecord.gameTime.month,
                                     gameRecord.gameTime.day,
                                     gameRecord.gameTime.hour,
                                     gameRecord.gameTime.minute,
                 gameRecord.gameTime.second] UTF8String]);
}

- (void) reset {
    executeSql("delete from games;");
}

- (NSArray *) getGameRecords {
    // Setup the database object
	sqlite3 *database;
    
	// Init the animals Array
	NSMutableArray *games = [[[NSMutableArray alloc] init] autorelease];
    
	// Open the database from the users filessytem
	if(sqlite3_open([databasePath() UTF8String], &database) == SQLITE_OK) {
		// Setup the SQL Statement and compile it for faster access
		const char *sqlStatement = "select * from games";
		sqlite3_stmt *compiledStatement;
		int error = sqlite3_prepare_v2(database, sqlStatement, -1, &compiledStatement, NULL);
        if (error == SQLITE_OK) {
			// Loop through the results and add them to the feeds array
			while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
				// Read the data from the result row
                int num_players = sqlite3_column_int(compiledStatement, 1);
                int first_place = sqlite3_column_int(compiledStatement, 2);
                int second_place = sqlite3_column_int(compiledStatement, 3);
                int third_place = sqlite3_column_int(compiledStatement, 4);
                int fourth_place = sqlite3_column_int(compiledStatement, 5);
                int year = sqlite3_column_int(compiledStatement, 6);
                int month = sqlite3_column_int(compiledStatement, 7);
                int day = sqlite3_column_int(compiledStatement, 8);
                int hour = sqlite3_column_int(compiledStatement, 9);
                int minute = sqlite3_column_int(compiledStatement, 10);
                int second = sqlite3_column_int(compiledStatement, 11);
                
                GameTime time = {
                    year,
                    month,
                    day,
                    hour,
                    minute,
                    second
                };
                
                GameRecord *game = [[[GameRecord alloc]
                                     initWithGameTime:time
                                     NumPlayers:num_players
                                     firstPlace:first_place
                                     secondPlace:second_place
                                     thirdPlace:third_place
                                     fourthPlace:fourth_place] autorelease];
                
				// Add the animal object to the animals Array
				[games addObject:game];
			}
		} else {
            NSLog(@"SQL read error %d", error);
        }
		// Release the compiled statement from memory
		sqlite3_finalize(compiledStatement);
        
	}
	sqlite3_close(database);
    return [NSArray arrayWithArray:games];
}

- (void) setPlayerName:(NSString *)playerName
{
	int difficulty = [self getDifficulty];
	
	executeSql("delete from settings;");
	
	executeSql([[NSString stringWithFormat:@"insert into settings (player_name, difficulty) values ('%@', %i);", playerName, difficulty] UTF8String]);
}

- (NSString *) getPlayerName
{
	// Setup the database object
	sqlite3 *database;
    
	// Init the animals Array
	NSString* playerName = nil;
    
	// Open the database from the users filessytem
	if(sqlite3_open([databasePath() UTF8String], &database) == SQLITE_OK) {
		// Setup the SQL Statement and compile it for faster access
		const char *sqlStatement = "select player_name from settings";
		sqlite3_stmt *compiledStatement;
		int error = sqlite3_prepare_v2(database, sqlStatement, -1, &compiledStatement, NULL);
        if (error == SQLITE_OK) {
			// Loop through the results and add them to the feeds array
			while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
				// Read the data from the result row
                const unsigned char* nameOfThePlayer = sqlite3_column_text(compiledStatement, 0);
                
				playerName = [[NSString alloc] initWithBytes:nameOfThePlayer length:strlen((const char*)nameOfThePlayer) encoding:NSASCIIStringEncoding];
			}
		} else {
            NSLog(@"SQL read error %d", error);
        }
		// Release the compiled statement from memory
		sqlite3_finalize(compiledStatement);
	}
	
	sqlite3_close(database);
    return playerName;
}

- (void) setDifficulty:(int)difficulty
{
	NSString* name = [self getPlayerName];
	
	if (name == nil)
		name = @"Player";
	
	executeSql("delete from settings;");
	
	executeSql([[NSString stringWithFormat:@"insert into settings (player_name, difficulty) values ('%@', %i);", name, difficulty] UTF8String]);
}

- (int) getDifficulty
{
	// Setup the database object
	sqlite3 *database;
    
	// Init the animals Array
	int difficulty = 0;
    
	// Open the database from the users filessytem
	if(sqlite3_open([databasePath() UTF8String], &database) == SQLITE_OK) {
		// Setup the SQL Statement and compile it for faster access
		const char *sqlStatement = "select difficulty from settings";
		sqlite3_stmt *compiledStatement;
		int error = sqlite3_prepare_v2(database, sqlStatement, -1, &compiledStatement, NULL);
        if (error == SQLITE_OK) {
			// Loop through the results and add them to the feeds array
			while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
				// Read the data from the result row
                difficulty = sqlite3_column_int(compiledStatement, 0);
			}
		} else {
            NSLog(@"SQL read error %d", error);
        }
		// Release the compiled statement from memory
		sqlite3_finalize(compiledStatement);
	}
	
	sqlite3_close(database);
	
    return difficulty;
}

@end
