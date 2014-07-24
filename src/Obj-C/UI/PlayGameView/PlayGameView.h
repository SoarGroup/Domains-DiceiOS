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

enum UITags
{
	DiceViewTag = 9,
	PlayerLabelTag = 10,
	ChallengeButtonTag = 11,
	ActivitySpinnerTag = 12
};

@interface PlayGameView : UIViewController <PlayGame, NewRoundListener> {
@private
	int currentBidCount;
	double internalCurrentBidCount;
    int currentBidFace;

	BOOL canContinueRound;

	BOOL hasTouchedBidCounterThisTurn;
	BOOL hasDisplayedRoundOverview;
	BOOL showAllDice;
@public
	BOOL shouldNotifyCurrentPlayer;

	void (^quitHandler)(void);

	BOOL tutorial;
	int step;
}

// Utility Functions
+ (UIImage *)imageForDie:(NSInteger)die;
+ (NSInteger)dieForImage:(UIImage*)image;

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
@property (nonatomic, strong) IBOutlet UIButton *continueRoundButton;
@property (nonatomic, strong) IBOutlet UIButton *fullscreenButton;

// Properties based on labels
@property (nonatomic, strong) IBOutlet UILabel *gameStateLabel;
@property (nonatomic, strong) IBOutlet UILabel *bidCountLabel;
@property (nonatomic, strong) IBOutlet UIImageView *bidFaceLabel;

// Properties based on variables
@property (readwrite, strong) DiceGame *game;
@property (readwrite, assign) BOOL hasPromptedEnd;
@property (readwrite, weak) PlayerState *state;
@property (readwrite, atomic, assign) BOOL animationFinished;

// Properties based on views
@property (nonatomic, strong) IBOutlet UIView *player1View;
@property (nonatomic, strong) IBOutlet UIView *player2View;
@property (nonatomic, strong) IBOutlet UIView *player3View;
@property (nonatomic, strong) IBOutlet UIView *player4View;
@property (nonatomic, strong) IBOutlet UIView *player5View;
@property (nonatomic, strong) IBOutlet UIView *player6View;
@property (nonatomic, strong) IBOutlet UIView *player7View;
@property (nonatomic, strong) IBOutlet UIView *player8View;

@property (nonatomic, strong) NSArray *playerViews;
@property (nonatomic, strong) IBOutlet UIScrollView *playerScrollView;

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
- (IBAction)dieButtonPressed:(id)sender;
- (IBAction)continueRoundPressed:(UIButton*)sender;

// Initialization Functions
- (id)initWithGame:(DiceGame*)theGame withQuitHandler:(void (^)(void))QuitHandler;
- (id)initWithGame:(DiceGame*)theGame withQuitHandler:(void (^)(void))QuitHandler withCustomMainView:(BOOL)custom;

- (id)initTutorialWithQuitHandler:(void (^)(void))QuitHandler;

+ (NSAttributedString*)formatTextString:(NSString*)nameLabelText;
+ (NSAttributedString*)formatTextAttributedString:(NSAttributedString*)nameLabelText;


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
