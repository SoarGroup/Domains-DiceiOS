//
//  DiceMainMenu.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "MainMenu.h"

#import "ApplicationDelegate.h"

#import "DiceGame.h"
#import "PlayGame.h"
#import "PlayGameView.h"
#import "SoarPlayer.h"
#import "LoadingGameView.h"
#import "RulesView.h"
#import "StatsView.h"
#import "SettingsView.h"
#import "AboutView.h"
#import "DiceDatabase.h"
#import "SingleplayerView.h"

@implementation MainMenu

@synthesize appDelegate;

@synthesize aiOnlyGameButton;
@synthesize multiplayerGameButton;
@synthesize rulesButton;
@synthesize statsButton;
@synthesize settingsButton;
@synthesize aboutButton;

- (id)initWithAppDelegate:(id)anAppDelegate
{
	NSString* device = [UIDevice currentDevice].model;
	device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];

	if ([device isEqualToString:@"iPhone"])
		device = @"";

	self = [super initWithNibName:[@"MainMenu" stringByAppendingString:device] bundle:nil];
    if (self)
	{
        self.appDelegate = anAppDelegate;

		self.title = @"Main Menu";
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
	
    int seed = arc4random() % RAND_MAX;
    srand(seed);
    NSLog(@"Seed:%i", seed);

	self.navigationController.title = @"Main Menu";
	self.navigationItem.title = @"Main Menu";
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;
}

- (void)dealloc {    
    [super dealloc];
}

- (IBAction)aiOnlyGameButtonPressed:(id)sender
{
	[self.navigationController pushViewController:[[[SingleplayerView alloc] initWithAppDelegate:self.appDelegate andWithMainMenu:self] autorelease] animated:YES];
}

- (IBAction)multiplayerGameButtonPressed:(id)sender
{
	UIAlertView *noMultiplayer = [[UIAlertView alloc] initWithTitle:@"Multiplayer Not Implemented." message:@"Unfortunately, multiplayer hasn't quite been implemented." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];

	[noMultiplayer show];
	[noMultiplayer release];
}

- (IBAction)rulesButtonPressed:(id)sender
{
	[self.navigationController pushViewController:[[[RulesView alloc] init] autorelease] animated:YES];
}

- (IBAction)statsButtonPressed:(id)sender
{
	[self.navigationController pushViewController:[[[StatsView alloc] init] autorelease] animated:YES];
}

- (IBAction)settingsButtonPressed:(id)sender
{
	[self.navigationController pushViewController:[[[SettingsView alloc] init] autorelease] animated:YES];
}

- (IBAction)aboutButtonPressed:(id)sender
{
	[self.navigationController pushViewController:[[[AboutView alloc] init] autorelease] animated:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

@end
