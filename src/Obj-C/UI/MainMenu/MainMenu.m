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
@synthesize removeAllMultiplayerGames;

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
	self.navigationController.navigationBar.translucent = NO;

	ApplicationDelegate* delegate = self.appDelegate;
	NSArray* handlers = [NSArray arrayWithArray:delegate.listener.handlers];

	for (GameKitGameHandler* handler in handlers)
		[delegate.listener removeGameKitGameHandler:handler];

#ifdef DEBUG
	self.removeAllMultiplayerGames.enabled = YES;
	self.removeAllMultiplayerGames.hidden = NO;
#endif
}
- (IBAction)aiOnlyGameButtonPressed:(id)sender
{
	[self.navigationController pushViewController:[[SingleplayerView alloc] initWithAppDelegate:self.appDelegate andWithMainMenu:self] animated:YES];
}

- (IBAction)multiplayerGameButtonPressed:(id)sender
{
	ApplicationDelegate* delegate = self.appDelegate;

	self.multiplayerEnabled = [GKLocalPlayer localPlayer].authenticated;

	if (!self.multiplayerEnabled)
	{
		UIAlertView *noMultiplayer;

		if (delegate.gameCenterLoginViewController)
			noMultiplayer = [[UIAlertView alloc] initWithTitle:@"Multiplayer Disabled" message:@"Liar's Dice Multiplayer requires Game Center to function.  You are not logged into Game Center.  Would you like to log into Game Center to access Multiplayer?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
		else
			noMultiplayer = [[UIAlertView alloc] initWithTitle:@"Multiplayer Disabled" message:@"Liar's Dice Multiplayer requires Game Center to function.  Authentication with Game Center failed.  If you would like to play multiplayer, please make sure that you are connected to the internet and logged into Game Center." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];

		[noMultiplayer show];
	}
	else
		[self.navigationController pushViewController:[[MultiplayerView alloc] initWithMainMenu:self withAppDelegate:delegate]  animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	ApplicationDelegate* delegate = self.appDelegate;

	if (buttonIndex == 1 && delegate.gameCenterLoginViewController)
	{
		[self.navigationController presentViewController:delegate.gameCenterLoginViewController animated:YES completion:^(void)
		 {
			 if (self.multiplayerEnabled)
				 [self multiplayerGameButtonPressed:nil];
		 }];
	}
}

- (IBAction)rulesButtonPressed:(id)sender
{
	[self.navigationController pushViewController:[[RulesView alloc] init]  animated:YES];
}

- (IBAction)statsButtonPressed:(id)sender
{
	[self.navigationController pushViewController:[[StatsView alloc] init]  animated:YES];
}

- (IBAction)settingsButtonPressed:(id)sender
{
	[self.navigationController pushViewController:[[SettingsView alloc] init]  animated:YES];
}

- (IBAction)aboutButtonPressed:(id)sender
{
	[self.navigationController pushViewController:[[AboutView alloc] init]  animated:YES];
}

- (IBAction)removeAllMultiplayerGamesPressed:(id)sender
{
	ApplicationDelegate* delegate = appDelegate;
	[GKTurnBasedMatch loadMatchesWithCompletionHandler:^(NSArray *matches, NSError *error)
	 {
		 static NSUInteger matchCount = 0;

		 if ([matches count] > matchCount)
			 matchCount = [matches count];

		 if ([matches count] == 0)
		 {
			 dispatch_async(dispatch_get_main_queue(), ^{
				 [delegate.listener.handlers removeAllObjects];

				 [[[UIAlertView alloc] initWithTitle:@"Removed All GK Matches" message:[NSString stringWithFormat:@"Removed: %lu matches", (unsigned long)matchCount] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];

				 matchCount = 0;
			 });

			 return;
		 }

		 [[matches objectAtIndex:0] removeWithCompletionHandler:^(NSError* matchError)
		  {
			  if (matchError)
				  NSLog(@"Error Removing Invalid Match: %@", error.description);

			  [self removeAllMultiplayerGamesPressed:nil];
		  }];
	 }];
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

//-(BOOL)shouldAutorotate
//{
//	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//		return !UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
//	else
//		return !UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
//}
//
//- (NSUInteger)supportedInterfaceOrientations
//{
//	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//		return UIInterfaceOrientationMaskLandscape;
//	else
//		return UIInterfaceOrientationMaskPortrait;
//}

@end
