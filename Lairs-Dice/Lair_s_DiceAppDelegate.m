//
//  Lair_s_DiceAppDelegate.m
//  Lair's Dice
//
//  Created by Alex on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Lair_s_DiceAppDelegate.h"

@implementation Lair_s_DiceAppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

- (void)dealloc
{
    [window release];
    [super dealloc];
}

@end
