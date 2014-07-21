//
//  RoundOverView.h
//  Liars Dice
//
//  Created by Miller Tinkerhess on 3/30/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DiceGame.h"
#import "PlayerState.h"
#import "PlayGameView.h"

@interface RoundOverView : UIViewController <UIScrollViewDelegate> {
	NSString* finalString;
	
	NSMutableArray *previousBidImageViews;
	BOOL iPad;
}

- (id) initWithGame:(DiceGame*)game player:(PlayerState*)player playGameView:(PlayGameView *)playGameView withFinalString:(NSString*)finalString;
- (IBAction)donePressed:(id)sender;

@property (readwrite, weak) DiceGame *game;
@property (readwrite, weak) PlayerState *player;
@property (readwrite, weak) PlayGameView *playGameView;
@property (nonatomic, strong) IBOutlet UILabel *gameStateLabel;
@property (strong, nonatomic) IBOutlet UIButton *doneButton;
@property (strong, nonatomic) IBOutlet UIImageView* transparencyLevel;

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

@end
