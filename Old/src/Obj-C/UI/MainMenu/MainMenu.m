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
#import "HelpView.h"
#import "RulesView.h"
#import "SettingsView.h"
#import "AboutView.h"
#import "DiceDatabase.h"
#import "SingleplayerView.h"
#import "MultiplayerView.h"

#import <GameKit/GameKit.h>

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@implementation MainMenu

@synthesize appDelegate;

@synthesize aiOnlyGameButton;
@synthesize multiplayerGameButton;
@synthesize helpButton;
@synthesize statsButton;
@synthesize settingsButton;
@synthesize aboutButton;
@synthesize removeAllMultiplayerGames;
@synthesize multiplayerController;
@synthesize versionLabel, player;

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

- (void)wolverinesAchievement
{}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

	self.navigationController.navigationBarHidden = YES;
	self.navigationItem.title = @"Main Menu";
	self.navigationController.delegate = self;

	versionLabel.userInteractionEnabled = YES;
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(wolverinesAchievement)];
	[versionLabel addGestureRecognizer:tapGesture];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.navigationController.navigationBarHidden = YES;
	self.navigationController.navigationBar.translucent = NO;

	ApplicationDelegate* delegate = self.appDelegate;
	NSArray* handlers = [NSArray arrayWithArray:delegate.listener.handlers];

	for (GameKitGameHandler* handler in handlers)
		[delegate.listener removeGameKitGameHandler:handler];

	self.removeAllMultiplayerGames.enabled = YES;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains
	(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSURL* rootURL = [NSURL URLWithString:documentsDirectory];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDirectoryEnumerator *dirEnumerator = [fm enumeratorAtURL:rootURL
									includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
													   options:NSDirectoryEnumerationSkipsHiddenFiles
												  errorHandler:nil];
	
	for (NSURL *url in dirEnumerator) {
		NSNumber *isDirectory;
		[url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		if (![isDirectory boolValue]) {
			// log file, remove it
			NSError* error = nil;;
			NSDictionary* dict = [fm attributesOfItemAtPath:[url path] error:&error];
			
			if ([((NSDate*)[dict objectForKey:NSFileCreationDate]) timeIntervalSinceNow] < -864000 /*10 days ago*/)
				[fm removeItemAtURL:url error:NULL];
		}
	}
}

- (IBAction)aiOnlyGameButtonPressed:(id)sender
{
	[self.navigationController pushViewController:[[SingleplayerView alloc] initWithAppDelegate:self.appDelegate andWithMainMenu:self] animated:YES];
}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	DiceDatabase* database = [[DiceDatabase alloc] init];

	if (![database hasSeenTutorial])
	{
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Learn Liar's Dice" message:@"It appears you have not completed the tutorial.  If you are not familiar with the rules of Liar's Dice, please read at least the summary of the rules.  If you are familiar with the rules of Liar's Dice, I recommend you go through the tutorial to learn the UI we use." delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Rules", @"Tutorial", nil];
		alert.tag = 99;
		[alert show];
	}
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
	{
		//if (!self.multiplayerController)
			self.multiplayerController = [[MultiplayerView alloc] initWithMainMenu:self withAppDelegate:delegate];

		[self.navigationController pushViewController:self.multiplayerController animated:YES];
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	ApplicationDelegate* delegate = self.appDelegate;

	if (alertView.tag == 99)
	{
		DiceDatabase* database = [[DiceDatabase alloc] init];

		if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Tutorial"])
		{
			void (^quitHandler)(void) =^ {
				[[self navigationController] popToRootViewControllerAnimated:YES];
			};

			[self.navigationController pushViewController:[[PlayGameView alloc] initTutorialWithQuitHandler:[quitHandler copy]]
												 animated:YES];
		}
		else if (buttonIndex == alertView.cancelButtonIndex)
			[database setHasSeenTutorial];
		else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Rules"])
			[self.navigationController pushViewController:[[RulesView alloc] init] animated:YES];
	}
	else if (buttonIndex == 1 && delegate.gameCenterLoginViewController)
	{
		[self.navigationController presentViewController:delegate.gameCenterLoginViewController animated:YES completion:^(void)
		 {
			 if (self.multiplayerEnabled)
				 [self multiplayerGameButtonPressed:nil];
		 }];
	}
}

- (IBAction)helpButtonPressed:(id)sender
{
	[self.navigationController pushViewController:[[HelpView alloc] init]  animated:YES];
}

- (IBAction)statsButtonPressed:(id)sender
{
	if (!self.multiplayerEnabled)
    {
        ApplicationDelegate* delegate = self.appDelegate;
        UIAlertView *noMultiplayer;
        
        if (delegate.gameCenterLoginViewController)
            noMultiplayer = [[UIAlertView alloc] initWithTitle:@"Achievements Require Game Center" message:@"Liar's Dice Achievements require Game Center to function.  You are not logged into Game Center.  Would you like to log into Game Center to access Achievements?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        else
            noMultiplayer = [[UIAlertView alloc] initWithTitle:@"Achievements Require Game Center" message:@"Liar's Dice Achievements require Game Center to function.  Authentication with Game Center failed.  If you would like to use/have statistics, please make sure that you are connected to the internet and logged into Game Center." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        
        [noMultiplayer show];
    }
	else
	{
		GKGameCenterViewController* gameCenterController = [[GKGameCenterViewController alloc] init];
		gameCenterController.delegate = self;
		gameCenterController.gameCenterDelegate = self;
		gameCenterController.viewState = GKGameCenterViewControllerStateAchievements;

		[self.navigationController presentViewController:gameCenterController animated:YES completion:nil];
	}
}

- (IBAction)settingsButtonPressed:(id)sender
{
	[self.navigationController pushViewController:[[SettingsView alloc] init:self]  animated:YES];
}

- (IBAction)aboutButtonPressed:(id)sender
{
	[self.navigationController pushViewController:[[AboutView alloc] init]  animated:YES];
}

- (IBAction)poweredBySoarPressed:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://soar.eecs.umich.edu/"]];
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

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
	[gameCenterViewController dismissViewControllerAnimated:YES completion:nil];
}

- (NSUInteger)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		return UIInterfaceOrientationMaskPortrait;
	else
		return UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)navigationControllerPreferredInterfaceOrientationForPresentation:(UINavigationController *)navigationController
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		return UIInterfaceOrientationPortrait;
	else
		return UIInterfaceOrientationLandscapeLeft;
}

-(BOOL)shouldAutorotate
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return !UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
	else
		return !UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
}

- (NSUInteger)supportedInterfaceOrientations
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationMaskLandscape;
	else
		return UIInterfaceOrientationMaskPortrait;
}

@end
