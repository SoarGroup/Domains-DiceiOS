//
//  LoadingGameView.m
//  Liars Dice
//
//  Created by Miller Tinkerhess on 4/3/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "LoadingGameView.h"

#import "SoarPlayer.h"
#import "PlayGameView.h"
#import "MainMenu.h"

#import "DiceDatabase.h"

@implementation LoadingGameView
@synthesize spinnerView;

@synthesize game, menu, startingGameLabel;

- (id) initWithGame:(DiceGame *)aGame mainMenu:(MainMenu*)aMenu
{
	NSString* device = [UIDevice currentDevice].model;
	device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];

	if ([device isEqualToString:@"iPhone"])
		device = @"";

	self = [super initWithNibName:[@"LoadingGameView" stringByAppendingString:device] bundle:nil];
    if (self)
	{
        self.game = aGame;
        self.menu = aMenu;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

	[self.spinnerView startAnimating];
	self.navigationController.title = @"Quit";
	self.navigationItem.title = @"Quit";
}

- (void) viewDidAppear:(BOOL)animated {
	MainMenu* mainMenu = self.menu;
    void (^quitHandler)(void) =^ {
		[mainMenu.navigationController popToViewController:mainMenu animated:YES];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
		[NSThread detachNewThreadSelector:@selector(end) toTarget:self->game withObject:nil];
#pragma clang diagnostic pop
	};

	UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                    self.startingGameLabel.text);


    UIViewController *gameView = [[PlayGameView alloc] initWithGame:self.game withQuitHandler:[quitHandler copy]];

    [self.navigationController pushViewController:gameView animated:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

@end
