//
//  GameRecord.h
//  Liars Dice
//
//  Created by Miller Tinkerhess on 5/3/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct GameTime {
    int year;
    int month;
    int day;
    int hour;
    int minute;
    int second;
} GameTime;

@interface GameRecord : NSObject <EngineClass> {
    GameTime time;
    int numPlayers;
    int firstPlace;
    int secondPlace;
    int thirdPlace;
    int fourthPlace;
}

@property (readwrite, assign) int numPlayers;
@property (readwrite, assign) int firstPlace;
@property (readwrite, assign) int secondPlace;
@property (readwrite, assign) int thirdPlace;
@property (readwrite, assign) int fourthPlace;
@property (readwrite, assign) GameTime gameTime;

- (id) initWithGameTime:(GameTime)gameTime
             NumPlayers:(int)numPlayers
             firstPlace:(int)firstPlace
            secondPlace:(int)secondPlace
             thirdPlace:(int)thirdPlace
            fourthPlace:(int)fourthPlace;

- (id) initWithDictionary:(NSDictionary*)dictionary;
- (NSDictionary*) dictionaryRepresentation;

+ (NSDictionary*) GameTimeToDictionary:(GameTime)time;
+ (GameTime) DictionaryToGameTime:(NSDictionary*)dictionary;

@end
