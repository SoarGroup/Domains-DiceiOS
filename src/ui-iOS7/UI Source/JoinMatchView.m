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

@interface JoinMatchView ()

@end

@implementation JoinMatchView

@synthesize numberOfAIPlayers, changeNumberOfAIPlayers, minimumNumberOfHumanPlayers, changeMinimumNumberOfHumanPlayers, maximumNumberOfHumanPlayers, changeMaximumNumberOfHumanPlayers, joinMatchButton, spinner, mainMenu, delegate;


- (id)initWithMainMenu:(MainMenu *)menu withAppDelegate:(ApplicationDelegate *)appDelegate
{
	self = [super initWithNibName:@"JoinMatchView" bundle:nil];

	if (self)
	{
		self.mainMenu = menu;
		self.delegate = appDelegate;
	}

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.navigationController.navigationBarHidden = NO;
	
    // Do any additional setup after loading the view.
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
							  BOOL isAI = (BOOL)arc4random() % 2;

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

					  [self.navigationController pushViewController:[[[LoadingGameView alloc] initWithGame:newGame mainMenu:self.mainMenu] autorelease] animated:YES];
				}];
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
}

@end
