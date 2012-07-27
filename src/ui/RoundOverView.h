//
//  RoundOverView.h
//  Liars Dice
//
//  Created by Miller Tinkerhess on 3/30/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DiceGame.h"
#import "PlayerState.h"
#import "PlayGameView.h"

@interface RoundOverView : UIViewController {
    DiceGame *game;
    PlayerState *player;
    PlayGameView *playGameView;
    UILabel *titleLabel;
    UIView *diceView;
}

- (id) initWithGame:(DiceGame*)game player:(PlayerState*)player playGameView:(PlayGameView *)playGameView;
- (IBAction)donePressed:(id)sender;

@property (readwrite, retain) DiceGame *game;
@property (readwrite, retain) PlayerState *player;
@property (readwrite, retain) PlayGameView *playGameView;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UIView *diceView;
@property (retain, nonatomic) IBOutlet UIButton *doneButton;

@end
