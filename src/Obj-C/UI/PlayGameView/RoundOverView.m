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

	for (NSUInteger i = [localGame.players count];i < [playerViews count];i++)
		((UIView*)[playerViews objectAtIndex:i]).hidden = YES;

	((UIView*)[playerScrollView.subviews firstObject]).translatesAutoresizingMaskIntoConstraints = YES;

	playerScrollView.contentSize = CGSizeMake(playerScrollView.frame.size.width,
											  [localGame.players count] * 128);

	PlayerState* localState = self.player;

	NSMutableArray* reorderedPlayers = [NSMutableArray arrayWithArray:localGame.players];

	while (![[reorderedPlayers firstObject] isKindOfClass:DiceLocalPlayer.class])
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
	[gameStateLabel sizeToFit];

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

- (void)viewDidAppear:(BOOL)animated
{
	UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification,
                                    self.gameStateLabel);
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
    [aScrollView setContentOffset:CGPointMake(0, aScrollView.contentOffset.y)];
}

- (IBAction)donePressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];

	PlayGameView* gameView = self.playGameView;
	if ([gameView.overViews containsObject:self])
	{
		[UIView animateWithDuration:0.25 animations:^{
			self.view.frame = CGRectMake(self.view.frame.origin.x,
										 self.view.frame.size.height,
										 self.view.frame.size.width,
										 self.view.frame.size.height);
		}];

		[self.view removeFromSuperview];
		[gameView.overViews removeObject:self];
	}

	[gameView continueRoundPressed:nil];
}

@end
