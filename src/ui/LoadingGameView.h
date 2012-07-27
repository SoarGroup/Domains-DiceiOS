//
//  LoadingGameView.h
//  Liars Dice
//
//  Created by Miller Tinkerhess on 4/3/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DiceGame.h"

@class DiceMainMenu;

@interface LoadingGameView : UIViewController {
    int numOpponents; // How many soar players, not total players;
    DiceGame *game;
    DiceMainMenu *menu;
    UIImageView *spinnerView;
}

- (id) initWithGame:(DiceGame *)game numOpponents:(int)numOpponents mainMenu:(DiceMainMenu*)aMenu;

@property (readwrite, assign) int numOpponents;
@property (readwrite, retain) DiceGame *game;
@property (readwrite, retain) DiceMainMenu *menu;
@property (nonatomic, retain) IBOutlet UIImageView *spinnerView;

@end

