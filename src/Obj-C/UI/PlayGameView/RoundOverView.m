//
//  RoundOverView.m
//  Liars Dice
//
//  Created by Miller Tinkerhess on 3/30/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "RoundOverView.h"
#import "HistoryItem.h"
#import "Die.h"
#import "DiceGraphics.h"
#import "UIImage+ImageEffects.h"

#import "DiceReplayPlayer.h"
#import "SoarPlayer.h"

@implementation RoundOverView

@synthesize game, player, playGameView;
@synthesize gameStateLabel;
@synthesize doneButton;
@synthesize transparencyLevel;

@synthesize playerViews, playerScrollView, player1View, player2View, player3View, player4View, player5View, player6View, player7View, player8View;

- (id) initWithGame:(DiceGame*) aGame player:(PlayerState*)aPlayer playGameView:(PlayGameView *)aPlayGameView withFinalString:(NSString*)finalString2
{
	self = [super initWithNibName:@"RoundOverView" bundle:nil];

	if (self)
	{
        self.game = aGame;
        self.player = aPlayer;
        self.playGameView = aPlayGameView;
		finalString = finalString2;

		self.accessibilityLabel = @"Round Over";
		self.accessibilityHint = @"The round is over, this screen is displaying a list of the dice your opponents had.";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePlayerNames) name:@"UpdateUINotification" object:nil];
	
	PlayGameView* localGameView = self.playGameView;

	UIImage* snapshot = [localGameView.view blurredSnapshot];
	[self.transparencyLevel setImage:snapshot];

	DiceGame* localGame = self.game;

	playerViews = @[player1View,
					player2View,
					player3View,
					player4View,
					player5View,
					player6View,
					player7View,
					player8View];

	for (UIView* view in playerViews)
		[view viewWithTag:ActivitySpinnerTag].hidden = YES;

	if ([[self nibName] rangeOfString:@"iPad"].location == NSNotFound)
	{
		id last = nil;

		if (localGameView->tutorial)
			last = player2View;
		else
			last = [playerViews objectAtIndex:localGame.players.count-1];

		[playerScrollView addConstraint:[NSLayoutConstraint constraintWithItem:last
																	 attribute:NSLayoutAttributeBottom
																	 relatedBy:NSLayoutRelationEqual
																		toItem:playerScrollView
																	 attribute:NSLayoutAttributeBottom
																	multiplier:1.0
																	  constant:0]];

		if (localGameView->tutorial)
			playerScrollView.contentSize = CGSizeMake(playerScrollView.frame.size.width,
													  256);
		else
			playerScrollView.contentSize = CGSizeMake(playerScrollView.frame.size.width,
													  [localGame.players count] * 128);
	}


	if (localGameView->tutorial)
	{
		for (NSUInteger i = 2;i < [playerViews count];i++)
			((UIView*)[playerViews objectAtIndex:i]).hidden = YES;

		for (int i = 0;i < 5;++i)
		{
			UIButton* button = [[localGameView.player1View viewWithTag:DiceViewTag].subviews objectAtIndex:i];
			UIButton* button2 = [[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:i];
			UIImage* image = button.imageView.image;

			[button2 setImage:image forState:UIControlStateNormal];
			button2.hidden = button.hidden;
            button2.accessibilityLabel = [NSString stringWithFormat:@"Your Die, Face Value of %li", (long)[PlayGameView dieForImage:image]];
		}

		for (int i = 0;i < 5;++i)
		{
			UIButton* button = [[localGameView.player2View viewWithTag:DiceViewTag].subviews objectAtIndex:i];
			UIButton* button2 = [[player2View viewWithTag:DiceViewTag].subviews objectAtIndex:i];
			UIImage* image = button.imageView.image;

			[button2 setImage:image forState:UIControlStateNormal];
			button2.hidden = button.hidden;
            button2.accessibilityLabel = [NSString stringWithFormat:@"Alice's Die, Face Value of %li", (long)[PlayGameView dieForImage:image]];
		}

		((UILabel*)[player1View viewWithTag:PlayerLabelTag]).text = @"You";
		((UILabel*)[player2View viewWithTag:PlayerLabelTag]).text = @"Alice";

		NSMutableArray* views = [NSMutableArray array];

		if (localGameView->step == 4)
		{
			UIView* aliceDice = [player2View viewWithTag:DiceViewTag];
			UILabel* aliceLabel = (UILabel*)[player2View viewWithTag:PlayerLabelTag];

			int index = 0;
			for (UIButton* button in aliceDice.subviews)
			{
				switch (index) {
					case 0:
					case 1:
						break;
					case 2:
						[button setImage:[PlayGameView imageForDie:DIE_3] forState:UIControlStateNormal];
                        button.accessibilityLabel = @"Alice's Die, Face Value of 3";
						break;
					case 3:
						[button setImage:[PlayGameView imageForDie:DIE_5] forState:UIControlStateNormal];
                        button.accessibilityLabel = @"Alice's Die, Face Value of 5";
						break;
					case 4:
						[button setImage:[PlayGameView imageForDie:DIE_5] forState:UIControlStateNormal];
                        button.accessibilityLabel = @"Alice's Die, Face Value of 5";
						break;
					default:
						break;
				}

				index++;
			}

			aliceLabel.attributedText = [PlayGameView formatTextString:@"Alice bid 6 3s."];

			gameStateLabel.attributedText = [PlayGameView formatTextString:@"Alice bid 6 3s.\nThere were 5 3s.\nYou challenged Alice's bid.\nAlice lost a die."];

			[views addObject:doneButton];
		}
		else if (localGameView->step == 6)
		{
			UIView* aliceDice = [player2View viewWithTag:DiceViewTag];
			UILabel* aliceLabel = (UILabel*)[player2View viewWithTag:PlayerLabelTag];

			int index = 0;
			for (UIButton* button in aliceDice.subviews)
			{
				switch (index) {
					case 0:
					case 1:
						[button setImage:[PlayGameView imageForDie:DIE_2] forState:UIControlStateNormal];
                        button.accessibilityLabel = @"Alice's Die, Face Value of 2";
						break;
					case 2:
					case 3:
						[button setImage:[PlayGameView imageForDie:DIE_4] forState:UIControlStateNormal];
                        button.accessibilityLabel = @"Alice's Die, Face Value of 4";
						break;
					default:
						break;
				}

				index++;
			}

			aliceLabel.text = @"Alice challenged your pass.";
			gameStateLabel.attributedText = [PlayGameView formatTextString:@"You passed.\nAlice challenged your pass.\nAlice lost a die."];

			[views addObject:doneButton];
		}
		else if (localGameView->step == 9)
		{
			UIView* myDice = [player1View viewWithTag:DiceViewTag];
			UIView* aliceDice = [player2View viewWithTag:DiceViewTag];
			UILabel* aliceLabel = (UILabel*)[player2View viewWithTag:PlayerLabelTag];

			int index = 0;
			for (UIButton* button in aliceDice.subviews)
			{
				switch (index) {
					case 0:
					case 1:
						[button setImage:[PlayGameView imageForDie:DIE_1] forState:UIControlStateNormal];
                        button.accessibilityLabel = @"Alice's Die, Face Value of 1";
						break;
					case 2:
						[button setImage:[PlayGameView imageForDie:DIE_2] forState:UIControlStateNormal];
						button.frame = CGRectMake(button.frame.origin.x, 0, button.frame.size.width, button.frame.size.height);
                        button.accessibilityLabel = @"Alice's Die, Face Value of 2";
						break;
					case 3:
					case 4:
						[button setImage:[PlayGameView imageForDie:DIE_6] forState:UIControlStateNormal];
                        button.accessibilityLabel = @"Alice's Die, Face Value of 6";
						if (index == 4)
							button.frame = CGRectMake(button.frame.origin.x, 15, button.frame.size.width, button.frame.size.height);
						break;
					default:
						break;
				}

				index++;
			}

			aliceLabel.text = @"Alice challenged your bid.";
			gameStateLabel.attributedText = [PlayGameView formatTextString:@"You bid 7 6s.\nThere were 7 6s.\nAlice challenged your bid.\nAlice lost a die."];

			[[myDice.subviews objectAtIndex:2] setImage:[PlayGameView imageForDie:DIE_6] forState:UIControlStateNormal];
			
			[views addObject:doneButton];
		}

		CABasicAnimation* pulse = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
		pulse.fromValue = (id)[UIColor clearColor].CGColor;
		pulse.toValue = (id)[UIColor clearColor].CGColor;
		pulse.duration = 2.0;
		pulse.autoreverses = YES;
		pulse.removedOnCompletion = NO;
		//pulse.fillMode = kCAFillModeBoth;
		pulse.repeatCount = HUGE_VALF;

		for (UIView* view in views)
		{
			[view.layer setCornerRadius:5.0f];
			[view.layer addAnimation:pulse forKey:@"backgroundColor"];
		}

		return;
	}

	for (NSUInteger i = [localGame.players count];i < [playerViews count];i++)
		((UIView*)[playerViews objectAtIndex:i]).hidden = YES;

	PlayerState* localState = self.player;

	NSMutableArray* reorderedPlayers = [NSMutableArray arrayWithArray:localGame.players];

	while (![[reorderedPlayers firstObject] isKindOfClass:DiceLocalPlayer.class] &&
           ![[reorderedPlayers firstObject] isKindOfClass:DiceReplayPlayer.class])
	{
		[reorderedPlayers insertObject:[reorderedPlayers lastObject] atIndex:0];
		[reorderedPlayers removeLastObject];
	}

	for (int i = 0;i < [reorderedPlayers count];++i)
		((UIView*)[playerViews objectAtIndex:i]).tag = [[reorderedPlayers objectAtIndex:i] getID];

	// State initialization
	NSString *headerString = finalString; // This sets it

	self.gameStateLabel.accessibilityLabel = [localGameView accessibleTextForString:headerString];

	NSMutableAttributedString* string = [[NSMutableAttributedString alloc] init];
	for (int i = 0;i < [headerString length];++i)
	{
		unichar characterOne = [headerString characterAtIndex:i], characterTwo = 0;

		if (i+1 < [headerString length])
			characterTwo = [headerString characterAtIndex:i+1];

		if (isdigit(characterOne) && characterTwo == 's')
		{
			int characterDigit = characterOne - '0';

			NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
			attachment.image = [PlayGameView imageForDie:characterDigit];
			[attachment setBounds:CGRectMake(0, -5, gameStateLabel.font.lineHeight, gameStateLabel.font.lineHeight)];

			NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];

			[string appendAttributedString:attachmentString];

			++i;
		}
		else
			[string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%c", [headerString characterAtIndex:i]]]];
	}

	gameStateLabel.attributedText = string;

	// Update the contents of the gameStateView
	NSArray *playerStates = localGame.gameState.playerStates;

	NSMutableArray* playerStatesReordered = [NSMutableArray arrayWithArray:playerStates];

	for (NSUInteger i = [playerStatesReordered count]; i > 0; i--) {
		PlayerState* obj = [playerStatesReordered lastObject];
		[playerStatesReordered insertObject:obj atIndex:0];
		[playerStatesReordered removeLastObject];

		if (obj.playerID == localState.playerID)
			break;
	}

	NSUInteger playerCount = [playerStatesReordered count];
	for (int z = 0;z < playerCount;++z)
	{
		PlayerState* playerState = [playerStatesReordered objectAtIndex:z];

		UIView* view = [playerViews objectAtIndex:z];

		// Handle the player's name text

		UILabel* nameLabel = (UILabel*)[view viewWithTag:PlayerLabelTag];

		nameLabel.text = [[playerState playerPtr] getDisplayName];

		// Update the dice
		UIView *diceView = [view viewWithTag:DiceViewTag];

		for (int dieIndex = 0; dieIndex < [playerState.arrayOfDice count]; ++dieIndex)
		{
			Die *die = [playerState getDie:dieIndex];

			UIImage *dieImage = [PlayGameView imageForDie:die.dieValue];

			UIButton* dieButton = (UIButton*)[diceView viewWithTag:dieIndex];

			dieButton.enabled = NO;

			[dieButton setImage:dieImage forState:UIControlStateNormal];
		}

		for (int dieIndex = (int)[playerState.arrayOfDice count]; dieIndex < 5; ++dieIndex)
			((UIButton*)[diceView viewWithTag:dieIndex]).hidden = YES;
	}
}

- (void)updatePlayerNames
{
	if (![[gameStateLabel.attributedText string] containsString:@"Remote Player"])
		return;
	
	DiceGame* localGame = self.game;
	
	NSString *headerString = [localGame.gameState headerString:-1 singleLine:YES displayDiceCount:NO];
	PlayerState* playerStateLocal = [localGame.gameState lastHistoryItem].player;
	NSString *lastMoveString = [localGame.gameState historyText:playerStateLocal.playerID];
	
	NSString* finalString2 = [NSString stringWithFormat:@"%@\n%@", headerString, lastMoveString];
	
	PlayGameView* localGameView = self.playGameView;
	self.gameStateLabel.accessibilityLabel = [localGameView accessibleTextForString:finalString2];
	
	NSMutableAttributedString* string = [[NSMutableAttributedString alloc] init];
	for (int i = 0;i < [finalString2 length];++i)
	{
		unichar characterOne = [finalString2 characterAtIndex:i], characterTwo = 0;
		
		if (i+1 < [finalString2 length])
			characterTwo = [finalString2 characterAtIndex:i+1];
		
		if (isdigit(characterOne) && characterTwo == 's')
		{
			int characterDigit = characterOne - '0';
			
			NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
			attachment.image = [PlayGameView imageForDie:characterDigit];
			[attachment setBounds:CGRectMake(0, -5, gameStateLabel.font.lineHeight, gameStateLabel.font.lineHeight)];
			
			NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
			
			[string appendAttributedString:attachmentString];
			
			++i;
		}
		else
			[string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%c", [finalString2 characterAtIndex:i]]]];
	}
	
	gameStateLabel.attributedText = string;
	
	PlayerState* localState = self.player;
	NSArray *playerStates = localGame.gameState.playerStates;
	
	NSMutableArray* playerStatesReordered = [NSMutableArray arrayWithArray:playerStates];
	
	for (NSUInteger i = [playerStatesReordered count]; i > 0; i--) {
		PlayerState* obj = [playerStatesReordered lastObject];
		[playerStatesReordered insertObject:obj atIndex:0];
		[playerStatesReordered removeLastObject];
		
		if (obj.playerID == localState.playerID)
			break;
	}
	
	NSUInteger playerCount = [playerStatesReordered count];
	for (int z = 0;z < playerCount;++z)
	{
		PlayerState* playerState = [playerStatesReordered objectAtIndex:z];
		
		UIView* view = [playerViews objectAtIndex:z];
		
		// Handle the player's name text
		
		UILabel* nameLabel = (UILabel*)[view viewWithTag:PlayerLabelTag];
		nameLabel.text = [[playerState playerPtr] getDisplayName];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification,
                                    self.gameStateLabel);
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
    [aScrollView setContentOffset:CGPointMake(0, aScrollView.contentOffset.y)];
}

- (IBAction)donePressed:(id)sender {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self dismissViewControllerAnimated:YES completion:nil];

	PlayGameView* gameView = self.playGameView;
	if ([gameView.overViews containsObject:self])
	{
		[UIView animateWithDuration:0.25 animations:^{
			self.view.frame = CGRectMake(self.view.frame.origin.x,
										 self.view.frame.size.height,
										 self.view.frame.size.width,
										 self.view.frame.size.height);
		} completion:^(BOOL finished)
		 {
			 [self.view removeFromSuperview];
			 [gameView.overViews removeObject:self];
		 }];
	}

	[gameView continueRoundPressed:nil];
}

@end
