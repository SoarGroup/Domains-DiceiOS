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

@interface SingleplayerView ()

@end

@implementation SingleplayerView

@synthesize appDelegate;
@synthesize mainMenu;

@synthesize oneOpponentButton;
@synthesize twoOpponentButton;
@synthesize threeOpponentButton;

- (id)initWithAppDelegate:(id)anAppDelegate andWithMainMenu:(MainMenu *)aMainMenu
{
	self = [super initWithNibName:@"SingleplayerView" bundle:nil];

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

	DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];

    username = [database getPlayerName];

	self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = @"AI Only Game";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
	[super dealloc];

	[username release];
}

- (void) startGameWithOpponents:(int)opponents {
	DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];

	username = [database getPlayerName];

	if ([username length] == 0)
		username = @"Player";

    DiceGame *game = [[[DiceGame alloc]
                       initWithType:LOCAL_PRIVATE
                       appDelegate:self.appDelegate
                       username:username]
                      autorelease];
    UIViewController *gameView = [[[LoadingGameView alloc] initWithGame:game numOpponents:opponents mainMenu:mainMenu] autorelease];
    [self.navigationController pushViewController:gameView animated:YES];
}

- (IBAction)oneOpponentPressed:(id)sender
{
	[self startGameWithOpponents:1];
}

- (IBAction)twoOpponentsPressed:(id)sender
{
	[self startGameWithOpponents:2];
}

- (IBAction)threeOpponentsPressed:(id)sender
{
	[self startGameWithOpponents:3];
}

@end
