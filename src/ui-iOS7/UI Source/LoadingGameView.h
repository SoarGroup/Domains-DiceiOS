//
//  LoadingGameView.h
//  Liars Dice
//
//  Created by Miller Tinkerhess on 4/3/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DiceGame.h"

@class MainMenu;

@interface LoadingGameView : UIViewController {
    int numOpponents; // How many soar players, not total players;
    DiceGame *game;
    MainMenu *menu;
    UIActivityIndicatorView *spinnerView;
}

- (id) initWithGame:(DiceGame *)game numOpponents:(int)numOpponents mainMenu:(MainMenu*)aMenu;

@property (readwrite, assign) int numOpponents;
@property (readwrite, retain) DiceGame *game;
@property (readwrite, retain) MainMenu *menu;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinnerView;

@end

