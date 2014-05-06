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

@synthesize numOpponents, game, menu;

- (id) initWithGame:(DiceGame *)aGame numOpponents:(int)aNumOpponents mainMenu:(MainMenu *)aMenu
{
	NSString* device = [UIDevice currentDevice].model;
	device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];

	if ([device isEqualToString:@"iPhone"])
		device = @"";

	self = [super initWithNibName:[@"LoadingGameView" stringByAppendingString:device] bundle:nil];
    if (self) {
        self.numOpponents = aNumOpponents;
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

NSString *makePlayerName(NSInteger index) {
    switch (index) {
        case 1:
            return @"Alice";
            break;
        case 2:
            return @"Bob";
        case 3:
            return @"Carol";
		case 4:
			return @"Chuck";
		case 5:
			return @"Craig";
		case 6:
			return @"Dan";
		case 7:
			return @"Erin";
        default:
		{
			DiceDatabase *database = [[DiceDatabase alloc] init];
			
            return [database getPlayerName];
            break;
		}
    }
}

- (void) initSoarOpponents {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // Top-level pool
    NSLock *lock = [[[NSLock alloc] init] autorelease];
    for (int i = 0; i < self.numOpponents; ++i) {
        NSString *playerName = makePlayerName([self.game getNumberOfPlayers]);
        SoarPlayer *soarPlayer = [[[SoarPlayer alloc] initWithName:playerName game:game connentToRemoteDebugger:NO lock:lock] autorelease];
        [self.game addPlayer:soarPlayer];
    }
    NSLog(@"Done initting Soar Opponents");

	NSLog(@"Pushing gameView");
	void (^quitHandler)(void) =^ {
		[menu.navigationController popToViewController:menu animated:YES];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
		[NSThread detachNewThreadSelector:@selector(end) toTarget:game withObject:nil];
#pragma clang diagnostic pop
	};

    UIViewController *gameView = [[[PlayGameView alloc] initWithGame:self.game withQuitHandler:[[quitHandler copy] autorelease]] autorelease];
    [self.navigationController pushViewController:gameView animated:YES];
    NSLog(@"Pushed gameView");

    [pool release];  // Release the objects in the pool.
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
    [NSThread detachNewThreadSelector:@selector(initSoarOpponents) toTarget:self withObject:nil];    
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

@end
