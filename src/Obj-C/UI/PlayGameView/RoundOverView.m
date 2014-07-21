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
	NSString* device = [UIDevice currentDevice].model;
	device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];

	if ([device isEqualToString:@"iPhone"])
		device = @"";

	self = [super initWithNibName:[@"RoundOverView" stringByAppendingString:device] bundle:nil];

	if (self)
	{
        self.game = aGame;
        self.player = aPlayer;
        self.playGameView = aPlayGameView;
		iPad = [device length] != 0;
		finalString = finalString2;
		
		previousBidImageViews = [[NSMutableArray alloc] init];

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

	// State initialization
	PlayerState* localState = self.player;
	DiceGame* localGame = self.game;

	playerScrollView.contentSize = CGSizeMake(playerScrollView.frame.size.width,
											  ((UIView*)[playerViews objectAtIndex:[localGame.players count]]).frame.origin.y);

	NSString *headerString = [localState headerString:NO]; // This sets it

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
			attachment.image = [localGameView imageForDie:characterDigit];
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

			UIImage *dieImage = [localGameView imageForDie:die.dieValue];

			UIButton* dieButton = (UIButton*)[diceView viewWithTag:dieIndex];

			dieButton.enabled = NO;

			[dieButton setImage:dieImage forState:UIControlStateNormal];
		}
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

	DiceGame* localGame = self.game;
	PlayerState* localState = self.player;
	PlayerState* lastPlayerState = [[localGame.gameState lastHistoryItem] player];

	for (;[lastPlayerState playerID] > 0 && [[lastPlayerState playerPtr] isKindOfClass:SoarPlayer.class];lastPlayerState = [localGame.gameState playerStateForPlayerID:([lastPlayerState playerID] - 1)]);


	localGame.gameState.canContinueGame = YES;

	NSString *title = nil, *message = nil;

	if ([localGame.gameState usingSpecialRules]) {
		title = [NSString stringWithFormat:@"Special Rules!"];
		message = @"For this round: 1s aren't wild. Only players with one die may change the bid face.";
	}
	else if ([localState hasWon])
		title = [NSString stringWithFormat:@"You Win!"];
	else if ([localGame.gameState hasAPlayerWonTheGame])
		title = [NSString stringWithFormat:@"%@ Wins!", [localGame.gameState.gameWinner getDisplayName]];
	else if ([localState hasLost])
		title = [NSString stringWithFormat:@"You Lost the Game"];
	else if (localGame.newRound && [lastPlayerState playerID] != [localState playerID])
	{
		NSString* name = [[lastPlayerState playerPtr] getDisplayName];

		title = @"Please Wait";
		message = [NSString stringWithFormat:@"Please wait until %@ has finished looking at the round overview.", name];
	}

	[[[UIAlertView alloc] initWithTitle:title
								message:message
							   delegate:nil
					  cancelButtonTitle:@"Okay"
					  otherButtonTitles:nil] show];
}

@end
