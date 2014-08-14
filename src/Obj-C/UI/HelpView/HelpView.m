//
//  HowToPlayView.m
//  Liars Dice
//
//  Created by Miller Tinkerhess on 5/1/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "HelpView.h"
#import "MultiplayerHelpView.h"
#import "RulesView.h"
#import "PlayGameView.h"

@interface HelpView ()

@end

@implementation HelpView

- (id)init
{
	self = [super initWithNibName:nil bundle:nil];
	if (self) {

	}
	return self;
}

- (void)viewDidLoad
{
	self.title = @"Help";
	
	self.navigationController.navigationBarHidden = NO;
	self.navigationController.navigationBar.translucent = YES;
}


- (IBAction)rulesButtonPressed:(id)sender
{
	[self.navigationController pushViewController:[[RulesView alloc] init]  animated:YES];
}

- (IBAction)tutorialButtonPressed:(id)sender
{
	void (^quitHandler)(void) =^ {
		[[self navigationController] popToRootViewControllerAnimated:YES];
	};

	[self.navigationController pushViewController:[[PlayGameView alloc] initTutorialWithQuitHandler:[quitHandler copy]]
										 animated:YES];
}

- (IBAction)multiplayerHelpButtonPressed:(id)sender
{
	[self.navigationController pushViewController:[[MultiplayerHelpView alloc] init] animated:YES];
}

@end
