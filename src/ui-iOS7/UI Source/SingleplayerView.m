//
//  SingleplayerView.m
//  UM Liars Dice
//
//  Created by Alex Turner on 9/23/13.
//
//

#import "SingleplayerView.h"

#import "DiceDatabase.h"
#import "DiceGame.h"
#import "LoadingGameView.h"
#import "SoarPlayer.h"

@interface SingleplayerView ()

@end

@implementation SingleplayerView

@synthesize appDelegate;
@synthesize mainMenu;

@synthesize playButton;
@synthesize aiPlayers;

- (id)initWithAppDelegate:(id)anAppDelegate andWithMainMenu:(MainMenu *)aMainMenu
{
	NSString* device = [UIDevice currentDevice].model;
	device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];

	if ([device isEqualToString:@"iPhone"])
		device = @"";

	self = [super initWithNibName:[@"SingleplayerView" stringByAppendingString:device] bundle:nil];

	if (self)
	{
        self.appDelegate = anAppDelegate;
		self.mainMenu = aMainMenu;

		self.title = @"AI Only Game";
	}

    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];

	self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = @"AI Only Game";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) startGameWithOpponents:(int)opponents
{
	[SingleplayerView startGameWithOpponents:opponents withNavigationController:self.navigationController withAppDelegate:self.appDelegate withMainMenu:self.mainMenu];
}

+ (void) startGameWithOpponents:(int)opponents withNavigationController:(UINavigationController*)controller withAppDelegate:(ApplicationDelegate*)delegate withMainMenu:(MainMenu*)mainMenu
{
	DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];

	NSString* username = [database getPlayerName];

	if ([username length] == 0)
		username = @"Player";

    DiceGame *game = [[[DiceGame alloc] initWithAppDelegate:delegate] autorelease];

	[game addPlayer:[[DiceLocalPlayer alloc] initWithName:username withHandler:nil withParticipant:nil]];

	NSLock* lock = [[[NSLock alloc] init] autorelease];

	for (int i = 0;i < opponents;i++)
		[game addPlayer:[[[SoarPlayer alloc] initWithGame:game connentToRemoteDebugger:NO lock:lock withGameKitGameHandler:nil] autorelease]];

    UIViewController *gameView = [[[LoadingGameView alloc] initWithGame:game mainMenu:mainMenu] autorelease];
    [controller pushViewController:gameView animated:YES];
}

- (IBAction)playButtonPressed:(id)sender
{
	[self startGameWithOpponents:((int)self.aiPlayers.selectedSegmentIndex+1)];
}

@end
