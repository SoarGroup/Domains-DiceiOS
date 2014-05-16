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

@synthesize joinMatchButton, gamesScrollView, scrollToTheFarRightButton, mainMenu, appDelegate, popoverController, joinMatchPopoverViewController, joinSpinner;

@synthesize miniGamesViewArray, playGameViews, handlerArray;

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

		if (iPad)
			joinMatchPopoverViewController = [[JoinMatchView alloc] initWithMainMenu:self.mainMenu withAppDelegate:self.appDelegate isPopOver:YES withMultiplayerView:self];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.navigationController.navigationBarHidden = NO;

	self.navigationController.title = @"Multiplayer Matches";
	self.navigationItem.title = @"Multiplayer Matches";

	if (iPad)
	{
		[self iPadPopulateScrollView];

		joinMatchPopoverViewController.spinner = self.joinSpinner;
	}
	else
		[self iPhonePopulateScrollView];
}

- (void)joinedNewMatch:(GKMatchRequest*)request
{
	[GKTurnBasedMatch loadMatchesWithCompletionHandler:^(NSArray *matches, NSError *error)
	 {
		 for (GKTurnBasedMatch* match in matches)
		 {
			 if (![self.appDelegate.listener handlerForMatch:match])
			 {
				 // the new match

				 [match loadMatchDataWithCompletionHandler:^(NSData* matchdata, NSError* error2)
				  {
					  MultiplayerMatchData* mmd = [[[MultiplayerMatchData alloc] initWithData:matchdata] autorelease];

					  if (!mmd && error2)
					  {
						  NSLog(@"Failed to load multiplayer data from game center: %@!\n", [error2 description]);
						  return;
					  }

					  DiceGame* newGame = [[DiceGame alloc] initWithAppDelegate:self.appDelegate];
					  GameKitGameHandler* handler = [[[GameKitGameHandler alloc] initWithDiceGame:newGame withLocalPlayer:nil withRemotePlayers:nil] autorelease];

					  if (mmd)
					  {
						  [newGame updateGame:[mmd theGame]];

						  for (id<Player> player in [newGame players])
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
					  }
					  else
					  {
						  // New Match
						  int AICount = (int)request.playerGroup;
						  int humanCount = (int)[match.participants count];
						  int currentHumanCount = 0;

						  NSLock* lock = [[[NSLock alloc] init] autorelease];

						  int totalPlayerCount = AICount + humanCount;

						  for (int i = 0;i < totalPlayerCount;i++)
						  {
							  BOOL isAI = (BOOL)arc4random_uniform(2);

							  if (isAI && AICount > 0)
							  {
								  [newGame addPlayer:[[SoarPlayer alloc] initWithGame:newGame connentToRemoteDebugger:NO lock:lock withGameKitGameHandler:handler]];

								  AICount--;
							  }
							  else
							  {
								  GKTurnBasedParticipant* participant = [match.participants objectAtIndex:currentHumanCount];
								  currentHumanCount++;

								  if ([[[GKLocalPlayer localPlayer] playerID] isEqualToString:[participant playerID]])
									  [newGame addPlayer:[[DiceLocalPlayer alloc] initWithName:[participant playerID] withHandler:handler withParticipant:participant]];
								  else
									  [newGame addPlayer:[[DiceRemotePlayer alloc] initWithGameKitParticipant:participant withGameKitGameHandler:handler]];
							  }
						  }
					  }

					  DiceLocalPlayer* localPlayer = nil;
					  NSMutableArray* remotePlayers = [[[NSMutableArray alloc] init] autorelease];

					  for (id<Player> player in newGame.players)
					  {
						  if ([player isKindOfClass:DiceLocalPlayer.class])
							  localPlayer = player;
						  else
							  [remotePlayers addObject:player];
					  }

					  [handler setLocalPlayer:localPlayer];
					  [handler setRemotePlayers:remotePlayers];

					  [self.appDelegate.listener addGameKitGameHandler:handler];

					  void (^quitHandlerFullScreen)(void) =^
					  {
						  [self.navigationController popToViewController:self animated:YES];
					  };

					  UIViewController *gameView = [[[PlayGameView alloc] initWithGame:newGame withQuitHandler:[[quitHandlerFullScreen copy] autorelease]] autorelease];

					  CGRect newFrame = gameView.view.frame;
					  newFrame.origin.x = gameView.view.frame.size.width * [self.playGameViews count];
					  gameView.view.frame = newFrame;

					  [self.miniGamesViewArray addObject:newGame];
					  [self.playGameViews addObject:gameView];
					  [self.handlerArray addObject:handler];

					  [self.gamesScrollView addSubview:gameView.view];

					  return;
				  }];
			 }
		 }
	 }];
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

	GameKitGameHandler* handler = [self.appDelegate.listener handlerForMatch:match];

	if (handler)
	{
		DiceGame* game = [handler getDiceGame];

		id<Player> player = nil;

		for (id<Player> p in [game players])
		{
			if ([p isKindOfClass:DiceLocalPlayer.class])
			{
				player = p;
				break;
			}
		}

		if (player)
		{
			[handler playerQuitMatch:player withRemoval:YES];

			int handlerIndex = 0;
			for (;handlerIndex < [handlerArray count];handlerIndex++)
			{
				if ([handlerArray objectAtIndex:handlerIndex] == handler)
					break;
			}

			[[(PlayGameView*)[playGameViews objectAtIndex:handlerIndex] view] removeFromSuperview];

			[self.appDelegate.listener removeGameKitGameHandler:handler];
			[handlerArray removeObjectAtIndex:handlerIndex];
			[playGameViews removeObjectAtIndex:handlerIndex];
			[miniGamesViewArray removeObjectAtIndex:handlerIndex];

			if ([handlerArray count] == 0)
				gamesScrollView.contentSize = CGSizeMake(0, gamesScrollView.frame.size.height);
			else
				gamesScrollView.contentSize = CGSizeMake(gamesScrollView.contentSize.width - ((UIView*)[playGameViews objectAtIndex:0]).frame.size.width, gamesScrollView.frame.size.height);

			if (handlerIndex == [handlerArray count])
				return; // Nothing more to do

			[UIView animateWithDuration:0.25 animations:^(void)
			 {
				 for (int i = handlerIndex;i < [handlerArray count];i++)
				 {
					 CGRect currentFrame = ((PlayGameView*)[playGameViews objectAtIndex:i]).view.frame;
					 currentFrame.origin.x -= currentFrame.size.width;

					 ((PlayGameView*)[playGameViews objectAtIndex:i]).view.frame = currentFrame;
				 }
			 }];
		}
	}
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
	self.popoverController = [[[UIPopoverController alloc] initWithContentViewController:self.joinMatchPopoverViewController] autorelease];
	self.popoverController.popoverContentSize = CGSizeMake(320,320);

	[self.popoverController presentPopoverFromRect:joinMatchButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

- (void)iPhoneJoinMatchButtonPressed
{
	[self.navigationController pushViewController:[[[JoinMatchView alloc] initWithMainMenu:self.mainMenu withAppDelegate:self.appDelegate isPopOver:NO withMultiplayerView:self] autorelease] animated:YES];
}

- (IBAction)scrollToTheFarRightButtonPressed:(id)sender
{
	
}

@end
