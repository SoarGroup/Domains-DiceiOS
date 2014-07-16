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

- (void)iPadJoinMatchButtonPressed;
- (void)iPhoneJoinMatchButtonPressed;

@end

@implementation MultiplayerView

@synthesize joinMatchButton, gamesScrollView, scrollToTheFarRightButton, mainMenu, appDelegate, popoverController, joinMatchPopoverViewController, joinSpinner, containers;

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
		self.containers = [[NSMutableArray alloc] init];

		if (iPad)
			self.joinMatchPopoverViewController = [[JoinMatchView alloc] initWithMainMenu:menu withAppDelegate:delegate isPopOver:YES withMultiplayerView:self];
    }

    return self;
}

- (void) dealloc
{
	NSLog(@"%@ deallocated", self.class);

	[[NSNotificationCenter defaultCenter] removeObserver:self];
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

	[self.miniGamesViewArray removeAllObjects];
	[self.playGameViews removeAllObjects];
	[self.handlerArray removeAllObjects];

	if (iPad)
		joinMatchPopoverViewController.spinner = self.joinSpinner;

	[self populateScrollView];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateNotification:) name:@"UpdateUINotification" object:nil];
}

- (void)handleUpdateNotification:(NSNotification*)notification
{
	if (!notification || [[notification name] isEqualToString:@"UpdateUINotification"])
	{
		if (iPad)
		{
			for (int matchNumber = 0;matchNumber < [self.miniGamesViewArray count];matchNumber++)
			{
				DiceGame* game = [self.miniGamesViewArray objectAtIndex:matchNumber];

				ApplicationDelegate* delegate = appDelegate;
				GameKitGameHandler* handler = [delegate.listener handlerForGame:game];
				GKTurnBasedMatch* match = handler.match;

				void (^quitHandler)(void) =^
				{
					UIAlertView* view = [[UIAlertView alloc] initWithTitle:@"Delete Game" message:@"Are you sure you want to permanently delete this game? If you delete it, you will never be able to access it again." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
					[view.LDContext setObject:match forKey:@"Match"];
					[view show];
				};

				PlayGameView* playGameView = nil;

				for (UIView* container in playGameViews)
				{
					PlayGameView* gameView = [container.LDContext objectForKey:@"PlayGameView"];

					if (gameView && gameView.game == game)
					{
						playGameView = gameView;
						break;
					}
				}

				if (!playGameView)
				{
					playGameView = [[PlayGameView alloc] initWithGame:game withQuitHandler:[quitHandler copy]  withCustomMainView:YES ];

					playGameView.view.frame = CGRectMake(matchNumber * (playGameView.view.frame.size.width + 10), 0, playGameView.view.frame.size.width, playGameView.view.frame.size.height);

					playGameView.multiplayerView = self;

					CGRect containerFrame = playGameView.view.frame;
					containerFrame.size.height += 50;
					containerFrame.origin.y -= 50;
					UIView* container = [[UIView alloc] initWithFrame:containerFrame];

					playGameView.view.frame = CGRectMake(0, 50, playGameView.view.frame.size.width, playGameView.view.frame.size.height);

					[container addSubview:playGameView.view];

					playGameView.fullscreenButton.hidden = NO;
					playGameView.fullscreenButton.enabled = YES;
					playGameView.fullscreenButton.tag = matchNumber;

					[playGameView.fullscreenButton addTarget:self action:@selector(playMatchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

					[playGameView.quitButton setTitle:@"Delete" forState:UIControlStateNormal];

					container.clipsToBounds = YES;

					[container.LDContext setObject:playGameView forKey:@"PlayGameView"];

					[self.gamesScrollView addSubview:container];
					[self->playGameViews addObject:container];
				}
				else
					[playGameView updateUI];
			}

			[self.gamesScrollView setContentSize:CGSizeMake([self.miniGamesViewArray count] * 330, 568)];
		}
		else
		{
			for (UIView* view in gamesScrollView.subviews)
				[view removeFromSuperview];
			
			[self.playGameViews removeAllObjects];

			for (int matchNumber = 0;matchNumber < [self.miniGamesViewArray count];matchNumber++)
			{
				DiceGame* game = [self.miniGamesViewArray objectAtIndex:matchNumber];

				ApplicationDelegate* delegate = appDelegate;
				GameKitGameHandler* handler = [delegate.listener handlerForGame:game];
				GKTurnBasedMatch* match = handler.match;

				if (!match)
					continue;

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

				NSString* currentPlayerName = nil;

				if ([game.players count] > 0)
					currentPlayerName = [[game.players objectAtIndex:game.gameState.currentTurn] getDisplayName];

				if (!currentPlayerName || [currentPlayerName isEqualToString:@"Player"])
					currentPlayerName = @"another player";

				if ([game.players count] > 0 && [[game.players objectAtIndex:game.gameState.currentTurn] isKindOfClass:DiceLocalPlayer.class])
				{
					turnInfo.text = [turnInfo.text stringByAppendingString:@"your"];
					[turnInfo setTextColor:[UIColor redColor]];
				}
				else
					turnInfo.text = [turnInfo.text stringByAppendingFormat:@"%@'s", currentPlayerName];

				turnInfo.text = [turnInfo.text stringByAppendingString:@" turn!"];

				if (game.gameState.gameWinner)
					turnInfo.text = [NSString stringWithFormat:@"%@ won!", [game.gameState.gameWinner getDisplayName]];

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
			}
			
			[self.gamesScrollView setContentSize:CGSizeMake(self.gamesScrollView.frame.size.width, [self.miniGamesViewArray count] * 30 * 6)];
		}
	}
}

- (void)populateScrollView
{
	[self populateScrollView:nil];
}

- (void)populateScrollView:(GKMatchRequest*)request
{
	[GKTurnBasedMatch loadMatchesWithCompletionHandler:^(NSArray *matches, NSError *error)
	 {
		 for (int matchNumber = 0;matchNumber < [matches count];matchNumber++)
		 {
			 GKTurnBasedMatch* match = [matches objectAtIndex:matchNumber];

			 [match loadMatchDataWithCompletionHandler:^(NSData* matchData, NSError* matchDataError)
			  {
				  ApplicationDelegate* delegate = [UIApplication sharedApplication].delegate;
				  NSLog(@"Multiplayer Match View: Updated Match Data (Populate) SHA1 Hash: %@", [delegate sha1HashFromData:matchData]);

				  GameKitGameHandler* handler = [delegate.listener handlerForMatch:match];

				  DiceGame* game = nil;
				  BOOL newGame = NO;

				  if (!handler)
				  {
					  game = [[DiceGame alloc] initWithAppDelegate:delegate];
					  newGame = YES;

					  handler = [[GameKitGameHandler alloc] initWithDiceGame:game withLocalPlayer:nil withRemotePlayers:nil withMatch:match];
					  [delegate.listener addGameKitGameHandler:handler];
				  }
				  else
					  game = handler.localGame;

				  MultiplayerMatchData* mmd = [[MultiplayerMatchData alloc] initWithData:matchData
																			 withRequest:request
																			   withMatch:match
																			 withHandler:handler];

				  if (!mmd)
				  {
					  NSLog(@"Failed to load multiplayer data from game center: %@!\n", [matchDataError description]);
					  return;
				  }

				  [mmd.theGame.gameState decodePlayers:match withHandler:handler];

				  if (mmd.theGame.gameState.players)
					  mmd.theGame.players = [NSArray arrayWithArray:mmd.theGame.gameState.players];

				  mmd.theGame.gameState.players = mmd.theGame.players;

				  [game updateGame:[mmd theGame]];

				  if (![self->miniGamesViewArray containsObject:game])
					  [self->miniGamesViewArray addObject:game];

				  if (![self->handlerArray containsObject:handler])
					  [self->handlerArray addObject:handler];

				  [self handleUpdateNotification:nil];
			  }];
		 }
	 }];
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1) // Yes
		[self deleteMatchButtonPressed:alertView];
}

- (void)playMatchButtonPressed:(id)sender
{
	int gameIndex = (int)[(UIButton*)sender tag];

	PlayGameView* playGameView = [((UIView*)[self->playGameViews objectAtIndex:gameIndex]).LDContext objectForKey:@"PlayGameView"];

	__block MultiplayerView* multiplayerView = self;
	void (^quitHandler)(void) =^
	{
		[multiplayerView.navigationController popToViewController:multiplayerView animated:YES];
	};

	PlayGameView *bigView = [[PlayGameView alloc] initWithGame:playGameView.game withQuitHandler:quitHandler withCustomMainView:NO];

	[self.navigationController pushViewController:bigView animated:YES];
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

		if (player &&
			!([[game.gameState playerStateForPlayerID:[player getID]] hasLost] ||
			  [[game.gameState playerStateForPlayerID:[player getID]] hasWon]))
		{
			[handler playerQuitMatch:player withRemoval:YES];
		}

		int handlerIndex = 0;
		for (;handlerIndex < [handlerArray count];handlerIndex++)
		{
			if ([handlerArray objectAtIndex:handlerIndex] == handler)
				break;
		}

		[UIView animateWithDuration:0.5 animations:^(void)
		 {
			 CGRect currentFrame = ((UIView*)[self->playGameViews objectAtIndex:handlerIndex]).frame;

			 if (!self->iPad)
				 currentFrame.origin.x -= currentFrame.size.width;
			 else
				 currentFrame.origin.y -= currentFrame.size.height;

			 ((UIView*)[self->playGameViews objectAtIndex:handlerIndex]).frame = currentFrame;

			 for (int i = handlerIndex+1;i < [self->handlerArray count];i++)
			 {
				 currentFrame = ((UIView*)[self->playGameViews objectAtIndex:i]).frame;

				 if (self->iPad)
					 currentFrame.origin.x -= currentFrame.size.width - 10;
				 else
					 currentFrame.origin.y -= currentFrame.size.height;
				 
				 ((UIView*)[self->playGameViews objectAtIndex:i]).frame = currentFrame;
			 }
		 } completion:^(BOOL finished) {
			 if (finished)
			 {
				 [((UIView*)[self->playGameViews objectAtIndex:handlerIndex]) removeFromSuperview];
				 [self->playGameViews removeObjectAtIndex:handlerIndex];

				 [self->miniGamesViewArray removeObjectAtIndex:handlerIndex];

				 [delegate.listener removeGameKitGameHandler:[self->handlerArray objectAtIndex:handlerIndex]];
				 [self->handlerArray removeObjectAtIndex:handlerIndex];
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
	if (!self.popoverController)
	{
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:self.joinMatchPopoverViewController];
		navigationController.navigationBarHidden = NO;
		navigationController.navigationBar.translucent = NO;

		self.popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
	}

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
