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
#import "MultiplayerHelpView.h"

#import "UIImage+ImageEffects.h"

@interface MultiplayerView ()

- (void)iPadJoinMatchButtonPressed;
- (void)iPhoneJoinMatchButtonPressed;

@end

@implementation MultiplayerView

@synthesize joinMatchButton, gamesScrollView, mainMenu, appDelegate, popoverController, joinMatchPopoverViewController, joinSpinner, containers;

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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.navigationController.navigationBarHidden = NO;
	self.navigationController.navigationBar.translucent = YES;

	self.navigationController.title = @"Multiplayer Matches";
	self.navigationItem.title = @"Multiplayer Matches";

//	for (UIView* view in self.gamesScrollView.subviews)
//		[view removeFromSuperview];
//
//	[self.miniGamesViewArray removeAllObjects];
//	[self.playGameViews removeAllObjects];
//	[self.handlerArray removeAllObjects];

	for (UIView* view in self.gamesScrollView.subviews)
		[(PlayGameView*)[view.LDContext objectForKey:@"PlayGameView"] viewWillAppear:animated];

	if (iPad)
		joinMatchPopoverViewController.spinner = self.joinSpinner;

	[self populateScrollView];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateNotification:) name:@"UpdateUINotification" object:nil];
	
	self.joinSpinner.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	for (UIView* view in self.gamesScrollView.subviews)
		[(PlayGameView*)[view.LDContext objectForKey:@"PlayGameView"] viewWillDisappear:animated];
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

					UIButton* quitButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 140, 40)];
					[quitButton setTitle:@"Delete Match" forState:UIControlStateNormal];
					[quitButton setTitleColor:[UIColor maizeColor] forState:UIControlStateNormal];
					
					UIButton* historyButton = [[UIButton alloc] initWithFrame:CGRectMake(80, 40, 140, 40)];
					[historyButton setTitle:@"History of Match" forState:UIControlStateNormal];
					[historyButton setTitleColor:[UIColor maizeColor] forState:UIControlStateNormal];

					UIButton* expandButton = [[UIButton alloc] initWithFrame:CGRectMake(160, 0, 140, 40)];
					[expandButton setTitle:@"Expand Match" forState:UIControlStateNormal];
					[expandButton setTitleColor:[UIColor maizeColor] forState:UIControlStateNormal];
					[expandButton.LDContext setObject:match forKey:@"Match"];

					[expandButton addTarget:self action:@selector(playMatchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
					[quitButton addTarget:playGameView action:@selector(backPressed:) forControlEvents:UIControlEventTouchUpInside];
					[historyButton addTarget:playGameView action:@selector(displayHistoryView:) forControlEvents:UIControlEventTouchUpInside];
#pragma clang diagnostic pop

					[container addSubview:quitButton];
					[container addSubview:expandButton];
					[container addSubview:historyButton];

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

				UIView* whiteBar = [[UIView alloc] init];

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

				if (!currentPlayerName || [currentPlayerName isEqualToString:@"Remote Player"])
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
				frame.size.width /= 2.0;
				frame.size.width -= 20;
				playMatch.frame = frame;

				[playMatch setTitle:@"Play Match!" forState:UIControlStateNormal];

				if (match.status == GKTurnBasedMatchStatusEnded)
					playMatch.titleLabel.text = @"View Match";

				[playMatch setTitleColor:[UIColor colorWithRed:(float)(247.0/255.0) green:(float)(192.0/255.0) blue:(float)(28.0/255.0) alpha:1.0] forState:UIControlStateNormal];
				[playMatch setTag:matchNumber];
				[playMatch addTarget:self action:@selector(playMatchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
				[playMatch.LDContext setObject:match forKey:@"Match"];

				frame.origin.x += frame.size.width;
				deleteMatch.frame = frame;
				frame.size.width += 20;
				[deleteMatch setTitle:@"Remove Match" forState:UIControlStateNormal];
				[deleteMatch setTitleColor:[UIColor colorWithRed:(float)(247.0/255.0) green:(float)(192.0/255.0) blue:(float)(28.0/255.0) alpha:1.0] forState:UIControlStateNormal];
				[deleteMatch.LDContext setObject:match forKey:@"Match"];
				[deleteMatch addTarget:self action:@selector(deleteMatchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

				frame.origin.y += 30;
				frame.origin.x -= frame.size.width;
				frame.size.width *= 2.0;
				frame.size.width -= 15;
				frame.size.height = 3;

				[whiteBar setBackgroundColor:[UIColor whiteColor]];
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
	self.joinSpinner.hidden = YES;
	
	[self populateScrollView:nil];
}

- (void)populateScrollView:(GKMatchRequest*)request
{
	[GKTurnBasedMatch loadMatchesWithCompletionHandler:^(NSArray *matches, NSError *error)
	 {
		 DiceDatabase* database = [[DiceDatabase alloc] init];
		 if (![database hasVisitedMultiplayerBefore])
		 {
			 [database setHasVisitedMultiplayerBefore];
			 
			 if ([matches count] == 0)
				 [[[UIAlertView alloc] initWithTitle:@"New to Multiplayer?" message:@"It appears you are new to multiplayer.  Would you like to read about how the multiplayer works in Liar's Dice?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Okay", nil] show];
		 }
		 
		 for (int matchNumber = 0;matchNumber < [matches count];matchNumber++)
		 {
			 GKTurnBasedMatch* match = [matches objectAtIndex:matchNumber];

			 [match loadMatchDataWithCompletionHandler:^(NSData* matchData, NSError* matchDataError)
			  {
				  ApplicationDelegate* delegate = [UIApplication sharedApplication].delegate;
				  DDLogGameKit(@"Updated Match Data (Populate) SHA1 Hash: %@", [delegate sha1HashFromData:matchData]);

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
					  DDLogError(@"Failed to load multiplayer data from game center: %@!\n", [matchDataError description]);
					  return;
				  }

				  if (!mmd.theGame.gameState && !request)
				  {
					  [match removeWithCompletionHandler:^(NSError* errorRemoving)
					  {
						  if (errorRemoving)
							  DDLogError(@"Error: %@", errorRemoving.description);
					  }];
					  handler.localGame = nil;
					  [delegate.listener removeGameKitGameHandler:handler];
					  return;
				  }

				  [mmd.theGame.gameState decodePlayers:match withHandler:handler];

				  if (mmd.theGame.gameState.players &&
					  [mmd.theGame.gameState.players count] > 0)
					  mmd.theGame.players = [NSArray arrayWithArray:mmd.theGame.gameState.players];

				  mmd.theGame.gameState.players = mmd.theGame.players;

				  [game updateGame:[mmd theGame]];

				  if (![self->miniGamesViewArray containsObject:game])
					  [self->miniGamesViewArray addObject:game];

				  if (![self->handlerArray containsObject:handler])
					  [self->handlerArray addObject:handler];

				  [self handleUpdateNotification:nil];

				  if (request || newGame)
					  [self->gamesScrollView scrollRectToVisible:CGRectMake(matchNumber * 330, 1, 1, 1)
														animated:YES];
			  }];
		 }
	 }];
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1 && ![[alertView title] isEqualToString:@"New to Multiplayer?"]) // Yes
		[self deleteMatchButtonPressed:alertView];
	else if (buttonIndex == 1)
		[self.navigationController pushViewController:[[MultiplayerHelpView alloc] init] animated:YES];
}

- (void)playMatchButtonPressed:(id)sender withWait:(BOOL)waitForHandler
{
	if ([NSThread isMainThread])
	{
		dispatch_async(dispatch_get_global_queue(0, 0), ^{
			[self playMatchButtonPressed:sender withWait:waitForHandler];
		});
		return;
	}
	
	GKTurnBasedMatch* match = [((NSObject*)sender).LDContext objectForKey:@"Match"];
	
	ApplicationDelegate* delegate = self.appDelegate;
	
	GameKitGameHandler* handler = [delegate.listener handlerForMatch:match];
	
	while (!handler && waitForHandler)
	{
		sleep(1);
		handler = [delegate.listener handlerForMatch:match];
	}
	
	if (handler)
	{
		dispatch_sync(dispatch_get_main_queue(), ^{
			DiceGame* localGame = handler.localGame;
			
			__block MultiplayerView* multiplayerView = self;
			void (^quitHandler)(void) =^
			{
				[multiplayerView.navigationController popToViewController:multiplayerView animated:YES];
				
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
				[localGame performSelectorInBackground:@selector(endGamePermanently) withObject:nil];
#pragma clang diagnostic pop
			};
			
			PlayGameView *bigView = [[PlayGameView alloc] initWithGame:localGame withQuitHandler:quitHandler withCustomMainView:NO];
			
			[self.navigationController pushViewController:bigView animated:YES];
		});
	}
}

- (void)playMatchButtonPressed:(id)sender
{
	GKTurnBasedMatch* match = [((NSObject*)sender).LDContext objectForKey:@"Match"];

	ApplicationDelegate* delegate = self.appDelegate;

	GameKitGameHandler* handler = [delegate.listener handlerForMatch:match];

	if (handler)
	{
		DiceGame* localGame = handler.localGame;

		__block MultiplayerView* multiplayerView = self;
		void (^quitHandler)(void) =^
		{
			[multiplayerView.navigationController popToViewController:multiplayerView animated:YES];
			
			[localGame performSelectorInBackground:@selector(endGamePermanently) withObject:nil];
		};

		PlayGameView *bigView = [[PlayGameView alloc] initWithGame:localGame withQuitHandler:quitHandler withCustomMainView:NO];

		[self.navigationController pushViewController:bigView animated:YES];
	}
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
			[handler playerQuitMatch:player withRemoval:YES];

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
				 
				 [[self->miniGamesViewArray objectAtIndex:handlerIndex] performSelectorInBackground:@selector(endGamePermanently) withObject:nil];

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

@end
