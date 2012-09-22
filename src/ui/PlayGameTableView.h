//
//  PlayGameView.h
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/5/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PlayGame.h"

@class DiceGame;
@class PlayerState;
@class DicePeekView;

typedef struct ControlButtons {
    UIButton *bidButton;
    UIButton *bidCountButton;
    UIButton *bidFaceButton;
    UIButton *passButton;
    UIButton *exactButton;
} ControlButtons;

@interface PlayGameTableView : UITableViewController <PlayGame, UITableViewDataSource, UITableViewDelegate> {
    DiceGame *game;    
    int currentBidCount;
    int currentBidFace;
    PlayerState *state;
    
    ControlButtons controlButtons;
    NSMutableArray *challengeButtons;
}

@property (readwrite, retain) DiceGame *game;
@property (readwrite, retain) PlayerState *state;
@property (readwrite, assign) int currentBidCount;
@property (readwrite, assign) int currentBidFace;
@property (readwrite, assign) ControlButtons controlButtons;

- (IBAction)backPressed:(id)sender;

- (IBAction)challengePressed:(id)sender;
- (IBAction)passPressed:(id)sender;
- (IBAction)bidPressed:(id)sender;
- (IBAction)exactPressed:(id)sender;

- (void) dieButtonPressed:(id)dieID;

@end
