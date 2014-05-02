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
	self = [super initWithNibName:@"LoadingGameView" bundle:nil];
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

#pragma mark - View lifecycle

- (void) onSoarOpponentsInitted {
    NSLog(@"Pushing gameView");
    UIViewController *gameView = [[[PlayGameView alloc] initWithGame:self.game mainMenu:self.menu] autorelease];
    [self.navigationController pushViewController:gameView animated:YES];
    NSLog(@"Pushed gameView");
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
//    [self performSelectorOnMainThread:@selector(onSoarOpponentsInitted) withObject:nil waitUntilDone:NO];
    NSLog(@"Pushing gameView");
    UIViewController *gameView = [[[PlayGameView alloc] initWithGame:self.game mainMenu:self.menu] autorelease];
    [self.navigationController pushViewController:gameView animated:YES];
    NSLog(@"Pushed gameView, %@", self.navigationController);

    [pool release];  // Release the objects in the pool.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

	[self.spinnerView startAnimating];
}

- (void) viewDidAppear:(BOOL)animated {
    [NSThread detachNewThreadSelector:@selector(initSoarOpponents) toTarget:self withObject:nil];    
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

@end
