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

@interface JoinMatchView ()

@end

@implementation JoinMatchView

@synthesize numberOfAIPlayers, maximumNumberOfHumanPlayers, minimumNumberOfHumanPlayers;
@synthesize changeMinimumNumberOfHumanPlayers, changeNumberOfAIPlayers, changeMaximumNumberOfHumanPlayers;
@synthesize joinMatchButton, spinner, mainMenu, multiplayerView, delegate, isPopOver;


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

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.navigationController.navigationBarHidden = self.isPopOver;
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
		UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:@"Join Match" message:@"I cannot join a match with no opponents!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];

		[alert show];
	}

	changeMaximumNumberOfHumanPlayers.enabled = NO;
	changeMinimumNumberOfHumanPlayers.enabled = NO;
	changeNumberOfAIPlayers.enabled = NO;

	if (changeMaximumNumberOfHumanPlayers.value == 0)
		[SingleplayerView startGameWithOpponents:changeNumberOfAIPlayers.value withNavigationController:self.navigationController withAppDelegate:self.delegate withMainMenu:self.mainMenu];
	else
	{
		GKMatchRequest *request = [[GKMatchRequest alloc] init];
		request.minPlayers = changeMinimumNumberOfHumanPlayers.value + 1;
		request.maxPlayers = changeMaximumNumberOfHumanPlayers.value + 1;
		request.playerGroup = changeNumberOfAIPlayers.value; // AI Player Numbers hack...

		self.spinner.hidden = NO;
		[self.spinner startAnimating];

		[GKTurnBasedMatch findMatchForRequest:request withCompletionHandler:^(GKTurnBasedMatch *match, NSError *error)
		 {
			 if (match)
			 {
				 if (iPad)
				 {
					 self.spinner.hidden = YES;
					 [self.multiplayerView joinedNewMatch:request];
				 }
				 else
				 {
					 [match loadMatchDataWithCompletionHandler:^(NSData* matchdata, NSError* error2)
					  {
						  MultiplayerMatchData* mmd = [[[MultiplayerMatchData alloc] initWithData:matchdata] autorelease];

						  if (!mmd && error2)
						  {
							  NSLog(@"Failed to load multiplayer data from game center: %@!\n", [error2 description]);
							  return;
						  }

						  DiceGame* newGame = [[DiceGame alloc] initWithAppDelegate:self.delegate];
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

						  [self.delegate.listener addGameKitGameHandler:handler];

						  void (^quitHandlerFullScreen)(void) =^
						  {
							  [self.multiplayerView.navigationController popToViewController:multiplayerView animated:YES];
						  };

						  UIViewController *gameView = [[[PlayGameView alloc] initWithGame:newGame withQuitHandler:[[quitHandlerFullScreen copy] autorelease]] autorelease];

						  [self.navigationController pushViewController:gameView animated:YES];
					  }];
				 }
			 }
			 else
				 NSLog(@"No match returned from game center! %@\n", error.description);
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

		[[[[UIAlertView alloc] initWithTitle:@"Maximum Players" message:@"Unfortunately, there is a maximum of 7 opponents in multiplayer (AI and Human combined)" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
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

@end
