//
//  PlayGameView.h
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/5/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PlayGame.h"
#import "DiceGameState.h"

@class DiceGame;
@class PlayerState;
@class MainMenu;
@class MultiplayerView;
@class RoundOverView;

const int pushMargin();

@interface PlayGameView : UIViewController <PlayGame, NewRoundListener> {
@private
	void (^quitHandler)(void);

	BOOL fullScreenView;

	int currentBidCount;
	double internalCurrentBidCount;
    int currentBidFace;

	NSMutableArray *challengeButtons;
    NSMutableArray *tempViews;

	UIView* centerPush;

	BOOL canContinueRound;

	// Temporary stuff
	UIAlertView* alertView2;
	NSInteger buttonIndex2;

	BOOL hasTouchedBidCounterThisTurn;
	BOOL hasDisplayedRoundOverview;
@public
	BOOL shouldNotifyCurrentPlayer;
}

// Utility Functions
+(UIImage*)barImage;
-(UIImage *)imageForDie:(NSInteger)die;
-(UIImage *)blurredSnapshot;

- (NSString*)accessibleTextForString:(NSString*)string;

// Properties based on buttons
@property (nonatomic, strong) IBOutlet UIButton *bidButton;
@property (nonatomic, strong) IBOutlet UIButton *bidCountMinusButton;
@property (nonatomic, strong) IBOutlet UIButton *bidCountPlusButton;
@property (nonatomic, strong) IBOutlet UIButton *bidFaceMinusButton;
@property (nonatomic, strong) IBOutlet UIButton *bidFacePlusButton;
@property (nonatomic, strong) IBOutlet UIButton *exactButton;
@property (nonatomic, strong) IBOutlet UIButton *passButton;
@property (nonatomic, strong) IBOutlet UIButton *quitButton;
@property (nonatomic, strong) IBOutlet UIButton *fullscreenButton;

// Properties based on lables
@property (nonatomic, strong) IBOutlet UILabel *gameStateLabel;
@property (nonatomic, strong) IBOutlet UILabel *bidCountLabel;

// Properties based on variables
@property (readwrite, strong) NSMutableArray *challengeButtons;
@property (readwrite, strong) DiceGame *game;
@property (readwrite, assign) BOOL hasPromptedEnd;
@property (readwrite, strong) NSArray *images;
@property (readwrite, weak) PlayerState *state;
@property (readwrite, strong) NSMutableArray *tempViews;
@property (readwrite, assign) BOOL isCustom;
@property (readwrite, atomic, assign) BOOL animationFinished;
@property (readwrite, strong) NSMutableArray* previousBidImageViews;

// Properties based on views
@property (nonatomic, strong) IBOutlet UIImageView *bidFaceLabel;
@property (nonatomic, strong) IBOutlet UIView *controlStateView;
@property (nonatomic, strong) IBOutlet UIScrollView *gameStateView;

@property (nonatomic, weak) MultiplayerView* multiplayerView;
@property (nonatomic, strong) NSMutableArray* overViews;

// Interface Builder Linked Actions
- (IBAction)backPressed:(id)sender;
- (IBAction)bidCountMinusPressed:(id)sender;
- (IBAction)bidCountPlusPressed:(id)sender;
- (IBAction)bidFaceMinusPressed:(id)sender;
- (IBAction)bidFacePlusPressed:(id)sender;
- (IBAction)bidPressed:(id)sender;
- (IBAction)challengePressed:(id)sender;
- (IBAction)exactPressed:(id)sender;
- (IBAction)passPressed:(id)sender;

// Initialization Functions
- (id)initWithGame:(DiceGame*)theGame withQuitHandler:(void (^)(void))QuitHandler;
- (id)initWithGame:(DiceGame*)theGame withQuitHandler:(void (^)(void))QuitHandler withCustomMainView:(BOOL)custom;

@end

// Extensions to UIApplication
@interface UIApplication (AppDimensions)
+(CGSize) currentSize;
+(CGSize) sizeInOrientation:(UIInterfaceOrientation)orientation;
@end

// Extensions to UINavigation Controller, basically allows us to override what the "back" button does in a UINavigationBar
@protocol BackButtonHandlerProtocol <NSObject>
@optional
// Override this method in UIViewController derived class to handle 'Back' button click
-(BOOL)navigationShouldPopOnBackButton;
@end

@interface UIViewController (BackButtonHandler) <BackButtonHandlerProtocol>

@end
