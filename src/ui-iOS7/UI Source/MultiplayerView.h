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

@interface MultiplayerView : UIViewController <GKLocalPlayerListener, UIAlertViewDelegate>
{
	UIPopoverController* createMatchPopoverViewController;
	UIPopoverController* findMatchPopoverViewController;

	NSMutableArray* miniGamesViewArray;
	NSMutableArray* handlerArray; // One-To-One Correspondence with miniGamesViewArray
	NSMutableArray* playGameViews;
	NSTimer* updateTimer;

	BOOL iPad;
}

- (id)initWithMainMenu:(MainMenu*)mainMenu withAppDelegate:(ApplicationDelegate*)appDelegate;

@property (nonatomic, retain) ApplicationDelegate* appDelegate;
@property (nonatomic, retain) MainMenu* mainMenu;
@property (nonatomic, retain) IBOutlet UIButton* joinMatchButton;
@property (nonatomic, retain) IBOutlet UIScrollView* gamesScrollView;
@property (nonatomic, retain) IBOutlet UIButton* scrollToTheFarRightButton;

- (IBAction)joinMatchButtonPressed:(id)sender;
- (IBAction)scrollToTheFarRightButtonPressed:(id)sender;

// GKTurnBasedEventListener methods
- (void)player:(GKPlayer*)player didRequestMatchWithPlayers:(NSArray *)playerIDsToInvite;
- (void)player:(GKPlayer*)player matchEnded:(GKTurnBasedMatch *)match;
- (void)player:(GKPlayer*)player receivedTurnEventForMatch:(GKTurnBasedMatch *)match didBecomeActive:(BOOL)didBecomeActive;

@end
