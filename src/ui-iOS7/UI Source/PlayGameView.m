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

#import <Foundation/NSObjCRuntime.h>

@implementation UIViewController (BackButtonHandler)

@end

@implementation UINavigationController (ShouldPopOnBackButton)

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {

	if([self.viewControllers count] < [navigationBar.items count]) {
		return YES;
	}

	BOOL shouldPop = YES;
	UIViewController* vc = [self topViewController];
	if([vc respondsToSelector:@selector(navigationShouldPopOnBackButton)]) {
		shouldPop = [vc navigationShouldPopOnBackButton];
	}

	if(shouldPop) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self popViewControllerAnimated:YES];
		});
	} else {
		// Workaround for iOS7.1. Thanks to @boliva - http://stackoverflow.com/posts/comments/34452906
		for(UIView *subview in [navigationBar subviews]) {
			if(subview.alpha < 1.) {
				[UIView animateWithDuration:.25 animations:^{
					subview.alpha = 1.;
				}];
			}
		}
	}

	return NO;
}

@end

@implementation UIApplication (AppDimensions)

+(CGSize) currentSize
{
    return [UIApplication sizeInOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

+(CGSize) sizeInOrientation:(UIInterfaceOrientation)orientation
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    UIApplication *application = [UIApplication sharedApplication];
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        size = CGSizeMake(size.height, size.width);
    }
    if (application.statusBarHidden == NO)
    {
        size.height -= MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    }
    return size;
}

@end

@interface PlayGameView()

-(void)constrainAndUpdateBidCount;
-(void)constrainAndUpdateBidFace;
-(NSArray*)makePushedDiceArray;
-(NSInteger)getChallengeTarget:(UIAlertView*)alertOrNil buttonIndex:(NSInteger) buttonIndex;
-(void)updateFullScreenUI;
-(void)updateNonFullScreenUI:(UIView*)controlStateView gameStateView:(UIScrollView*)gameStateView;
-(void)initializeUI;

- (void)fullScreenViewInitialization;
- (void)fullScreenViewGameInitialization;

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
@synthesize gameStateView;
@synthesize controlStateView;
@synthesize gameStateLabel;
@synthesize challengeButtons;
@synthesize fullscreenButton;
@synthesize tempViews, images;

@synthesize game, state, isCustom;

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

- (id)initWithGame:(DiceGame *)theGame withQuitHandler:(void (^)(void))QuitHandler
{
	return [self initWithGame:theGame withQuitHandler:QuitHandler withCustomMainView:NO];
}

- (id)initWithGame:(DiceGame*)aGame withQuitHandler:(void (^)(void))QuitHandler withCustomMainView:(BOOL)custom
{
	if (!custom)
	{
		NSString* device = [UIDevice currentDevice].model;
		device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];

		if ([device isEqualToString:@"iPhone"])
			device = @"";

		self = [super initWithNibName:[@"PlayGameView" stringByAppendingString:device] bundle:nil];
		self.isCustom = NO;
	}
	else
	{
		self = [super initWithNibName:@"PlayGameView" bundle:nil];
		self.isCustom = YES;
	}

    if (self)
	{
        // Custom initialization
        self.game = aGame;
        self.game.gameView = self;
        self.state = nil;
        currentBidCount = 1;
        currentBidFace = 2;
        quitHandler = QuitHandler;
		[quitHandler retain];
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

- (void)viewWillAppear:(BOOL)animated
{
	if (self.view.frame.size.width > 500)
		fullScreenView = YES;
	else
		fullScreenView = NO;

    self.navigationController.navigationBarHidden = !fullScreenView;
}

- (void)fullScreenViewInitialization
{
	// Game State Label Creation

	self.gameStateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 220, 80)];
	[gameStateLabel setTextColor:[UIColor whiteColor]];
	gameStateLabel.numberOfLines = 0;
	gameStateLabel.lineBreakMode = NSLineBreakByTruncatingTail;
	[self.view addSubview:self.gameStateLabel];

	// Control State (Player Location/Controls!) Creation

	self.controlStateView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 180)];
	controlStateView.userInteractionEnabled = YES;

	self.exactButton = [[UIButton alloc] init];
	exactButton.frame = CGRectMake(2, 64, 60, 44);
	[exactButton setTitle:@"Exact" forState:UIControlStateNormal];
	[exactButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
	exactButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
	[exactButton addTarget:self action:@selector(exactPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlStateView addSubview:exactButton];

	self.passButton = [[UIButton alloc] init];
	passButton.frame = CGRectMake(70, 64, 60, 44);
	[passButton setTitle:@"Pass" forState:UIControlStateNormal];
	[passButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
	passButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
	[passButton addTarget:self action:@selector(passPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlStateView addSubview:passButton];

	self.bidButton = [[UIButton alloc] init];
	bidButton.frame = CGRectMake(138, 64, 60, 44);
	[bidButton setTitle:@"Bid" forState:UIControlStateNormal];
	[bidButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
	bidButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
	[bidButton addTarget:self action:@selector(bidPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlStateView addSubview:bidButton];

	self.bidCountPlusButton = [[UIButton alloc] init];
	bidCountPlusButton.frame = CGRectMake(200, 0, 40, 36);
	[bidCountPlusButton setTitle:@"+" forState:UIControlStateNormal];
	[bidCountPlusButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
	bidCountPlusButton.titleLabel.font = [UIFont boldSystemFontOfSize:25];
	[bidCountPlusButton addTarget:self action:@selector(bidCountPlusPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlStateView addSubview:bidCountPlusButton];

	self.bidCountMinusButton = [[UIButton alloc] init];
	bidCountMinusButton.frame = CGRectMake(200, 68, 40, 36);
	[bidCountMinusButton setTitle:@"-" forState:UIControlStateNormal];
	[bidCountMinusButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
	bidCountMinusButton.titleLabel.font = [UIFont boldSystemFontOfSize:25];
	[bidCountMinusButton addTarget:self action:@selector(bidCountMinusPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlStateView addSubview:bidCountMinusButton];

	self.bidFacePlusButton = [[UIButton alloc] init];
	bidFacePlusButton.frame = CGRectMake(239, 0, 40, 36);
	[bidFacePlusButton setTitle:@"+" forState:UIControlStateNormal];
	[bidFacePlusButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
	bidFacePlusButton.titleLabel.font = [UIFont boldSystemFontOfSize:25];
	[bidFacePlusButton addTarget:self action:@selector(bidFacePlusPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlStateView addSubview:bidFacePlusButton];

	self.bidFaceMinusButton = [[UIButton alloc] init];
	bidFaceMinusButton.frame = CGRectMake(239, 68, 40, 36);
	[bidFaceMinusButton setTitle:@"-" forState:UIControlStateNormal];
	[bidFaceMinusButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
	bidFaceMinusButton.titleLabel.font = [UIFont boldSystemFontOfSize:25];
	[bidFaceMinusButton addTarget:self action:@selector(bidFaceMinusPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlStateView addSubview:bidFaceMinusButton];

	self.bidFaceLabel = [[UIImageView alloc] initWithImage:[self imageForDie:2]];
	bidFaceLabel.frame = CGRectMake(247, 44, 25, 21);
	[self.controlStateView addSubview:bidFaceLabel];

	self.bidCountLabel = [[UILabel alloc] init];
	bidCountLabel.frame = CGRectMake(215, 44, 30, 21);
	[bidCountLabel setText:@"1"];
	[bidCountLabel setTextColor:[UIColor whiteColor]];
	bidCountLabel.font = [UIFont boldSystemFontOfSize:17];
	[self.controlStateView addSubview:bidCountLabel];

	[self.view addSubview:self.controlStateView];
}

- (void)fullScreenViewGameInitialization
{
	// Correction based on how many players there are

	NSArray *playerStates = self.state.gameState.playerStates;

	unsigned long playerCount = [playerStates count];

	CGSize screenSize = [UIApplication sizeInOrientation:self.interfaceOrientation];

	double divisionFactor = 2.0;

	if (playerCount == 8)
		divisionFactor = 3.0;

	[self.gameStateLabel setFrame:CGRectMake(screenSize.width / 2.0 - self.gameStateLabel.frame.size.width / 2.0 + 8,
											 screenSize.height / 2.0 - self.gameStateLabel.frame.size.height / 2.0,
											 self.gameStateLabel.frame.size.width,
											 self.gameStateLabel.frame.size.height)];

	[self.controlStateView setFrame:CGRectMake(screenSize.width / divisionFactor - self.controlStateView.frame.size.width / 2.0,
											   screenSize.height * 7.6/ 8.0 - self.controlStateView.frame.size.height / 2.0 - 40,
											   self.controlStateView.frame.size.width,
											   self.controlStateView.frame.size.height)];

	self.navigationItem.title = [NSString stringWithFormat:@"Single Player Match: %lu Players", playerCount];

	centerPush = [[UIView alloc] initWithFrame:CGRectMake(292.5, 221, 442, 308)];
	UIImageView* centerPushImage = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Center-Push"]] autorelease];
	centerPushImage.frame = CGRectMake(0, 0, 442, 308);
	[centerPush addSubview:centerPushImage];

	[self.view addSubview:centerPush];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	if (self.view.frame.size.width > 500)
		fullScreenView = YES;
	else
		fullScreenView = NO;

    // THIS IS THE ONLY PLACE THIS SHOULD GET CALLED FROM.
    NSLog(@"PlayGameView viewDidLoad");

	if (fullScreenView)
		[self fullScreenViewInitialization];

	for (id<Player> player in self.game.players)
	{
		if ([player isKindOfClass:DiceLocalPlayer.class])
		{
			[(DiceLocalPlayer*)player setGameView:self];
			break;
		}
	}

    [self.game startGame];
    [self.game.gameState addNewRoundListener:self];

	if (fullScreenView)
		[self fullScreenViewGameInitialization];

	if (isCustom && !fullScreenView)
		fullscreenButton.hidden = NO;
}

-(BOOL) navigationShouldPopOnBackButton {
	[self backPressed:nil];

	return NO;
}

-(UIImage *)imageForDie:(NSInteger)die
{
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
    NSString *message = nil;
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
    [passButton release];
    [bidButton release];
    [exactButton release];
    [gameStateView release];
    [bidCountLabel release];
    [bidFaceLabel release];
    [quitButton release];
    [bidCountPlusButton release];
    [bidCountMinusButton release];
    [bidFacePlusButton release];
    [bidFaceMinusButton release];
	[centerPush release];
	[quitHandler release];
	
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
	[self.bidFaceLabel setImage:[self imageForDie:currentBidFace]];
}

- (void) dieButtonPressed:(id)sender {
    UIButton *button = (UIButton*)sender;
    NSInteger dieIndex = button.tag;
	
    Die *dieObject = [self.state.arrayOfDice objectAtIndex:dieIndex];
    if (dieObject.hasBeenPushed)
        return;
    
    dieObject.markedToPush = ! dieObject.markedToPush;
    CGRect newFrame = button.frame;
    if (dieObject.markedToPush)
        newFrame.origin.y = fullScreenView ? 30 - pushMargin() : 0;
    else
        newFrame.origin.y = fullScreenView ? 30 : pushMargin();

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3f];
    button.frame = newFrame;
    [UIView commitAnimations];
}

- (void)initializeUI
{
	self.gameStateLabel.text = @"Waiting for game to begin";
	self.passButton.enabled = NO;
	self.bidButton.enabled = NO;
	self.exactButton.enabled = NO;
	self.bidCountPlusButton.enabled = NO;
	self.bidCountMinusButton.enabled = NO;
	self.bidFacePlusButton.enabled = NO;
	self.bidFaceMinusButton.enabled = NO;
}

- (void)updateUI
{
	if (![NSThread isMainThread])
	{
		[self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:YES];

		return;
	}

	// State initialization
    if (self.state == nil)
    {
		[self initializeUI];
        return;
    }

	// Header string, "Bob big 5 6s.\n19 dice, 2 4s, 14 unknown.
    self.gameStateLabel.text = [NSString stringWithFormat:@"%@'s turn",
                                [[self.state.gameState getCurrentPlayer] getName]]; // This is incase it sets something wrong?
    Bid *previousBid = self.state.gameState.previousBid;
    NSString *headerString = [state headerString:NO]; // This sets it

	// Dealloc all old die images
	for (UIImageView* view in previousBidImageViews)
	{
		[view removeFromSuperview];
		[view release];
	}

	// Remove them all
	[previousBidImageViews removeAllObjects];

	// Arrays for die images
	NSMutableArray *locations = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *lines = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *numbers = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *beginning = [[[NSMutableArray alloc] init] autorelease];
	
	int line = 0;
	int location = 0;

	// Replace die values with spaces for images "6s" -> "   "
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
				
				for (int j = 0;j < (i - startLocation) + 2;j++)
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

	self.gameStateLabel.text = headerString;

	// Add the die images to the player info label
	if ([locations count] > 0)
	{
		for (int i = 0;i < [locations count];i++)
		{
			NSString* previous = [beginning objectAtIndex:i];
			
			CGSize widthSize = [previous sizeWithAttributes:[NSDictionary dictionaryWithObject:self.gameStateLabel.font forKey:NSFontAttributeName]];
			
			NSNumber *newLine = [lines objectAtIndex:i];
			
			int x = (int)widthSize.width + self.gameStateLabel.frame.origin.x - ([newLine integerValue] * 10);
			
			int y = (int)widthSize.height * [newLine integerValue] + self.gameStateLabel.frame.origin.y + (fullScreenView ? 23 : 4);
			
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

	// Player UI
    BOOL canBid = [self.state canBid];

	// Enable the buttons if we actually can do those actions at this update cycle
    self.passButton.enabled = canBid && [self.state canPass];
    self.bidButton.enabled = canBid;
    self.bidCountPlusButton.enabled = canBid;
    self.bidCountMinusButton.enabled = canBid;
    self.bidFacePlusButton.enabled = canBid;
    self.bidFaceMinusButton.enabled = canBid;
    self.exactButton.enabled = canBid && [self.state canExact];

	if (self.exactButton.enabled)
		[self.exactButton.titleLabel setTextColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28/255.0 alpha:1.0]];
	else
		[self.exactButton.titleLabel setTextColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0]];

	if (self.passButton.enabled)
		[self.passButton.titleLabel setTextColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28/255.0 alpha:1.0]];
	else
		[self.passButton.titleLabel setTextColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0]];

	if (self.bidButton.enabled)
		[self.bidButton.titleLabel setTextColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28/255.0 alpha:1.0]];
	else
		[self.bidButton.titleLabel setTextColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0]];

	// Check if our previous bid is nil, if it is then we're starting and set the default dice to be bidding 1 two.
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

	// Update the bid "scroller" labels, the die image and number for the bid chooser
    [self updateCurrentBidLabels];
    
    // Update the contents of the gameStateView
	// iPad and iPhone specific
	if (!fullScreenView)
		[self updateNonFullScreenUI:controlStateView gameStateView:gameStateView];
	else
		[self updateFullScreenUI];
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
    [aScrollView setContentOffset: CGPointMake(0, aScrollView.contentOffset.y)];
}

- (void)updateNonFullScreenUI:(UIView*)controlStateViewToUpdate gameStateView:(UIScrollView*)gameStateViewToUpdate
{
	// Remove all challenge buttons and all unused images
    for (id subview in tempViews)
        [subview removeFromSuperview]; // auto released

    [tempViews removeAllObjects];
    [challengeButtons removeAllObjects];

    NSArray *playerStates = self.state.gameState.playerStates;
	BOOL canBid = [self.state canBid];
	int location = 0;
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

        ++i;

        // The parent view to put these UI elements into.
        UIView *parent = (control ? controlStateViewToUpdate : gameStateViewToUpdate);

        int labelIndex = control ? 0 : i - 1;

        int starSize = 64 / 2;
        int x = starSize;

        int y = (hasHitControl ? labelIndex : labelIndex + 1) * dy;
		int width = parent.frame.size.width;
        int height = labelHeight;

        UIImageView *dividerView = [[[UIImageView alloc] initWithImage:[PlayGameView barImage]] autorelease];
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
            UIImage *dieImage = [self imageForDie:dieFace];
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

	gameStateViewToUpdate.contentSize = CGSizeMake(gameStateViewToUpdate.frame.size.width, i*dy);
}

- (void)updateFullScreenUI
{
	// Remove all challenge buttons and all unused images
    for (id subview in tempViews)
        [subview removeFromSuperview]; // auto released

    [tempViews removeAllObjects];
    [challengeButtons removeAllObjects];

    NSArray *playerStates = self.state.gameState.playerStates;
	BOOL canBid = [self.state canBid];

	unsigned long playerCount = [playerStates count];
	int diceHeight = 96 / 2;

	CGSize screenSize = [UIApplication sizeInOrientation:self.interfaceOrientation];

	CGSize viewSize = controlStateView.frame.size;

	// Location mapping based on the number of players
	// Unfortunately there isn't a good way to debug this or come up with an algorithm for this so I just hard coded it
	CGPoint player1Location = {screenSize.width / 2.0 - viewSize.width / 2.0, 7.0 / 8.0 * screenSize.height - viewSize.height / 2.0 - 40};
	CGRect player1TextLabelFrame = {{0, 0}, {280, 90}};
	CGRect player1DiceFrame = {{0, 90}, {280, 80}};
	CGRect player1PushFrame = {{171, 198}, {100, 100}};

	CGPoint player2Location = {screenSize.width * 0.1/8.0, screenSize.height / 2.0 - viewSize.height / 2.0};
	CGRect player2TextLabelFrame = {{55, 0}, {230, 140}};
	CGRect player2DiceFrame = {{0, -55}, {50, 195}};
	CGRect player2PushFrame = {{15, 104}, {100, 100}};

	CGPoint player3Location = {screenSize.width / 2.0 - viewSize.width / 2.0, 1.0 / 8.0 * screenSize.height};
	CGRect player3TextLabelFrame = {{0, 50}, {280, 90}};
	CGRect player3DiceFrame = {{0, 0}, {280, 50}};
	CGRect player3PushFrame = {{171, 10}, {100, 100}};

	CGPoint player4Location = {screenSize.width * 7.9/8.0 - viewSize.width, screenSize.height / 2.0 - viewSize.height / 2.0};
	CGRect player4TextLabelFrame = {{0, 0}, {230, 140}};
	CGRect player4DiceFrame = {{230, -55}, {50, 195}};
	CGRect player4PushFrame = {{322, 104}, {100, 100}};


	CGPoint player1AltLocation = {screenSize.width / 3.0 - viewSize.width / 2.0, 7.0 / 8.0 * screenSize.height - viewSize.height / 2.0 - 40};
	CGRect player1AltTextLabelFrame = {{0, 0}, {280, 90}};
	CGRect player1AltDiceFrame = {{0, 90}, {280, 50}};
	CGRect player1AltPushFrame = {{117, 198}, {100, 100}};

	CGPoint player2AltLocation = {screenSize.width * 0.1/8.0, screenSize.height * 1.8 / 3.0 - viewSize.height / 2.0};
	CGRect player2AltTextLabelFrame = {{55, 0}, {230, 140}};
	CGRect player2AltDiceFrame = {{0, 0}, {50, 250}};
	CGRect player2AltPushFrame = {{15, 155}, {100, 100}};

	CGPoint player3AltLocation = {screenSize.width * 0.1/8.0, screenSize.height * 1.2 / 3.0 - viewSize.height / 2.0};
	CGRect player3AltTextLabelFrame = {{55, 0}, {230, 140}};
	CGRect player3AltDiceFrame = {{0, -110}, {50, 250}};
	CGRect player3AltPushFrame = {{15, 53}, {100, 100}};

	CGPoint player4AltLocation = {screenSize.width / 3.0 - viewSize.width / 2.0, 0.8 / 8.0 * screenSize.height};
	CGRect player4AltTextLabelFrame = {{0, 50}, {280, 90}};
	CGRect player4AltDiceFrame = {{0, 0}, {280, 50}};
	CGRect player4AltPushFrame = {{117, 10}, {100, 100}};

	CGPoint player5Location = {screenSize.width * 2.0 / 3.0 - viewSize.width / 2.0, 0.8 / 8.0 * screenSize.height};
	CGRect player5TextLabelFrame = {{0, 50}, {280, 90}};
	CGRect player5DiceFrame = {{0, 0}, {280, 50}};
	CGRect player5PushFrame = {{220, 10}, {100, 100}};

	CGPoint player6Location = {screenSize.width * 7.9/8.0 - viewSize.width, screenSize.height * 1.2 / 3.0 - viewSize.height / 2.0};
	CGRect player6TextLabelFrame = {{0, 0}, {230, 140}};
	CGRect player6DiceFrame = {{230, -110}, {50, 250}};
	CGRect player6PushFrame = {{322, 53}, {100, 100}};

	CGPoint player7Location = {screenSize.width * 7.9/8.0 - viewSize.width, screenSize.height * 1.8 / 3.0 - viewSize.height / 2.0};
	CGRect player7TextLabelFrame = {{0, 0}, {230, 140}};
	CGRect player7DiceFrame = {{230, 0}, {50, 250}};
	CGRect player7PushFrame = {{322, 155}, {100, 100}};

	CGPoint player8Location = {screenSize.width * 2.0 / 3.0 - viewSize.width / 2.0, 7.6 / 8.0 * screenSize.height - viewSize.height / 2.0 - 10};
	CGRect player8TextLabelFrame = {{0, 0}, {280, 90}};
	CGRect player8DiceFrame = {{0, 90}, {280, 50}};
	CGRect player8PushFrame = {{220, 198}, {100, 100}};

	switch (playerCount)
	{
		case 2:
			player2Location = player3Location;
			player2DiceFrame = player3DiceFrame;
			player2TextLabelFrame = player3TextLabelFrame;
			player2PushFrame = player3PushFrame;
			break;
		case 5:
			player5Location = player4Location;
			player5DiceFrame = player4DiceFrame;
			player5TextLabelFrame = player4TextLabelFrame;
			player5PushFrame = player4PushFrame;

			player4Location = player3Location;
			player4DiceFrame = player3DiceFrame;
			player4TextLabelFrame = player3TextLabelFrame;
			player4PushFrame = player3PushFrame;

			player2Location = player2AltLocation;
			player2DiceFrame = player2AltDiceFrame;
			player2TextLabelFrame = player2AltTextLabelFrame;
			player2PushFrame = player2AltPushFrame;

			player3Location = player3AltLocation;
			player3DiceFrame = player3AltDiceFrame;
			player3TextLabelFrame = player3AltTextLabelFrame;
			player3PushFrame = player3AltPushFrame;
			break;
		case 6:
			player6Location = player4Location;
			player6DiceFrame = player4DiceFrame;
			player6TextLabelFrame = player4TextLabelFrame;
			player6PushFrame = player4PushFrame;

			player2Location = player2AltLocation;
			player2DiceFrame = player2AltDiceFrame;
			player2TextLabelFrame = player2AltTextLabelFrame;
			player2PushFrame = player2AltPushFrame;

			player3Location = player3AltLocation;
			player3DiceFrame = player3AltDiceFrame;
			player3TextLabelFrame = player3AltTextLabelFrame;
			player3PushFrame = player3AltPushFrame;

			player4Location = player4AltLocation;
			player4DiceFrame = player4AltDiceFrame;
			player4TextLabelFrame = player4AltTextLabelFrame;
			player4PushFrame = player4AltPushFrame;
			break;
		case 7:
			player2Location = player2AltLocation;
			player2DiceFrame = player2AltDiceFrame;
			player2TextLabelFrame = player2AltTextLabelFrame;
			player2PushFrame = player2AltPushFrame;

			player3Location = player3AltLocation;
			player3DiceFrame = player3AltDiceFrame;
			player3TextLabelFrame = player3AltTextLabelFrame;
			player3PushFrame = player3AltPushFrame;

			player4Location = player4AltLocation;
			player4DiceFrame = player4AltDiceFrame;
			player4TextLabelFrame = player4AltTextLabelFrame;
			player4PushFrame = player4AltPushFrame;
			break;
		case 8:
			player1Location = player1AltLocation;
			player1TextLabelFrame = player1AltTextLabelFrame;
			player1DiceFrame = player1AltDiceFrame;
			player1PushFrame = player1AltPushFrame;

			player2Location = player2AltLocation;
			player2DiceFrame = player2AltDiceFrame;
			player2TextLabelFrame = player2AltTextLabelFrame;
			player2PushFrame = player2AltPushFrame;

			player3Location = player3AltLocation;
			player3DiceFrame = player3AltDiceFrame;
			player3TextLabelFrame = player3AltTextLabelFrame;
			player3PushFrame = player3AltPushFrame;

			player4Location = player4AltLocation;
			player4DiceFrame = player4AltDiceFrame;
			player4TextLabelFrame = player4AltTextLabelFrame;
			player4PushFrame = player4AltPushFrame;
			break;
		default:
			break;
	}

	CGPoint locations[] = {	player1Location,
							player2Location,
							player3Location,
							player4Location,
							player5Location,
							player6Location,
							player7Location,
							player8Location};
	CGRect textFrames[] = { player1TextLabelFrame,
							player2TextLabelFrame,
							player3TextLabelFrame,
							player4TextLabelFrame,
							player5TextLabelFrame,
							player6TextLabelFrame,
							player7TextLabelFrame,
							player8TextLabelFrame};

	CGRect diceFrames[] = { player1DiceFrame,
							player2DiceFrame,
							player3DiceFrame,
							player4DiceFrame,
							player5DiceFrame,
							player6DiceFrame,
							player7DiceFrame,
							player8DiceFrame};

	CGRect pushFrames[] = {	player1PushFrame,
							player2PushFrame,
							player3PushFrame,
							player4PushFrame,
							player5PushFrame,
							player6PushFrame,
							player7PushFrame,
							player8PushFrame};

	CGPoint pushLocations[] = { {0,50},
								{50,50},
								{0,0},
								{50,0}};

	// Add all the players with their locations
	for (int i = 0;i < playerCount;++i)
	{
		UIView* playerLocation = nil;

		if (i != 0)
			playerLocation = [[UIView alloc] initWithFrame:CGRectMake(locations[i].x, locations[i].y, 280, 140)];
		else
			playerLocation = self.controlStateView;

        UILabel *nameLabel = [[[UILabel alloc] initWithFrame:textFrames[i]] autorelease];
        nameLabel.backgroundColor = [UIColor clearColor];
		[nameLabel setTextColor:[UIColor whiteColor]];
		nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        [tempViews addObject:nameLabel];

		NSMutableAttributedString* nameLabelText = [self.game.gameState historyText:((PlayerState*)playerStates[i]).playerID colorName:(i == 0)];
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

					for (int j = 0;j < (z - startLocation) + 3;j++)
						[spaces insertString:@" " atIndex:0];

					[nameLabelText replaceCharactersInRange:NSMakeRange(startLocation, z-startLocation+1) withString:spaces];

					CGSize widthSize = [previousPart sizeWithAttributes:[NSDictionary dictionaryWithObject:nameLabel.font forKey:NSFontAttributeName]];

					int x_label = (int)widthSize.width + nameLabel.frame.origin.x + 1;

					int y_label = nameLabel.frame.origin.y - 1;

					UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x_label, y_label, 25, 25)];
					[imageView setImage:[self imageForDie:number]];

					[playerLocation addSubview:imageView];
					[previousBidImageViews addObject:imageView];
				}
			}
		}

		nameLabel.numberOfLines = 0;
		nameLabel.attributedText = nameLabelText;
		nameLabel.frame = CGRectMake(nameLabel.frame.origin.x, nameLabel.frame.origin.y + 1, textFrames[i].size.width, nameLabel.frame.size.height);
		[nameLabel sizeToFit];
		nameLabel.frame = CGRectMake(nameLabel.frame.origin.x, nameLabel.frame.origin.y, textFrames[i].size.width, nameLabel.frame.size.height);

		if ([playerStates[i] isMyTurn] && i != 0)
		{
			UIActivityIndicatorView* spinnerView = [[[UIActivityIndicatorView alloc] init] autorelease];
			int x,y;

			if ((i >= 1 && i <= 4) || i == 7)
				x = 230;
			else
				x = 0;

			if (i == 7)
				y = 0;
			else
				y = 90;

			spinnerView.frame = CGRectMake(x, y, diceHeight, diceHeight);
			[playerLocation addSubview:spinnerView];
			[tempViews addObject:spinnerView];

			[spinnerView startAnimating];
		}

		[playerLocation addSubview:nameLabel];

		UIView *diceView = [[[UIView alloc] initWithFrame:diceFrames[i]] autorelease];
		UIView *pushView = [[[UIView alloc] initWithFrame:pushFrames[i]] autorelease];
		int pushCount = 0;

		int dieSize = 50;

		int incrementer = 0;

		for (int dieIndex = 0; dieIndex < ((PlayerState*)playerStates[i]).numberOfDice; ++dieIndex)
		{
			incrementer = (dieIndex - pushCount) * (dieSize);
			Die *die = [((PlayerState*)playerStates[i]) getDie:dieIndex];

			CGRect dieFrame = {{0,0}, {dieSize, dieSize}};

			if (diceFrames[i].size.height > diceFrames[i].size.width)
				dieFrame.origin.y = incrementer;
			else
				dieFrame.origin.x = incrementer;

			if (i == 0)
				dieFrame.origin.y = 30;

			int dieFace = -1;
			if (die.hasBeenPushed || i == 0)
				dieFace = die.dieValue;

			UIImage *dieImage = [self imageForDie:dieFace];
			if (i == 0 && !die.hasBeenPushed)
			{
				UIButton *dieButton = [UIButton buttonWithType:UIButtonTypeCustom];
				dieButton.frame = dieFrame;
				[dieButton setImage:dieImage forState:UIControlStateNormal];
				dieButton.tag = dieIndex;

				if (canBid)
					[dieButton addTarget:self action:@selector(dieButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
				else
					dieButton.userInteractionEnabled = NO;

				[diceView addSubview:dieButton];
			}
			else
			{
				UIImageView *dieView = [[[UIImageView alloc] initWithFrame:dieFrame] autorelease];
				[dieView setImage:[self imageForDie:dieFace]];

				if (die.hasBeenPushed)
				{
					dieView.frame = CGRectMake(pushLocations[pushCount].x, pushLocations[pushCount].y, dieView.frame.size.width, dieView.frame.size.height);
					pushCount++;

					[pushView addSubview:dieView];
				}
				else
					[diceView addSubview:dieView];
			}
		}

		[playerLocation addSubview:diceView];
		[centerPush addSubview:pushView];
		[tempViews addObject:diceView];
		[tempViews addObject:pushView];

		// Possibly add challenge button.
		if (canBid && [self canChallengePlayer:((PlayerState*)playerStates[i]).playerID]) {
			CGRect frame = CGRectMake(200, 90, 100, 40);

			if (i == 7)
				frame.origin.y = 0;
			else if (i == 6 || i == 5)
				frame.origin.x = 0;

			UIButton *challengeButton = [[[UIButton alloc] initWithFrame:frame] autorelease];
			[challengeButton setTitle:@"Challenge" forState:UIControlStateNormal];
			challengeButton.tag = ((PlayerState*)playerStates[i]).playerID;
			[challengeButton addTarget:self action:@selector(challengePressed:) forControlEvents:UIControlEventTouchUpInside];
			[challengeButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28/255.0 alpha:1.0] forState:UIControlStateNormal];
			challengeButton.titleLabel.font = [UIFont systemFontOfSize:17.0];

			[playerLocation addSubview:challengeButton];
			[challengeButtons addObject:challengeButton];
			[tempViews addObject:challengeButton];
		}

		[self.view addSubview:playerLocation];
		[tempViews addObject:playerLocation];
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
		// Enable the buttons if we actually can do those actions at this update cycle
		BOOL canBid = [self.state canBid];

		self.passButton.enabled = canBid && [self.state canPass];
		self.bidButton.enabled = canBid;
		self.bidCountPlusButton.enabled = canBid;
		self.bidCountMinusButton.enabled = canBid;
		self.bidFacePlusButton.enabled = canBid;
		self.bidFaceMinusButton.enabled = canBid;
		self.exactButton.enabled = canBid && [self.state canExact];

		if (self.exactButton.enabled)
			[self.exactButton.titleLabel setTextColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28/255.0 alpha:1.0]];
		else
			[self.exactButton.titleLabel setTextColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0]];

		if (self.passButton.enabled)
			[self.passButton.titleLabel setTextColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28/255.0 alpha:1.0]];
		else
			[self.passButton.titleLabel setTextColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0]];

		if (self.bidButton.enabled)
			[self.bidButton.titleLabel setTextColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28/255.0 alpha:1.0]];
		else
			[self.bidButton.titleLabel setTextColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0]];

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
            quitHandler();
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

+ (UIImage*)barImage
{
	CGSize size = CGSizeMake(1, 1);
	UIGraphicsBeginImageContextWithOptions(size, YES, 0);
	[[UIColor whiteColor] setFill];
	UIRectFill(CGRectMake(0, 0, size.width, size.height));
	UIImage *barImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return barImage;
}

- (UIImage *)blurredSnapshot
{
    // Create the image context
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, self.view.window.screen.scale);

    // There he is! The new API method
    [self.view drawViewHierarchyInRect:self.view.frame afterScreenUpdates:NO];

    // Get the snapshot
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();

    // Now apply the blur effect using Apple's UIImageEffect category
	UIColor *tintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    UIImage *blurredSnapshotImage = [snapshotImage applyBlurWithRadius:20 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];

    // Or apply any other effects available in "UIImage+ImageEffects.h"
    // UIImage *blurredSnapshotImage = [snapshotImage applyDarkEffect];
    // UIImage *blurredSnapshotImage = [snapshotImage applyExtraLightEffect];

    // Be nice and clean your mess up
    UIGraphicsEndImageContext();

    return blurredSnapshotImage;
}

@end
