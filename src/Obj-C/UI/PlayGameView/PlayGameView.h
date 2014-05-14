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

const int pushMargin();

@interface PlayGameView : UIViewController <PlayGame, NewRoundListener> {
	void (^quitHandler)(void);

	BOOL fullScreenView;

	int currentBidCount;
    int currentBidFace;

	NSMutableArray *challengeButtons;
    NSMutableArray *tempViews;

	UIView* centerPush;

	BOOL canContinueRound;

	// Temporary stuff
	UIAlertView* alertView2;
	NSInteger buttonIndex2;

	BOOL hasTouchedBidCounterThisRound;
}

// Utility Functions
+(UIImage*)barImage;
-(UIImage *)imageForDie:(NSInteger)die;
-(UIImage *)blurredSnapshot;

// Properties based on buttons
@property (nonatomic, retain) IBOutlet UIButton *bidButton;
@property (nonatomic, retain) IBOutlet UIButton *bidCountMinusButton;
@property (nonatomic, retain) IBOutlet UIButton *bidCountPlusButton;
@property (nonatomic, retain) IBOutlet UIButton *bidFaceMinusButton;
@property (nonatomic, retain) IBOutlet UIButton *bidFacePlusButton;
@property (nonatomic, retain) IBOutlet UIButton *exactButton;
@property (nonatomic, retain) IBOutlet UIButton *passButton;
@property (nonatomic, retain) IBOutlet UIButton *quitButton;
@property (nonatomic, retain) IBOutlet UIButton *fullscreenButton;

// Properties based on lables
@property (nonatomic, retain) IBOutlet UILabel *gameStateLabel;
@property (nonatomic, retain) IBOutlet UILabel *bidCountLabel;

// Properties based on variables
@property (readwrite, retain) NSMutableArray *challengeButtons;
@property (readwrite, retain) DiceGame *game;
@property (readwrite, assign) BOOL hasPromptedEnd;
@property (readwrite, retain) NSArray *images;
@property (readwrite, retain) PlayerState *state;
@property (readwrite, retain) NSMutableArray *tempViews;
@property (readwrite, assign) BOOL isCustom;
@property (readwrite, atomic, assign) BOOL animationFinished;
@property (readwrite, retain) NSMutableArray* previousBidImageViews;

// Properties based on views
@property (nonatomic, retain) IBOutlet UIImageView *bidFaceLabel;
@property (nonatomic, retain) IBOutlet UIView *controlStateView;
@property (nonatomic, retain) IBOutlet UIScrollView *gameStateView;

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
