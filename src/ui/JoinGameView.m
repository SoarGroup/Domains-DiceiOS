//
//  JoinGameView.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "JoinGameView.h"

#import "DiceGame.h"

@implementation JoinGameView

@synthesize game;

- (id)initWithGame:(DiceGame*)aGame
{
    NSString* nibFile = nil;
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	
	if (screenBounds.size.height > 480)
		nibFile = @"JoinGameView-i5";
	else
		nibFile = @"JoinGameView";
	
    self = [super initWithNibName:nibFile bundle:nil];
    if (self) {
        // Custom initialization
        self.game = aGame;
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
}

- (IBAction)backPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
