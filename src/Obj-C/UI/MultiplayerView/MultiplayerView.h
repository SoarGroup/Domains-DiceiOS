//
//  MultiplayerView.h
//  UM Liars Dice
//
//  Created by Alex Turner on 9/23/13.
//
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import "MainMenu.h"

@class JoinMatchView;
@class DiceGame;

@interface MultiplayerView : UIViewController <UIAlertViewDelegate>
{
	BOOL iPad;
}

- (id)initWithMainMenu:(MainMenu*)mainMenu withAppDelegate:(ApplicationDelegate*)appDelegate;

@property (nonatomic, weak) ApplicationDelegate* appDelegate;
@property (nonatomic, weak) MainMenu* mainMenu;
@property (nonatomic, strong) IBOutlet UIButton* joinMatchButton;
@property (nonatomic, strong) IBOutlet UIScrollView* gamesScrollView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView* joinSpinner;

@property (atomic, strong) NSMutableArray* miniGamesViewArray;
@property (atomic, strong) NSMutableArray* handlerArray; // One-To-One Correspondence with miniGamesViewArray
@property (atomic, strong) NSMutableArray* playGameViews; // One-To-One Correspondence with miniGamesViewArray
@property (atomic, strong) NSMutableArray* containers; // One-To-One Correspondence with miniGamesViewArray

@property (nonatomic, strong) JoinMatchView* joinMatchPopoverViewController;
@property (nonatomic, strong) UIPopoverController* popoverController;

- (IBAction)joinMatchButtonPressed:(id)sender;

- (void)deleteMatchButtonPressed:(id)sender;
- (void)populateScrollView;
- (void)populateScrollView:(GKMatchRequest*)request;

@end
