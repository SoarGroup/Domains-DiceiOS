//
//  Lair_s_DiceAppDelegate_iPad.m
//  Lair's Dice
//
//  Created by Alex on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Lair_s_DiceAppDelegate_iPad.h"
#import "iPadServerViewController.h"
#import "MainMenu.h"

@implementation Lair_s_DiceAppDelegate_iPad

- (id) init
{
    self = [super init];
    if (self)
    {
		server = [[Server alloc] initWithDelegate:self];
    }
    return self;
}

- (void) dealloc
{
	[server release];
	[super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[server goToMainMenu];
	
    return YES;
}

- (iPadServerViewController *)goToMainServerGameWithPlayers:(int)players
{
	[mainViewController.view removeFromSuperview];
	[mainViewController release];
	mainViewController = nil;
	
	mainViewController = [[iPadServerViewController alloc] initWithNibName:@"iPadServerViewController" bundle:nil withPlayers:players];
	
	[window addSubview:mainViewController.view];
	[window makeKeyAndVisible];
	return (iPadServerViewController*) mainViewController;
}

- (MainMenu *)goToMainMenu
{
	[mainViewController.view removeFromSuperview];
	[mainViewController release];
	mainViewController = nil;
	
	mainViewController = [[MainMenu alloc] initWithNibName:@"MainMenu" bundle:nil];
	
	[window addSubview:mainViewController.view];
	[window makeKeyAndVisible];
	return (MainMenu*)mainViewController;
}

- (iPadHelp *)goToHelp
{
	[mainViewController.view removeFromSuperview];
	[mainViewController release];
	mainViewController = nil;
	
	mainViewController = [[iPadHelp alloc] initWithNibName:@"iPadHelp" bundle:nil];
	
	[window addSubview:mainViewController.view];
	[window makeKeyAndVisible];
	return (iPadHelp*)mainViewController;
}

@end
