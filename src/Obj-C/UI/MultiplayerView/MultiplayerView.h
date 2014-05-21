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

@property (nonatomic, assign) ApplicationDelegate* appDelegate;
@property (nonatomic, assign) MainMenu* mainMenu;
@property (nonatomic, retain) IBOutlet UIButton* joinMatchButton;
@property (nonatomic, retain) IBOutlet UIScrollView* gamesScrollView;
@property (nonatomic, retain) IBOutlet UIButton* scrollToTheFarRightButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* joinSpinner;

@property (atomic, retain) NSMutableArray* miniGamesViewArray;
@property (atomic, retain) NSMutableArray* handlerArray; // One-To-One Correspondence with miniGamesViewArray
@property (atomic, retain) NSMutableArray* playGameViews; // One-To-One Correspondence with miniGamesViewArray

@property (nonatomic, assign) JoinMatchView* joinMatchPopoverViewController;
@property (nonatomic, retain) UIPopoverController* popoverController;

- (IBAction)joinMatchButtonPressed:(id)sender;
- (IBAction)scrollToTheFarRightButtonPressed:(id)sender;

- (void)deleteMatchButtonPressed:(id)sender;
- (void)joinedNewMatch:(GKMatchRequest*)request;

@end
