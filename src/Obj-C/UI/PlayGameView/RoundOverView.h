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

@interface RoundOverView : UIViewController <UIScrollViewDelegate, EngineClass> {
	NSString* finalString;
	
	NSMutableArray *previousBidImageViews;
	BOOL iPad;
}

- (id) initWithGame:(DiceGame*)game player:(PlayerState*)player playGameView:(PlayGameView *)playGameView withFinalString:(NSString*)finalString;
- (IBAction)donePressed:(id)sender;

- (UIImage*)barImage;

@property (readwrite, weak) DiceGame *game;
@property (readwrite, weak) PlayerState *player;
@property (readwrite, weak) PlayGameView *playGameView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIScrollView *diceView;
@property (strong, nonatomic) IBOutlet UIButton *doneButton;
@property (strong, nonatomic) IBOutlet UIImageView* transparencyLevel;

@end
