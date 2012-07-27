//
//  Die.h
//  iSoar
//
//  Created by Alex on 6/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NUMBER_OF_SIDES 6

@interface Die : NSObject {
@private
    int dieValue;
    BOOL hasBeenPushed;
    BOOL markedToPush;
}

@property (readonly) int dieValue;
@property (readonly) BOOL hasBeenPushed;
@property (readwrite, assign) BOOL markedToPush;

- (id)init;
- (id)initWithNumber:(int)dieValue;
- (void)roll;
- (void)push;

- (NSString *)asString;

+ (int)getNumberOfDiceSides;

- (BOOL) isEqual:(Die *)die;

@end
