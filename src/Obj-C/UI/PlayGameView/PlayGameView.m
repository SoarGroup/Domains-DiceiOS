//
//  PlayGameView.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/5/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "PlayGameView.h"
#import "DiceGame.h"
#import "DiceGameState.h"
#import "HistoryItem.h"
#import "RoundOverview.h"
#import "Die.h"
#import "DiceGraphics.h"
#import "UIIMage+ImageEffects.h"
#import "ApplicationDelegate.h"

#import "MultiplayerView.h"

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
-(void)updateFullScreenUI:(BOOL)showAllDice;
-(void)updateNonFullScreenUI:(UIView*)controlStateView gameStateView:(UIScrollView*)gameStateView;
-(void)initializeUI;

- (void)fullScreenViewInitialization;
- (void)fullScreenViewGameInitialization;

- (void)realRoundEnding;

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
@synthesize multiplayerView, overViews;

@synthesize game, state, isCustom, animationFinished, previousBidImageViews;

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
        aGame.gameView = self;
        self.state = nil;
        currentBidCount = 1;
		internalCurrentBidCount = 1;
        currentBidFace = 2;
        quitHandler = QuitHandler;
        self.challengeButtons = [NSMutableArray array];
        self.tempViews = [NSMutableArray array];
        self.images = buildDiceImages();

		self.previousBidImageViews = [[NSMutableArray alloc] init];

		hasPromptedEnd = NO;
		hasDisplayedRoundOverview = NO;

		overViews = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL) roundEnding
{
	if (hasDisplayedRoundOverview)
		return YES;

	DiceGame* localGame = self.game;

	localGame.gameState.canContinueGame = NO;

	shouldNotifyCurrentPlayer = localGame->shouldNotifyOfNewRound;

	hasDisplayedRoundOverview = YES;

	[self performSelectorOnMainThread:@selector(realRoundEnding) withObject:nil waitUntilDone:NO];

    return YES;
}

- (void)realRoundEnding
{
	DiceGame* localGame = self.game;

	NSString *headerString = [localGame.gameState headerString:-1 singleLine:YES displayDiceCount:NO];
	PlayerState* playerStateLocal = [localGame.gameState lastHistoryItem].player;
	NSString *lastMoveString = [localGame.gameState historyText:playerStateLocal.playerID];

	NSString* finalString = [NSString stringWithFormat:@"%@\n%@", headerString, lastMoveString];

	if (!fullScreenView)
	{
		RoundOverView *roundOverView = [[RoundOverView alloc] initWithGame:localGame
																player:state
															  playGameView:self
														   withFinalString:finalString];

		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			[self.overViews addObject:roundOverView];
			roundOverView.view.frame = self.view.frame;
			roundOverView.view.frame = CGRectMake(roundOverView.view.frame.origin.x,
												  roundOverView.view.frame.size.height,
												  roundOverView.view.frame.size.width,
												  roundOverView.view.frame.size.height);

			[self.view.superview addSubview:roundOverView.view];

			[UIView animateWithDuration:0.35 animations:^{
				roundOverView.view.frame = CGRectMake(roundOverView.view.frame.origin.x,
													  0,
													  roundOverView.view.frame.size.width,
													  roundOverView.view.frame.size.height);
			}];
		}
		else
			[self.navigationController presentViewController:roundOverView animated:YES completion:nil];
	}
	else
	{
		for (UIView* view in previousBidImageViews)
			view.hidden = YES;

		[self updateFullScreenUI:YES];

		for (UIView* view in tempViews)
		{
			if ([view isKindOfClass:UIActivityIndicatorView.class])
				view.hidden = YES;
		}

		CGRect frame = centerPush.bounds;
		UILabel* titleLabel = [[UILabel alloc] initWithFrame:frame];
		[titleLabel setTextColor:[UIColor whiteColor]];
		titleLabel.numberOfLines = 0;

		titleLabel.text = finalString;
		[titleLabel sizeToFit];

		frame = titleLabel.frame;
		frame.origin.x = centerPush.bounds.size.width / 2.0 - frame.size.width / 2.0;
		frame.origin.y = centerPush.bounds.size.height / 2.0 - frame.size.height / 2.0;
		titleLabel.frame = frame;

		NSArray* lines = [finalString componentsSeparatedByString:@"\n"];

		NSError* error = nil;
		NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"[1-6]s" options:0 error:&error];

		CGSize constrainedSize = CGSizeMake(titleLabel.frame.size.width, 9999);
		NSDictionary* attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:titleLabel.font, NSFontAttributeName, nil];

		CGFloat y = 0;

		for (int i = 0;i < [lines count];i++)
		{
			NSString* line = [lines objectAtIndex:i];

			NSArray* matches = [regex matchesInString:line options:0 range:NSMakeRange(0, [line length])];

			assert([matches count] <= 1);

			if ([matches count] == 1) // Should only ever be one!
			{
				NSTextCheckingResult* result = [matches objectAtIndex:0];
				CGFloat x = -1;

				NSString* before = [line substringToIndex:[result range].location];
				x += [before boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributesDictionary context:nil].size.width;

				int number = [line characterAtIndex:result.range.location] - '0';

				UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, 20, 20)];
				[imageView setImage:[self imageForDie:number]];

				[titleLabel addSubview:imageView];
			}

			y += [line boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributesDictionary context:nil].size.height;
		}

		self.gameStateLabel.hidden = YES;

		UIButton* continueButton = [[UIButton alloc] initWithFrame:CGRectMake(275, 250, 150, 60)];
		[continueButton setTitle:@"Continue Round" forState:UIControlStateNormal];
		[continueButton addTarget:self action:@selector(continueRoundPressed:) forControlEvents:UIControlEventTouchUpInside];
		[continueButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
		continueButton.hidden = NO;
		continueButton.userInteractionEnabled = YES;
		[centerPush addSubview:continueButton];

		[centerPush addSubview:titleLabel];
		[centerPush sendSubviewToBack:titleLabel];

		canContinueRound = NO;

		self.exactButton.enabled = NO;
		self.passButton.enabled = NO;
		self.bidButton.enabled = NO;
		self.bidCountPlusButton.enabled = NO;
		self.bidCountMinusButton.enabled = NO;
		self.bidFacePlusButton.enabled = NO;
		self.bidFaceMinusButton.enabled = NO;

		[[[UIAlertView alloc] initWithTitle:@"Round Over!" message:@"The round has ended." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
	}
}

- (void)continueRoundPressed:(id)sender
{
	canContinueRound = YES;

	for (UIView* view in centerPush.subviews)
	{
		if (view != self.gameStateLabel && ![view isKindOfClass:UIImageView.class])
			[view removeFromSuperview];
	}

	self.exactButton.enabled = YES;
	self.passButton.enabled = YES;
	self.bidButton.enabled = YES;
	self.bidCountPlusButton.enabled = YES;
	self.bidCountMinusButton.enabled = YES;
	self.bidFacePlusButton.enabled = YES;
	self.bidFaceMinusButton.enabled = YES;

	self.gameStateLabel.hidden = NO;

	DiceGame* localGame = self.game;
	PlayerState* localState = self.state;

	localGame.gameState.canContinueGame = YES;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"ContinueRoundPressed" object:nil];

	BOOL specialRules = NO;
	unsigned long playersLeft = [localGame.gameState.playerStates count];

	for (PlayerState* player in localGame.gameState.playerStates)
	{
		if ([player numberOfDice] == 0)
			playersLeft--;
	}

	for (PlayerState *player in localGame.gameState.playerStates)
	{
        if ([player numberOfDice] == 1 && !player.hasDoneSpecialRules && playersLeft > 2)
            specialRules = YES;
    }

	if (specialRules) {
        NSString *title = [NSString stringWithFormat:@"Special Rules!"];
        NSString *message = @"For this round: 1s aren't wild. Only players with one die may change the bid face."; // (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %d dice?", [push count]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"Okay"
                                               otherButtonTitles:nil];
        // alert.tag = ACTION_QUIT;
        [alert show];
    }
    else if ([localState hasWon]) {
        NSString *title = [NSString stringWithFormat:@"You Win!"];
        //NSString *message = @"For this round: 1s aren't wild. Only players with one die may change the bid face."; // (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %d dice?", [push count]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                         message:nil
                                                        delegate:self
                                               cancelButtonTitle:nil
                                               otherButtonTitles:@"Okay", nil];
        alert.tag = ACTION_QUIT;
        [alert show];
    }
    else if ([localGame.gameState hasAPlayerWonTheGame]) {
        NSString *title = [NSString stringWithFormat:@"%@ Wins!", [localGame.gameState.gameWinner getDisplayName]];
        //NSString *message = @"For this round: 1s aren't wild. Only players with one die may change the bid face."; // (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %d dice?", [push count]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                         message:nil
                                                        delegate:self
                                               cancelButtonTitle:nil
                                               otherButtonTitles:@"Okay", nil];
        alert.tag = ACTION_QUIT;
        [alert show];
	}
    else if ([localState hasLost] && !self.hasPromptedEnd) {
        self.hasPromptedEnd = YES;
        NSString *title = [NSString stringWithFormat:@"You Lost the Game"];
        NSString *message = @"Quit or keep watching?"; // (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %d dice?", [push count]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                         message:message
                                                        delegate:self
                                               cancelButtonTitle:@"Watch"
                                               otherButtonTitles:@"Quit", nil];
        alert.tag = ACTION_QUIT;
        [alert show];
    }

	PlayerState* playerState = [[localGame.gameState lastHistoryItem] player];

	if (localGame.newRound == YES && [playerState playerID] != [localState playerID])
	{
		NSString* playerName = [[localGame.players objectAtIndex:[playerState playerID]] getDisplayName];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please Wait"
														message:[NSString stringWithFormat:@"Please wait until %@ has finished looking at the round overview.", playerName]
													   delegate:nil
											  cancelButtonTitle:@"Okay"
											  otherButtonTitles:nil];
		[alert show];
	}

	[localGame notifyCurrentPlayer];
}

- (BOOL) roundBeginning {
	hasTouchedBidCounterThisTurn = NO;
	hasDisplayedRoundOverview = NO;

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

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUINotification:) name:@"UpdateUINotification" object:nil];

	if (self.game.gameState.gameWinner)
	{
		DiceGame* localGame = self.game;

		for (id<Player> player in localGame.players)
		{
			if ([player isKindOfClass:DiceLocalPlayer.class])
			{
				[(DiceLocalPlayer*)player end:YES];
				break;
			}
		}
	}
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
	exactButton.frame = CGRectMake(2, 50, 60, 60);
	//[exactButton setBackgroundColor:[UIColor redColor]];
	[exactButton setTitle:@"Exact" forState:UIControlStateNormal];
	[exactButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
	[exactButton setTitleColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0] forState:UIControlStateDisabled];
	exactButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
	[exactButton addTarget:self action:@selector(exactPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlStateView addSubview:exactButton];

	self.passButton = [[UIButton alloc] init];
	passButton.frame = CGRectMake(70, 50, 60, 60);
	//[passButton setBackgroundColor:[UIColor redColor]];
	[passButton setTitle:@"Pass" forState:UIControlStateNormal];
	[passButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
	[passButton setTitleColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0] forState:UIControlStateDisabled];
	passButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
	[passButton addTarget:self action:@selector(passPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlStateView addSubview:passButton];

	self.bidButton = [[UIButton alloc] init];
	bidButton.frame = CGRectMake(138, 50, 60, 60);
	//[bidButton setBackgroundColor:[UIColor redColor]];
	[bidButton setTitle:@"Bid" forState:UIControlStateNormal];
	[bidButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
	[bidButton setTitleColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0] forState:UIControlStateDisabled];
	bidButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
	[bidButton addTarget:self action:@selector(bidPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlStateView addSubview:bidButton];

	self.bidCountPlusButton = [[UIButton alloc] init];
	bidCountPlusButton.frame = CGRectMake(200, -15, 40, 50);
	//[bidCountPlusButton setBackgroundColor:[UIColor redColor]];
	[bidCountPlusButton setTitle:@"+" forState:UIControlStateNormal];
	[bidCountPlusButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
	[bidCountPlusButton setTitleColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0] forState:UIControlStateDisabled];
	bidCountPlusButton.titleLabel.font = [UIFont boldSystemFontOfSize:25];
	[bidCountPlusButton addTarget:self action:@selector(bidCountPlusPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlStateView addSubview:bidCountPlusButton];

	self.bidCountMinusButton = [[UIButton alloc] init];
	bidCountMinusButton.frame = CGRectMake(200, 58, 40, 50);
	//[bidCountMinusButton setBackgroundColor:[UIColor redColor]];
	[bidCountMinusButton setTitle:@"-" forState:UIControlStateNormal];
	[bidCountMinusButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
	[bidCountMinusButton setTitleColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0] forState:UIControlStateDisabled];
	bidCountMinusButton.titleLabel.font = [UIFont boldSystemFontOfSize:25];
	[bidCountMinusButton addTarget:self action:@selector(bidCountMinusPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlStateView addSubview:bidCountMinusButton];

	self.bidFacePlusButton = [[UIButton alloc] init];
	bidFacePlusButton.frame = CGRectMake(245, -15, 40, 50);
	//[bidFacePlusButton setBackgroundColor:[UIColor redColor]];
	[bidFacePlusButton setTitle:@"+" forState:UIControlStateNormal];
	[bidFacePlusButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
	[bidFacePlusButton setTitleColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0] forState:UIControlStateDisabled];
	bidFacePlusButton.titleLabel.font = [UIFont boldSystemFontOfSize:25];
	[bidFacePlusButton addTarget:self action:@selector(bidFacePlusPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlStateView addSubview:bidFacePlusButton];

	self.bidFaceMinusButton = [[UIButton alloc] init];
	bidFaceMinusButton.frame = CGRectMake(245, 58, 40, 50);
	//[bidFaceMinusButton setBackgroundColor:[UIColor redColor]];
	[bidFaceMinusButton setTitle:@"-" forState:UIControlStateNormal];
	[bidFaceMinusButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28.0/255.0 alpha:1.0] forState:UIControlStateNormal];
	[bidFaceMinusButton setTitleColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0] forState:UIControlStateDisabled];
	bidFaceMinusButton.titleLabel.font = [UIFont boldSystemFontOfSize:25];
	[bidFaceMinusButton addTarget:self action:@selector(bidFaceMinusPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlStateView addSubview:bidFaceMinusButton];

	self.bidFaceLabel = [[UIImageView alloc] initWithImage:[self imageForDie:2]];
	bidFaceLabel.frame = CGRectMake(253, 34, 25, 21);
	[self.controlStateView addSubview:bidFaceLabel];

	self.bidCountLabel = [[UILabel alloc] init];
	bidCountLabel.frame = CGRectMake(215, 34, 30, 21);
	[bidCountLabel setText:@"1"];
	[bidCountLabel setTextColor:[UIColor whiteColor]];
	bidCountLabel.font = [UIFont boldSystemFontOfSize:17];
	[self.controlStateView addSubview:bidCountLabel];

	[self.view addSubview:self.controlStateView];
}

- (void)fullScreenViewGameInitialization
{
	// Correction based on how many players there are

	DiceGame* localGame = self.game;

	NSArray *playerStates = localGame.gameState.playerStates;

	unsigned long playerCount = [playerStates count];

	CGSize screenSize = self.view.frame.size;

	double divisionFactor = 2.0;

	if (playerCount == 8)
		divisionFactor = 3.0;

	[self.gameStateLabel setFrame:CGRectMake(screenSize.width / 2.0 - self.gameStateLabel.frame.size.width / 2.0 + 8,
											 screenSize.height / 2.0 - self.gameStateLabel.frame.size.height / 2.0,
											 self.gameStateLabel.frame.size.width,
											 self.gameStateLabel.frame.size.height)];

	[self.controlStateView setFrame:CGRectMake(screenSize.width / divisionFactor - self.controlStateView.frame.size.width / 2.0,
											   screenSize.height * 7.6/ 8.0 - self.controlStateView.frame.size.height / 2.0 - 50,
											   self.controlStateView.frame.size.width,
											   self.controlStateView.frame.size.height)];

	self.navigationItem.title = [NSString stringWithFormat:@"Single Player Match: %lu Players", playerCount];

	centerPush = [[UIView alloc] initWithFrame:CGRectMake(292.5, 221, 442, 308)];
	UIImageView* centerPushImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Center-Push"]];
	centerPushImage.frame = CGRectMake(0, 0, 442, 308);
	//[centerPush addSubview:centerPushImage];

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

	self.bidCountMinusButton.accessibilityLabel = @"Decrease Bid Die Count";
	self.bidCountPlusButton.accessibilityLabel = @"Increase Bid Die Count";
	self.bidFaceMinusButton.accessibilityLabel = @"Decrease Bid Die Face";
	self.bidFacePlusButton.accessibilityLabel = @"Increase Bid Die Face";
	self.bidFaceLabel.accessibilityLabel = @"Die Face of 2";
	self.bidFaceLabel.isAccessibilityElement = YES;
	self.bidCountLabel.accessibilityLabel = @"Die Count of 1";

	DiceGame* localGame = self.game;

	for (id<Player> player in localGame.players)
	{
		if ([player isKindOfClass:DiceLocalPlayer.class])
		{
			[(DiceLocalPlayer*)player setGameView:self];
			break;
		}
	}

    [localGame startGame];

	ApplicationDelegate* delegate = localGame.appDelegate;
	GameKitGameHandler* handler = [delegate.listener handlerForGame:localGame];

	if (handler)
		[handler saveMatchData];

	if ([localGame.gameState.theNewRoundListeners count] == 0)
		[localGame.gameState addNewRoundListener:self];

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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Quit", nil];
    alert.tag = ACTION_QUIT;
    [alert show];
}

- (bool) canChallengePlayer:(int)otherPlayerID {
	PlayerState* localState = self.state;

    Bid *challengeableBid = [localState getChallengeableBid];
    if (challengeableBid != nil && challengeableBid.playerID == otherPlayerID)
    {
        return YES;
    }
    int passID = [localState getChallengeableLastPass];
    if (passID != -1 && passID == otherPlayerID)
    {
        return YES;
    }
    passID = [localState getChallengeableSecondLastPass];
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
	self.bidCountLabel.accessibilityLabel = [NSString stringWithFormat:@"Bid Die Count, Face Value of %i", currentBidCount];

	[self.bidFaceLabel setImage:[self imageForDie:currentBidFace]];
	self.bidFaceLabel.accessibilityLabel = [NSString stringWithFormat:@"Bid Die Face, Face Value of %i", currentBidFace];
}

- (void) dieButtonPressed:(id)sender
{
    UIButton *button = (UIButton*)sender;
    NSInteger dieIndex = button.tag;

	PlayerState* localState = self.state;

    Die *dieObject = [localState.arrayOfDice objectAtIndex:dieIndex];
    if (dieObject.hasBeenPushed)
        return;

    dieObject.markedToPush = ! dieObject.markedToPush;

	if (dieObject.markedToPush)
	{
		self.passButton.enabled = YES;

		button.accessibilityLabel = [NSString stringWithFormat:@"Your Die, Face Value of %i, pushed", dieObject.dieValue];
		button.accessibilityHint = @"Tap to unpush this die";
	}
	else
	{
		BOOL noneMarkedToPush = YES;

		for (Die* object in localState.arrayOfDice)
		{
			if ([object markedToPush])
			{
				noneMarkedToPush = NO;
				break;
			}
		}

		if (noneMarkedToPush)
			self.passButton.enabled = [localState canBid] && [localState canPass];

		button.accessibilityLabel = [NSString stringWithFormat:@"Your Die, Face Value of %i, unpushed", dieObject.dieValue];
		button.accessibilityHint = @"Tap to push this die";
	}

	if (fullScreenView)
		button = [[button subviews] objectAtIndex:0];

	CGRect newFrame = button.frame;

	if (dieObject.markedToPush)
		newFrame.origin.y = 0;
	else
		newFrame.origin.y = fullScreenView ? 15 : pushMargin();

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

- (NSString*)accessibleTextForString:(NSString*)string
{
	NSError* error = nil;
	NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"[1-6]s" options:0 error:&error];

	NSString* accessibleText = [NSString stringWithString:string];

	NSArray* accessibleMatches = [regex matchesInString:accessibleText options:0 range:NSMakeRange(0, [accessibleText length])];

	NSString* finalAccessibleText = [NSString string];
	int lastRange = 0;

	for (NSTextCheckingResult* result in accessibleMatches)
	{
		finalAccessibleText = [finalAccessibleText stringByAppendingString:[accessibleText substringWithRange:NSMakeRange(lastRange, result.range.location - lastRange)]];

		NSString* number = nil;

		switch ([accessibleText characterAtIndex:result.range.location] - '0')
		{
			case 1:
				number = @"ones";
				break;
			case 2:
				number = @"twos";
				break;
			case 3:
				number = @"threes";
				break;
			case 4:
				number = @"fours";
				break;
			case 5:
				number = @"fives";
				break;
			case 6:
				number = @"sixes";
				break;
			default:
				break;
		}

		finalAccessibleText = [finalAccessibleText stringByAppendingString:number];
		lastRange = (int)result.range.location + (int)result.range.length;
	}

	finalAccessibleText = [finalAccessibleText stringByAppendingString:[accessibleText substringWithRange:NSMakeRange(lastRange, accessibleText.length - lastRange)]];

	return finalAccessibleText;
}

- (void)updateUINotification:(NSNotification*)notification
{
	if (notification && [notification.name isEqualToString:@"UpdateUINotification"])
		[self updateUI];
}

- (void)updateUI
{
	if (![NSThread isMainThread])
	{
		[self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:YES];

		return;
	}

	// State initialization
	PlayerState* localState = self.state;
	DiceGame* localGame = self.game;

	if (localGame.newRound && !hasDisplayedRoundOverview)
		[self roundEnding];

	if ([localGame.gameState.theNewRoundListeners count] == 0)
		[localGame.gameState addNewRoundListener:self];

    if (localState == nil)
    {
		[self initializeUI];
        return;
    }

	Bid *previousBid = localGame.gameState.previousBid;
    NSString *headerString = [localState headerString:NO]; // This sets it

	// Dealloc all old die images
	for (UIImageView* view in self.previousBidImageViews)
		[view removeFromSuperview];

	// Remove them all
	[self.previousBidImageViews removeAllObjects];

	self.gameStateLabel.text = headerString;
	self.gameStateLabel.accessibilityLabel = [self accessibleTextForString:headerString];

	NSArray* lines = [headerString componentsSeparatedByString:@"\n"];

	NSError* error = nil;
	NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"[1-6]s" options:0 error:&error];

	CGSize constrainedSize = CGSizeMake(gameStateLabel.frame.size.width, 9999);
	NSDictionary* attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:gameStateLabel.font, NSFontAttributeName, nil];

	CGFloat y = 0;
	CGFloat maxX = self.gameStateLabel.frame.size.width;

	for (int i = 0;i < [lines count];i++)
	{
		NSString* line = [lines objectAtIndex:i];

		CGFloat lineX = [line boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributesDictionary context:nil].size.width;

		if (lineX > maxX)
			maxX = lineX;

		NSArray* matches = [regex matchesInString:line options:0 range:NSMakeRange(0, [line length])];

		assert([matches count] <= 1);

		if ([matches count] == 1) // Should only ever be one or zero!
		{
			NSTextCheckingResult* result = [matches objectAtIndex:0];
			CGFloat x = -2;

			NSString* before = [line substringToIndex:[result range].location];
			x += [before boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributesDictionary context:nil].size.width;

			int number = [line characterAtIndex:result.range.location] - '0';

			UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, 20, 20)];
			[imageView setImage:[self imageForDie:number]];

			[self.gameStateLabel addSubview:imageView];
			[previousBidImageViews addObject:imageView];
		}

		y += [line boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributesDictionary context:nil].size.height;
	}

	CGRect playerFrame = self.gameStateLabel.frame;
	playerFrame.size.height = y;
	playerFrame.size.width = maxX;

	CGSize screenSize = self.view.frame.size;

	playerFrame.origin.x = screenSize.width / 2.0 - playerFrame.size.width / 2.0;
	playerFrame.origin.y = screenSize.height / 2.0 - playerFrame.size.height / 2.0;

	if (fullScreenView)
		self.gameStateLabel.frame = playerFrame;

	// Player UI
    BOOL canBid = [localState canBid];

	// Enable the buttons if we actually can do those actions at this update cycle
    self.passButton.enabled = canBid && [localState canPass];
    self.bidButton.enabled = canBid;
    self.bidCountPlusButton.enabled = canBid;
    self.bidCountMinusButton.enabled = canBid;
    self.bidFacePlusButton.enabled = canBid;
    self.bidFaceMinusButton.enabled = canBid;
    self.exactButton.enabled = canBid && [localState canExact];

	hasTouchedBidCounterThisTurn = NO;

	// Check if our previous bid is nil, if it is then we're starting and set the default dice to be bidding 1 two.
	if (previousBid == nil)
	{
		currentBidCount = 1;
		internalCurrentBidCount = 1;
		currentBidFace = 2;
	}
	else if ([[localState arrayOfDice] count] > 1 && [localGame.gameState usingSpecialRules])
	{
		currentBidCount = previousBid.numberOfDice + 1;
		internalCurrentBidCount = currentBidCount;
		currentBidFace = previousBid.rankOfDie;
		self.bidFacePlusButton.enabled = NO;
		self.bidFaceMinusButton.enabled = NO;
	}
	else
	{
		Bid* previousBidToUse = previousBid;

		NSArray* lastPlayerMoves = [localGame.gameState lastMoveForPlayer:localState.playerID];
		if ([lastPlayerMoves count] > 0)
		{
			for (int i = (int)[lastPlayerMoves count] - 1;i >= 0;i--)
			{
				HistoryItem* item = [lastPlayerMoves objectAtIndex:i];

				if ([item actionType] == ACTION_BID)
				{
					previousBidToUse = [item bid];
					break;
				}
			}
		}

		Bid* nextLegalBid = [self minimumLegalBid:previousBid withCurrentFace:previousBidToUse.rankOfDie];

		if (!nextLegalBid)
			nextLegalBid = [self minimumLegalBid:previousBid withCurrentFace:previousBid.rankOfDie];

		if (!nextLegalBid)
		{
			currentBidFace = previousBid.rankOfDie;
			self.bidFacePlusButton.enabled = NO;
			self.bidFaceMinusButton.enabled = NO;

			currentBidCount = previousBid.numberOfDice;
			internalCurrentBidCount = currentBidCount;
			self.bidCountMinusButton.enabled = NO;
			self.bidCountPlusButton.enabled = NO;
		}
		else
		{
			currentBidFace = [nextLegalBid rankOfDie];
			currentBidCount = [nextLegalBid numberOfDice];
			internalCurrentBidCount = currentBidCount;
		}
	}

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

	// Update the bid "scroller" labels, the die image and number for the bid chooser
    [self updateCurrentBidLabels];

    // Update the contents of the gameStateView
	// iPad and iPhone specific
	if (!fullScreenView)
		[self updateNonFullScreenUI:controlStateView gameStateView:gameStateView];
	else
		[self updateFullScreenUI:NO];
}

- (Bid*)minimumLegalBid:(Bid*)previousBid withCurrentFace:(int)currentFace
{
	DiceGame* localGame = self.game;

	if (previousBid)
	{
		int maxBidCount = 0;

		for (PlayerState* pstate in localGame.gameState.playerStates)
		{
			if ([pstate isKindOfClass:[PlayerState class]])
				maxBidCount += [[pstate arrayOfDice] count];
		}

		Bid* newBid = [[Bid alloc] initWithPlayerID:-1 name:nil dice:1 rank:currentFace];

		while (![newBid isLegalRaise:previousBid specialRules:localGame.gameState.usingSpecialRules playerSpecialRules:NO])
		{
			if (newBid.numberOfDice > maxBidCount)
			{
				if (previousBid.rankOfDie == 1)
					return nil;

				int nextRank = (previousBid.rankOfDie + 1);

				if (nextRank > 6)
					nextRank = 1;

				newBid = [[Bid alloc] initWithPlayerID:-1 name:nil dice:1 rank:nextRank];
			}
			else
				newBid = [[Bid alloc] initWithPlayerID:-1 name:nil dice:(newBid.numberOfDice + 1) rank:newBid.rankOfDie];
		}

		return newBid;
	}
	else
		return [[Bid alloc] initWithPlayerID:-1 name:nil dice:1 rank:2];
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

	PlayerState* localState = self.state;
	DiceGame* localGame = self.game;

    NSArray *playerStates = localGame.gameState.playerStates;
	BOOL canBid = [localState canBid];
    int labelHeight = 64 / 2;
    int diceHeight = 96 / 2;
    int dividerHeight = 8 / 2;

    int dy = labelHeight + diceHeight + dividerHeight;
    int buttonWidth = 160 / 2;

	NSMutableArray* playerStatesReordered = [NSMutableArray arrayWithArray:playerStates];

	for (NSUInteger i = [playerStatesReordered count]; i > 0; i--) {
		PlayerState* obj = [playerStatesReordered lastObject];
		[playerStatesReordered insertObject:obj atIndex:0];
		[playerStatesReordered removeLastObject];

		if (obj.playerID == localState.playerID)
			break;
	}

	for (int z = 0;z < [playerStatesReordered count];++z)
    {
		PlayerState* playerState = [playerStatesReordered objectAtIndex:z];

        // Whether this player is the play that we're controlling
        bool control = localState.playerID == playerState.playerID;

        // The parent view to put these UI elements into.
        UIView *parent = (control ? controlStateViewToUpdate : gameStateViewToUpdate);

        int starSize = 64 / 2;
        int x = starSize;

		int labelIndex = control ? 0 : z-1;

        int y = labelIndex * dy;
		int width = parent.frame.size.width;
        int height = labelHeight;

        UIImageView *dividerView = [[UIImageView alloc] initWithImage:[PlayGameView barImage]];
        dividerView.frame = CGRectMake(0, y, width, dividerHeight);
        [parent addSubview:dividerView];
        y += dividerHeight;
        CGRect nameLabelRect = CGRectMake(x, y, width - starSize, height);
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:nameLabelRect];
        nameLabel.backgroundColor = [UIColor clearColor];
		[nameLabel setTextColor:[UIColor whiteColor]];

        [tempViews addObject:nameLabel];

		nameLabel.attributedText = [localGame.gameState historyText:playerState.playerID colorName:control];
		nameLabel.accessibilityLabel = [self accessibleTextForString:nameLabel.attributedText.string];

		CGRect nameFrame = nameLabel.frame;

		{
			NSArray* lines = [nameLabel.text componentsSeparatedByString:@"\n"];

			NSError* error = nil;
			NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"[1-6]s" options:0 error:&error];

			CGSize constrainedSize = CGSizeMake(nameLabel.frame.size.width, 9999);
			NSDictionary* attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:nameLabel.font, NSFontAttributeName, nil];

			CGFloat y2 = 0;

			for (int j = 0;j < [lines count];j++)
			{
				NSString* line = [lines objectAtIndex:j];

				NSArray* matches = [regex matchesInString:line options:0 range:NSMakeRange(0, [line length])];

				assert([matches count] <= 1);

				if ([matches count] == 1) // Should only ever be one!
				{
					NSTextCheckingResult* result = [matches objectAtIndex:0];
					CGFloat x2 = -2;

					NSString* before = [line substringToIndex:[result range].location];
					x2 += [before boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributesDictionary context:nil].size.width;

					int number = [line characterAtIndex:result.range.location] - '0';

					UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x2, y2, 25, 25)];
					[imageView setImage:[self imageForDie:number]];

					[nameLabel addSubview:imageView];
					[previousBidImageViews addObject:imageView];
				}

				y2 += [line boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributesDictionary context:nil].size.height;
			}

			nameFrame.size.height = y2;
		}

		nameLabel.frame = nameFrame;

        if ([playerState isMyTurn] && ![playerState hasLost])
        {
            if (!control)
			{
                int extraX = (buttonWidth - diceHeight) / 2;
                int extray = (buttonWidth + labelIndex - diceHeight) / 2;
                UIActivityIndicatorView* spinnerView = [[UIActivityIndicatorView alloc] init];
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
        UIView *diceView = [[UIView alloc] initWithFrame:diceFrame];
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
            if (die.hasBeenPushed || control || localGame.gameState.gameWinner)
            {
                dieFace = die.dieValue;
            }
            UIImage *dieImage = [self imageForDie:dieFace];
            if (control && !localGame.gameState.gameWinner) {
                UIButton *dieButton = [UIButton buttonWithType:UIButtonTypeCustom];
                dieButton.frame = dieFrame;
                [dieButton setImage:dieImage forState:UIControlStateNormal];
                dieButton.tag = dieIndex;
                if (canBid) {
                    [dieButton addTarget:self action:@selector(dieButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                } else {
                    dieButton.userInteractionEnabled = NO;
                }
				dieButton.accessibilityLabel = [NSString stringWithFormat:@"Your Die, Face Value of %i, unpushed", die.dieValue];
				dieButton.accessibilityHint = @"Tap to push the die.";

                [diceView addSubview:dieButton];
            } else {
                UIImageView *dieView = [[UIImageView alloc] initWithFrame:dieFrame];

				NSString* name = [NSString stringWithFormat:@"%@'s", playerState.playerName];

				if (control)
					name = @"Your";

				if (die.hasBeenPushed || localGame.gameState.gameWinner)
					dieView.accessibilityLabel = [NSString stringWithFormat:@"%@ Die, Face Value of %i, pushed", name, die.dieValue];
				else
					dieView.accessibilityLabel = [NSString stringWithFormat:@"%@ Die, Unknown Face Value", name];

				dieView.isAccessibilityElement = YES;
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

	gameStateViewToUpdate.contentSize = CGSizeMake(gameStateViewToUpdate.frame.size.width, ([playerStates count]-1)*dy);
}

- (void)updateFullScreenUI:(BOOL)showAllDice
{
	// Remove all challenge buttons and all unused images
    for (id subview in tempViews)
        [subview removeFromSuperview]; // auto released

    [tempViews removeAllObjects];
    [challengeButtons removeAllObjects];

	PlayerState* localState = self.state;
	DiceGame* localGame = self.game;

	NSMutableArray* playerStates = [NSMutableArray arrayWithArray:localGame.gameState.playerStates];

	for (NSUInteger i = [playerStates count]; i > 0; i--) {
		PlayerState* obj = [playerStates lastObject];
		[playerStates insertObject:obj atIndex:0];
		[playerStates removeLastObject];

		if (obj.playerID == localState.playerID)
			break;
	}

	BOOL canBid = [localState canBid];

	unsigned long playerCount = [playerStates count];
	int diceHeight = 96 / 2;

	CGSize screenSize = self.view.frame.size;

	CGSize viewSize = controlStateView.frame.size;

	// Location mapping based on the number of players
	// Unfortunately there isn't a good way to debug this or come up with an algorithm for this so I just hard coded it
	CGPoint player1Location = {screenSize.width / 2.0 - viewSize.width / 2.0, 7.0 / 8.0 * screenSize.height - viewSize.height / 2.0 - 40};
	CGRect player1TextLabelFrame = {{-35, -25}, {230, 75}};
	CGRect player1DiceFrame = {{0, 115}, {280, 65}};

	CGPoint player2Location = {screenSize.width * 0.1/8.0, screenSize.height / 2.0 - viewSize.height / 2.0};
	CGRect player2TextLabelFrame = {{70, 0}, {230, 140}};
	CGRect player2DiceFrame = {{0, -55}, {65, 195}};

	CGPoint player3Location = {screenSize.width / 2.0 - viewSize.width / 2.0, 1.0 / 8.0 * screenSize.height};
	CGRect player3TextLabelFrame = {{0, 70}, {280, 90}};
	CGRect player3DiceFrame = {{0, 0}, {280, 65}};

	CGPoint player4Location = {screenSize.width * 7.9/8.0 - viewSize.width, screenSize.height / 2.0 - viewSize.height / 2.0};
	CGRect player4TextLabelFrame = {{0, 0}, {215, 140}};
	CGRect player4DiceFrame = {{215, -55}, {65, 195}};


	CGPoint player1AltLocation = {screenSize.width / 3.0 - viewSize.width / 2.0, 7.0 / 8.0 * screenSize.height - viewSize.height / 2.0 - 40};
	CGRect player1AltTextLabelFrame = {{-35, -25}, {230, 75}};
	CGRect player1AltDiceFrame = {{0, 115}, {280, 65}};

	CGPoint player2AltLocation = {screenSize.width * 0.1/8.0, screenSize.height * 1.8 / 3.0 - viewSize.height / 2.0};
	CGRect player2AltTextLabelFrame = {{70, 0}, {230, 140}};
	CGRect player2AltDiceFrame = {{0, 0}, {65, 250}};

	CGPoint player3AltLocation = {screenSize.width * 0.1/8.0, screenSize.height * 1.2 / 3.0 - viewSize.height / 2.0};
	CGRect player3AltTextLabelFrame = {{70, 0}, {230, 140}};
	CGRect player3AltDiceFrame = {{0, -110}, {65, 250}};

	CGPoint player4AltLocation = {screenSize.width / 3.0 - viewSize.width / 2.0, 0.8 / 8.0 * screenSize.height};
	CGRect player4AltTextLabelFrame = {{0, 70}, {280, 90}};
	CGRect player4AltDiceFrame = {{0, 0}, {280, 65}};

	CGPoint player5Location = {screenSize.width * 2.0 / 3.0 - viewSize.width / 2.0, 0.8 / 8.0 * screenSize.height};
	CGRect player5TextLabelFrame = {{0, 70}, {280, 90}};
	CGRect player5DiceFrame = {{0, 0}, {280, 65}};

	CGPoint player6Location = {screenSize.width * 7.9/8.0 - viewSize.width, screenSize.height * 1.2 / 3.0 - viewSize.height / 2.0};
	CGRect player6TextLabelFrame = {{0, 0}, {215, 140}};
	CGRect player6DiceFrame = {{215, -110}, {65, 250}};

	CGPoint player7Location = {screenSize.width * 7.9/8.0 - viewSize.width, screenSize.height * 1.8 / 3.0 - viewSize.height / 2.0};
	CGRect player7TextLabelFrame = {{0, 0}, {215, 140}};
	CGRect player7DiceFrame = {{215, 0}, {65, 250}};

	CGPoint player8Location = {screenSize.width * 2.0 / 3.0 - viewSize.width / 2.0, 7.6 / 8.0 * screenSize.height - viewSize.height / 2.0 - 10};
	CGRect player8TextLabelFrame = {{0, 0}, {280, 75}};
	CGRect player8DiceFrame = {{0, 75}, {280, 65}};

	switch (playerCount)
	{
		case 2:
			player2Location = player3Location;
			player2DiceFrame = player3DiceFrame;
			player2TextLabelFrame = player3TextLabelFrame;
			break;
		case 5:
			player5Location = player4Location;
			player5DiceFrame = player4DiceFrame;
			player5TextLabelFrame = player4TextLabelFrame;

			player4Location = player3Location;
			player4DiceFrame = player3DiceFrame;
			player4TextLabelFrame = player3TextLabelFrame;

			player2Location = player2AltLocation;
			player2DiceFrame = player2AltDiceFrame;
			player2TextLabelFrame = player2AltTextLabelFrame;

			player3Location = player3AltLocation;
			player3DiceFrame = player3AltDiceFrame;
			player3TextLabelFrame = player3AltTextLabelFrame;
			break;
		case 6:
			player6Location = player4Location;
			player6DiceFrame = player4DiceFrame;
			player6TextLabelFrame = player4TextLabelFrame;

			player2Location = player2AltLocation;
			player2DiceFrame = player2AltDiceFrame;
			player2TextLabelFrame = player2AltTextLabelFrame;

			player3Location = player3AltLocation;
			player3DiceFrame = player3AltDiceFrame;
			player3TextLabelFrame = player3AltTextLabelFrame;

			player4Location = player4AltLocation;
			player4DiceFrame = player4AltDiceFrame;
			player4TextLabelFrame = player4AltTextLabelFrame;
			break;
		case 7:
			player2Location = player2AltLocation;
			player2DiceFrame = player2AltDiceFrame;
			player2TextLabelFrame = player2AltTextLabelFrame;

			player3Location = player3AltLocation;
			player3DiceFrame = player3AltDiceFrame;
			player3TextLabelFrame = player3AltTextLabelFrame;

			player4Location = player4AltLocation;
			player4DiceFrame = player4AltDiceFrame;
			player4TextLabelFrame = player4AltTextLabelFrame;
			break;
		case 8:
			player1Location = player1AltLocation;
			player1TextLabelFrame = player1AltTextLabelFrame;
			player1DiceFrame = player1AltDiceFrame;

			player2Location = player2AltLocation;
			player2DiceFrame = player2AltDiceFrame;
			player2TextLabelFrame = player2AltTextLabelFrame;

			player3Location = player3AltLocation;
			player3DiceFrame = player3AltDiceFrame;
			player3TextLabelFrame = player3AltTextLabelFrame;

			player4Location = player4AltLocation;
			player4DiceFrame = player4AltDiceFrame;
			player4TextLabelFrame = player4AltTextLabelFrame;
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

	self.animationFinished = YES;
	NSMutableArray* dieViewAnimated = [[NSMutableArray alloc] init];
	NSMutableArray* dieFramesAnimated = [[NSMutableArray alloc] init];

	// Add all the players with their locations
	for (int i = 0;i < playerCount;++i)
	{
		UIView* playerLocation = nil;

		if (i != 0)
			playerLocation = [[UIView alloc] initWithFrame:CGRectMake(locations[i].x, locations[i].y, 280, 140)];
		else
			playerLocation = self.controlStateView;

        UILabel *nameLabel = [[UILabel alloc] initWithFrame:textFrames[i]];
        nameLabel.backgroundColor = [UIColor clearColor];
		[nameLabel setTextColor:[UIColor whiteColor]];
		nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        [tempViews addObject:nameLabel];

		NSMutableAttributedString* nameLabelText = [localGame.gameState historyText:((PlayerState*)playerStates[i]).playerID colorName:(i == 0)];

		if ([playerStates[i] playerHasExacted])
			[nameLabelText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@ has exacted", [playerStates[i] playerName]]] ];

		if ([playerStates[i] playerHasPassed])
			[nameLabelText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@ has passed", [playerStates[i] playerName]]] ];

		nameLabel.numberOfLines = 0;
		nameLabel.attributedText = nameLabelText;
		nameLabel.accessibilityLabel = [self accessibleTextForString:nameLabel.attributedText.string];

		CGRect nameFrame = nameLabel.frame;

		{
			NSArray* lines = [nameLabel.text componentsSeparatedByString:@"\n"];

			NSError* error = nil;
			NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"[1-6]s" options:0 error:&error];

			CGSize constrainedSize = CGSizeMake(nameLabel.frame.size.width, 9999);
			NSDictionary* attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:nameLabel.font, NSFontAttributeName, nil];

			CGFloat y = 0;

			for (int j = 0;j < [lines count];j++)
			{
				NSString* line = [lines objectAtIndex:j];

				NSArray* matches = [regex matchesInString:line options:0 range:NSMakeRange(0, [line length])];

				assert([matches count] <= 1);

				if ([matches count] == 1) // Should only ever be one!
				{
					NSTextCheckingResult* result = [matches objectAtIndex:0];
					CGFloat x = -1;

					NSString* before = [line substringToIndex:[result range].location];
					x += [before boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributesDictionary context:nil].size.width;

					int number = [line characterAtIndex:result.range.location] - '0';

					UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, 25, 25)];
					[imageView setImage:[self imageForDie:number]];

					[nameLabel addSubview:imageView];
					[previousBidImageViews addObject:imageView];
				}

				y += [line boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributesDictionary context:nil].size.height;
			}

			nameFrame.size.height = y;
		}

		nameLabel.frame = nameFrame;

		if ([playerStates[i] isMyTurn] && i != 0)
		{
			UIActivityIndicatorView* spinnerView = [[UIActivityIndicatorView alloc] init];
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

		UIView *diceView = [[UIView alloc] initWithFrame:diceFrames[i]];

		int dieSize = 50;

		int incrementer = 0;

		for (int dieIndex = 0; dieIndex < [((PlayerState*)playerStates[i]).arrayOfDice count]; ++dieIndex)
		{
			incrementer = dieIndex * dieSize;
			Die *die = [((PlayerState*)playerStates[i]) getDie:dieIndex];

			CGRect dieFrame = {{0,0}, {dieSize, dieSize}};

			if (diceFrames[i].size.height > diceFrames[i].size.width)
				dieFrame.origin.y = incrementer;
			else
				dieFrame.origin.x = incrementer;

			if (i == 0)
				dieFrame.origin.y = 0;

			int dieFace = -1;

			if (die.hasBeenPushed || i == 0 || showAllDice || localGame.gameState.gameWinner)
				dieFace = die.dieValue;

			UIImage *dieImage = [self imageForDie:dieFace];
			if (i == 0 && !die.hasBeenPushed && !localGame.gameState.gameWinner)
			{
				UIButton *dieButton = [UIButton buttonWithType:UIButtonTypeCustom];

				dieFrame.size.height += 30;
				dieButton.frame = dieFrame;

				CGRect imageFrame = CGRectMake(0, 15, dieSize, dieSize);

				UIImageView* dieView = [[UIImageView alloc] initWithFrame:imageFrame];
				[dieView setImage:dieImage];
				[dieView setUserInteractionEnabled:NO];

				[dieButton addSubview:dieView];
				dieButton.tag = dieIndex;

				if (canBid)
					[dieButton addTarget:self action:@selector(dieButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
				else
					dieButton.userInteractionEnabled = NO;

				[diceView addSubview:dieButton];
			}
			else
			{
				UIImageView *dieView = [[UIImageView alloc] initWithFrame:dieFrame];
				[dieView setImage:[self imageForDie:dieFace]];
				[diceView addSubview:dieView];

				if (die.hasBeenPushed)
				{
					if (i == 0)
						dieFrame.origin.y = 0;
					else if (playerCount == 2 && i == 1)
						dieFrame.origin.y = 15;
					else if (playerCount == 3 || playerCount == 4)
					{
						if (i == 1)
							dieFrame.origin.x = 15;
						else if (i == 2)
							dieFrame.origin.y = 15;
						else if (i == 3)
							dieFrame.origin.x = 0;
					}
					else if (playerCount == 5)
					{
						if (i == 1 || i == 2)
							dieFrame.origin.x = 15;
						else if (i == 3)
							dieFrame.origin.y = 15;
						else if (i == 4)
							dieFrame.origin.x = 0;
					}
					else
					{
						if (i == 1 || i == 2)
							dieFrame.origin.x = 15;
						else if (i == 3 || i == 4)
							dieFrame.origin.y = 15;
						else if (i == 5 || i == 6)
							dieFrame.origin.x = 0;
						else if (i == 7)
							dieFrame.origin.y = 0;
					}
				}
				else
				{
					if (i == 0)
						dieFrame.origin.y = 15;
					else if (playerCount == 2 && i == 1)
						dieFrame.origin.y = 0;
					else if (playerCount == 3 || playerCount == 4)
					{
						if (i == 1)
							dieFrame.origin.x = 0;
						else if (i == 2)
							dieFrame.origin.y = 0;
						else if (i == 3)
							dieFrame.origin.x = 15;
					}
					else if (playerCount == 5)
					{
						if (i == 1 || i == 2)
							dieFrame.origin.x = 0;
						else if (i == 3)
							dieFrame.origin.y = 0;
						else if (i == 4)
							dieFrame.origin.x = 15;
					}
					else
					{
						if (i == 1 || i == 2)
							dieFrame.origin.x = 0;
						else if (i == 3 || i == 4)
							dieFrame.origin.y = 0;
						else if (i == 5 || i == 6)
							dieFrame.origin.x = 15;
						else if (i == 7)
							dieFrame.origin.y = 15;
					}
				}

				if (die.markedToPush && i != 0)
				{
					die.markedToPush = NO;

					[dieViewAnimated addObject:dieView];
					[dieFramesAnimated addObject:[NSValue valueWithCGRect:dieFrame]];
				}
				else
					dieView.frame = dieFrame;
			}
		}

		[playerLocation addSubview:diceView];
		[tempViews addObject:diceView];

		// Possibly add challenge button.
		if (canBid && [self canChallengePlayer:((PlayerState*)playerStates[i]).playerID] && !localGame.gameState.gameWinner) {
			CGRect frame = CGRectMake(200, 0, 100, 40);

			if (i == 7)
			{
				frame.origin.y = -40;
				frame.origin.x = 0;
			}
			else if (i == 6 || i == 5 || (playerCount == 5 && i == 4) || (playerCount == 4 && i == 3))
				frame.origin.x = 0;

			frame.origin.x += locations[i].x;
			frame.origin.y += locations[i].y;

			UIButton *challengeButton = [[UIButton alloc] initWithFrame:frame];
			[challengeButton setTitle:@"Challenge" forState:UIControlStateNormal];
			challengeButton.tag = ((PlayerState*)playerStates[i]).playerID;
			[challengeButton addTarget:self action:@selector(challengePressed:) forControlEvents:UIControlEventTouchUpInside];
			[challengeButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:192.0/255.0 blue:28/255.0 alpha:1.0] forState:UIControlStateNormal];
			challengeButton.titleLabel.font = [UIFont systemFontOfSize:17.0];

			[self.view addSubview:challengeButton];
			[self.view bringSubviewToFront:challengeButton];

			[challengeButtons addObject:challengeButton];
			[tempViews addObject:challengeButton];
		}

		[self.view addSubview:playerLocation];
		[tempViews addObject:playerLocation];
	}

	if ([dieFramesAnimated count] > 0)
	{
		self.animationFinished = NO;

		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionOverrideInheritedDuration animations:^(void)
		 {
			 for (int i = 0;i < [dieFramesAnimated count];i++)
				 ((UIImageView*)[dieViewAnimated objectAtIndex:i]).frame = [((NSValue*)[dieFramesAnimated objectAtIndex:i]) CGRectValue];

		 } completion:^(BOOL finished)
		 {
			 self.animationFinished = finished;
		 }];

		while (!self.animationFinished)
			[[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
	}
}

- (IBAction)bidCountPlusPressed:(id)sender {
	hasTouchedBidCounterThisTurn = YES;

    ++currentBidCount;
	internalCurrentBidCount = currentBidCount;
    [self constrainAndUpdateBidCount];
}

- (IBAction)bidCountMinusPressed:(id)sender {
	hasTouchedBidCounterThisTurn = YES;

    --currentBidCount;
	internalCurrentBidCount = currentBidCount;
    [self constrainAndUpdateBidCount];
}

- (IBAction)bidFacePlusPressed:(id)sender {
	if (hasTouchedBidCounterThisTurn && currentBidFace == 1)
	{
		internalCurrentBidCount *= 2.0;
		currentBidCount = internalCurrentBidCount;
	}

	++currentBidFace;

	if (currentBidFace == 7)
		currentBidFace = 1;

	if (hasTouchedBidCounterThisTurn && currentBidFace == 1)
	{
		internalCurrentBidCount /= 2.0;
		currentBidCount = ceil(internalCurrentBidCount);
	}
	else if (!hasTouchedBidCounterThisTurn)
	{
		DiceGame* localGame = self.game;

		currentBidCount = [self minimumLegalBid:localGame.gameState.previousBid withCurrentFace:currentBidFace].numberOfDice;
		internalCurrentBidCount = currentBidCount;
	}

    [self constrainAndUpdateBidFace];
}

- (IBAction)bidFaceMinusPressed:(id)sender {
	if (hasTouchedBidCounterThisTurn && currentBidFace == 1)
	{
		internalCurrentBidCount *= 2.0;
		currentBidCount = internalCurrentBidCount;
	}

	--currentBidFace;

	if (currentBidFace == 0)
		currentBidFace = 6;

	if (hasTouchedBidCounterThisTurn && currentBidFace == 1)
	{
		internalCurrentBidCount /= 2.0;
		currentBidCount = ceil(internalCurrentBidCount);
	}
	else if (!hasTouchedBidCounterThisTurn)
	{
		DiceGame* localGame = self.game;

		currentBidCount = [self minimumLegalBid:localGame.gameState.previousBid withCurrentFace:currentBidFace].numberOfDice;
		internalCurrentBidCount = currentBidCount;
	}

    [self constrainAndUpdateBidFace];
}

-(void)constrainAndUpdateBidCount {
    int maxBidCount = 0;

	DiceGame* localGame = self.game;

	for (PlayerState* pstate in localGame.gameState.playerStates)
	{
		if ([pstate isKindOfClass:[PlayerState class]])
			maxBidCount += [[pstate arrayOfDice] count];
	}

	if (maxBidCount != 0)
	{
		currentBidCount = (currentBidCount - 1 + maxBidCount) % maxBidCount + 1;
		internalCurrentBidCount = currentBidCount;
	}
	else
	{
		currentBidCount = 1;
		internalCurrentBidCount = currentBidCount;
	}

    [self updateCurrentBidLabels];
}

-(void)constrainAndUpdateBidFace {
    int maxFace = 6;
    currentBidFace = (currentBidFace - 1 + maxFace) % maxFace + 1;
    [self updateCurrentBidLabels];
}

- (IBAction)challengePressed:(id)sender {
	UIButton* challengeButton = (UIButton*)sender;
	int playerID = (int)challengeButton.tag;

	HistoryItem* previousItem = nil;

	DiceGame* localGame = self.game;

	NSArray* lastPlayerMoves = [localGame.gameState lastMoveForPlayer:playerID];
	if ([lastPlayerMoves count] > 0)
	{
		for (int i = (int)[lastPlayerMoves count] - 1;i >= 0;i--)
		{
			HistoryItem* item = [lastPlayerMoves objectAtIndex:i];

			if ([item actionType] == ACTION_BID || [item actionType] == ACTION_PASS)
			{
				previousItem = item;
				break;
			}
		}
	}

	assert(previousItem != nil);

	NSString* messageString = nil;
	PlayerState* stateLocal = [previousItem player];
	NSString* buttonTitle = [[self.game.players objectAtIndex:stateLocal.playerID] getDisplayName];

	if (previousItem.actionType == ACTION_BID)
	{
		messageString = [previousItem asString];
		buttonTitle = [NSString stringWithFormat:@"%@'s bid", buttonTitle];
	}
	else
	{
		messageString = @"";
		buttonTitle = [NSString stringWithFormat:@"%@'s pass", buttonTitle];
	}

	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Challenge?"
                                                     message:messageString
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:buttonTitle, nil];

	alert.tag = (previousItem.actionType == ACTION_BID ? ACTION_CHALLENGE_BID : ACTION_CHALLENGE_PASS);
    [alert show];
}

- (IBAction)passPressed:(id)sender {
	NSString* message = nil;

	PlayerState* stateLocal = self.state;

	if ([[stateLocal markedToPushDice] count] > 0)
		message = [NSString stringWithFormat:@"Pass and push %lu %@?", (unsigned long)[[stateLocal markedToPushDice] count], ([[stateLocal markedToPushDice] count] == 1 ? @"die" : @"dice")];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pass?"
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Pass", nil];
    alert.tag = ACTION_PASS;
    [alert show];
}

- (IBAction)bidPressed:(id)sender {
    // Check that the bid is legal
	PlayerState* stateLocal = self.state;
	DiceGame* localGame = self.game;

	NSMutableArray *markedToPushDiceWithPushedDice = [NSMutableArray arrayWithArray:[stateLocal markedToPushDice]];
	[markedToPushDiceWithPushedDice addObjectsFromArray:[stateLocal pushedDice]];

    Bid *bid = [[Bid alloc] initWithPlayerID:stateLocal.playerID name:stateLocal.playerName dice:currentBidCount rank:currentBidFace push:markedToPushDiceWithPushedDice];
    if (!([localGame.gameState getCurrentPlayerState].playerID == stateLocal.playerID &&
		  [localGame.gameState checkBid:bid playerSpecialRules:([localGame.gameState usingSpecialRules] &&
																[stateLocal numberOfDice] > 1)])) {
        NSString *title = @"Illegal raise";
		NSString *pushedDice = @"";

		if ([markedToPushDiceWithPushedDice count] > 0)
			pushedDice = [NSString stringWithFormat:@",\nAnd push %lu %@", (unsigned long)[[stateLocal markedToPushDice] count], ([[stateLocal markedToPushDice] count] == 1 ? @"die" : @"dice")];

        NSString *message = [NSString stringWithFormat:@"Can't bid %d %@ %@", currentBidCount, [self stringForDieFace:currentBidFace andIsPlural:(currentBidCount > 1)], pushedDice];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"Okay"
                                               otherButtonTitles:nil];

        [alert show];
        return;
    }

    NSString *title = [NSString stringWithFormat:@"Bid %d %@?", currentBidCount, [self stringForDieFace:currentBidFace andIsPlural:(currentBidCount > 1)]];
    NSArray *push = [self makePushedDiceArray];
    NSString *message = (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %lu %@?", (unsigned long)[push count], ([push count] == 1 ? @"die" : @"dice")];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Bid", nil];
    alert.tag = ACTION_BID;

    [alert show];
}

- (IBAction)exactPressed:(id)sender {
	DiceGame* localGame = self.game;

    Bid *previousBid = localGame.gameState.previousBid;
    NSString *bidStr = [previousBid asString];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Exact?"
                                                     message:bidStr
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Exact", nil];
    alert.tag = ACTION_EXACT;

    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	PlayerState* localState = self.state;
	DiceGame* localGame = self.game;

	if (buttonIndex == alertView.cancelButtonIndex)
    {
		// Enable the buttons if we actually can do those actions at this update cycle
		BOOL canBid = [localState canBid];

		self.passButton.enabled = canBid && [localState canPass];
		self.bidButton.enabled = canBid;
		self.bidCountPlusButton.enabled = canBid;
		self.bidCountMinusButton.enabled = canBid;
		self.bidFacePlusButton.enabled = canBid;
		self.bidFaceMinusButton.enabled = canBid;
		self.exactButton.enabled = canBid && [localState canExact];

        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"

    switch (alertView.tag)
    {
        case ACTION_BID:
        {
            DiceAction *action = [DiceAction bidAction:localState.playerID
                                                 count:currentBidCount
                                                  face:currentBidFace
                                                  push:[self makePushedDiceArray]];

            [localGame performSelectorInBackground:@selector(handleAction:) withObject:action];
            break;
        }
        case ACTION_CHALLENGE_BID:
        case ACTION_CHALLENGE_PASS:
        {
			ActionType type = alertView.tag == ACTION_CHALLENGE_BID ? ACTION_BID : ACTION_PASS;

			// Find last bid
			int target = -1;

			for (int i = (int)[localGame.gameState.history count] - 1;i >= 0;i--)
			{
				HistoryItem* item = [localGame.gameState.history objectAtIndex:i];
				if ([item actionType] == type)
				{
					PlayerState* itemState = [item player];
					target = [itemState playerID];
					break;
				}
			}

			assert(target != -1);

			DiceAction *action = [DiceAction challengeAction:localState.playerID
													  target:target];

			[localGame performSelectorInBackground:@selector(handleAction:) withObject:action];
			break;
        }
        case ACTION_EXACT:
        {
            DiceAction *action = [DiceAction exactAction:localState.playerID];

			[localGame performSelectorInBackground:@selector(handleAction:) withObject:action];
            break;
        }
        case ACTION_PASS:
        {
            DiceAction *action = [DiceAction passAction:localState.playerID
                                                   push:[self makePushedDiceArray]];

			[localGame performSelectorInBackground:@selector(handleAction:) withObject:action];
            break;
        }
        case ACTION_QUIT:
        {
            quitHandler();
        }
        default:
			return;
    }

#pragma clang diagnostic pop
}

-(NSArray*)makePushedDiceArray {
    NSMutableArray *ar = [NSMutableArray array];
	PlayerState* localState = self.state;

    for (Die *die in localState.arrayOfDice)
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
	PlayerState* localState = self.state;

    NSInteger buttonOffset = buttonIndex - 1;
    Bid *challengeableBid = [localState getChallengeableBid];
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
    int passID = [localState getChallengeableLastPass];
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
    passID = [localState getChallengeableSecondLastPass];
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
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];

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
