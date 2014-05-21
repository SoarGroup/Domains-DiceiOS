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
@class GameKitGameHandler;

@interface LoadingGameView : UIViewController {
    UIActivityIndicatorView *spinnerView;
}

- (id) initWithGame:(DiceGame *)game mainMenu:(MainMenu*)aMenu;

@property (readwrite, weak) DiceGame *game;
@property (readwrite, weak) MainMenu *menu;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinnerView;
@property (nonatomic, strong) IBOutlet UILabel* startingGameLabel;

@end

