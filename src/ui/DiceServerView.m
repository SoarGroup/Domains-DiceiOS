//
//  DiceServerView.m
//  Lair's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DiceServerView.h"

#import "PlayGame.h"
#import "PlayGameTableView.h"
#import "PlayGameView.h"
#import "SoarPlayer.h"

@implementation DiceServerView
@synthesize playerNameList;

@synthesize game, appDelegate;

- (id)initWithGame:(DiceGame*)aGame
{
    self = [super initWithNibName:@"DiceServerView" bundle:nil];
    if (self) {
        // Custom initialization
        self.game = aGame;
    }
    return self;
}

- (void) viewDidAppear:(BOOL)animated
{
    NSLog(@"server view appear");
    if (self.game.started)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
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

- (void)viewDidUnload
{
    [self setPlayerNameList:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)quitGame:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)startGamePressed:(id)sender {
    if ([game getNumberOfPlayers] < 2)
    {
        UIAlertView *alert = [[[UIAlertView alloc]
                               initWithTitle:@"Can't start game"
                               message:@"Need at least two players"
                               delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil] autorelease];
        [alert show];
        return;
    }
    
    /* Here is where the PlayGame actually gets instantiated */
    
    /*
    UIViewController *gameView = [[[PlayGameTableView alloc]
                                   initWithGame:self.game]
                                  autorelease];
     */
    UIViewController *gameView = [[[PlayGameView alloc] initWithGame:self.game] autorelease];
    [self.navigationController pushViewController:gameView animated:YES];
}

- (IBAction)addSoarAgentPressed:(id)sender {
    if ([game getNumberOfPlayers] >= 4)
    {
        UIAlertView *alert = [[[UIAlertView alloc]
                               initWithTitle:@"Too many players"
                               message:@"Maximum four players"
                               delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil] autorelease];
        [alert show];
        return;
    }
    NSString *agentName = [NSString stringWithFormat:@"Soar-%d", [game getNumberOfPlayers]];
    SoarPlayer *soarPlayer = [[[SoarPlayer alloc] initWithName:agentName game:self.game connentToRemoteDebugger:NO] autorelease];
    [game addPlayer:soarPlayer];
    [playerNameList reloadData];
}

// Data source methods

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int index = [indexPath indexAtPosition:indexPath.length - 1];
    if (index < 0 || index >= [game getNumberOfPlayers])
    {
        return nil;
    }
    UITableViewCell *cell = [[[UITableViewCell alloc] init] autorelease];
    UILabel *label = cell.textLabel;
    label.text = [[game getPlayerAtIndex:index] getName];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [game getNumberOfPlayers];
    }
    return 0;
}

- (void)dealloc {
    [playerNameList release];
    [super dealloc];
}
@end
