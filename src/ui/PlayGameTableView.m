//
//  PlayGameView.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/5/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "PlayGameTableView.h"
#import "DiceGame.h"
#import "PlayerState.h"
#import "DicePeekView.h"
#import "Die.h"
#import "DiceAction.h"
#import "DiceHistoryView.h"

float controlButtonHeight()         { return 40.0f; }
float controlButtonWidth()          { return 68.0f; }
float margin()                      {
	float margin = 8.0f;
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	
	if (screenBounds.size.height > 480)
		margin *= 2.0f;
	
	return margin;
}
float titleTopMargin()              { return 4.0f; }
float controlCellHeight()           { return 152.0f; }
float headerCellHeight()            { return 64.0f; }
float historyCellHeight()           { return 72.0f; }
float cellTitleHeight()             { return 20.0f; }
float cellTitleBackgroundHeight()   { return 28.0f; }
float cellPushHeight()              { return 24.0f; }
float diceViewWidth()               { return 224.0f; }
float diceViewHeight()              { return 64.0f; }
float diceViewFixedHeight()         { return 42.0f; }

@interface PlayGameTableView()

-(void)constrainAndUpdateBidCount;
-(void)constrainAndUpdateBidFace;
-(NSArray*)makePushedDiceArray;
-(int)getChallengeTarget:(UIAlertView*)alertOrNil buttonIndex:(int) buttonIndex;

@end

@implementation PlayGameTableView

@synthesize game, state, currentBidFace, currentBidCount, controlButtons;

- (id)initWithGame:(DiceGame*)aGame
{
    self = [super initWithStyle: UITableViewStylePlain];
    if (self) {
        // Custom initialization
        self.game = aGame;
        self.game.gameView = self;
        self.state = nil;
        currentBidCount = 1;
        currentBidFace = 2;
        self.tableView.allowsSelection = NO;
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
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
    
    // THIS IS THE ONLY PLACE THIS SHOULD GET CALLED FROM.
    [self.game startGame];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)backPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dealloc {
    [super dealloc];
}

- (void)updateState:(PlayerState*)newState
{
    self.state = newState;
    [self updateUI];
}

- (void)updateUI
{
    if (self.state == nil)
    {
        return;
    }
    
    Bid *previousBid = self.state.gameState.previousBid;
	
    if (previousBid != nil)
    {
        currentBidCount = previousBid.numberOfDice;
        currentBidFace = previousBid.rankOfDie;
    }
    else
    {
        currentBidCount = 1;
        currentBidFace = 2;
    }
    
    [self.tableView reloadData];
}

- (IBAction)bidCountPlusPressed:(id)sender {
    ++currentBidCount;
    [self constrainAndUpdateBidCount];
}

- (IBAction)bidCountMinusPressed:(id)sender {
    --currentBidCount;
    [self constrainAndUpdateBidCount];
}

- (IBAction)bidFacePlusPressed:(id)sender {
    ++currentBidFace;
    [self constrainAndUpdateBidFace];
}

- (IBAction)bidFaceMinusPressed:(id)sender {
    --currentBidFace;
    [self constrainAndUpdateBidFace];
}

- (void) updateBidText {
    NSString *countString = [NSString stringWithFormat:@"%d", currentBidCount];
    [controlButtons.bidCountButton setTitle:countString forState:UIControlStateNormal];
    [controlButtons.bidFaceButton setTitle:@"" /* numberName(currentBidFace) */ forState:UIControlStateNormal];
}

-(void)constrainAndUpdateBidCount {
    int maxBidCount = [self.state getNumberOfPlayers] * 5;
    currentBidCount = (currentBidCount - 1 + maxBidCount) % maxBidCount + 1;
    [self updateBidText];
}

-(void)constrainAndUpdateBidFace {
    int maxFace = 6;
    currentBidFace = (currentBidFace - 1 + maxFace) % maxFace + 1;
    [self updateBidText];
}

- (IBAction)challengePressed:(id)sender {
    Bid *previousBid = self.state.gameState.previousBid;
    NSString *bidStr = [previousBid asString];

    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Challenge?"
                                                     message:bidStr
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:nil]
                          autorelease];
    Bid *challengeableBid = [state getChallengeableBid];
    if (challengeableBid != nil)
    {
        NSString *playerName = [[state.gameState getPlayerWithID:challengeableBid.playerID] getName];
        [alert addButtonWithTitle:[NSString stringWithFormat:@"%@'s bid", playerName]];
    }
    int passID = [state getChallengeableLastPass];
    if (passID != -1)
    {
        NSString *playerName = [[state.gameState getPlayerWithID:passID] getName];
        [alert addButtonWithTitle:[NSString stringWithFormat:@"%@'s pass", playerName]];
    }
    passID = [state getChallengeableSecondLastPass];
    if (passID != -1)
    {
        NSString *playerName = [[state.gameState getPlayerWithID:passID] getName];
        [alert addButtonWithTitle:[NSString stringWithFormat:@"%@'s pass", playerName]];
    }
    alert.tag = ACTION_CHALLENGE_BID; // TODO ask which player to challenge, bid / pass / etc
    [alert show];           
}

- (IBAction)passPressed:(id)sender {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Pass?"
                                                     message:nil
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"OK", nil]
                          autorelease];
    alert.tag = ACTION_PASS;
    [alert show];
}

- (IBAction)bidPressed:(id)sender {
    
    // Check that the bid is legal
    Bid *bid = [[[Bid alloc] initWithPlayerID:state.playerID name:state.playerName dice:currentBidCount rank:currentBidFace] autorelease];
    if (!(game.gameState.currentTurn == state.playerID && [game.gameState checkBid:bid playerSpecialRules:([ game.gameState usingSpecialRules] && [state numberOfDice] > 1)])) {
        NSString *title = [NSString stringWithFormat:@"Illegal raise"];
        NSString *message = [NSString stringWithFormat:@"Can't bid %d %@", currentBidCount, @"" /* numberName(currentBidFace) */];
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil]
                              autorelease];
        [alert show];
        return;
    }
    
    NSString *title = [NSString stringWithFormat:@"Bid %d %ds?", currentBidCount, currentBidFace];
    NSArray *push = [self makePushedDiceArray];
    NSString *message = (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %d dice?", [push count]];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"OK", nil]
                          autorelease];
    alert.tag = ACTION_BID;
    [alert show];
}

- (IBAction)exactPressed:(id)sender {
    Bid *previousBid = self.state.gameState.previousBid;
    NSString *bidStr = [previousBid asString];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Exact?"
                                                     message:bidStr
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"OK", nil]
                          autorelease];
    alert.tag = ACTION_EXACT;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex)
    {
        return;
    }
    switch (alertView.tag)
    {
        case ACTION_BID:
        {
            DiceAction *action = [DiceAction bidAction:state.playerID
                                                 count:currentBidCount
                                                  face:currentBidFace
                                                  push:[self makePushedDiceArray]];
            [game handleAction:action];
            break;
        }
        case ACTION_CHALLENGE_BID:
        case ACTION_CHALLENGE_PASS:
        {
            DiceAction *action = [DiceAction challengeAction:state.playerID
                                                      target:[self getChallengeTarget:alertView buttonIndex:buttonIndex]];
            [game handleAction:action];

        }
        case ACTION_EXACT:
        {
            DiceAction *action = [DiceAction exactAction:state.playerID];
            [game handleAction:action];
            break;
        }
        case ACTION_PASS:
        {
            DiceAction *action = [DiceAction passAction:state.playerID
                                                   push:[self makePushedDiceArray]];
            [game handleAction:action];
            break;
        }
        default: return;
    }
}

-(NSArray*)makePushedDiceArray {
    NSMutableArray *ar = [NSMutableArray array];
    for (Die *die in self.state.arrayOfDice)
    {
        if (die.markedToPush && !die.hasBeenPushed)
        {
            [ar addObject:die];
        }
    }
    NSArray *ret = [NSArray arrayWithArray:ar];
    return ret;
}
                                  
-(int)getChallengeTarget:(UIAlertView*)alertOrNil buttonIndex:(int)buttonIndex {
    if (alertOrNil == nil) return -1;
    if (buttonIndex == alertOrNil.cancelButtonIndex)
    {
        return -1;
    }
    int buttonOffset = buttonIndex - 1;
    Bid *challengeableBid = [state getChallengeableBid];
    if (challengeableBid != nil)
    {
        if (buttonOffset == 0)
        {
            return challengeableBid.playerID;
        }
        else
        {
            --buttonOffset;
        }
    }
    int passID = [state getChallengeableLastPass];
    if (passID != -1)
    {
        if (buttonOffset == 0)
        {
            return passID;
        }
        else
        {
            --buttonOffset;
        }
    }
    passID = [state getChallengeableSecondLastPass];
    if (passID != -1)
    {
        if (buttonOffset == 0)
        {
            return passID;
        }
        else
        {
            --buttonOffset;
        }
    }
    return -1;
}

#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Minimum: One cell for the header information plus one cell for each player
    return 1 + [game getNumberOfPlayers];
}

UILabel *makeLabel(NSString *text, int x, int y) {
    UILabel *ret = [[[UILabel alloc] init] autorelease];
    ret.numberOfLines = 0;
    CGSize maxSize = CGSizeMake(99999, 99999);
    CGSize size = [text sizeWithFont:[ret font]
                   constrainedToSize:maxSize
                       lineBreakMode:ret.lineBreakMode];
    ret.frame = CGRectMake(x, y, size.width, size.height);
    ret.text = text;
    ret.textColor = [UIColor blackColor];
    ret.backgroundColor = [UIColor clearColor];
    return ret;
}

// Make a UITableViewCell for the header cell.
UITableViewCell *headerCell(PlayGameTableView *table) {
    UITableViewCell *ret = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Header"] autorelease];
    [ret addSubview: makeLabel([table.state headerString:NO], margin(), margin())];
    return ret;
}

UIImage *imageForDie(int die) {
    if (die <= 0)
    {
        return [UIImage imageNamed:@"QuestionMark"];
    }
    NSString *dieName = [NSString stringWithFormat:@"die_%d", die];
    return [UIImage imageNamed:dieName];
}

// Called when the user presses on a die to push / unpush it.
- (void) dieButtonPressed:(id)dieID {
    
    // Check that it's this player's turn
    if (game.gameState.currentTurn != state.playerID) {
        return;
    }
    
    UIButton *button = (UIButton*)dieID;
    int dieIndex = button.tag;
    
    Die *dieObject = [self.state.arrayOfDice objectAtIndex:dieIndex];
    if (dieObject.hasBeenPushed)
    {
        return;
    }
    
    dieObject.markedToPush = ! dieObject.markedToPush;
    CGRect newFrame = button.frame;
    if (dieObject.markedToPush)
    {
        newFrame.origin.y = 0.0f;
    }
    else
    {
        newFrame.origin.y = button.superview.frame.size.height - button.frame.size.height;
    }
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3f];
    button.frame = newFrame;
    [UIView commitAnimations];
}

void addDice(PlayGameTableView *table, UITableViewCell *cell, NSArray *dice, bool showHidden, bool interactive) {
    UIView *diceView = [[[UIView alloc] initWithFrame:CGRectMake(margin(), cellTitleHeight() + margin(),
                                                                 diceViewWidth(), (interactive ? diceViewHeight() : diceViewFixedHeight()))] autorelease];
    int width = diceView.frame.size.width;
    int numDice = [dice count];
    int maxDice = 5;
    int dieWidth = (width - (margin() * (maxDice - 1))) / maxDice;
    for (int i = 0; i < numDice; ++i)
    {
        Die *die = [dice objectAtIndex:i];
        int x = (dieWidth + margin()) * i;
        int y;
        if (interactive && (die.hasBeenPushed || die.markedToPush))
        {
            y = 0;
        }
        else
        {
            y = diceView.frame.size.height - dieWidth;
        }
        int dieNumber = die.dieValue;
        CGRect buttonFrame = CGRectMake(x, y, dieWidth, dieWidth);
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = buttonFrame;
        button.tag = i;
        if (interactive) {
            [button addTarget:table action:@selector(dieButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        } else {
            button.enabled = NO;
        }
        button.adjustsImageWhenDisabled = NO;
        UIImage *dieImage = imageForDie((showHidden || die.hasBeenPushed) ? dieNumber : -1);
        [button setImage:dieImage forState:UIControlStateNormal];
        [diceView addSubview:button];
    }
    [cell addSubview:diceView];
}

// Add colors for the title of the cell and the push area of the cell.
void addCellColors(UITableViewCell *cell, float height, bool active) {
    if (!active) {
        CGRect backgroundFrame = CGRectMake(0, 0, cell.frame.size.width, height);
        UIView *backgroundColor = [[[UIView alloc] initWithFrame:backgroundFrame] autorelease];
        backgroundColor.backgroundColor = [UIColor colorWithRed:0.3f green:0.3f blue:0.3f alpha:1.0f];
        [cell addSubview: backgroundColor];
    }
    
    CGRect titleFrame = CGRectMake(0, 0, cell.frame.size.width, cellTitleBackgroundHeight());
    UIView *titleColor = [[[UIView alloc] initWithFrame:titleFrame] autorelease];
    titleColor.backgroundColor = [UIColor colorWithRed:0.5f green:0.8 blue:1.0f alpha:1.0f];
    [cell addSubview: titleColor];
    
    CGRect lineFrame = CGRectMake(0, 0, cell.frame.size.width, 2.0f);
    UIView *lineColor = [[[UIView alloc] initWithFrame:lineFrame] autorelease];
    lineColor.backgroundColor = [UIColor blackColor];
    [cell addSubview: lineColor];
}

// Make a UITableViewCell for the history item at the given index.
UITableViewCell *historyCell(PlayGameTableView *table, int index, bool active) {
    NSString *labelText;
    // What playerID goes in this slot
    int playerIndex = index;
    id <Player> player = [table.game.gameState.players objectAtIndex:playerIndex];
    NSString *playerName = [player getName];
    int playerID = [player getID];
    NSArray *lastMove = [table.game.gameState lastMoveForPlayer:playerID];
    if ([lastMove count] == 0) {
        // This player hasn't bid yet.
        // Figure out what playerID goes in this slot.
        labelText = playerName;
    } else {
        NSMutableString *moveString = [NSMutableString string];
        for (int i = [lastMove count] - 1; i >= 0; --i) {
            HistoryItem *item = [lastMove objectAtIndex:i];
            [moveString appendFormat:@"%@", [item asString]];
            if (i > 0) {
                [moveString appendFormat:@", "];
            }
        }
        labelText = moveString;
    }
    UITableViewCell *ret = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Header"] autorelease];
    addCellColors(ret, historyCellHeight(), active);
    [ret addSubview: makeLabel(labelText, margin(), titleTopMargin())];
    addDice(table, ret, ((PlayerState *)[table.game.gameState.playerStates objectAtIndex:playerIndex]).arrayOfDice, NO, NO);
    return ret;
}

// Makea UITableViewCell for the current player, with controls to make moves.
- (UITableViewCell *) controlCell:(bool)active {
    UITableViewCell *ret = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Control"] autorelease];
    addCellColors(ret, controlCellHeight(), active);
    [ret addSubview:makeLabel([NSString stringWithFormat:@"%@'s Turn", state.playerName], margin(), titleTopMargin())];
    
    // Dice
    addDice(self, ret, state.arrayOfDice, YES, YES);
    
    // Bid action button
    UIButton *bidButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [bidButton setTitle:@"Bid" forState:UIControlStateNormal];
    bidButton.frame = CGRectMake(ret.frame.size.width - controlButtonWidth() - margin(),
                                 controlCellHeight() - (controlButtonHeight() + margin()) * 2.0f,
                                 controlButtonWidth(),
                                 controlButtonHeight());
    [ret addSubview:bidButton];
    
    // Bid labels
    UIButton *countButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    countButton.frame = CGRectMake(ret.frame.size.width - (controlButtonWidth() + margin()) * 2.0f,
                                   controlCellHeight() - controlButtonHeight() - margin(),
                                   controlButtonWidth(),
                                   controlButtonHeight());
    [ret addSubview:countButton];
    
    UIButton *faceButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    faceButton.frame = CGRectMake(ret.frame.size.width - (controlButtonWidth() + margin()),
                                   controlCellHeight() - controlButtonHeight() - margin(),
                                   controlButtonWidth(),
                                   controlButtonHeight());
    [ret addSubview:faceButton];
    
    controlButtons.bidCountButton = countButton;
    controlButtons.bidFaceButton = faceButton;
    [self updateBidText];
    
    // Other actions
    UIButton *passButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [passButton setTitle:@"Pass" forState:UIControlStateNormal];
    passButton.frame = CGRectMake(margin(),
                                  controlCellHeight() - controlButtonHeight() - margin(),
                                  controlButtonWidth(),
                                  controlButtonHeight());
    [ret addSubview:passButton];
    
    UIButton *exactButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [exactButton setTitle:@"Exact" forState:UIControlStateNormal];
    exactButton.frame = CGRectMake(controlButtonWidth() + margin() * 2.0f,
                                  controlCellHeight() - controlButtonHeight() - margin(),
                                  controlButtonWidth(),
                                  controlButtonHeight());
    [ret addSubview:exactButton];
    
    controlButtons.bidButton = bidButton;
    controlButtons.exactButton = exactButton;
    controlButtons.passButton = passButton;
    
    [bidButton addTarget:self action:@selector(bidPressed:) forControlEvents:UIControlEventTouchUpInside];
    [countButton addTarget:self action:@selector(bidCountPlusPressed:) forControlEvents:UIControlEventTouchUpInside];
    [faceButton addTarget:self action:@selector(bidFacePlusPressed:) forControlEvents:UIControlEventTouchUpInside];
    [exactButton addTarget:self action:@selector(exactPressed:) forControlEvents:UIControlEventTouchUpInside];
    [passButton addTarget:self action:@selector(passPressed:) forControlEvents:UIControlEventTouchUpInside];

    return ret;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    int index = [indexPath row];
    if (index == 0) {
        // Header
        return headerCellHeight();
    }
    if (index == 1) {
        // Control cell
        return controlCellHeight();
    }
    // Other history cell
    return historyCellHeight();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int index = [indexPath row];
    UITableViewCell *ret;
    int playerID = index - 1;
    bool active = (playerID == game.gameState.currentTurn);
    if (index == 0) {
        ret = headerCell(self);
    } else if (index == 1) {
        ret = [self controlCell:active];
    } else {
        ret = historyCell(self, playerID, active);   
    }
    return ret;
}

@end
