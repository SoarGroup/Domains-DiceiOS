//
//  PlayGame.h
//  Liars Dice
//
//  Created by Miller Tinkerhess on 3/29/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PlayerState.h"

@protocol PlayGame <NSObject>
- (void)updateState:(PlayerState*)newState;
- (void)updateUI;
@end
