//
//  FindMatchView.h
//  UM Liars Dice
//
//  Created by Alex Turner on 5/6/14.
//
//

#import <UIKit/UIKit.h>
#import "MainMenu.h"

@class MultiplayerView;

@interface JoinMatchView : UIViewController
{
	BOOL iPad;
}

- (id)initWithMainMenu:(MainMenu*)mainMenu withAppDelegate:(ApplicationDelegate*)delegate isPopOver:(BOOL)popOver withMultiplayerView:(MultiplayerView*)multiplayerView;

@property (nonatomic, retain) ApplicationDelegate* delegate;
@property (nonatomic, retain) MainMenu* mainMenu;
@property (nonatomic, retain) MultiplayerView* multiplayerView;

@property (nonatomic, retain) IBOutlet UILabel* numberOfAIPlayers;
@property (nonatomic, retain) IBOutlet UIStepper* changeNumberOfAIPlayers;

@property (nonatomic, retain) IBOutlet UILabel* minimumNumberOfHumanPlayers;
@property (nonatomic, retain) IBOutlet UIStepper* changeMinimumNumberOfHumanPlayers;

@property (nonatomic, retain) IBOutlet UILabel* maximumNumberOfHumanPlayers;
@property (nonatomic, retain) IBOutlet UIStepper* changeMaximumNumberOfHumanPlayers;

@property (nonatomic, retain) IBOutlet UIButton* joinMatchButton;

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* spinner;

@property (nonatomic, assign) BOOL isPopOver;

-(IBAction)joinMatchButtonPressed:(id)sender;
-(IBAction)stepperValueChanged:(UIStepper*)sender;

@end
