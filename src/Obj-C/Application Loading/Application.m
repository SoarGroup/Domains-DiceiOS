//
//  DiceApplication.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Rewritten/Modified by Alex Turner on 9/22/13.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "Application.h"

@implementation Application

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	NSString* device = [UIDevice currentDevice].model;
	device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];

	if ([device isEqualToString:@"iPhone"])
		device = @"";

	return [super initWithNibName:[@"Application" stringByAppendingString:device] bundle:nil];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end
