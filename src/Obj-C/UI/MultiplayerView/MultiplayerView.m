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
#import <objc/runtime.h>

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
		self.handlerArray = [[NSMutableArray alloc] init];
		self.miniGamesViewArray = [[NSMutableArray alloc] init];
		self.playGameViews = [[NSMutableArray alloc] init];

		if (iPad)
			self.joinMatchPopoverViewController = [[JoinMatchView alloc] initWithMainMenu:menu withAppDelegate:delegate isPopOver:YES withMultiplayerView:self];
    }

    return self;
}

- (void) dealloc
{
	NSLog(@"%@ deallocated", self.class);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.navigationController.navigationBarHidden = NO;

	self.navigationController.title = @"Multiplayer Matches";
	self.navigationItem.title = @"Multiplayer Matches";
}

- (void)viewWillAppear:(BOOL)animated
{
	self.navigationController.navigationBarHidden = NO;

	for (UIView* view in self.gamesScrollView.subviews)
		[view removeFromSuperview];

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
	ApplicationDelegate* delegate = self.appDelegate;

	[GKTurnBasedMatch loadMatchesWithCompletionHandler:^(NSArray *matches, NSError *error)
	 {
		 for (GKTurnBasedMatch* match in matches)
		 {
			 if (![delegate.listener handlerForMatch:match])
			 {
				 // the new match

				 [match loadMatchDataWithCompletionHandler:^(NSData* matchdata, NSError* error2)
				  {
					  NSLog(@"Multiplayer Match View: Updated Match Data Retrieved (iPad) SHA1 Hash: %@", [delegate sha1HashFromData:matchdata]);

					  DiceGame* newGame = [[DiceGame alloc] initWithAppDelegate:delegate];

					  GameKitGameHandler* handler = [delegate.listener handlerForMatch:match];

					  if (!handler)
					  {
						  handler = [[GameKitGameHandler alloc] initWithDiceGame:newGame withLocalPlayer:nil withRemotePlayers:nil withMatch:match];
						  [delegate.listener addGameKitGameHandler:handler];
					  }
					  else
						  handler.localGame = newGame;

					  MultiplayerMatchData* mmd = [[MultiplayerMatchData alloc] initWithData:matchdata
																				  withRequest:request
																					withMatch:match
																				  withHandler:handler];

					  if (!mmd)
					  {
						  NSLog(@"Failed to load multiplayer data from game center: %@!\n", [error2 description]);
						  return;
					  }

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
						  [self.navigationController popToViewController:self animated:YES];
					  };

					  UIViewController *gameView = [[PlayGameView alloc] initWithGame:newGame withQuitHandler:[quitHandlerFullScreen copy]  withCustomMainView:YES];

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
		 for (int matchNumber = 0;matchNumber < [matches count];matchNumber++)
		 {
			 GKTurnBasedMatch* match = [matches objectAtIndex:matchNumber];

			 [match loadMatchDataWithCompletionHandler:^(NSData* matchData, NSError* matchDataError)
			  {
				  ApplicationDelegate* delegate = [UIApplication sharedApplication].delegate;
				  NSLog(@"Multiplayer Match View: Updated Match Data (iPad/Populate) SHA1 Hash: %@", [delegate sha1HashFromData:matchData]);

				  DiceGame* game = [[DiceGame alloc] initWithAppDelegate:delegate];

				  GameKitGameHandler* handler = [delegate.listener handlerForMatch:match];

				  if (!handler)
				  {
					  handler = [[GameKitGameHandler alloc] initWithDiceGame:game withLocalPlayer:nil withRemotePlayers:nil withMatch:match];
					  [delegate.listener addGameKitGameHandler:handler];
				  }
				  else
					  handler.localGame = game;

				  MultiplayerMatchData* mmd = [[MultiplayerMatchData alloc] initWithData:matchData
																			  withRequest:nil
																				withMatch:match
																			  withHandler:handler];

				  if (!mmd || ![mmd theGame])
				  {
					  NSLog(@"Failed to load multiplayer data from game center: %@!\n", [matchDataError description]);
					  return;
				  }

				  [mmd.theGame.gameState decodePlayers:match withHandler:handler];
				  mmd.theGame.players = [NSArray arrayWithArray:mmd.theGame.gameState.players];
				  mmd.theGame.gameState.players = mmd.theGame.players;

				  [game updateGame:[mmd theGame]];

				  [self->miniGamesViewArray addObject:game];
				  [self->handlerArray addObject:handler];

				  void (^quitHandler)(void) =^
				  {
					  UIAlertView* view = [[UIAlertView alloc] initWithTitle:@"Delete Game" message:@"Are you sure you want to permanently delete this game? If you delete it, you will never be able to access it again." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
					  [view.LDContext setObject:match forKey:@"Match"];
					  [view show];
				  };

				  PlayGameView* playGameView = [[PlayGameView alloc] initWithGame:game withQuitHandler:[quitHandler copy]  withCustomMainView:YES];
				  
				  [playGameView.fullscreenButton addTarget:self action:@selector(playMatchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

				  playGameView.view.frame = CGRectMake(matchNumber * (playGameView.view.frame.size.width + 10), 0, playGameView.view.frame.size.width, playGameView.view.frame.size.height);

				  [self.gamesScrollView addSubview:playGameView.view];
				  [self->playGameViews addObject:playGameView];
			  }];
		 }

		 [self.gamesScrollView setContentSize:CGSizeMake([matches count] * 330, 568)];
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
		 for (int matchNumber = 0;matchNumber < [matches count];matchNumber++)
		 {
			 GKTurnBasedMatch* match = [matches objectAtIndex:matchNumber];

			 [match loadMatchDataWithCompletionHandler:^(NSData* matchData, NSError* matchDataError)
			  {
				  ApplicationDelegate* delegate = [UIApplication sharedApplication].delegate;
				  NSLog(@"Multiplayer Match View: Updated Match Data (iPhone/Populate) SHA1 Hash: %@", [delegate sha1HashFromData:matchData]);

				  DiceGame* game = [[DiceGame alloc] initWithAppDelegate:delegate];

				  GameKitGameHandler* handler = [delegate.listener handlerForMatch:match];

				  if (!handler)
				  {
					  handler = [[GameKitGameHandler alloc] initWithDiceGame:game withLocalPlayer:nil withRemotePlayers:nil withMatch:match];
					  [delegate.listener addGameKitGameHandler:handler];
				  }
				  else
					  handler.localGame = game;

				  MultiplayerMatchData* mmd = [[MultiplayerMatchData alloc] initWithData:matchData
																			  withRequest:nil
																				withMatch:match
																			  withHandler:handler];

				  if (!mmd)
				  {
					  NSLog(@"Failed to load multiplayer data from game center: %@!\n", [matchDataError description]);
					  return;
				  }

				  [mmd.theGame.gameState decodePlayers:match withHandler:handler];
				  mmd.theGame.players = [NSArray arrayWithArray:mmd.theGame.gameState.players];
				  mmd.theGame.gameState.players = mmd.theGame.players;

				  [game updateGame:[mmd theGame]];

				  [self->miniGamesViewArray addObject:game];
				  [self->handlerArray addObject:handler];

				  UILabel* matchName = [[UILabel alloc] init];
				  UILabel* aiMatchInfo = [[UILabel alloc] init];
				  UILabel* turnInfo = [[UILabel alloc] init];
				  UILabel* timeoutInfo = [[UILabel alloc] init];
				  UIButton* playMatch = [[UIButton alloc] init];
				  UIButton* deleteMatch = [[UIButton alloc] init];

				  UIImageView* whiteBar = [[UIImageView alloc] init];

				  CGRect frame = CGRectMake(15, 0, self.gamesScrollView.frame.size.width - 15, 30);
				  matchName.frame = frame;
				  matchName.text = [game gameNameString];
				  matchName.textColor = [UIColor whiteColor];

				  frame.origin.y += 30;
				  aiMatchInfo.frame = frame;
				  aiMatchInfo.text = [game AINameString];
				  aiMatchInfo.textColor = [UIColor whiteColor];


				  frame.origin.y += 30;
				  turnInfo.frame = frame;
				  turnInfo.text = @"It's ";
				  turnInfo.textColor = [UIColor whiteColor];

				  NSString* currentPlayerName = [[[[game gameState] playerStates] objectAtIndex:[[game gameState] currentTurn]] playerName];

				  if (!currentPlayerName)
					  currentPlayerName = @"another player";

				  if ([currentPlayerName isEqualToString:[[GKLocalPlayer localPlayer] alias]])
				  {
					  turnInfo.text = [turnInfo.text stringByAppendingString:@"your"];
					  [turnInfo setTextColor:[UIColor redColor]];
				  }
				  else
					  turnInfo.text = [turnInfo.text stringByAppendingString:currentPlayerName];

				  turnInfo.text = [turnInfo.text stringByAppendingString:@"'s turn!"];

				  frame.origin.y += 30;
				  timeoutInfo.frame = frame;
				  timeoutInfo.text = @"Timeout until Forfeit: ";
				  timeoutInfo.textColor = [UIColor whiteColor];

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

				  frame.origin.y += 30;
				  frame.size.width /= 2.0;
				  frame.size.width -= 20;
				  playMatch.frame = frame;

				  [playMatch setTitle:@"Play Match!" forState:UIControlStateNormal];

				  if (match.status == GKTurnBasedMatchStatusEnded)
					  playMatch.titleLabel.text = @"View Match";

				  [playMatch setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
				  [playMatch setTag:matchNumber];
				  [playMatch addTarget:self action:@selector(playMatchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

				  frame.origin.x += frame.size.width;
				  deleteMatch.frame = frame;
				  frame.size.width += 20;
				  [deleteMatch setTitle:@"Remove Match" forState:UIControlStateNormal];
				  [deleteMatch setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
				  [deleteMatch.LDContext setObject:match forKey:@"Match"];
				  [deleteMatch addTarget:self action:@selector(deleteMatchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

				  frame.origin.y += 30;
				  frame.origin.x -= frame.size.width;
				  frame.size.width *= 2.0;
				  frame.size.width -= 15;
				  frame.size.height = 3;

				  [whiteBar setImage:[PlayGameView barImage]];
				  whiteBar.frame = frame;

				  CGRect viewFrame = CGRectMake(15, matchNumber * 30 * 6, self.gamesScrollView.frame.size.width - 15, 180);

				  UIView* container = [[UIView alloc] initWithFrame:viewFrame];

				  [container addSubview:matchName];
				  [container addSubview:aiMatchInfo];
				  [container addSubview:turnInfo];
				  [container addSubview:timeoutInfo];
				  [container addSubview:playMatch];
				  [container addSubview:deleteMatch];
				  [container addSubview:whiteBar];

				  [self.gamesScrollView addSubview:container];
				  [self.playGameViews addObject:container];
			  }];
		 }

		 [self.gamesScrollView setContentSize:CGSizeMake(self.gamesScrollView.frame.size.width, [matches count] * 30 * 6)];
	 }];
}

- (void)playMatchButtonPressed:(id)sender
{
	int gameIndex = (int)[(UIButton*)sender tag];

	__block MultiplayerView* multiplayerView = self;
	void (^quitHandler)(void) =^
	{
		[multiplayerView.navigationController popToViewController:multiplayerView animated:YES];
	};

	PlayGameView* playGameView = [[PlayGameView alloc] initWithGame:[miniGamesViewArray objectAtIndex:gameIndex] withQuitHandler:[quitHandler copy]];

	[self.navigationController pushViewController:playGameView animated:YES];

	[playGameView.quitButton setTitle:@"Back" forState:UIControlStateNormal];
}

- (void)deleteMatchButtonPressed:(id)sender
{
	GKTurnBasedMatch* match = [((NSObject*)sender).LDContext objectForKey:@"Match"];

	ApplicationDelegate* delegate = self.appDelegate;

	GameKitGameHandler* handler = [delegate.listener handlerForMatch:match];

	if (handler)
	{
		DiceGame* game = [handler localGame];

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
			[handler playerQuitMatch:player withRemoval:NO];

		for (GKTurnBasedParticipant* participant in match.participants)
			participant.matchOutcome = GKTurnBasedMatchOutcomeQuit;

		[match removeWithCompletionHandler:^(NSError* error)
		 {
			 if (error)
				 NSLog(@"Error Removing Invalid Match: %@", error.description);
		 }];

		int handlerIndex = 0;
		for (;handlerIndex < [handlerArray count];handlerIndex++)
		{
			if ([handlerArray objectAtIndex:handlerIndex] == handler)
				break;
		}

		if (iPad)
			[[(PlayGameView*)[playGameViews objectAtIndex:handlerIndex] view] removeFromSuperview];
		else
			[(UIView*)[playGameViews objectAtIndex:handlerIndex]removeFromSuperview];

		[delegate.listener removeGameKitGameHandler:handler];
		[handlerArray removeObjectAtIndex:handlerIndex];
		if ([playGameViews count] > 0)
			[playGameViews removeObjectAtIndex:handlerIndex];
		
		[miniGamesViewArray removeObjectAtIndex:handlerIndex];

		if (iPad)
		{
			if ([handlerArray count] == 0)
				gamesScrollView.contentSize = CGSizeMake(0, gamesScrollView.frame.size.height);
			else
				gamesScrollView.contentSize = CGSizeMake(gamesScrollView.contentSize.width - 330, gamesScrollView.frame.size.height);
		}
		else
			gamesScrollView.contentSize = CGSizeMake(gamesScrollView.frame.size.width, [miniGamesViewArray count] * 30 * 6);

		if (handlerIndex == [handlerArray count])
			return; // Nothing more to do

		[UIView animateWithDuration:0.25 animations:^(void)
		 {
			 for (int i = handlerIndex;i < [self->handlerArray count];i++)
			 {
				 CGRect currentFrame;

				 if (self->iPad)
				 {
					 currentFrame = ((PlayGameView*)[self->playGameViews objectAtIndex:i]).view.frame;

					 currentFrame.origin.x -= currentFrame.size.width;

					 ((PlayGameView*)[self->playGameViews objectAtIndex:i]).view.frame = currentFrame;
				 }
				 else
				 {
					 currentFrame = ((UIView*)[self->playGameViews objectAtIndex:i]).frame;

					 currentFrame.origin.y -= 180;

					 ((UIView*)[self->playGameViews objectAtIndex:i]).frame = currentFrame;
				 }
			 }
		 }];
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
	self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.joinMatchPopoverViewController];
	self.popoverController.popoverContentSize = CGSizeMake(320,320);

	[self.popoverController presentPopoverFromRect:joinMatchButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

- (void)iPhoneJoinMatchButtonPressed
{
	[self.navigationController pushViewController:[[JoinMatchView alloc] initWithMainMenu:self.mainMenu withAppDelegate:self.appDelegate isPopOver:NO withMultiplayerView:self]  animated:YES];
}

- (IBAction)scrollToTheFarRightButtonPressed:(id)sender
{
	
}

@end
