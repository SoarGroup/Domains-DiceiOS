//
//  DiceMainMenu.h
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@class ApplicationDelegate;

@interface MainMenu : UIViewController <UIAlertViewDelegate, UINavigationControllerDelegate, GKGameCenterControllerDelegate>

@property (nonatomic, assign) BOOL multiplayerEnabled;
@property (readwrite, weak) ApplicationDelegate *appDelegate;

-(id)initWithAppDelegate:(ApplicationDelegate*)appDelegate;

- (IBAction)aiOnlyGameButtonPressed:(id)sender;
- (IBAction)multiplayerGameButtonPressed:(id)sender;
- (IBAction)helpButtonPressed:(id)sender;
- (IBAction)statsButtonPressed:(id)sender;
- (IBAction)settingsButtonPressed:(id)sender;
- (IBAction)aboutButtonPressed:(id)sender;

- (IBAction)poweredBySoarPressed:(id)sender;

@property (nonatomic, strong) IBOutlet UIButton *aiOnlyGameButton;
@property (nonatomic, strong) IBOutlet UIButton *multiplayerGameButton;
@property (nonatomic, strong) IBOutlet UIButton *helpButton;
@property (nonatomic, strong) IBOutlet UIButton *statsButton;
@property (strong, nonatomic) IBOutlet UIButton *settingsButton;
@property (strong, nonatomic) IBOutlet UIButton *aboutButton;

@property (strong, nonatomic) IBOutlet UIButton *removeAllMultiplayerGames;

@property (strong, nonatomic) UIViewController* multiplayerController;

@end
