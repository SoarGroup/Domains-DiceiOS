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
    DiceGame *game;
    UILabel *gameStateLabel;
    UIButton *bidFacePlusPressed;
    UIButton *passButton;
    UIButton *bidButton;
    UIButton *exactButton;
    
    int currentBidCount;
    int currentBidFace;
    
    PlayerState *state;
    
    UIButton *bidCountButton;
    UIButton *bidFaceButton;
    UILabel *previousBidLabel;
	NSMutableArray *previousBidImageViews;
	
    UIView *controlStateView;
    UIView *gameStateView;
    
    NSMutableArray *challengeButtons;
    NSMutableArray *tempViews;
    UILabel *bidCountLabel;
    UIImageView *bidFaceLabel;
    UIButton *bidCountPlusButton;
    UIButton *bidCountMinusButton;
    UIButton *bidFacePlusButton;
    UIButton *bidFaceMinusButton;
    MainMenu *menu;
    
    NSArray *images;
    UIButton *quitButton;
    BOOL hasPromptedEnd;
}

- (UIImage*)barImage;

@property (readwrite, retain) DiceGame *game;
@property (readwrite, retain) PlayerState *state;
@property (readwrite, retain) MainMenu *menu;
@property (readwrite, retain) NSArray *images;
@property (nonatomic, retain) IBOutlet UIButton *quitButton;
@property (readwrite, assign) BOOL hasPromptedEnd;

- (IBAction)backPressed:(id)sender;
- (id)initWithGame:(DiceGame*)aGame mainMenu:(MainMenu *)aMenu;

@property (nonatomic, retain) IBOutlet UILabel *gameStateLabel;
@property (nonatomic, retain) IBOutlet UILabel *previousBidLabel;
@property (nonatomic, retain) IBOutlet UIView *controlStateView;
@property (nonatomic, retain) IBOutlet UIView *gameStateView;

@property (readwrite, retain) NSMutableArray *challengeButtons;
@property (readwrite, retain) NSMutableArray *tempViews;

- (IBAction)bidCountPlusPressed:(id)sender;
- (IBAction)bidCountMinusPressed:(id)sender;
- (IBAction)bidFacePlusPressed:(id)sender;
- (IBAction)bidFaceMinusPressed:(id)sender;
@property (nonatomic, retain) IBOutlet UIButton *passButton;
@property (nonatomic, retain) IBOutlet UIButton *bidButton;
@property (nonatomic, retain) IBOutlet UIButton *exactButton;
- (IBAction)challengePressed:(id)sender;
- (IBAction)passPressed:(id)sender;
- (IBAction)bidPressed:(id)sender;
- (IBAction)exactPressed:(id)sender;
@property (nonatomic, retain) IBOutlet UILabel *bidCountLabel;
@property (nonatomic, retain) IBOutlet UIImageView *bidFaceLabel;
@property (nonatomic, retain) IBOutlet UIButton *bidCountPlusButton;
@property (nonatomic, retain) IBOutlet UIButton *bidCountMinusButton;
@property (nonatomic, retain) IBOutlet UIButton *bidFacePlusButton;
@property (nonatomic, retain) IBOutlet UIButton *bidFaceMinusButton;
-(UIImage *)imageForDie:(NSInteger)die;

-(UIImage *)blurredSnapshot;

@end
