//
//  JoinGameView.h
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DiceGame;

@interface JoinGameView : UIViewController {
    DiceGame *game;
}

- (id)initWithGame:(DiceGame*)aGame;

@property (readwrite, retain) DiceGame *game;
- (IBAction)backPressed:(id)sender;

@end
