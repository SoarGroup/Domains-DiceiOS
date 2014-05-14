//
//  DiceMainMenu.h
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ApplicationDelegate;

@interface MainMenu : UIViewController <UIAlertViewDelegate>

@property (nonatomic, assign) BOOL multiplayerEnabled;
@property (readwrite, retain) ApplicationDelegate *appDelegate;

-(id)initWithAppDelegate:(ApplicationDelegate*)appDelegate;

- (IBAction)aiOnlyGameButtonPressed:(id)sender;
- (IBAction)multiplayerGameButtonPressed:(id)sender;
- (IBAction)rulesButtonPressed:(id)sender;
- (IBAction)statsButtonPressed:(id)sender;
- (IBAction)settingsButtonPressed:(id)sender;
- (IBAction)aboutButtonPressed:(id)sender;

@property (nonatomic, retain) IBOutlet UIButton *aiOnlyGameButton;
@property (nonatomic, retain) IBOutlet UIButton *multiplayerGameButton;
@property (nonatomic, retain) IBOutlet UIButton *rulesButton;
@property (nonatomic, retain) IBOutlet UIButton *statsButton;
@property (retain, nonatomic) IBOutlet UIButton *settingsButton;
@property (retain, nonatomic) IBOutlet UIButton *aboutButton;

@end
