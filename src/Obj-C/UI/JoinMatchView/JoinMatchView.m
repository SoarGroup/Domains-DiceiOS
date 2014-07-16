//
//  FindMatchView.m
//  UM Liars Dice
//
//  Created by Alex Turner on 5/6/14.
//
//

#import "JoinMatchView.h"
#import "SingleplayerView.h"
#import "LoadingGameView.h"
#import "MultiplayerMatchData.h"
#import "DiceGame.h"
#import "SoarPlayer.h"
#import <GameKit/GameKit.h>
#import "MultiplayerView.h"
#import "PlayGameView.h"
#import "InviteFriendsView.h"

@interface JoinMatchView ()

@end

@implementation JoinMatchView

@synthesize numberOfAIPlayers, maximumNumberOfHumanPlayers, minimumNumberOfHumanPlayers;
@synthesize changeMinimumNumberOfHumanPlayers, changeNumberOfAIPlayers, changeMaximumNumberOfHumanPlayers;
@synthesize joinMatchButton, spinner, mainMenu, multiplayerView, delegate, isPopOver, inviteFriendsButton, inviteFriendsController;


- (id)initWithMainMenu:(MainMenu *)menu withAppDelegate:(ApplicationDelegate *)appDelegate isPopOver:(BOOL)popOver withMultiplayerView:(MultiplayerView*)multiplayer;
{
	NSString* device = [UIDevice currentDevice].model;
	device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];

	if ([device isEqualToString:@"iPhone"])
		device = @"";

	if (!popOver)
		self = [super initWithNibName:@"JoinMatchView" bundle:nil];
	else
		self = [super initWithNibName:@"JoinMatchViewPopover" bundle:nil];

	if (self)
	{
		iPad = [device isEqualToString:@"iPad"];
		
		self.mainMenu = menu;
		self.multiplayerView = multiplayer;
		self.delegate = appDelegate;
		self.isPopOver = popOver;

		self.changeMinimumNumberOfHumanPlayers.minimumValue = 1;
		self.changeMaximumNumberOfHumanPlayers.minimumValue = 1;
		self.changeNumberOfAIPlayers.minimumValue = 0;
	}

    return self;
}

- (void) dealloc
{
	NSLog(@"%@ deallocated", self.class);
}

- (void)viewWillAppear:(BOOL)animated
{
	if (self.inviteFriendsButton)
	{
		[[GKLocalPlayer localPlayer] loadFriendsWithCompletionHandler:^(NSArray* friends, NSError* error)
		{
			self.inviteFriendsButton.hidden = [friends count] == 0;
		}];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)joinMatchButtonPressed:(id)sender
{
	if (changeMaximumNumberOfHumanPlayers.value == 0 &&
		changeMinimumNumberOfHumanPlayers.value == 0 &&
		changeNumberOfAIPlayers.value == 0)
	{
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Join Match" message:@"I cannot join a match with no opponents!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];

		[alert show];
	}

	changeMaximumNumberOfHumanPlayers.enabled = NO;
	changeMinimumNumberOfHumanPlayers.enabled = NO;
	changeNumberOfAIPlayers.enabled = NO;

	if (changeMaximumNumberOfHumanPlayers.value == 0)
		[SingleplayerView startGameWithOpponents:changeNumberOfAIPlayers.value withNavigationController:self.navigationController withAppDelegate:self.delegate withMainMenu:self.mainMenu];
	else
	{
		MultiplayerView* multiplayerViewLocal = self.multiplayerView;
		[multiplayerViewLocal.popoverController dismissPopoverAnimated:YES];
		
		GKMatchRequest *request = [[GKMatchRequest alloc] init];
		request.minPlayers = changeMinimumNumberOfHumanPlayers.value + 1;
		request.maxPlayers = changeMaximumNumberOfHumanPlayers.value + 1;

		NSMutableArray* friendsToInvite = [NSMutableArray array];

		for (GKPlayer* player in friendIDs)
			[friendsToInvite addObject:player.playerID];

		request.playersToInvite = friendsToInvite;

		int group = 0;

		if (changeNumberOfAIPlayers.value > 0)
			group |= kAI_Human;
		else
			group |= kNo_AIs;

		switch ((int)changeNumberOfAIPlayers.value)
		{
			case 1: group |= kAI_1;
				break;
			case 2: group |= kAI_2;
				break;
			case 3: group |= kAI_3;
				break;
			case 4: group |= kAI_4;
				break;
			case 5: group |= kAI_5;
				break;
			case 6: group |= kAI_6;
				break;
			case 7: group |= kAI_7;
				break;
			case 8: group |= kAI_8;
				break;
			default:
				NSLog(@"Error selecting AI group!");
				break;
		}

		request.playerGroup = group; // AI Player Numbers hack...

		self.spinner.hidden = NO;
		[self.spinner startAnimating];

		[GKTurnBasedMatch findMatchForRequest:request withCompletionHandler:^(GKTurnBasedMatch *match, NSError *error)
		 {
			 if (match)
			 {
				 if (self->iPad)
				 {
					 self.spinner.hidden = YES;
					 self.changeNumberOfAIPlayers.enabled = YES;
					 self.changeMaximumNumberOfHumanPlayers.enabled = YES;
					 self.changeMinimumNumberOfHumanPlayers.enabled = YES;

					 [multiplayerViewLocal populateScrollView:request];
				 }
				 else
				 {
					 [match loadMatchDataWithCompletionHandler:^(NSData* matchdata, NSError* error2)
					  {
						  ApplicationDelegate* delegateLocal = self.delegate;

						  NSLog(@"Join Match View: Match Data Retrieved SHA1 Hash: %@", [delegateLocal sha1HashFromData:matchdata]);

						  DiceGame* newGame = [[DiceGame alloc] initWithAppDelegate:delegateLocal];
						  GameKitGameHandler* handler = [[GameKitGameHandler alloc] initWithDiceGame:newGame withLocalPlayer:nil withRemotePlayers:nil withMatch:match];

						  MultiplayerMatchData* mmd = [[MultiplayerMatchData alloc] initWithData:matchdata
																					  withRequest:request
																						withMatch:match
																					  withHandler:handler];

						  if (!mmd)
						  {
							  NSLog(@"Failed to load multiplayer data from game center: %@!\n", [error2 description]);
							  return;
						  }

						  [delegateLocal.listener addGameKitGameHandler:handler];

						  [newGame updateGame:[mmd theGame]];

						  DiceLocalPlayer* localPlayer = nil;
						  NSMutableArray* remotePlayers = [[NSMutableArray alloc] init];

						  for (id<Player> player in newGame.players)
						  {
							  if ([player isKindOfClass:DiceLocalPlayer.class])
								  localPlayer = player;
							  else
								  [remotePlayers addObject:player];
						  }

						  [handler setLocalPlayer:localPlayer];
						  [handler setRemotePlayers:remotePlayers];

						  void (^quitHandlerFullScreen)(void) =^
						  {
							  [multiplayerViewLocal.navigationController popToViewController:self->multiplayerView animated:YES];
						  };

						  UIViewController *gameView = [[PlayGameView alloc] initWithGame:newGame withQuitHandler:[quitHandlerFullScreen copy]];

						  [self.navigationController pushViewController:gameView animated:YES];
					  }];
				 }
			 }
			 else
			 {
				 NSLog(@"No match returned from game center! %@\n", error.description);

				 if (error.code == 6)
				 {
					 MainMenu* menu = self.mainMenu;
					 menu.multiplayerEnabled = NO;
					 
					 [menu.navigationController popToViewController:menu animated:YES];

					 [[[UIAlertView alloc] initWithTitle:@"Multiplayer Disabled" message:@"Unfortunately, game center was just disabled.  This can be caused by numerous things including lack of internet connectivity or a bug in Game Center.  Please reauthenticate with game center to continue playing multiplayer." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
				 }
			 }
		 }];
	}
}

-(IBAction)stepperValueChanged:(UIStepper*)sender
{
	if (sender.value <= 0)
		[sender setValue:0];
	else if ((changeMaximumNumberOfHumanPlayers.value + changeNumberOfAIPlayers.value) > 7)
	{
		[sender setValue:(sender.value - 1)];

		[[[UIAlertView alloc] initWithTitle:@"Maximum Players" message:@"Unfortunately, there is a maximum of 7 opponents in multiplayer (AI and Human combined)" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
	}

	if (sender == changeMaximumNumberOfHumanPlayers &&
		changeMaximumNumberOfHumanPlayers.value < changeMinimumNumberOfHumanPlayers.value)
		changeMinimumNumberOfHumanPlayers.value = changeMaximumNumberOfHumanPlayers.value;

	if (sender == changeMinimumNumberOfHumanPlayers &&
		changeMinimumNumberOfHumanPlayers.value > changeMaximumNumberOfHumanPlayers.value)
		changeMaximumNumberOfHumanPlayers.value = changeMinimumNumberOfHumanPlayers.value;

	[maximumNumberOfHumanPlayers setText:[NSString stringWithFormat:@"%i", (int)changeMaximumNumberOfHumanPlayers.value]];
	[minimumNumberOfHumanPlayers setText:[NSString stringWithFormat:@"%i", (int)changeMinimumNumberOfHumanPlayers.value]];
	[numberOfAIPlayers setText:[NSString stringWithFormat:@"%i", (int)changeNumberOfAIPlayers.value]];

	changeMaximumNumberOfHumanPlayers.maximumValue = 7 - changeNumberOfAIPlayers.value;
	changeMinimumNumberOfHumanPlayers.maximumValue = changeMaximumNumberOfHumanPlayers.maximumValue;
	changeNumberOfAIPlayers.maximumValue = 7 - changeMaximumNumberOfHumanPlayers.value;
}

-(IBAction)inviteFriendsButtonPressed:(id)sender
{
	InviteFriendsView* ifv = [[InviteFriendsView alloc] init:iPad withQuitHandler:^(InviteFriendsView* view)
							  {
								  self->friendIDs = view->selectedFriends;

								  self.inviteFriendsController = nil;
							  } maxSelection:changeMaximumNumberOfHumanPlayers.value];

	if (friendIDs)
		ifv->selectedFriends = friendIDs;

	[self.navigationController pushViewController:ifv animated:YES];
}

@end
