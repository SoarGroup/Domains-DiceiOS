//
//  Lair_s_DiceAppDelegate.m
//  Liar's Dice
//
//  Created by Alex on 6/29/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "Liar_s_DiceAppDelegate.h"

@implementation Liar_s_DiceAppDelegate

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
