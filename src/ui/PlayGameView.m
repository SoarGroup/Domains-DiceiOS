//
//  PlayGameView.m
//  Lair's Dice
//
//  Created by Miller Tinkerhess on 10/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlayGameView.h"
#import "DiceGame.h"
#import "PlayerState.h"
#import "DicePeekView.h"
#import "Die.h"
#import "DiceAction.h"
#import "DiceHistoryView.h"
#import "RoundOverView.h"
#import "DiceMainMenu.h"
#import "DiceGraphics.h"

@interface PlayGameView()

-(void)constrainAndUpdateBidCount;
-(void)constrainAndUpdateBidFace;
-(NSArray*)makePushedDiceArray;
-(int)getChallengeTarget:(UIAlertView*)alertOrNil buttonIndex:(int) buttonIndex;

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

- (id)initWithGame:(DiceGame*)aGame mainMenu:(DiceMainMenu *)aMenu
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
    [self.navigationController presentModalViewController:overView animated:YES];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.exactButton setImage:[self.images objectAtIndex:BUTTON_EXACT] forState:UIControlStateNormal];
    [self.exactButton setImage:[self.images objectAtIndex:BUTTON_EXACT_PRESSED] forState:UIControlStateHighlighted];
    [self.exactButton setTitle:@"" forState:UIControlStateNormal];
    
    [self.passButton setImage:[self.images objectAtIndex:BUTTON_PASS] forState:UIControlStateNormal];
    [self.passButton setImage:[self.images objectAtIndex:BUTTON_PASS_PRESSED] forState:UIControlStateHighlighted];
    [self.passButton setTitle:@"" forState:UIControlStateNormal];
    
    [self.bidButton setImage:[self.images objectAtIndex:BUTTON_BID] forState:UIControlStateNormal];
    [self.bidButton setImage:[self.images objectAtIndex:BUTTON_BID_PRESSED] forState:UIControlStateHighlighted];
	[self.bidButton setTitle:@"" forState:UIControlStateNormal];
    
    [self.quitButton setImage:[self.images objectAtIndex:BUTTON_QUIT] forState:UIControlStateNormal];
    [self.quitButton setImage:[self.images objectAtIndex:BUTTON_QUIT_PRESSED] forState:UIControlStateHighlighted];
	[self.quitButton setTitle:@"" forState:UIControlStateNormal];
    
    UIImage *padImage = [self.images objectAtIndex:BID_PAD];
    UIImage *padPressedImage = [self.images objectAtIndex:BID_PAD_PRESSED];
    int padWidth = padImage.size.width;
    int padHeight = padImage.size.height;
    int halfPadWidth = padWidth / 2;
    int halfPadHeight = padHeight / 2;
    UIButton *padButtons[] = {
        self.bidCountPlusButton,
        self.bidFacePlusButton,
        self.bidCountMinusButton,
        self.bidFaceMinusButton
    };
    for (int pressed = 0; pressed <= 1; ++pressed) {
        for (int x = 0; x <= 1; ++x) {
            for (int y = 0; y <= 1; ++y) {
                UIButton *padButton = padButtons[x + y * 2];
                CGRect crop = CGRectMake(halfPadWidth * x, halfPadHeight * y, halfPadWidth, halfPadHeight);
                CGImageRef imageRef = CGImageCreateWithImageInRect((pressed ? [padPressedImage CGImage]: [padImage CGImage]), crop);
                [padButton setImage:[UIImage imageWithCGImage:imageRef] forState:(pressed ? UIControlStateHighlighted : UIControlStateNormal)];
                CGImageRelease(imageRef);
            }
        }
    }
    
    // THIS IS THE ONLY PLACE THIS SHOULD GET CALLED FROM.
    NSLog(@"PlayGameView viewDidLoad");
    [self.game startGame];
    [self.game.gameState addNewRoundListener:self];
}

-(UIImage *)imageForDie:(int)die {
    if (die <= 0 || die > 6) return [self.images objectAtIndex:DIE_UNKNOWN];
    return [self.images objectAtIndex:(DIE_1 - 1 + die)];
}

- (void)viewDidUnload
{
    [self setGameStateLabel:nil];
    [self setPassButton:nil];
    [self setBidButton:nil];
    [self setExactButton:nil];
    [self setPreviousBidLabel:nil];
    [self setBidCountLabel:nil];
    [self setBidFaceLabel:nil];
    [self setQuitButton:nil];
    [self setBidCountPlusButton:nil];
    [self setBidCountMinusButton:nil];
    [self setBidFacePlusButton:nil];
    [self setBidFaceMinusButton:nil];
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
			
			int startLocation = i;
			
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
			
			CGSize widthSize = [previous sizeWithFont:self.previousBidLabel.font];
			
			NSNumber *line = [lines objectAtIndex:i];
			
			int x = (int)widthSize.width + self.previousBidLabel.frame.origin.x - ([line integerValue] * 10);
			
			int y = (int)widthSize.height * [line integerValue] + self.previousBidLabel.frame.origin.y + 10;
			
			NSNumber *die = [numbers objectAtIndex:i];
			
			int dieValue = [die integerValue];
			
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
        UIImageView *dividerView = [[[UIImageView alloc] initWithImage:[self.images objectAtIndex:BAR]] autorelease];
        dividerView.frame = CGRectMake(0, y, width, dividerHeight);
        [parent addSubview:dividerView];
        y += dividerHeight;
        CGRect nameLabelRect = CGRectMake(x, y, width - starSize, height);
        UILabel *nameLabel = [[[UILabel alloc] initWithFrame:nameLabelRect] autorelease];
        nameLabel.backgroundColor = [UIColor clearColor];
        [tempViews addObject:nameLabel];
		
		NSString* nameLabelText = [self.game.gameState historyText:playerState.playerID];
		for (NSUInteger i = 0;i < [nameLabelText length];i++)
		{
			if (isdigit([nameLabelText characterAtIndex:i]))
			{
				int number = 0;
				
				int startLocation = i;
				
				for (;i < [nameLabelText length];i++)
				{
					if (!isdigit([nameLabelText characterAtIndex:i]))
						break;
					
					number *= 10;
					number += (int)([nameLabelText characterAtIndex:i] - '0');
				}
				
				if (i == [nameLabelText length])
					continue;
				
				if ([nameLabelText characterAtIndex:i] == 's')
				{
					NSMutableString *previousPart = [[[NSMutableString alloc] init] autorelease];
					
					for (NSUInteger g = startLocation;g > 0;g--)
					{
						if ([nameLabelText characterAtIndex:g] != '\n')
						{
							unichar* characters = (unichar*)malloc(sizeof(unichar));
							characters[0] = [nameLabelText characterAtIndex:g];
							
							[previousPart insertString:[NSString stringWithCharacters:characters length:1] atIndex:0];
						}
						else
							break;
					}
					
					NSMutableString *spaces = [[[NSMutableString alloc] init] autorelease];
					
					for (int j = 0;j < (i - startLocation) + 3;j++)
						[spaces insertString:@" " atIndex:0];
					
					nameLabelText = [nameLabelText stringByReplacingCharactersInRange:NSMakeRange(startLocation, i-startLocation+1) withString:spaces];
					
					CGSize widthSize = [previousPart sizeWithFont:nameLabel.font];
					
					int x = (int)widthSize.width + nameLabel.frame.origin.x;
					
					int y = nameLabel.frame.origin.y + 5;
										
					UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, 25, 25)];
					[imageView setImage:[self imageForDie:number]];
					
					[parent addSubview:imageView];
					
					[previousBidImageViews addObject:imageView];
				}
			}
			
			location++;
		}
		
		nameLabel.text = nameLabelText;
		
        if ([playerState isMyTurn])
        {
            UIImageView *star = [[[UIImageView alloc] initWithFrame:CGRectMake(0, y, starSize, starSize)] autorelease];
            star.image = [images objectAtIndex:STAR];
            [parent addSubview:star];
            [tempViews addObject:star];
            if (!control) {
                int extraX = (buttonWidth - diceHeight) / 2;
                int extray = (buttonWidth + labelIndex - diceHeight) / 2;
                UIImageView *spinnerView = [[[UIImageView alloc] initWithImage:[self.images objectAtIndex:SPINNER]] autorelease];
                spinnerView.frame = CGRectMake(width - buttonWidth + extraX, y + extray, diceHeight, diceHeight);
                [parent addSubview:spinnerView];
                [tempViews addObject:spinnerView];
                
                [UIView beginAnimations:@"Spinner" context:nil];
                [UIView setAnimationDuration:0.6];
                [UIView setAnimationRepeatCount:FLT_MAX];
                [UIView setAnimationDelay:0.0];
                [UIView setAnimationCurve:UIViewAnimationCurveLinear];
                spinnerView.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
                [UIView commitAnimations];
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
            UIButton *challengeButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [challengeButton setImage:[self.images objectAtIndex:BUTTON_CHALLENGE] forState:UIControlStateNormal];
            [challengeButton setImage:[self.images objectAtIndex:BUTTON_CHALLENGE_PRESSED] forState:UIControlStateHighlighted];
            challengeButton.frame = frame;
            [challengeButton setTitle:@"Challenge" forState:UIControlStateNormal];
            challengeButton.tag = playerState.playerID;
            [challengeButton addTarget:self action:@selector(challengePressed:) forControlEvents:UIControlEventTouchUpInside];
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
    int maxBidCount = [self.state getNumberOfPlayers] * 5;
    currentBidCount = (currentBidCount - 1 + maxBidCount) % maxBidCount + 1;
    [self updateCurrentBidLabels];
}

-(void)constrainAndUpdateBidFace {
    int maxFace = 6;
    currentBidFace = (currentBidFace - 1 + maxFace) % maxFace + 1;
    [self updateCurrentBidLabels];
}

- (IBAction)challengePressed:(id)sender {
    UIButton *challengeButton = (UIButton *) sender;
    int challengeTargetID = challengeButton.tag;
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
    Bid *bid = [[[Bid alloc] initWithPlayerID:state.playerID name:state.playerName dice:currentBidCount rank:currentBidFace] autorelease];
    if (!([game.gameState getCurrentPlayerState].playerID == state.playerID && [game.gameState checkBid:bid playerSpecialRules:([game.gameState usingSpecialRules] && [state numberOfDice] > 1)])) {
        NSString *title = @"Illegal raise";
        NSString *message = [NSString stringWithFormat:@"Can't bid %d       ", currentBidCount];
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"Okay"
                                               otherButtonTitles:nil]
                              autorelease];
		UIImageView *dieFace = [[[UIImageView alloc] initWithFrame:CGRectMake(170, 43, 25, 25)] autorelease];
		[dieFace setImage:[self imageForDie:currentBidFace]];
		
		[alert addSubview:dieFace];
		
        [alert show];
        return;
    }
    
    NSString *title = [NSString stringWithFormat:@"Bid %d        ?", currentBidCount];
    NSArray *push = [self makePushedDiceArray];
    NSString *message = (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %d dice?", [push count]];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Bid", nil]
                          autorelease];
    alert.tag = ACTION_BID;
	
	UIImageView *dieFace = [[[UIImageView alloc] initWithFrame:CGRectMake(145 + (currentBidCount >= 10 ? 5 : 0), 15, 25, 25)] autorelease];
	[dieFace setImage:[self imageForDie:currentBidFace]];
	
	[alert addSubview:dieFace];
	
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
            [NSThread detachNewThreadSelector:@selector(end) toTarget:self.game withObject:nil];
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

- (IBAction)historyPressed:(id)sender {
    DiceHistoryView *history = [[[DiceHistoryView alloc] initWithPlayerState:self.state] autorelease];
    [self.navigationController presentModalViewController:history animated:YES];
}

@end
