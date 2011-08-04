//
//  iPadServerViewController.h
//  Lair's Dice
//
//  Created by Alex on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Lair_s_DiceAppDelegate_iPad.h"
#import "PopoverViewController.h"

typedef struct {
    int dieNumber;
    int playerNumber;
    int die;
} Args;

@interface iPadServerViewController : UIViewController <UIAlertViewDelegate> {
    UITextView *console;
    
    UITextView *lastAction;
    
    UIButton *toggleButton;
    
    UIView *rootView;
        
    NSMutableArray *Players;
        
    Lair_s_DiceAppDelegate_iPad *appDelegate;
    
    int playerNumbers;
    
    UIPopoverController *popOverController;
    
    UIAlertView *gameOverAlert;
}

@property (nonatomic, retain) IBOutlet UITextView *console;

@property (nonatomic, retain) IBOutlet UITextView *lastAction;

@property (nonatomic, retain) IBOutlet UIButton *toggleButton;

@property (nonatomic, assign) UIAlertView *gameOverAlert;

@property (nonatomic, assign) Lair_s_DiceAppDelegate_iPad *appDelegate;

@property (nonatomic, retain) NSMutableArray *Players;

- (void)logToConsole:(NSString *)message;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withPlayers:(int)players;

- (void)dieWasPushed:(Arguments*)args;

- (void)clearPushedDice:(id)didWin;

- (void)clearAll;
- (void)showAll:(NSArray *)dice;

- (IBAction)didEndGame:(UIButton *)sender;
- (IBAction)toggleDebugConsole:(UIButton *)sender;
- (IBAction)tappedArea:(UIButton *)sender;

- (void)showPopOverFor:(int)playerNumber withContents:(NSString *)content;

- (void)setPlayerName:(NSString *)name forPlayer:(int)player;

- (void)gameOver:(NSString *)winner;

- (void)setCurrentTurn:(NSValue *)player;

@end
