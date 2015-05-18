//
//  HowToPlayView.m
//  Liars Dice
//
//  Created by Miller Tinkerhess on 5/1/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "MultiplayerHelpView.h"

@interface MultiplayerHelpView ()

@end

@implementation MultiplayerHelpView

- (id)init
{
	self = [super initWithNibName:nil bundle:nil];
	if (self) {

	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Multiplayer Help";
	
	self.navigationController.navigationBarHidden = NO;
	self.navigationController.navigationBar.translucent = NO;
}

@end
