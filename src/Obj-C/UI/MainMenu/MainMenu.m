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
#import "MultiplayerView.h"

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
		self.multiplayerEnabled = NO;
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
	
    int seed = arc4random_uniform(RAND_MAX);
    srand(seed);
    NSLog(@"Seed:%i", seed);

	self.navigationController.navigationBarHidden = YES;

	self.navigationController.title = @"Main Menu";
	self.navigationItem.title = @"Main Menu";
}

- (void)viewWillAppear:(BOOL)animated
{
	self.navigationController.navigationBarHidden = YES;

	NSArray* handlers = [NSArray arrayWithArray:self.appDelegate.listener.handlers];
	for (GameKitGameHandler* handler in handlers)
		[self.appDelegate.listener removeGameKitGameHandler:handler];
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
//	UIAlertView *noMultiplayer = [[[UIAlertView alloc] initWithTitle:@"Multiplayer Disabled" message:@"Multiplayer is not implemented yet and is therefore disabled." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] autorelease];
//
//	[noMultiplayer show];
//
//	return;

	if (!self.multiplayerEnabled)
	{
		UIAlertView *noMultiplayer;

		if (self.appDelegate.gameCenterLoginViewController)
			noMultiplayer = [[[UIAlertView alloc] initWithTitle:@"Multiplayer Disabled" message:@"Liar's Dice Multiplayer requires Game Center to function.  You are not logged into Game Center.  Would you like to log into Game Center to access Multiplayer?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease];
		else
			noMultiplayer = [[[UIAlertView alloc] initWithTitle:@"Multiplayer Disabled" message:@"Liar's Dice Multiplayer requires Game Center to function.  Authentication with Game Center failed.  If you would like to play multiplayer, please make sure that you are connected to the internet and logged into Game Center." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] autorelease];

		[noMultiplayer show];
	}
	else
		[self.navigationController pushViewController:[[[MultiplayerView alloc] initWithMainMenu:self withAppDelegate:self.appDelegate] autorelease] animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1 && self.appDelegate.gameCenterLoginViewController)
	{
		[self.navigationController presentViewController:self.appDelegate.gameCenterLoginViewController animated:YES completion:^(void)
		 {
			 if (self.multiplayerEnabled)
				 [self multiplayerGameButtonPressed:nil];
		 }];
	}
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

- (void)setMultiplayerEnabled:(BOOL)multiplayerEnabled
{
	return;
}

- (BOOL)multiplayerEnabled
{
	return [GKLocalPlayer localPlayer].authenticated;
}

@end
