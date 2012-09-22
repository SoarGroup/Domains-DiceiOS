//
//  Player.h
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/5/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PlayerState;

@protocol Player <NSObject>
- (NSString*) getName;
- (void) updateState:(PlayerState*)state;
- (int) getID;
- (void) setID:(int)anID;
- (void) itsYourTurn;
- (void) end;
@end
