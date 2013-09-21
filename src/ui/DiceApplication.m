//
//  DiceApplication.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DiceApplication.h"

@implementation DiceApplication

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	NSString* nibFile = nil;
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	
	if (screenBounds.size.height > 480)
		nibFile = @"DiceApplication-i5";
	else
		nibFile = @"DiceApplication";
	
    self = [super initWithNibName:nibFile bundle:nil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end
