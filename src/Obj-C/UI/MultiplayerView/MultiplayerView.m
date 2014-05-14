//
//  MultiplayerView.m
//  UM Liars Dice
//
//  Created by Alex Turner on 9/23/13.
//
//

#import "MultiplayerView.h"
#import "MultiplayerMatchData.h"
#import "PlayGameView.h"
#import "JoinMatchView.h"
#import "SoarPlayer.h"
#import "ApplicationDelegate.h"
#import <GameKit/GameKit.h>

@interface MultiplayerView ()

- (void)iPadPopulateScrollView;
- (void)iPhonePopulateScrollView;

- (void)iPadJoinMatchButtonPressed;
- (void)iPhoneJoinMatchButtonPressed;

@end

@implementation MultiplayerView

@synthesize joinMatchButton, gamesScrollView, scrollToTheFarRightButton, mainMenu, appDelegate;

- (id)initWithMainMenu:(MainMenu *)menu withAppDelegate:(ApplicationDelegate *)delegate
{
    NSString* device = [UIDevice currentDevice].model;
	device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];

	if ([device isEqualToString:@"iPhone"])
		device = @"";

	self = [super initWithNibName:[@"MultiplayerView" stringByAppendingString:device] bundle:nil];

    if (self)
	{
        iPad = [device isEqualToString:@"iPad"];
		self.mainMenu = menu;
		self.appDelegate = delegate;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.navigationController.navigationBarHidden = NO;

	self.navigationController.title = @"Multiplayer Matches";
	self.navigationItem.title = @"Back";

	if (iPad)
		[self iPadPopulateScrollView];
	else
		[self iPhonePopulateScrollView];
}

- (void)iPadPopulateScrollView
{
	[GKTurnBasedMatch loadMatchesWithCompletionHandler:^(NSArray *matches, NSError *error)
	 {
		 NSNumber** matchNumber = (NSNumber**)malloc(sizeof(NSNumber*));
		 *matchNumber = [[NSNumber alloc] initWithInt:-1];
		 NSLock* lock = [[NSLock alloc] init];

		 for (GKTurnBasedMatch* match in matches)
		 {
			 [match loadMatchDataWithCompletionHandler:^(NSData* matchData, NSError* matchDataError)
			  {
				  MultiplayerMatchData* data = [[[MultiplayerMatchData alloc] initWithData:matchData] autorelease];

				  DiceGame* game = [[DiceGame alloc] initWithAppDelegate:self.appDelegate];
				  GameKitGameHandler* handler = [[[GameKitGameHandler alloc] initWithDiceGame:game withLocalPlayer:nil withRemotePlayers:nil] autorelease];
				  [self.appDelegate.listener addGameKitGameHandler:handler];

				  [game updateGame:[data theGame]];

				  for (id<Player> player in [game players])
				  {
					  [player setHandler:handler];

					  if (![player isKindOfClass:SoarPlayer.class])
					  {
						  for (GKTurnBasedParticipant* participant in match.participants)
						  {
							  if ([[player getName] isEqualToString:[participant playerID]])
							  {
								  [player setParticipant:participant];
								  break;
							  }
						  }
					  }
				  }

				  [miniGamesViewArray addObject:game];
				  [handlerArray addObject:handler];

				  int matchNumberCopy = -1;
				  [lock lock];
				  *matchNumber = [NSNumber numberWithInt:([*matchNumber intValue] + 1)];
				  matchNumberCopy = [*matchNumber intValue];
				  [lock unlock];

				  assert(matchNumberCopy != -1);

				  void (^quitHandler)(void) =^
				  {
					  UIAlertView* view = [[[UIAlertView alloc] initWithTitle:@"Delete Game" message:@"Are you sure you want to permanently delete this game? If you delete it, you will never be able to access it again." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease];
					  [view setValue:match forKey:@"Match"];
					  [view show];
				  };

				  PlayGameView* playGameView = [[PlayGameView alloc] initWithGame:game withQuitHandler:quitHandler withCustomMainView:YES];
				  [playGameView.fullscreenButton addTarget:self action:@selector(playMatchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

				  playGameView.view.frame = CGRectMake(matchNumberCopy * (playGameView.view.frame.size.width + 10), 0, playGameView.view.frame.size.width, playGameView.view.frame.size.height);

				  [self.gamesScrollView addSubview:playGameView.view];
				  [playGameViews addObject:playGameView];
			  }];
		 }

		 BOOL done = NO;
		 while (!done)
		 {
			 [lock lock];
			 if ([*matchNumber intValue] == ([matches count]-1))
				 done = YES;
			 [lock unlock];
		 }

		 if ([matches count] > 0)
			 [self.gamesScrollView setContentSize:CGSizeMake([matches count] * (((PlayGameView*)[playGameViews objectAtIndex:0]).view.frame.size.width + 10), self.gamesScrollView.frame.size.height)];

		 [lock release];
		 [*matchNumber release];
		 free(matchNumber);
	 }];
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1) // Yes
		[self deleteMatchButtonPressed:alertView];
}

- (void)timerUpdateMethod:(NSTimer*)timer
{
	if (iPad)
		[self iPadPopulateScrollView];
	else
		[self iPhonePopulateScrollView];
}

- (void)iPhonePopulateScrollView
{
	[GKTurnBasedMatch loadMatchesWithCompletionHandler:^(NSArray *matches, NSError *error)
	 {
		 NSNumber** matchNumber = (NSNumber**)malloc(sizeof(NSNumber*));
		 *matchNumber = [[NSNumber alloc] initWithInt:-1];
		 NSLock* lock = [[NSLock alloc] init];

		 for (GKTurnBasedMatch* match in matches)
		 {
			 [match loadMatchDataWithCompletionHandler:^(NSData* matchData, NSError* matchDataError)
			  {
				  MultiplayerMatchData* data = [[[MultiplayerMatchData alloc] initWithData:matchData] autorelease];

				  DiceGame* game = [[DiceGame alloc] initWithAppDelegate:self.appDelegate];
				  GameKitGameHandler* handler = [[[GameKitGameHandler alloc] initWithDiceGame:game withLocalPlayer:nil withRemotePlayers:nil] autorelease];
				  [self.appDelegate.listener addGameKitGameHandler:handler];

				  [game updateGame:[data theGame]];

				  for (id<Player> player in [game players])
				  {
					  [player setHandler:handler];

					  if (![player isKindOfClass:SoarPlayer.class])
					  {
						  for (GKTurnBasedParticipant* participant in match.participants)
						  {
							  if ([[player getName] isEqualToString:[participant playerID]])
							  {
								  [player setParticipant:participant];
								  break;
							  }
						  }
					  }
				  }

				  [miniGamesViewArray addObject:game];
				  [handlerArray addObject:handler];

				  int matchNumberCopy = -1;
				  [lock lock];
				  *matchNumber = [NSNumber numberWithInt:([*matchNumber intValue] + 1)];
				  matchNumberCopy = [*matchNumber intValue];
				  [lock unlock];

				  assert(matchNumberCopy != -1);

				  UILabel* matchName = [[[UILabel alloc] init] autorelease];
				  UILabel* gameInfo = [[[UILabel alloc] init] autorelease];
				  UILabel* turnInfo = [[[UILabel alloc] init] autorelease];
				  UILabel* timeoutInfo = [[[UILabel alloc] init] autorelease];
				  UIButton* playMatch = [[[UIButton alloc] init] autorelease];
				  UIButton* deleteMatch = [[[UIButton alloc] init] autorelease];

				  UIImageView* whiteBar = [[[UIImageView alloc] init] autorelease];

				  CGRect frame = CGRectMake(0, matchNumberCopy * 30 * 6, self.gamesScrollView.frame.size.width, 30);
				  matchName.frame = frame;
				  matchName.text = [game gameNameString];

				  frame.origin.y += 30;
				  gameInfo.frame = frame;
				  gameInfo.text = [game lastTurnInfo];

				  frame.origin.y += 30;
				  turnInfo.frame = frame;
				  turnInfo.text = @"It's ";

				  NSString* currentPlayerName = [[[[game gameState] playerStates] objectAtIndex:[[game gameState] currentTurn]] name];

				  if ([currentPlayerName isEqualToString:[[GKLocalPlayer localPlayer] displayName]])
				  {
					  turnInfo.text = [turnInfo.text stringByAppendingString:@"your"];
					  [turnInfo setTextColor:[UIColor redColor]];
				  }
				  else
					  turnInfo.text = [turnInfo.text stringByAppendingString:currentPlayerName];

				  turnInfo.text = [turnInfo.text stringByAppendingString:@" turn!"];

				  frame.origin.y += 30;
				  timeoutInfo.frame = frame;
				  timeoutInfo.text = @"Timeout until Forfeit: ";

				  if (![currentPlayerName isEqualToString:[[GKLocalPlayer localPlayer] displayName]])
					  timeoutInfo.text = @"2 days";
				  else
				  {
					  NSDate* timeout = [[match currentParticipant] timeoutDate];

					  NSTimeInterval timeInterval = [timeout timeIntervalSinceNow];

					  double value = -1.0;
					  NSString *type = @"second";

					  if (timeInterval > 60*60*24)
					  {
						  value = timeInterval / (60.0*60.0*24.0);

						  type = @"day";
					  }
					  else if (timeInterval > 60*60)
					  {
						  value = ceil(timeInterval / (60.0*60.0));

						  type = @"hour";
					  }
					  else if (timeInterval > 60)
					  {
						  value = ceil(timeInterval / (60.0));

						  type = @"minute";
					  }
					  else
						  value = ceil(timeInterval);

					  if (value > 60*60)
						  timeoutInfo.text = [timeoutInfo.text stringByAppendingString:[NSString stringWithFormat:@"%f %@%@", value, type, value > 1 ? @"s" : @""]];
					  else
						  timeoutInfo.text = [timeoutInfo.text stringByAppendingString:[NSString stringWithFormat:@"%i %@%@", (int)value, type, value > 1 ? @"s" : @""]];
				  }

				  frame.origin.y += 30;
				  frame.size.width /= 2.0;
				  playMatch.frame = frame;
				  playMatch.titleLabel.text = @"Play Match!";

				  if (match.status == GKTurnBasedMatchStatusEnded)
					  playMatch.titleLabel.text = @"View Match";

				  [playMatch.titleLabel setTextColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0]];
				  [playMatch setTag:matchNumberCopy];
				  [playMatch addTarget:self action:@selector(playMatchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

				  frame.origin.x += frame.size.width;
				  deleteMatch.frame = frame;
				  deleteMatch.titleLabel.text = @"Remove Match";
				  [deleteMatch.titleLabel setTextColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0]];
				  [deleteMatch setValue:match forKey:@"Removal"];
				  [deleteMatch addTarget:self action:@selector(deleteMatchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

				  frame.origin.y += 30;
				  frame.origin.x -= frame.size.width;
				  frame.size.width *= 2.0;

				  [whiteBar setImage:[PlayGameView barImage]];
				  whiteBar.frame = frame;

				  [self.gamesScrollView addSubview:matchName];
				  [self.gamesScrollView addSubview:gameInfo];
				  [self.gamesScrollView addSubview:turnInfo];
				  [self.gamesScrollView addSubview:timeoutInfo];
				  [self.gamesScrollView addSubview:playMatch];
				  [self.gamesScrollView addSubview:deleteMatch];
				  [self.gamesScrollView addSubview:whiteBar];
			  }];
		 }

		 BOOL done = NO;
		 while (!done)
		 {
			 [lock lock];
			 if ([*matchNumber intValue] == ([matches count]-1))
				 done = YES;
			 [lock unlock];
		 }

		 if ([matches count] > 0)
			 [self.gamesScrollView setContentSize:CGSizeMake(self.gamesScrollView.frame.size.width, [matches count] * 30 * 6)];

		 [lock release];
		 [*matchNumber release];
		 free(matchNumber);
	}];
}

- (void)playMatchButtonPressed:(id)sender
{
	int gameIndex = (int)[(UIButton*)sender tag];
	MultiplayerView* multiplayerView = self;

	void (^quitHandler)(void) =^
	{
		[multiplayerView.navigationController popToViewController:multiplayerView animated:YES];
	};

	PlayGameView* playGameView = [[[PlayGameView alloc] initWithGame:[miniGamesViewArray objectAtIndex:gameIndex] withQuitHandler:quitHandler] autorelease];

	[self.navigationController pushViewController:playGameView animated:YES];

	[playGameView.quitButton setTitle:@"Back" forState:UIControlStateNormal];
}

- (void)deleteMatchButtonPressed:(id)sender
{
	GKTurnBasedMatch* match = [(UIButton*)sender valueForKey:@"Removal"];

	[match removeWithCompletionHandler:^(NSError* error)
	{
		if (error)
			NSLog(@"Error removing match: %@\n", error.description);
	}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)joinMatchButtonPressed:(id)sender
{
	if (iPad)
		[self iPadJoinMatchButtonPressed];
	else
		[self iPhoneJoinMatchButtonPressed];
}

- (void)iPadJoinMatchButtonPressed
{

}

- (void)iPhoneJoinMatchButtonPressed
{
	[updateTimer invalidate];

	[self.navigationController pushViewController:[[[JoinMatchView alloc] initWithMainMenu:self.mainMenu withAppDelegate:self.appDelegate] autorelease] animated:YES];
}

- (IBAction)scrollToTheFarRightButtonPressed:(id)sender
{
	
}

- (void)player:(GKPlayer*)player didRequestMatchWithPlayers:(NSArray *)playerIDsToInvite
{
	// This is called from GAME CENTER not US.
}

- (void)player:(GKPlayer*)player matchEnded:(GKTurnBasedMatch *)match
{

}

- (void)player:(GKPlayer*)player receivedTurnEventForMatch:(GKTurnBasedMatch *)match didBecomeActive:(BOOL)didBecomeActive
{
	
}

@end
