//
//  DiceMainMenu.h
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DiceApplicationDelegate;

@interface DiceMainMenu : UIViewController {
    DiceApplicationDelegate *appDelegate;
    UIButton *singlePlayerButton;
    UIButton *multiPlayerButton;
    UIButton *joinMultiplayerButton;
    UIButton *serverOnlyButton;
    UIButton *startGameTwoOpponents;
	
	NSString *username;
}

@property (readwrite, retain) DiceApplicationDelegate *appDelegate;

- (void) startGameWithOpponents:(int)opponents;

/*
- (IBAction)newSinglePlayerGame:(id)sender;
- (IBAction)newMultiplayerGame:(id)sender;
- (IBAction)joinMultiplayerGame:(id)sender;
- (IBAction)startServerOnly:(id)sender;
 */
- (IBAction)startGameOneOpponent:(id)sender;
- (IBAction)startGameThreeOpponents:(id)sender;
- (IBAction)startGameTwoOpponents:(id)sender;

-(id)initWithAppDelegate:(DiceApplicationDelegate*)appDelegate;
@property (nonatomic, retain) IBOutlet UIButton *singlePlayerButton;
@property (nonatomic, retain) IBOutlet UIButton *multiPlayerButton;
@property (nonatomic, retain) IBOutlet UIButton *joinMultiplayerButton;
@property (nonatomic, retain) IBOutlet UIButton *serverOnlyButton;
- (IBAction)howToPlayPressed:(id)sender;
@property (retain, nonatomic) IBOutlet UIButton *oneOpponentButton;
@property (retain, nonatomic) IBOutlet UIButton *twoOpponentButton;
@property (retain, nonatomic) IBOutlet UIButton *threeOpponentButton;
@property (retain, nonatomic) IBOutlet UIButton *settingsButton;
- (IBAction)settingsPressed:(id)sender;
@property (retain, nonatomic) IBOutlet UIButton *aboutButton;
- (IBAction)aboutPressed:(id)sender;
@property (retain, nonatomic) IBOutlet UIButton *howToPlayButton;
- (IBAction)howToPlayPressed:(id)sender;
- (IBAction)recordsPressed:(id)sender;
@property (retain, nonatomic) IBOutlet UIButton *statsButton;

@end
