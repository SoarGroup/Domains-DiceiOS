//
//  DiceMainMenu.m
//  Lair's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DiceMainMenu.h"

#import "DiceGame.h"
#import "DiceServerView.h"
#import "DiceApplicationDelegate.h"
#import "JoinGameView.h"
#import "PlayGame.h"
#import "PlayGameView.h"
#import "SoarPlayer.h"
#import "LoadingGameView.h"
#import "HowToPlayView.h"
#import "RecordStatsView.h"
#import "SettingsView.h"
#import "AboutView.h"
#import "DiceDatabase.h"

@implementation DiceMainMenu
@synthesize statsButton;
@synthesize oneOpponentButton;
@synthesize twoOpponentButton;
@synthesize threeOpponentButton;
@synthesize settingsButton;
@synthesize aboutButton;
@synthesize howToPlayButton;
@synthesize singlePlayerButton;
@synthesize multiPlayerButton;
@synthesize joinMultiplayerButton;
@synthesize serverOnlyButton;
@synthesize appDelegate;

- (id)initWithAppDelegate:(id)anAppDelegate
{
    self = [super initWithNibName:@"DiceMainMenu" bundle:nil];
    if (self) {
        // Custom initialization
        self.appDelegate = anAppDelegate;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.oneOpponentButton setImage:[UIImage imageNamed:@"button-one-opponent-pressed"] forState:UIControlStateHighlighted];
	[self.twoOpponentButton setImage:[UIImage imageNamed:@"button-two-opponents-pressed"] forState:UIControlStateHighlighted];
	[self.threeOpponentButton setImage:[UIImage imageNamed:@"button-three-opponents-pressed"] forState:UIControlStateHighlighted];
	
	[self.settingsButton setImage:[UIImage imageNamed:@"button-settings-pressed"] forState:UIControlStateHighlighted];
	[self.aboutButton setImage:[UIImage imageNamed:@"button-about-pressed"] forState:UIControlStateHighlighted];
	[self.howToPlayButton setImage:[UIImage imageNamed:@"button-how-to-play-pressed"] forState:UIControlStateHighlighted];
	[self.statsButton setImage:[UIImage imageNamed:@"button-stats-pressed"] forState:UIControlStateHighlighted];
    
	DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];
	
    username = [database getPlayerName];
	
    self.singlePlayerButton.enabled = YES;
    self.multiPlayerButton.enabled = NO;
    self.joinMultiplayerButton.enabled = NO;
    self.serverOnlyButton.enabled = NO;
    int seed = arc4random() % RAND_MAX;
    srand(seed);
    NSLog(@"Seed:%i", seed);
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidUnload
{
    [self setSinglePlayerButton:nil];
    [self setMultiPlayerButton:nil];
    [self setJoinMultiplayerButton:nil];
    [self setServerOnlyButton:nil];
    [self setOneOpponentButton:nil];
    [self setTwoOpponentButton:nil];
    [self setThreeOpponentButton:nil];
	[self setSettingsButton:nil];
    [self setHowToPlayButton:nil];
    [self setStatsButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [username release];
    [singlePlayerButton release];
    [multiPlayerButton release];
    [joinMultiplayerButton release];
    [serverOnlyButton release];
    [startGameTwoOpponents release];
    [oneOpponentButton release];
    [twoOpponentButton release];
    [threeOpponentButton release];
	[settingsButton release];
	[aboutButton release];
    [howToPlayButton release];
    [statsButton release];
    [super dealloc];
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
    UIViewController *gameView = [[[LoadingGameView alloc] initWithGame:game numOpponents:opponents mainMenu:self] autorelease];
    [self.navigationController pushViewController:gameView animated:YES];
}

- (IBAction)startGameOneOpponent:(id)sender {
    [self startGameWithOpponents:1];
}

- (IBAction)startGameTwoOpponents:(id)sender {
    [self startGameWithOpponents:2];
}

- (IBAction)startGameThreeOpponents:(id)sender {
    [self startGameWithOpponents:3];
}

- (IBAction)settingsPressed:(id)sender {
	[self.navigationController pushViewController:[[[SettingsView alloc] init] autorelease] animated:YES];
}

- (IBAction)aboutPressed:(id)sender {
	[self.navigationController pushViewController:[[[AboutView alloc] init] autorelease] animated:YES];
}

- (IBAction)howToPlayPressed:(id)sender {
    [self.navigationController pushViewController:[[[HowToPlayView alloc] init] autorelease] animated:YES];
//    NSURL *url = [NSURL URLWithString:@"http://freedice.net/rules.php"];
//    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)recordsPressed:(id)sender {
    [self.navigationController pushViewController:[[[RecordStatsView alloc] init] autorelease] animated:YES];
}

@end
