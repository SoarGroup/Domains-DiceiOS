//
//  PlayGameView.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/5/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "PlayGameView.h"
#import "DiceGame.h"
#import "PlayerState.h"
#import "Die.h"
#import "DiceAction.h"
#import "DiceHistoryView.h"
#import "RoundOverView.h"
#import "MainMenu.h"
#import "DiceGraphics.h"

#import "UIImage+ImageEffects.h"

@interface PlayGameView()

-(void)constrainAndUpdateBidCount;
-(void)constrainAndUpdateBidFace;
-(NSArray*)makePushedDiceArray;
-(NSInteger)getChallengeTarget:(UIAlertView*)alertOrNil buttonIndex:(NSInteger) buttonIndex;

@end

@implementation PlayGameView
@synthesize quitButton, hasPromptedEnd;
@synthesize bidCountLabel;
@synthesize bidFaceLabel;
@synthesize bidCountPlusButton;
@synthesize bidCountMinusButton;
@synthesize bidFacePlusButton;
@synthesize bidFaceMinusButton;
@synthesize passButton;
@synthesize bidButton;
@synthesize exactButton;
@synthesize previousBidLabel;
@synthesize gameStateView;
@synthesize controlStateView;
@synthesize gameStateLabel;
@synthesize challengeButtons;
@synthesize tempViews, menu, images;

@synthesize game, state;

const int pushMargin() { return 48 / 2; }

NSString *numberName(int number) {
    return [NSString stringWithFormat:@"%ds", number];
    /*
	 static NSString *values[] = {
	 @"Ones",
	 @"Twos",
	 @"Threes",
	 @"Fours",
	 @"Fives",
	 @"Sixes",
	 };
	 return values[number - 1];
     */
}

NSArray *buildDiceImages() {
    NSMutableArray *ar = [NSMutableArray array];
    // Guarenteed that DIE_1 - DIE_6 are in order in the enum
    for (int i = 0; i < MAX_IMAGE_TYPE; ++i) {
        [ar addObject:[DiceGraphics imageWithType:i]];
    }
    return [NSArray arrayWithArray:ar];
}

- (id)initWithGame:(DiceGame*)aGame mainMenu:(MainMenu *)aMenu
{
	self = [super initWithNibName:@"PlayGameView" bundle:nil];

    if (self) {
        // Custom initialization
        self.game = aGame;
        self.game.gameView = self;
        self.state = nil;
        currentBidCount = 1;
        currentBidFace = 2;
        self.menu = aMenu;
        self.challengeButtons = [NSMutableArray array];
        self.tempViews = [NSMutableArray array];
        self.images = buildDiceImages();
		
		previousBidImageViews = [[NSMutableArray alloc] init];
        
		hasPromptedEnd = NO;
    }
    return self;
}

- (BOOL) roundEnding {
    RoundOverView *overView = [[[RoundOverView alloc]
                                initWithGame:self.game
                                player:state playGameView:self]
                               autorelease];
    [self.navigationController presentViewController:overView animated:YES completion:nil];
    return YES;
}

- (BOOL) roundBeginning {
    return NO;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // THIS IS THE ONLY PLACE THIS SHOULD GET CALLED FROM.
    NSLog(@"PlayGameView viewDidLoad");
    [self.game startGame];
    [self.game.gameState addNewRoundListener:self];
}

-(UIImage *)imageForDie:(NSInteger)die {
    if (die <= 0 || die > 6) return [self.images objectAtIndex:DIE_UNKNOWN];
    return [self.images objectAtIndex:(DIE_1 - 1 + die)];
}

-(NSString *)stringForDieFace:(NSInteger)die andIsPlural:(BOOL)plural {
	switch (die)
	{
		case 1:
			return [@"one" stringByAppendingString:(plural ? @"s" : @"")];
		case 2:
			return [@"two" stringByAppendingString:(plural ? @"s" : @"")];
		case 3:
			return [@"three" stringByAppendingString:(plural ? @"s" : @"")];
		case 4:
			return [@"four" stringByAppendingString:(plural ? @"s" : @"")];
		case 5:
			return [@"five" stringByAppendingString:(plural ? @"s" : @"")];
		case 6:
			return [@"six" stringByAppendingString:(plural ? @"es" : @"")];
		default:
			return [@"unknown" stringByAppendingString:(plural ? @"s" : @"")];
	}
}

- (IBAction)backPressed:(id)sender {
    NSString *title = [NSString stringWithFormat:@"Quit the game?"];
    NSString *message = nil; // (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %d dice?", [push count]];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Quit", nil]
                          autorelease];
    alert.tag = ACTION_QUIT;
    [alert show];
}

- (void)dealloc {
    [gameStateLabel release];
    [bidCountButton release];
    [bidFaceButton release];
    [bidFacePlusPressed release];
    [passButton release];
    [bidButton release];
    [exactButton release];
    [previousBidLabel release];
    [gameStateView release];
    [bidCountLabel release];
    [bidFaceLabel release];
    [quitButton release];
    [bidCountPlusButton release];
    [bidCountMinusButton release];
    [bidFacePlusButton release];
    [bidFaceMinusButton release];
	
	for (UIImageView* view in previousBidImageViews)
		[view release];
	
	[previousBidImageViews release];
    [super dealloc];
}

- (bool) canChallengePlayer:(int)otherPlayerID {
    Bid *challengeableBid = [state getChallengeableBid];
    if (challengeableBid != nil && challengeableBid.playerID == otherPlayerID)
    {
        return YES;
    }
    int passID = [state getChallengeableLastPass];
    if (passID != -1 && passID == otherPlayerID)
    {
        return YES;
    }
    passID = [state getChallengeableSecondLastPass];
    if (passID != -1 && passID == otherPlayerID)
    {
        return YES;
    }
    return NO;
}

- (void)updateState:(PlayerState*)newState
{
    self.state = newState;
    [self updateUI];
}

- (void) updateCurrentBidLabels {
    self.bidCountLabel.text = [NSString stringWithFormat:@"%d", currentBidCount];
    //self.bidFaceLabel.text = [NSString stringWithFormat:@"%ds", currentBidFace];
	//[self.bidFaceLabel sizeToFit];
	[self.bidFaceLabel setImage:[self imageForDie:currentBidFace]];
}

- (void) dieButtonPressed:(id)sender {
    UIButton *button = (UIButton*)sender;
    NSInteger dieIndex = button.tag;
	
    Die *dieObject = [self.state.arrayOfDice objectAtIndex:dieIndex];
    if (dieObject.hasBeenPushed)
    {
        return;
    }
    
    dieObject.markedToPush = ! dieObject.markedToPush;
    CGRect newFrame = button.frame;
    if (dieObject.markedToPush)
    {
        newFrame.origin.y = 0;
    }
    else
    {
        newFrame.origin.y = pushMargin();
    }
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3f];
    button.frame = newFrame;
    [UIView commitAnimations];
}

- (void)updateUI
{
    if (self.state == nil)
    {
        self.gameStateLabel.text = @"Waiting for game to begin";
        self.previousBidLabel.text = nil;
        self.passButton.enabled = NO;
        self.bidButton.enabled = NO;
        self.exactButton.enabled = NO;
        self.bidCountPlusButton.enabled = NO;
        self.bidCountMinusButton.enabled = NO;
        self.bidFacePlusButton.enabled = NO;
        self.bidFaceMinusButton.enabled = NO;
        return;
    }
    
    self.gameStateLabel.text = [NSString stringWithFormat:@"%@'s turn",
                                [[self.state.gameState getCurrentPlayer] getName]];
    Bid *previousBid = self.state.gameState.previousBid;
    NSString *headerString = [state headerString:NO];
	/*
	 if (previousBid == nil)
	 {
	 self.previousBidLabel.text = @"No previous bid";
	 }
	 else
	 {
	 */
	
	for (UIImageView* view in previousBidImageViews)
	{
		[view removeFromSuperview];
		[view release];
	}
	
	[previousBidImageViews removeAllObjects];
	
	NSMutableArray *locations = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *lines = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *numbers = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *beginning = [[[NSMutableArray alloc] init] autorelease];
	
	int line = 0;
	int location = 0;
	
	for (NSUInteger i = 0;i < [headerString length];i++)
	{
		if (isdigit([headerString characterAtIndex:i]))
		{
			int number = 0;
			
			NSInteger startLocation = i;
			
			for (;i < [headerString length];i++)
			{
				if (!isdigit([headerString characterAtIndex:i]))
					break;
				
				number *= 10;
				number += (int)([headerString characterAtIndex:i] - '0');
			}
			
			if (i == [headerString length])
				continue;
			
			if ([headerString characterAtIndex:i] == 's')
			{
				[locations addObject:[NSNumber numberWithInt:location]];
				[lines addObject:[NSNumber numberWithInt:line]];
				[numbers addObject:[NSNumber numberWithInt:number]];
				
				NSMutableString *previousPart = [[[NSMutableString alloc] init] autorelease];
				
				for (NSUInteger g = startLocation;g > 0;g--)
				{
					if ([headerString characterAtIndex:g] != '\n')
					{
						unichar* characters = (unichar*)malloc(sizeof(unichar));
						characters[0] = [headerString characterAtIndex:g];
						
						[previousPart insertString:[NSString stringWithCharacters:characters length:1] atIndex:0];
					}
					else
						break;
				}
				
				[beginning addObject:[NSString stringWithString:previousPart]];
				
				NSMutableString *spaces = [[[NSMutableString alloc] init] autorelease];
				
				for (int j = 0;j < (i - startLocation) + 3;j++)
					[spaces insertString:@" " atIndex:0];
								
				headerString = [headerString stringByReplacingCharactersInRange:NSMakeRange(startLocation, i-startLocation+1) withString:spaces];
			}
		}
		
		location++;
		
		if ([headerString characterAtIndex:i] == '\n')
		{
			line++;
			location = 0;
		}
	}
	
	if ([self.state.gameState usingSpecialRules])
	{
		self.previousBidLabel.text = [NSString stringWithFormat:@"%@\n(SPECIAL RULES)", headerString];
	}
	else
	{
		self.previousBidLabel.text = headerString;
	}
	// }
	
	if ([locations count] > 0)
	{
		for (int i = 0;i < [locations count];i++)
		{
			NSString* previous = [beginning objectAtIndex:i];
			
			CGSize widthSize = [previous sizeWithAttributes:[NSDictionary dictionaryWithObject:self.previousBidLabel.font forKey:NSFontAttributeName]];
			
			NSNumber *newLine = [lines objectAtIndex:i];
			
			int x = (int)widthSize.width + self.previousBidLabel.frame.origin.x - ([newLine integerValue] * 10);
			
			int y = (int)widthSize.height * [newLine integerValue] + self.previousBidLabel.frame.origin.y + 4;
			
			if ([self.state.gameState usingSpecialRules])
				y -= 10;
			
			NSNumber *die = [numbers objectAtIndex:i];
			
			NSInteger dieValue = [die integerValue];
			
			UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, 15, 15)];
			[imageView setImage:[self imageForDie:dieValue]];
			
			[self.view addSubview:imageView];
			
			[previousBidImageViews addObject:imageView];
		}
	}
    
    BOOL canBid = [self.state canBid];
    
    self.passButton.enabled = [self.state canPass];
    self.bidButton.enabled = canBid;
    self.bidCountPlusButton.enabled = canBid;
    self.bidCountMinusButton.enabled = canBid;
    self.bidFacePlusButton.enabled = canBid;
    self.bidFaceMinusButton.enabled = canBid;
    self.exactButton.enabled = [self.state canExact];
    
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
    
    [self updateCurrentBidLabels];
    
    // Update the contents of the gameStateView
    for (id subview in tempViews)
    {
        [subview removeFromSuperview];
    }
    [tempViews removeAllObjects];
    [challengeButtons removeAllObjects];
    
    NSArray *playerStates = self.state.gameState.playerStates;
    int i = -1;
    int labelHeight = 64 / 2;
    int diceHeight = 96 / 2;
    int dividerHeight = 8 / 2;
	
    int dy = labelHeight + diceHeight + dividerHeight;
    int buttonWidth = 160 / 2;
	bool hasHitControl = false;
	
    for (PlayerState *playerState in playerStates)
    {
        // Whether this player is the play that we're controlling
        bool control = self.state.playerID == playerState.playerID;
		
		if (control)
			hasHitControl = true;
		
        if (playerState.hasLost && !control)
        {
            // continue;
        }
        ++i;
        
        // Thae parent view to put these UI elements into.
        UIView *parent = (control ? controlStateView : gameStateView);
        
        int labelIndex = control ? 0 : i - 1;
        
        int starSize = 64 / 2;
        int x = starSize;
		
        int y = (hasHitControl ? labelIndex : labelIndex + 1) * dy;
		int width = parent.frame.size.width;
        int height = labelHeight;

        UIImageView *dividerView = [[[UIImageView alloc] initWithImage:[self barImage]] autorelease];
        dividerView.frame = CGRectMake(0, y, width, dividerHeight);
        [parent addSubview:dividerView];
        y += dividerHeight;
        CGRect nameLabelRect = CGRectMake(x, y, width - starSize, height);
        UILabel *nameLabel = [[[UILabel alloc] initWithFrame:nameLabelRect] autorelease];
        nameLabel.backgroundColor = [UIColor clearColor];
		[nameLabel setTextColor:[UIColor whiteColor]];

        [tempViews addObject:nameLabel];
		
		NSMutableAttributedString* nameLabelText = [self.game.gameState historyText:playerState.playerID colorName:control];
		for (NSUInteger z = 0;z < [nameLabelText length];z++)
		{
			if (isdigit([[nameLabelText string ]characterAtIndex:z]))
			{
				int number = 0;
				
				NSInteger startLocation = z;
				
				for (;z < [nameLabelText length];z++)
				{
					if (!isdigit([[nameLabelText string] characterAtIndex:z]))
						break;
					
					number *= 10;
					number += (int)([[nameLabelText string] characterAtIndex:z] - '0');
				}
				
				if (z == [nameLabelText length])
					continue;
				
				if ([[nameLabelText string] characterAtIndex:z] == 's')
				{
					NSMutableString *previousPart = [[[NSMutableString alloc] init] autorelease];
					
					for (NSUInteger g = startLocation;g > 0;g--)
					{
						if ([[nameLabelText string] characterAtIndex:g] != '\n')
						{
							unichar* characters = (unichar*)malloc(sizeof(unichar));
							characters[0] = [[nameLabelText string]characterAtIndex:g];
							
							[previousPart insertString:[NSString stringWithCharacters:characters length:1] atIndex:0];
						}
						else
							break;
					}
					
					NSMutableString *spaces = [[[NSMutableString alloc] init] autorelease];
					
					for (int j = 0;j < (z - startLocation) + 4;j++)
						[spaces insertString:@" " atIndex:0];
					
					[nameLabelText replaceCharactersInRange:NSMakeRange(startLocation, z-startLocation+1) withString:spaces];
					
					CGSize widthSize = [previousPart sizeWithAttributes:[NSDictionary dictionaryWithObject:nameLabel.font forKey:NSFontAttributeName]];
					
					int x_label = (int)widthSize.width + nameLabel.frame.origin.x;
					
					int y_label = nameLabel.frame.origin.y + 5;
										
					UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x_label, y_label, 25, 25)];
					[imageView setImage:[self imageForDie:number]];
					
					[parent addSubview:imageView];
					
					[previousBidImageViews addObject:imageView];
				}
			}
			
			location++;
		}
		
		nameLabel.attributedText = nameLabelText;
		
        if ([playerState isMyTurn])
        {
            if (!control) {
                int extraX = (buttonWidth - diceHeight) / 2;
                int extray = (buttonWidth + labelIndex - diceHeight) / 2;
                UIActivityIndicatorView* spinnerView = [[[UIActivityIndicatorView alloc] init] autorelease];
                spinnerView.frame = CGRectMake(width - buttonWidth + extraX, y + extray, diceHeight, diceHeight);
                [parent addSubview:spinnerView];
                [tempViews addObject:spinnerView];
                
                [spinnerView startAnimating];
            }
        }
        [parent addSubview:nameLabel];
        x = 0; // = x + width - starSize;
        y += labelHeight;
        CGRect diceFrame = CGRectMake(x, y, width - buttonWidth, control ? diceHeight + pushMargin() : diceHeight);
        UIView *diceView = [[[UIView alloc] initWithFrame:diceFrame] autorelease];
        int dieSize = (diceView.frame.size.width) / 5;
        if (dieSize > diceView.frame.size.height)
        {
            dieSize = diceView.frame.size.height;
        }
        for (int dieIndex = 0; dieIndex < playerState.numberOfDice; ++dieIndex)
        {
            x = dieIndex * (dieSize);
            int dieY = 0;
            Die *die = [playerState getDie:dieIndex];
            if (control) {
                if (!(die.hasBeenPushed || die.markedToPush)) {
                    dieY = pushMargin();
                }
            }
            CGRect dieFrame = CGRectMake(x, dieY, dieSize, dieSize);
            int dieFace = -1;
            if (die.hasBeenPushed || control)
            {
                dieFace = die.dieValue;
            }
            UIImage *dieImage = [images objectAtIndex:(dieFace == - 1 ? DIE_UNKNOWN : DIE_1 - 1 + dieFace)];
            if (control) {
                UIButton *dieButton = [UIButton buttonWithType:UIButtonTypeCustom];
                dieButton.frame = dieFrame;
                [dieButton setImage:dieImage forState:UIControlStateNormal];
                dieButton.tag = dieIndex;
                if (canBid) {
                    [dieButton addTarget:self action:@selector(dieButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                } else {
                    dieButton.userInteractionEnabled = NO;
                }
                [diceView addSubview:dieButton];
            } else {
                UIImageView *dieView = [[[UIImageView alloc] initWithFrame:dieFrame] autorelease];
                [dieView setImage:dieImage];
                [diceView addSubview:dieView];
            }
        }
        [parent addSubview:diceView];
        [tempViews addObject:diceView];
        
        // Possibly add challenge button.
        if (canBid && !control && [self canChallengePlayer:playerState.playerID]) {
            CGRect frame = CGRectMake(width - buttonWidth, y, buttonWidth, diceHeight);
            UIButton *challengeButton = [UIButton buttonWithType:UIButtonTypeSystem];
            challengeButton.frame = frame;
            [challengeButton setTitle:@"Challenge" forState:UIControlStateNormal];
            challengeButton.tag = playerState.playerID;
            [challengeButton addTarget:self action:@selector(challengePressed:) forControlEvents:UIControlEventTouchUpInside];
			[challengeButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28/255.0 alpha:1.0] forState:UIControlStateNormal];
            [parent addSubview:challengeButton];
            [challengeButtons addObject:challengeButton];
            [tempViews addObject:challengeButton];
        }
    }
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

-(void)constrainAndUpdateBidCount {
    int maxBidCount = 0;
	
	for (PlayerState* pstate in game.gameState.playerStates)
	{
		if ([pstate isKindOfClass:[PlayerState class]])
			maxBidCount += [[pstate arrayOfDice] count];
	}
	
    currentBidCount = (currentBidCount - 1 + maxBidCount) % maxBidCount + 1;
    [self updateCurrentBidLabels];
}

-(void)constrainAndUpdateBidFace {
    int maxFace = 6;
    currentBidFace = (currentBidFace - 1 + maxFace) % maxFace + 1;
    [self updateCurrentBidLabels];
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
                                           otherButtonTitles:@"Pass", nil]
                          autorelease];
    alert.tag = ACTION_PASS;
    [alert show];
}

- (IBAction)bidPressed:(id)sender {
    // Check that the bid is legal
	NSMutableArray *markedToPushDiceWithPushedDice = [NSMutableArray arrayWithArray:[state markedToPushDice]];
	[markedToPushDiceWithPushedDice addObjectsFromArray:[state pushedDice]];
	
    Bid *bid = [[[Bid alloc] initWithPlayerID:state.playerID name:state.playerName dice:currentBidCount rank:currentBidFace push:markedToPushDiceWithPushedDice] autorelease];
    if (!([game.gameState getCurrentPlayerState].playerID == state.playerID && [game.gameState checkBid:bid playerSpecialRules:([game.gameState usingSpecialRules] && [state numberOfDice] > 1)])) {
        NSString *title = @"Illegal raise";
		NSString *pushedDice = @"";
		
		if ([markedToPushDiceWithPushedDice count] > 0)
			pushedDice = [NSString stringWithFormat:@",\nAnd push %lu %@", (unsigned long)[[state markedToPushDice] count], ([[state markedToPushDice] count] == 1 ? @"die" : @"dice")];
		
        NSString *message = [NSString stringWithFormat:@"Can't bid %d %@ %@", currentBidCount, [self stringForDieFace:currentBidFace andIsPlural:(currentBidCount > 1)], pushedDice];
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"Okay"
                                               otherButtonTitles:nil]
                              autorelease];
		
        [alert show];
        return;
    }
    
    NSString *title = [NSString stringWithFormat:@"Bid %d %@?", currentBidCount, [self stringForDieFace:currentBidFace andIsPlural:(currentBidCount > 1)]];
    NSArray *push = [self makePushedDiceArray];
    NSString *message = (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %lu %@?", (unsigned long)[push count], ([push count] == 1 ? @"die" : @"dice")];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Bid", nil]
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
                                           otherButtonTitles:@"Exact", nil]
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
            break;
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
        case ACTION_QUIT:
        {
            [self.navigationController popToViewController:self.menu animated:YES];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
			
            [NSThread detachNewThreadSelector:@selector(end) toTarget:self.game withObject:nil];

#pragma clang diagnostic pop
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

-(NSInteger)getChallengeTarget:(UIAlertView*)alertOrNil buttonIndex:(NSInteger)buttonIndex {
    if (alertOrNil == nil) return -1;
    if (buttonIndex == alertOrNil.cancelButtonIndex)
    {
        return -1;
    }
    NSInteger buttonOffset = buttonIndex - 1;
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

- (IBAction)historyPressed:(id)sender {
    DiceHistoryView *history = [[[DiceHistoryView alloc] initWithPlayerState:self.state] autorelease];
    [self.navigationController presentViewController:history animated:YES completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

- (UIImage*)barImage
{
	CGSize size = CGSizeMake(1, 1);
	UIGraphicsBeginImageContextWithOptions(size, YES, 0);
	[[UIColor whiteColor] setFill];
	UIRectFill(CGRectMake(0, 0, size.width, size.height));
	UIImage *barImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return barImage;
}

-(UIImage *)blurredSnapshot
{
    // Create the image context
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, self.view.window.screen.scale);

    // There he is! The new API method
    [self.view drawViewHierarchyInRect:self.view.frame afterScreenUpdates:NO];

    // Get the snapshot
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();

    // Now apply the blur effect using Apple's UIImageEffect category
    UIImage *blurredSnapshotImage = [snapshotImage applyLightEffect];

    // Or apply any other effects available in "UIImage+ImageEffects.h"
    // UIImage *blurredSnapshotImage = [snapshotImage applyDarkEffect];
    // UIImage *blurredSnapshotImage = [snapshotImage applyExtraLightEffect];

    // Be nice and clean your mess up
    UIGraphicsEndImageContext();

    return blurredSnapshotImage;
}

@end
