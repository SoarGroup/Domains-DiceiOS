//
//  iPadServerViewController.h
//  Lair's Dice
//
//  Created by Alex on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Lair_s_DiceAppDelegate_iPad.h"

typedef struct {
    int dieNumber;
    int playerNumber;
    int die;
} Args;

@interface iPadServerViewController : UIViewController {
    UITextView *console;
    
    UITextView *lastAction;
    UITextView *secondToLastAction;
    
    UIButton *toggleButton;
    
    UIView *rootView;
        
    NSMutableArray *Players;
        
    Lair_s_DiceAppDelegate_iPad *appDelegate;
    
    int playerNumbers;
}

@property (nonatomic, retain) IBOutlet UITextView *console;

@property (nonatomic, retain) IBOutlet UITextView *lastAction;
@property (nonatomic, retain) IBOutlet UITextView *secondToLastAction;

@property (nonatomic, retain) IBOutlet UIButton *toggleButton;

@property (nonatomic, assign) Lair_s_DiceAppDelegate_iPad *appDelegate;

- (void)logToConsole:(NSString *)message;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withPlayers:(int)players;

- (void)dieWasPushed:(Arguments*)args;

- (void)clearPushedDice:(Arguments*)didWin;

- (void)clearAll;
- (void)showAll:(NSArray *)dice;

- (IBAction)didEndGame:(UIButton *)sender;
- (IBAction)toggleDebugConsole:(UIButton *)sender;

- (void)setPlayerName:(NSString *)name forPlayer:(int)player;

@end
