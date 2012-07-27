//
//  DiceSoarPlayer.m
//  Lair's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DiceSoarPlayer.h"

@implementation DiceSoarPlayer

@synthesize name;

- (id)initWithName:(NSString *)aName
{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.name = aName;
    }
    
    return self;
}

-(NSString*) getName {
    return self.name;
}

-(void)updateState:(PlayerState*)state {
    // TODO implement
}

-(int)getID {
    return playerID;
}

-(void)setID:(int)anID {
    playerID = anID;
}

- (void) itsYourTurn {
    // TODO implement
}

@end
