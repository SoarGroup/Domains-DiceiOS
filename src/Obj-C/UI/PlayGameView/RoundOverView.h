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

- (UIImage*)barImage;

@property (readwrite, assign) DiceGame *game;
@property (readwrite, assign) PlayerState *player;
@property (readwrite, assign) PlayGameView *playGameView;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UIScrollView *diceView;
@property (retain, nonatomic) IBOutlet UIButton *doneButton;
@property (retain, nonatomic) IBOutlet UIImageView* transparencyLevel;

@end
