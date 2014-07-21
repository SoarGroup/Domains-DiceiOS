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

	NSMutableSet* friendIDs;
}

- (id)initWithMainMenu:(MainMenu*)mainMenu withAppDelegate:(ApplicationDelegate*)delegate isPopOver:(BOOL)popOver withMultiplayerView:(MultiplayerView*)multiplayerView;

@property (nonatomic, weak) ApplicationDelegate* delegate;
@property (nonatomic, weak) MainMenu* mainMenu;
@property (nonatomic, weak) MultiplayerView* multiplayerView;

@property (nonatomic, strong) IBOutlet UILabel* numberOfAIPlayers;
@property (nonatomic, strong) IBOutlet UIStepper* changeNumberOfAIPlayers;

@property (nonatomic, strong) IBOutlet UILabel* minimumNumberOfHumanPlayers;
@property (nonatomic, strong) IBOutlet UIStepper* changeMinimumNumberOfHumanPlayers;

@property (nonatomic, strong) IBOutlet UILabel* maximumNumberOfHumanPlayers;
@property (nonatomic, strong) IBOutlet UIStepper* changeMaximumNumberOfHumanPlayers;

@property (nonatomic, strong) IBOutlet UIButton* joinMatchButton;
@property (nonatomic, strong) IBOutlet UIButton* inviteFriendsButton;
@property (nonatomic, strong) UIPopoverController* inviteFriendsController;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView* spinner;


@property (nonatomic, assign) BOOL isPopOver;

-(IBAction)joinMatchButtonPressed:(id)sender;
-(IBAction)inviteFriendsButtonPressed:(id)sender;

-(IBAction)stepperValueChanged:(UIStepper*)sender;

@end
