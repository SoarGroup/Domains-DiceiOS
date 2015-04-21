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
#import "SoarPlayer.h"

#import "DiceReplayPlayer.h"
#import "DiceSoarReplayPlayer.h"

#import "MultiplayerView.h"
#import "HistoryView.h"

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

- (void)realRoundEnding;

- (void)updateUI:(NSString*)gameStateLabel;

- (void)handleTutorial;

@end

@implementation PlayGameView
@synthesize hasPromptedEnd;
@synthesize bidCountLabel;
@synthesize bidFaceLabel;
@synthesize bidCountPlusButton;
@synthesize bidCountMinusButton;
@synthesize bidFacePlusButton;
@synthesize bidFaceMinusButton;
@synthesize passButton;
@synthesize bidButton;
@synthesize exactButton;
@synthesize gameStateLabel;
@synthesize continueRoundButton;
@synthesize multiplayerView, overViews;
@synthesize playerScrollView;

@synthesize bidCountLabelHint, bidFaceLabelHint;

@synthesize game, state, animationFinished;

@synthesize player1View, player2View, player3View, player4View, player5View, player6View, player7View, player8View, playerViews;

NSString *numberName(int number) {
	return [NSString stringWithFormat:@"%ds", number];
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
		
		NSString* nibName = @"PlayGameView";
		
		NSUInteger playerCount = [aGame.players count];
		
		if (![device isEqualToString:@"iPhone"])
			nibName = [nibName stringByAppendingFormat:@"-%luiPad", (unsigned long)playerCount];
		
		self = [super initWithNibName:nibName bundle:nil];
	}
	else
		self = [super initWithNibName:@"PlayGameView" bundle:nil];
	
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
		
		overViews = [NSMutableArray array];
		hasPromptedEnd = NO;
		hasDisplayedRoundOverview = NO;
		hasDisplayedRoundBeginning = NO;
		canContinueRound = YES;
	}
	return self;
}

- (id)initTutorialWithQuitHandler:(void (^)(void))QuitHandler
{
	NSString* device = [UIDevice currentDevice].model;
	device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];
	
	NSString* nibName = @"TutorialView";
	
	if (![device isEqualToString:@"iPhone"])
		nibName = [nibName stringByAppendingString:@"-iPad"];
	
	self = [super initWithNibName:nibName bundle:nil];
	
	if (self)
	{
		// Custom initialization
		self.game = nil;
		self.state = nil;
		currentBidCount = 1;
		internalCurrentBidCount = 1;
		currentBidFace = 2;
		quitHandler = QuitHandler;
		
		overViews = [NSMutableArray array];
		hasPromptedEnd = NO;
		hasDisplayedRoundOverview = NO;
		hasDisplayedRoundBeginning = NO;
		canContinueRound = YES;
		
		tutorial = YES;
		step = 0;
	}
	
	return self;
}

- (BOOL) roundEnding
{
	DDLogInfo(@"Round Ending!");
	
	if (hasDisplayedRoundOverview)
		return YES;
	
	DDLogInfo(@"Has not displayed overview!");
	
	DiceGame* localGame = self.game;
	localGame.gameState.canContinueGame = NO;
	shouldNotifyCurrentPlayer = localGame->shouldNotifyOfNewRound;
	hasDisplayedRoundOverview = YES;
	hasDisplayedRoundBeginning = NO;
	
	[self performSelectorOnMainThread:@selector(realRoundEnding) withObject:nil waitUntilDone:YES];
	
	return YES;
}

- (void)realRoundEnding
{
	DiceGame* localGame = self.game;
	
	if (isSoarOnlyGame)
	{
		[self continueRoundPressed:nil];
		return;
	}
	
	NSString *headerString = [localGame.gameState headerString:-1 singleLine:YES displayDiceCount:NO];
	PlayerState* playerStateLocal = [localGame.gameState lastHistoryItem].player;
	NSString *lastMoveString = [localGame.gameState historyText:playerStateLocal.playerID];
	
	NSString* finalString = [NSString stringWithFormat:@"%@\n%@", headerString, lastMoveString];
	
	if ([self.nibName rangeOfString:@"iPad"].location == NSNotFound)
	{
		RoundOverView *roundOverView = [[RoundOverView alloc] initWithGame:localGame
																	player:state
															  playGameView:self
														   withFinalString:finalString];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			[self.overViews addObject:roundOverView];
			//			roundOverView.view.frame = self.view.frame;
			roundOverView.view.frame = CGRectMake(0,
												  self.view.frame.size.height,
												  roundOverView.view.frame.size.width,
												  roundOverView.view.frame.size.height);
			
			//			ApplicationDelegate* localDelegate = (ApplicationDelegate*)[[UIApplication sharedApplication] delegate];
			//			MultiplayerView* controller = (MultiplayerView*)localDelegate.navigationController.visibleViewController;
			//			[controller.gamesScrollView addSubview:roundOverView.view];
			//			[controller.gamesScrollView bringSubviewToFront:roundOverView.view];
			[self.view addSubview:roundOverView.view];
			
			[UIView animateWithDuration:0.35 animations:^{
				roundOverView.view.frame = CGRectMake(0, 0, roundOverView.view.frame.size.width, roundOverView.view.frame.size.height);
				//				roundOverView.view.frame = CGRectMake(roundOverView.view.frame.origin.x,
				//													  self.view.frame.origin.y,
				//													  roundOverView.view.frame.size.width,
				//													  roundOverView.view.frame.size.height);
				
			}];
		}
		else
			[self.navigationController presentViewController:roundOverView animated:YES completion:nil];
	}
	else
	{
		showAllDice = YES;
		
		for (UIView* player in playerViews)
		{
			UIActivityIndicatorView* spinner = (UIActivityIndicatorView*)[player viewWithTag:ActivitySpinnerTag];
			
			if ([spinner isKindOfClass:UIActivityIndicatorView.class])
				spinner.hidden = YES;
		}
		
		self.continueRoundButton.hidden = NO;
		self.continueRoundButton.enabled = YES;
		
		self.exactButton.enabled = NO;
		self.passButton.enabled = NO;
		self.bidButton.enabled = NO;
		self.bidCountPlusButton.enabled = NO;
		self.bidCountMinusButton.enabled = NO;
		self.bidFacePlusButton.enabled = NO;
		self.bidFaceMinusButton.enabled = NO;
		
		canContinueRound = NO;
		showAllDice = NO;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self updateUI:finalString];
		});
	}
}

- (IBAction)continueRoundPressed:(UIButton*)sender
{
	if (tutorial)
	{
		[self handleTutorial];
		return;
	}
	
	canContinueRound = YES;
	sender.enabled = NO;
	sender.hidden = YES;
	
	self.exactButton.enabled = YES;
	self.passButton.enabled = YES;
	self.bidButton.enabled = YES;
	self.bidCountPlusButton.enabled = YES;
	self.bidCountMinusButton.enabled = YES;
	self.bidFacePlusButton.enabled = YES;
	self.bidFaceMinusButton.enabled = YES;
	
	DiceGame* localGame = self.game;
	PlayerState* lastPlayerState = [[localGame.gameState lastHistoryItem] player];
	
	while ([[lastPlayerState playerPtr] isKindOfClass:SoarPlayer.class] && ![[lastPlayerState playerPtr] isKindOfClass:DiceSoarReplayPlayer.class])
	{
		int playerID = [lastPlayerState playerID] - 1;
		
		if (playerID < 0)
			playerID = (int)[localGame.players count] - 1;
		
		lastPlayerState = [localGame.gameState playerStateForPlayerID:playerID];
	}
	
	localGame.gameState.canContinueGame = YES;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ContinueRoundPressed" object:nil];
	
	[self updateUI];
	
	if (isSoarOnlyGame && [localGame.gameState hasAPlayerWonTheGame])
	{
		[self quit];

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			self->quitHandler();
		});
	}
}

- (void)quit
{
	PlayerState* localState = self.state;
	id<Player> playerPtr = localState.playerPtr;
	[((DiceLocalPlayer*)playerPtr).gameViews removeAllObjects];
}

- (BOOL) roundBeginning
{
	if (![NSThread isMainThread])
	{
		[self performSelectorOnMainThread:@selector(roundBeginning) withObject:nil waitUntilDone:YES];
		return NO;
	}
	
	hasTouchedBidCounterThisTurn = NO;
	hasDisplayedRoundOverview = NO;
	
	NSString *title = nil, *message = nil;
	
	DiceGame* localGame = self.game;
	PlayerState* localState = self.state;
	
	if (!hasDisplayedRoundBeginning)
	{
		if ([localGame.gameState usingSpecialRules]) {
			title = [NSString stringWithFormat:@"Special Rules!"];
			message = @"For this round: 1s aren't wild. Only players with one die may change the bid face.";
		}
		else if ([localState hasWon])
			title = [[NSString stringWithFormat:@"You Win!"] uppercaseString];
		else if ([localGame.gameState hasAPlayerWonTheGame])
		{
			id<Player> gameWinner = localGame.gameState.gameWinner;
			title = [[NSString stringWithFormat:@"%@ Wins!", [gameWinner getDisplayName]] uppercaseString];
		}
		else if ([localState hasLost] && !self.hasPromptedEnd)
		{
			self.hasPromptedEnd = YES;
			title = [NSString stringWithFormat:@"You Lost the Game"];
		}
		
		hasDisplayedRoundBeginning = YES;
	}
	
	if (title)
		[[[UIAlertView alloc] initWithTitle:title
									message:message
								   delegate:nil
						  cancelButtonTitle:@"Okay"
						  otherButtonTitles:nil] show];
	
	return NO;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.navigationController.navigationBarHidden = NO;
	self.navigationController.navigationBar.translucent = [self.nibName rangeOfString:@"iPad"].location != NSNotFound;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUINotification:) name:@"UpdateUINotification" object:nil];
	
	DiceGame* localGame = self.game;
	
	[localGame.gameState addNewRoundListener:self];
	
	if (localGame.gameState.gameWinner)
		for (id<Player> player in localGame.players)
			if ([player isKindOfClass:DiceLocalPlayer.class])
			{
				[(DiceLocalPlayer*)player end:YES];
				break;
			}
	
	[self updateUI];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	DiceGame* localGame = self.game;
	
	[[localGame gameLock] lock];
	[localGame.gameState.theNewRoundListeners removeObject:self];
	[[localGame gameLock] unlock];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if (tutorial && step == 0)
	{
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Welcome to Liar's Dice!"
														message:@"This tutorial is designed to familiarize you with our interface for the game."
													   delegate:self
											  cancelButtonTitle:@"Exit Tutorial"
											  otherButtonTitles:@"Continue", nil];
		
		alert.tag = TUTORIAL;
		if (!isSoarOnlyGame)
			[alert show];
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	DiceGame* localGame = self.game;
	
	for (id<Player> player in localGame.players)
		if ([player isKindOfClass:DiceLocalPlayer.class])
		{
			[((DiceLocalPlayer*)player).gameViews addObject:self];
			break;
		}
	
	NSMutableArray* array = [NSMutableArray array];
	
	if (player1View)
		[array addObject:player1View];
	
	if (player2View)
		[array addObject:player2View];
	
	if (player3View)
		[array addObject:player3View];
	
	if (player4View)
		[array addObject:player4View];
	
	if (player5View)
		[array addObject:player5View];
	
	if (player6View)
		[array addObject:player6View];
	
	if (player7View)
		[array addObject:player7View];
	
	if (player8View)
		[array addObject:player8View];
	
	playerViews = array;
	
	int humanCount = 0;
	int AICount = 0;
	
	for (NSUInteger i = 0; i < [localGame.players count];++i)
	{
		if ([[localGame.players objectAtIndex:i] isKindOfClass:DiceRemotePlayer.class])
			humanCount++;
		else if ([[localGame.players objectAtIndex:i] isKindOfClass:SoarPlayer.class])
			AICount++;
	}
	
	if (tutorial)
		self.navigationItem.title = @"Tutorial";
	else if (humanCount == 0)
		self.navigationItem.title = [NSString stringWithFormat:@"Single Player Match"];
	else if (humanCount > 1)
		self.navigationItem.title = [NSString stringWithFormat:@"Multiplayer Match"];
	
	if ([[self nibName] rangeOfString:@"iPad"].location == NSNotFound)
	{
		id last = nil;
		
		if (tutorial)
			last = player2View;
		else
			last = [playerViews objectAtIndex:localGame.players.count - 1];
		
		[playerScrollView addConstraint:[NSLayoutConstraint constraintWithItem:last
																	 attribute:NSLayoutAttributeBottom
																	 relatedBy:NSLayoutRelationEqual
																		toItem:playerScrollView
																	 attribute:NSLayoutAttributeBottom
																	multiplier:1.0
																	  constant:0]];
		
		if (tutorial)
			playerScrollView.contentSize = CGSizeMake(playerScrollView.frame.size.width,
													  128);
		else
			playerScrollView.contentSize = CGSizeMake(playerScrollView.frame.size.width,
													  ([localGame.players count]-1) * 128);
	}
	
	if (tutorial)
		return;
	
	UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"History" style:UIBarButtonItemStylePlain target:self action:@selector(displayHistoryView:)];
	self.navigationItem.rightBarButtonItem = rightButton;
	
	for (NSUInteger i = [localGame.players count];i < [playerViews count];i++)
		((UIView*)[playerViews objectAtIndex:i]).hidden = YES;
	
	[localGame startGame];
	
	ApplicationDelegate* delegate = localGame.appDelegate;
	GameKitGameHandler* handler = [delegate.listener handlerForGame:localGame];
	
	if (handler)
		[handler saveMatchData];
	
	NSMutableArray* reorderedPlayers = [NSMutableArray arrayWithArray:localGame.players];
	
	while (![[reorderedPlayers firstObject] isKindOfClass:DiceLocalPlayer.class] &&
		   ![[reorderedPlayers firstObject] isKindOfClass:DiceReplayPlayer.class] &&
		   ![[reorderedPlayers firstObject] isKindOfClass:DiceSoarReplayPlayer.class])
	{
		[reorderedPlayers insertObject:[reorderedPlayers lastObject] atIndex:0];
		[reorderedPlayers removeLastObject];
	}
	
	for (int i = 0;i < [reorderedPlayers count];++i)
		((UIView*)[playerViews objectAtIndex:i]).tag = [[reorderedPlayers objectAtIndex:i] getID];
}

-(BOOL) navigationShouldPopOnBackButton {
	[self backPressed:nil];
	
	return NO;
}

+ (UIImage *)imageForDie:(NSInteger)die
{
	return [DiceGraphics imageWithType:(DiceImageType)die];
}

+ (NSInteger)dieForImage:(UIImage*)image
{
	NSData *data1 = UIImagePNGRepresentation(image);
	
	for (int i = DIE_1;i <= DIE_6;++i)
	{
		NSData *data2 = UIImagePNGRepresentation([DiceGraphics imageWithType:(DiceImageType)i]);
		
		if ([data1 isEqualToData:data2])
			return i;
	}
	
	return DIE_UNKNOWN;
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

- (IBAction)backPressed:(id)sender
{
	NSArray* controllers = self.navigationController.viewControllers;
	if (!self.navigationController ||
		[[controllers lastObject] isKindOfClass:MultiplayerView.class] ||
		[[controllers objectAtIndex:(controllers.count - 2)] isKindOfClass:MultiplayerView.class])
	{
		quitHandler();
		return;
	}
	
	NSString *title = [NSString stringWithFormat:@"Leave the game?"];
	NSString *message = nil;
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:self
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"Leave", nil];
	alert.tag = ACTION_QUIT;
	if (!isSoarOnlyGame)
		[alert show];
}

- (bool) canChallengePlayer:(int)otherPlayerID {
	PlayerState* localState = self.state;
	
	Bid *challengeableBid = [localState getChallengeableBid];
	if (challengeableBid != nil && challengeableBid.playerID == otherPlayerID)
		return YES;
	
	int passID = [localState getChallengeableLastPass];
	if (passID != -1 && passID == otherPlayerID)
		return YES;
	
	passID = [localState getChallengeableSecondLastPass];
	if (passID != -1 && passID == otherPlayerID)
		return YES;
	
	return NO;
}

- (void)updateState:(PlayerState*)newState
{
	DiceGame* localGame = self.game;
	if (![localGame.gameState.theNewRoundListeners containsObject:self])
	{
		[[localGame gameLock] lock];
		[localGame.gameState.theNewRoundListeners removeAllObjects];
		[localGame.gameState.theNewRoundListeners addObject:self];
		[[localGame gameLock] unlock];
	}
	
	self.state = newState;
	[self updateUI];
}

- (void) updateCurrentBidLabels {
	self.bidCountLabel.text = [NSString stringWithFormat:@"%d", currentBidCount];
	self.bidCountLabel.accessibilityLabel = [NSString stringWithFormat:@"Bid Die Count, Face Value of %i", currentBidCount];
	
	[self.bidFaceLabel setImage:[PlayGameView imageForDie:currentBidFace]];
	self.bidFaceLabel.accessibilityLabel = [NSString stringWithFormat:@"Bid Die Face, Face Value of %i", currentBidFace];
}

- (IBAction) dieButtonPressed:(id)sender
{
	UIButton *button = (UIButton*)sender;
	
	if (tutorial && step != 8)
	{
		[self handleTutorial];
		return;
	}
	
	NSInteger dieIndex = button.tag;
	
	PlayerState* localState = self.state;
	
	if (tutorial)
	{
		localState = [[PlayerState alloc] initWithName:@"You" withID:0 withNumberOfDice:5 withDiceGameState:nil];
		[localState.arrayOfDice removeAllObjects];
		
		NSArray* subviews = [player1View viewWithTag:DiceViewTag].subviews;
		for (UIButton* dieButton in subviews)
		{
			Die* dieObject = [[Die alloc] initWithNumber:(int)[PlayGameView dieForImage:dieButton.imageView.image]];
			
			if (dieButton.frame.origin.y == 0)
				dieObject.markedToPush = YES;
			
			[localState.arrayOfDice addObject:dieObject];
		}
	}
	
	
	Die *dieObject = [localState.arrayOfDice objectAtIndex:dieIndex];
	if (dieObject.hasBeenPushed)
		return;
	
	dieObject.markedToPush = ! dieObject.markedToPush;
	
	if (dieObject.markedToPush)
	{
		if (!tutorial)
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
	
	CGRect newFrame = button.frame;
	
	if (dieObject.markedToPush)
		newFrame.origin.y = 0;
	else
		newFrame.origin.y = 15;
	
	NSMutableArray* nonMarkedOrPushedDice = [NSMutableArray array];
	
	for (int i = 0;i < [localState.arrayOfDice count];i++)
	{
		Die* die = [localState.arrayOfDice objectAtIndex:i];
		if (!die.markedToPush && !die.hasBeenPushed)
			[nonMarkedOrPushedDice addObject:[NSNumber numberWithInt:i]];
	}
	
	if ([nonMarkedOrPushedDice count] == 1)
		((UIButton*)[[player1View viewWithTag:DiceViewTag] viewWithTag:[[nonMarkedOrPushedDice firstObject] intValue]]).enabled = NO;
	else if (!tutorial)
		for (NSNumber* number in nonMarkedOrPushedDice)
			((UIButton*)[[player1View viewWithTag:DiceViewTag] viewWithTag:[number intValue]]).enabled = YES;
	
	[UIView animateWithDuration:0.3f animations:^{
		button.frame = newFrame;
	} completion:^(BOOL finished)
	 {
		 if (finished && self->tutorial && self->step == 8 && [nonMarkedOrPushedDice count] == 1)
			 [self handleTutorial];
	 }];
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
	[self updateUI:nil];
}

- (void)updateUI:(NSString*)stateLabel
{
	if (![NSThread isMainThread])
	{
		[self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:YES];
		
		return;
	}
	
	if (tutorial)
		return;
	
	if (!canContinueRound)
		return;
	
	self.exactButton.enabled = NO;
	self.passButton.enabled = NO;
	self.bidButton.enabled = NO;
	self.bidCountPlusButton.enabled = NO;
	self.bidCountMinusButton.enabled = NO;
	self.bidFacePlusButton.enabled = NO;
	self.bidFaceMinusButton.enabled = NO;
	
	// State initialization
	DiceGame* localGame = self.game;
	PlayerState* localState = self.state;
	
	ApplicationDelegate* delegate = localGame.appDelegate;
	GameKitGameHandler* handler = [delegate.listener handlerForGame:localGame];
	GKTurnBasedMatch* match = handler.match;
	NSString* localPlayerID = [GKLocalPlayer localPlayer].playerID;
	
	if ([match.currentParticipant.player.playerID isEqualToString:localPlayerID] &&
		[[localGame.players objectAtIndex:localGame.gameState.currentTurn] isKindOfClass:DiceRemotePlayer.class] &&
		[localState hasLost])
	{
		DiceRemotePlayer* next = nil;
		
		for (id<Player> player in localGame.players)
			if ([player isKindOfClass:DiceRemotePlayer.class] && ![[localGame.gameState playerStateForPlayerID:[player getID]] hasLost])
				next = player;
		
		if (next)
			[handler advanceToRemotePlayer:next];
	}
	
	if (localGame.newRound && !hasDisplayedRoundOverview)
	{
		[self roundEnding];
		return;
	}
	
	if ([localGame.gameState.theNewRoundListeners count] == 0)
		[localGame.gameState addNewRoundListener:self];
	
	if (localState == nil)
	{
		for (id<Player> player in localGame.players)
			if ([player isKindOfClass:DiceLocalPlayer.class])
			{
				self.state = [localGame.gameState playerStateForPlayerID:[player getID]];
				[((DiceLocalPlayer*)player).gameViews addObject:self];
			}
		
		localState = self.state;
	}
	
	Bid *previousBid = localGame.gameState.previousBid;
	NSString *headerString = [localState headerString:NO]; // This sets it
	
	if (stateLabel != nil)
		headerString = stateLabel;
	
	self.gameStateLabel.accessibilityLabel = [self accessibleTextForString:headerString];
	
	gameStateLabel.attributedText = [PlayGameView formatTextString:headerString];
	
	// Player UI
	BOOL canBid = [localState canBid];
	
	id<Player> gameWinner = localGame.gameState.gameWinner;
	if (gameWinner)
		canBid = NO;
	
	// Enable the buttons if we actually can do those actions at this update cycle
	self.passButton.enabled = canBid && [localState canPass];
	self.bidButton.enabled = canBid;
	self.bidCountPlusButton.enabled = canBid;
	self.bidCountMinusButton.enabled = canBid;
	self.bidFacePlusButton.enabled = canBid;
	self.bidFaceMinusButton.enabled = canBid;
	self.exactButton.enabled = canBid && [localState canExact];
	
	continueRoundButton.hidden = YES;
	
	hasTouchedBidCounterThisTurn = NO;
	
	// Check if our previous bid is nil, if it is then we're starting and set the default dice to be bidding 1 two.
	if (localGame.gameState.currentTurn == localState.playerID)
	{
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
		
		// Update the bid "scroller" labels, the die image and number for the bid chooser
		[self updateCurrentBidLabels];
	}
	
	// Update the contents of the gameStateView
	NSArray *playerStates = localGame.gameState.playerStates;
	
	NSMutableArray* playerStatesReordered = [NSMutableArray arrayWithArray:playerStates];
	
	for (NSUInteger i = [playerStatesReordered count]; i > 0; i--) {
		PlayerState* obj = [playerStatesReordered lastObject];
		[playerStatesReordered insertObject:obj atIndex:0];
		[playerStatesReordered removeLastObject];
		
		if (obj.playerID == localState.playerID)
			break;
	}
	
	NSUInteger playerCount = [playerStatesReordered count];
	for (int z = 0;z < playerCount;++z)
	{
		PlayerState* playerState = [playerStatesReordered objectAtIndex:z];
		id<Player> playerPtr = [playerState playerPtr];
		
		UIView* view = [playerViews objectAtIndex:z];
		
		// Handle the player's info text
		
		UILabel* nameLabel = (UILabel*)[view viewWithTag:PlayerLabelTag];
		
		NSMutableAttributedString* nameLabelText = [localGame.gameState historyText:playerState.playerID colorName:(z == 0)];
		
		NSString* playerName = [playerPtr getDisplayName];
		
		if ([playerState playerHasExacted])
			[nameLabelText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@ %@ exacted", playerName, [playerName isEqualToString:@"You"] ? @"have" : @"has"]]];
		
		if ([playerState playerHasPassed])
			[nameLabelText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@ %@ passed", playerName, [playerName isEqualToString:@"You"] ? @"have" : @"has"]]];
		
		if ([playerPtr isKindOfClass:DiceRemotePlayer.class] && ((DiceRemotePlayer*)playerPtr).participant.matchOutcome == GKTurnBasedMatchOutcomeQuit)
			nameLabelText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@ quit", playerName, [playerName isEqualToString:@"You"] ? @"have" : @"has"]];
		else if ([playerPtr isKindOfClass:DiceRemotePlayer.class] && ((DiceRemotePlayer*)playerPtr).participant.matchOutcome == GKTurnBasedMatchOutcomeTimeExpired)
			nameLabelText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@ timed out", playerName, [playerName isEqualToString:@"You"] ? @"have" : @"has"]];
		else if ([playerState hasLost])
			nameLabelText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@ lost", playerName, [playerName isEqualToString:@"You"] ? @"have" : @"has"]];
		else if ([playerState hasWon])
			nameLabelText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@ won!", playerName, [playerName isEqualToString:@"You"] ? @"have" : @"has"]];
		
		nameLabel.accessibilityLabel = [self accessibleTextForString:nameLabelText.string];
		
		nameLabel.attributedText = [PlayGameView formatTextAttributedString:nameLabelText];
		
		// Update the spinner
		UIActivityIndicatorView* spinner = (UIActivityIndicatorView*)[view viewWithTag:ActivitySpinnerTag];
		
		if ([playerState isMyTurn])
		{
			[spinner startAnimating];
			spinner.hidden = NO;
		}
		else
			spinner.hidden = YES;
		
		// Update the dice
		UIView *diceView = [view viewWithTag:DiceViewTag];
		NSMutableArray* diceToAnimate = [NSMutableArray array];
		NSMutableArray* diceFramesToAnimate = [NSMutableArray array];
		
		NSMutableArray* diceNotPushed = [NSMutableArray array];
		
		for (int dieIndex = 0; dieIndex < [playerState.arrayOfDice count]; ++dieIndex)
		{
			Die *die = [playerState getDie:dieIndex];
			
			int dieFace = DIE_UNKNOWN;
			if (die.hasBeenPushed || z == 0 || showAllDice || gameWinner)
				dieFace = die.dieValue;
			
			UIImage *dieImage = [PlayGameView imageForDie:dieFace];
			
			UIButton* dieButton = (UIButton*)[diceView viewWithTag:dieIndex];
			dieButton.enabled = YES;
			dieButton.hidden = NO;
			
			if (dieFace == DIE_UNKNOWN || die.hasBeenPushed)
				dieButton.enabled = NO;
			else if (!die.hasBeenPushed)
				[diceNotPushed addObject:dieButton];
			
			[dieButton setImage:dieImage forState:UIControlStateNormal];
			
			NSString* accessibleName = [NSString stringWithFormat:@"%@%@", playerName, [playerName isEqualToString:@"You"] ? @"r" : @"'s"];
			NSString* faceValue = @"Unknown Face Value";
			
			if (die.hasBeenPushed || z == 0 || showAllDice || gameWinner)
				faceValue = [NSString stringWithFormat:@"Face Value of %i", die.dieValue];
			
			if (die.hasBeenPushed)
				dieButton.accessibilityLabel = [NSString stringWithFormat:@"%@ Die, %@, pushed", accessibleName, faceValue];
			else
			{
				dieButton.accessibilityLabel = [NSString stringWithFormat:@"%@ Die, %@, unpushed", accessibleName, faceValue];
				
				if (z == 0 && !die.hasBeenPushed && !showAllDice && !gameWinner)
					dieButton.accessibilityHint = @"Tap to push this die";
			}
			
			if (die.hasBeenPushed)
			{
				CGRect dieFrame = dieButton.frame;
				
				if ([self.nibName rangeOfString:@"iPad"].location == NSNotFound ||
					z == 0 ||
					z == 7)
					dieFrame.origin.y = 0;
				else
				{
					// iPad Specific
					if (playerCount == 2 && z == 1)
						dieFrame.origin.y = 15;
					else if (playerCount == 3 || playerCount == 4)
					{
						if (z == 1)
							dieFrame.origin.x = 15;
						else if (z == 2)
							dieFrame.origin.y = 15;
						else if (z == 3)
							dieFrame.origin.x = 0;
					}
					else if (playerCount == 5)
					{
						if (z == 1 || z == 2)
							dieFrame.origin.x = 15;
						else if (z == 3)
							dieFrame.origin.y = 15;
						else if (z == 4)
							dieFrame.origin.x = 0;
					}
					else if (playerCount == 6)
					{
						if (z == 1 || z == 2)
							dieFrame.origin.x = 15;
						else if (z == 3)
							dieFrame.origin.y = 15;
						else if (z == 4 || z == 5)
							dieFrame.origin.x = 0;
					}
					else
					{
						if (z == 1 || z == 2)
							dieFrame.origin.x = 15;
						else if (z == 3 || z == 4)
							dieFrame.origin.y = 15;
						else if (z == 5 || z == 6)
							dieFrame.origin.x = 0;
						else if (z == 7)
							dieFrame.origin.y = 0;
					}
				}
				
				if (die.markedToPush && ![[playerState playerPtr] isKindOfClass:DiceLocalPlayer.class])
				{
					[diceToAnimate addObject:dieButton];
					[diceFramesToAnimate addObject:[NSValue valueWithCGRect:dieFrame]];
				}
				else
				{
					dieButton.frame = dieFrame;
				}
			}
			else
			{
				CGRect dieFrame = dieButton.frame;
				
				if ([self.nibName rangeOfString:@"iPad"].location == NSNotFound ||
					z == 0 ||
					z == 7)
					dieFrame.origin.y = 15;
				else
				{
					// iPad Specific
					if (playerCount == 2 && z == 1)
						dieFrame.origin.y = 0;
					else if (playerCount == 3 || playerCount == 4)
					{
						if (z == 1)
							dieFrame.origin.x = 0;
						else if (z == 2)
							dieFrame.origin.y = 0;
						else if (z == 3)
							dieFrame.origin.x = 15;
					}
					else if (playerCount == 5)
					{
						if (z == 1 || z == 2)
							dieFrame.origin.x = 0;
						else if (z == 3)
							dieFrame.origin.y = 0;
						else if (z == 4)
							dieFrame.origin.x = 15;
					}
					else if (playerCount == 6)
					{
						if (z == 1 || z == 2)
							dieFrame.origin.x = 0;
						else if (z == 3)
							dieFrame.origin.y = 0;
						else if (z == 4 || z == 5)
							dieFrame.origin.x = 15;
					}
					else
					{
						if (z == 1 || z == 2)
							dieFrame.origin.x = 0;
						else if (z == 3 || z == 4)
							dieFrame.origin.y = 0;
						else if (z == 5 || z == 6)
							dieFrame.origin.x = 15;
						else if (z == 7)
							dieFrame.origin.y = 15;
					}
				}
				
				dieButton.frame = dieFrame;
			}
		}
		
		if ([diceNotPushed count] == 1)
			((UIButton*)[diceNotPushed firstObject]).enabled = NO;
		
		for (int dieIndex = (int)[playerState.arrayOfDice count]; dieIndex < 5; ++dieIndex)
			((UIButton*)[diceView viewWithTag:dieIndex]).hidden = YES;
		
		if ([diceToAnimate count] > 0)
			[UIView animateWithDuration:0.3f animations:^{
				for (int i = 0;i < [diceToAnimate count];i++)
					((UIView*)[diceToAnimate objectAtIndex:i]).frame = [((NSValue*)[diceFramesToAnimate objectAtIndex:i]) CGRectValue];
			}];
		
		// Update Challenge Buttons
		
		if (z != 0 && [self canChallengePlayer:playerState.playerID])
			[view viewWithTag:ChallengeButtonTag].hidden = NO;
		else
			[view viewWithTag:ChallengeButtonTag].hidden = YES;
	}
	
	if (!canBid)
		for (UIButton* view in [player1View viewWithTag:DiceViewTag].subviews)
			view.enabled = NO;
}

- (Bid*)minimumLegalBid:(Bid*)previousBid withCurrentFace:(int)currentFace
{
	DiceGame* localGame = self.game;
	
	if (localGame.gameState.gameWinner || !previousBid)
		return [[Bid alloc] initWithPlayerID:-1 name:nil dice:1 rank:2];
	
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
			if (newBid.rankOfDie == 1)
				return nil;
			
			int nextRank = (newBid.rankOfDie + 1);
			
			if (nextRank > 6)
				nextRank = 1;
			
			newBid = [[Bid alloc] initWithPlayerID:-1 name:nil dice:1 rank:nextRank];
		}
		else
			newBid = [[Bid alloc] initWithPlayerID:-1 name:nil dice:(newBid.numberOfDice + 1) rank:newBid.rankOfDie];
	}
	
	return newBid;
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
	[aScrollView setContentOffset: CGPointMake(0, aScrollView.contentOffset.y)];
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
		currentBidCount = (int)internalCurrentBidCount;
	}
	
	++currentBidFace;
	
	if (currentBidFace == 7)
		currentBidFace = 1;
	
	if (hasTouchedBidCounterThisTurn && currentBidFace == 1)
	{
		internalCurrentBidCount /= 2.0;
		currentBidCount = (int)ceil(internalCurrentBidCount);
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
		currentBidCount = (int)internalCurrentBidCount;
	}
	
	--currentBidFace;
	
	if (currentBidFace == 0)
		currentBidFace = 6;
	
	if (hasTouchedBidCounterThisTurn && currentBidFace == 1)
	{
		internalCurrentBidCount /= 2.0;
		currentBidCount = (int)ceil(internalCurrentBidCount);
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
	
	if (tutorial)
		maxBidCount = 10;
	
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
	
	if (tutorial && ((step == 2 && currentBidCount == 5 && currentBidFace == 5) ||
					 (step == 9 && currentBidCount == 7 && currentBidFace == 6)))
	{
		if (step == 9)
		{
			bidButton.enabled = YES;
			bidCountMinusButton.enabled = NO;
			bidCountPlusButton.enabled = NO;
			bidFaceMinusButton.enabled = NO;
			bidFacePlusButton.enabled = NO;
			
			bidFaceLabelHint.hidden = YES;
			bidCountLabelHint.hidden = YES;
			
			CABasicAnimation* pulse = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
			pulse.fromValue = (id)[UIColor redColor].CGColor;
			pulse.toValue = (id)[UIColor clearColor].CGColor;
			pulse.duration = 2.0;
			pulse.autoreverses = YES;
			pulse.removedOnCompletion = NO;
			//pulse.fillMode = kCAFillModeBoth;
			pulse.repeatCount = HUGE_VALF;
			
			[bidButton.layer addAnimation:pulse forKey:@"backgroundColor"];
			
			[bidCountMinusButton.layer removeAllAnimations];
			[bidCountPlusButton.layer removeAllAnimations];
			[bidFaceMinusButton.layer removeAllAnimations];
			[bidFacePlusButton.layer removeAllAnimations];
		}
		else
			[self handleTutorial];
	}
}

-(void)constrainAndUpdateBidFace {
	int maxFace = 6;
	currentBidFace = (currentBidFace - 1 + maxFace) % maxFace + 1;
	[self updateCurrentBidLabels];
	
	if (tutorial && ((step == 2 && currentBidCount == 5 && currentBidFace == 5) ||
					 (step == 9 && currentBidCount == 7 && currentBidFace == 6)))
	{
		if (step == 9)
		{
			bidButton.enabled = YES;
			bidCountMinusButton.enabled = NO;
			bidCountPlusButton.enabled = NO;
			bidFaceMinusButton.enabled = NO;
			bidFacePlusButton.enabled = NO;
			
			bidFaceLabelHint.hidden = YES;
			bidCountLabelHint.hidden = YES;
			
			CABasicAnimation* pulse = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
			pulse.fromValue = (id)[UIColor redColor].CGColor;
			pulse.toValue = (id)[UIColor clearColor].CGColor;
			pulse.duration = 2.0;
			pulse.autoreverses = YES;
			pulse.removedOnCompletion = NO;
			//pulse.fillMode = kCAFillModeBoth;
			pulse.repeatCount = HUGE_VALF;
			
			[bidButton.layer addAnimation:pulse forKey:@"backgroundColor"];
			
			[bidCountMinusButton.layer removeAllAnimations];
			[bidCountPlusButton.layer removeAllAnimations];
			[bidFaceMinusButton.layer removeAllAnimations];
			[bidFacePlusButton.layer removeAllAnimations];
		}
		else
			[self handleTutorial];
	}
}

- (IBAction)challengePressed:(id)sender {
	UIButton* challengeButton = (UIButton*)sender;
	UIView* location = [challengeButton superview];
	
	int playerID = (int)location.tag;
	
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
	
	if (tutorial)
		previousItem = [[HistoryItem alloc] initWithState:nil andWithPlayer:[[PlayerState alloc] initWithName:@"Alice" withID:1 withNumberOfDice:5 withDiceGameState:nil] withBid:[[Bid alloc] initWithPlayerID:1 name:@"Alice" dice:6 rank:3]];
	
	assert(previousItem != nil);
	
	NSString* messageString = nil;
	PlayerState* stateLocal = [previousItem player];
	
	NSString* buttonTitle = [[self.game.players objectAtIndex:stateLocal.playerID] getDisplayName];
	
	if (tutorial)
		buttonTitle = @"Alice";
	
	if (previousItem.actionType == ACTION_BID)
	{
		messageString = [previousItem asString];
		if (tutorial)
			messageString = @"Alice bid 6 threes";
		
		buttonTitle = [NSString stringWithFormat:@"%@'s bid", buttonTitle];
	}
	else
		buttonTitle = [NSString stringWithFormat:@"%@'s pass", buttonTitle];
	
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Challenge?"
													message:messageString
												   delegate:self
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:buttonTitle, nil];
	
	alert.tag = (previousItem.actionType == ACTION_BID ? ACTION_CHALLENGE_BID : ACTION_CHALLENGE_PASS);
	if (!isSoarOnlyGame)
		[alert show];
}

- (IBAction)passPressed:(id)sender {
	NSString* message = nil;
	
	PlayerState* stateLocal = self.state;
	
	if (tutorial)
		stateLocal = [[PlayerState alloc] initWithName:@"You" withID:0 withNumberOfDice:5 withDiceGameState:nil];
	
	if ([[stateLocal markedToPushDice] count] > 0)
		message = [NSString stringWithFormat:@"Pass and push %lu %@?", (unsigned long)[[stateLocal markedToPushDice] count], ([[stateLocal markedToPushDice] count] == 1 ? @"die" : @"dice")];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pass?"
													message:message
												   delegate:self
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"Pass", nil];
	alert.tag = ACTION_PASS;
	if (!isSoarOnlyGame)
		[alert show];
}

- (IBAction)bidPressed:(id)sender
{
	// Check that the bid is legal
	PlayerState* stateLocal = self.state;
	DiceGame* localGame = self.game;
	
	if (tutorial)
		stateLocal = [[PlayerState alloc] initWithName:@"You" withID:0 withNumberOfDice:5 withDiceGameState:nil];
	
	NSMutableArray *markedToPushDiceWithPushedDice = [NSMutableArray arrayWithArray:[stateLocal markedToPushDice]];
	[markedToPushDiceWithPushedDice addObjectsFromArray:[stateLocal pushedDice]];
	
	Bid *bid = [[Bid alloc] initWithPlayerID:stateLocal.playerID name:stateLocal.playerName dice:currentBidCount rank:currentBidFace push:markedToPushDiceWithPushedDice];
	if (!tutorial && !([localGame.gameState getCurrentPlayerState].playerID == stateLocal.playerID &&
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
		
		if (!isSoarOnlyGame)
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
	
	if (!isSoarOnlyGame)
		[alert show];
}

- (IBAction)exactPressed:(id)sender {
	DiceGame* localGame = self.game;
	
	Bid *previousBid = localGame.gameState.previousBid;
	NSString* oldName = previousBid.playerName;
	previousBid.playerName = [[localGame.players objectAtIndex:previousBid.playerID] getDisplayName];
	NSString *bidStr = [previousBid asString];
	previousBid.playerName = oldName;
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Exact?"
													message:bidStr
												   delegate:self
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"Exact", nil];
	alert.tag = ACTION_EXACT;
	
	if (!isSoarOnlyGame)
		[alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	PlayerState* localState = self.state;
	DiceGame* localGame = self.game;
	
	if (buttonIndex == alertView.cancelButtonIndex)
	{
		if (tutorial && alertView.tag == TUTORIAL)
		{
			[self quit];

			if ((step == 5 || step == 7 || step == 10) && ![alertView.title isEqualToString:@"Done!"])
				[self dismissViewControllerAnimated:YES completion:^{
					self->quitHandler();
				}];
			else
				quitHandler();
		}
		
		return;
	}
	
	DiceAction* action = nil;
	
	if (alertView.tag != TUTORIAL && alertView.tag != ACTION_QUIT && tutorial)
	{
		[self handleTutorial];
		return;
	}
	
	switch (alertView.tag)
	{
		case ACTION_BID:
			action = [DiceAction bidAction:localState.playerID
									 count:currentBidCount
									  face:currentBidFace
									  push:[self makePushedDiceArray]];
			break;
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
			
			action = [DiceAction challengeAction:localState.playerID
										  target:target];
			break;
		}
		case ACTION_EXACT:
			action = [DiceAction exactAction:localState.playerID];
			break;
		case ACTION_PASS:
			action = [DiceAction passAction:localState.playerID
									   push:[self makePushedDiceArray]];
			break;
		case TUTORIAL:
			if (step == 0)
				[self handleTutorial];
			
			return;
		case ACTION_QUIT:
			[self quit];
			
			quitHandler();
		default:
			return;
	}
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
	[localGame performSelectorInBackground:@selector(handleAction:) withObject:action];
#pragma clang diagnostic pop
}

-(NSArray*)makePushedDiceArray
{
	NSMutableArray *ar = [NSMutableArray array];
	PlayerState* localState = self.state;
	
	for (Die *die in localState.arrayOfDice)
		if (die.markedToPush && !die.hasBeenPushed)
			[ar addObject:die];
	
	return ar;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

+ (NSAttributedString*)formatTextString:(NSString*)nameLabelText
{
	NSAttributedString* attributed = [[NSAttributedString alloc] initWithString:nameLabelText];
	
	return [PlayGameView formatTextAttributedString:attributed];
}

+ (NSAttributedString*)formatTextAttributedString:(NSAttributedString*)nameLabelText
{
	NSMutableAttributedString* string = [[NSMutableAttributedString alloc] init];
	int imageCount = 0;
	for (int j = 0;j < [nameLabelText.string length];++j)
	{
		unichar characterOne = [nameLabelText.string characterAtIndex:j], characterTwo = 0;
		
		if (j+1 < [nameLabelText.string length])
			characterTwo = [nameLabelText.string characterAtIndex:j+1];
		
		if (isdigit(characterOne) && characterTwo == 's')
		{
			int characterDigit = characterOne - '0';
			
			NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
			attachment.image = [PlayGameView imageForDie:characterDigit];
			[attachment setBounds:CGRectMake(0, -5, 21, 21)];
			
			NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
			
			[string appendAttributedString:attachmentString];
			
			++j;
			++imageCount;
		}
		else
		{
			[string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%c", [nameLabelText.string characterAtIndex:j]]]];
			
			NSDictionary* attributes = [nameLabelText attributesAtIndex:j effectiveRange:nil];
			
			[string addAttributes:attributes range:NSMakeRange(j-imageCount, 1)];
		}
	}
	
	return string;
}

- (void)handleTutorial
{
	NSString *title = nil, *message = nil;
	
	NSMutableArray* views = [NSMutableArray array];
	
	[[player1View viewWithTag:DiceViewTag].layer removeAllAnimations];
	[((UIView*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:0]).layer removeAllAnimations];
	[((UIView*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:1]).layer removeAllAnimations];
	[((UIView*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:2]).layer removeAllAnimations];
	[((UIView*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:3]).layer removeAllAnimations];
	[((UIView*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:4]).layer removeAllAnimations];
	
	((UIView*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:0]).translatesAutoresizingMaskIntoConstraints = YES;
	((UIView*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:1]).translatesAutoresizingMaskIntoConstraints = YES;
	((UIView*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:2]).translatesAutoresizingMaskIntoConstraints = YES;
	((UIView*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:3]).translatesAutoresizingMaskIntoConstraints = YES;
	((UIView*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:4]).translatesAutoresizingMaskIntoConstraints = YES;
	
	[[player2View viewWithTag:DiceViewTag].layer removeAllAnimations];
	[[player2View viewWithTag:ChallengeButtonTag].layer removeAllAnimations];
	[bidCountPlusButton.layer removeAllAnimations];
	[bidCountMinusButton.layer removeAllAnimations];
	[bidFaceMinusButton.layer removeAllAnimations];
	[bidFacePlusButton.layer removeAllAnimations];
	[bidButton.layer removeAllAnimations];
	[exactButton.layer removeAllAnimations];
	[passButton.layer removeAllAnimations];
	[continueRoundButton.layer removeAllAnimations];
	[bidFacePlusButton.layer removeAllAnimations];
	
	((UIButton*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:0]).enabled = NO;
	((UIButton*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:1]).enabled = NO;
	((UIButton*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:2]).enabled = NO;
	((UIButton*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:3]).enabled = NO;
	((UIButton*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:4]).enabled = NO;
	
	bidButton.enabled = NO;
	exactButton.enabled = NO;
	passButton.enabled = NO;
	bidCountMinusButton.enabled = NO;
	bidCountPlusButton.enabled = NO;
	bidFacePlusButton.enabled = NO;
	bidFaceMinusButton.enabled = NO;
	
	[player2View viewWithTag:ChallengeButtonTag].hidden = YES;
	[player2View viewWithTag:ActivitySpinnerTag].hidden = YES;
	
	continueRoundButton.hidden = YES;
	
	bidFaceLabelHint.hidden = YES;
	bidCountLabelHint.hidden = YES;
	
	currentBidCount = 1;
	currentBidFace = 2;
	
	[self updateCurrentBidLabels];
	
	gameStateLabel.text = @"";
	
	((UILabel*)[player2View viewWithTag:PlayerLabelTag]).text = @"Alice";
	((UILabel*)[player1View viewWithTag:PlayerLabelTag]).text = @"You";
	
	if (step == 0)
	{
		title = @"Bidding";
		message = @"In Liar's Dice, players bid using knowledge of their current dice and opponents revealed dice.  Your current dice are highlighted in flashing red.  Tap on one of them to continue.";
		[views addObject:[player1View viewWithTag:DiceViewTag]];
		
		((UIButton*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:0]).enabled = YES;
		((UIButton*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:1]).enabled = YES;
		((UIButton*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:2]).enabled = YES;
		((UIButton*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:3]).enabled = YES;
		((UIButton*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:4]).enabled = YES;
		
		((UIButton*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:0]).accessibilityLabel = @"Your Die, Face Value of 1, unpushed";
		((UIButton*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:1]).accessibilityLabel = @"Your Die, Face Value of 1, unpushed";
		((UIButton*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:2]).accessibilityLabel = @"Your Die, Face Value of 5, unpushed";
		((UIButton*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:3]).accessibilityLabel = @"Your Die, Face Value of 5, unpushed";
		((UIButton*)[[player1View viewWithTag:DiceViewTag].subviews objectAtIndex:4]).accessibilityLabel = @"Your Die, Face Value of 6, unpushed";
		
		((UIButton*)[[player2View viewWithTag:DiceViewTag].subviews objectAtIndex:0]).accessibilityLabel = @"Alice's Die, Unknown Face Value, unpushed";
		((UIButton*)[[player2View viewWithTag:DiceViewTag].subviews objectAtIndex:1]).accessibilityLabel = @"Alice's Die, Unknown Face Value, unpushed";
		((UIButton*)[[player2View viewWithTag:DiceViewTag].subviews objectAtIndex:2]).accessibilityLabel = @"Alice's Die, Unknown Face Value, unpushed";
		((UIButton*)[[player2View viewWithTag:DiceViewTag].subviews objectAtIndex:3]).accessibilityLabel = @"Alice's Die, Unknown Face Value, unpushed";
		((UIButton*)[[player2View viewWithTag:DiceViewTag].subviews objectAtIndex:4]).accessibilityLabel = @"Alice's Die, Unknown Face Value, unpushed";
	}
	else if (step == 1)
	{
		title = @"Bidding";
		message = @"Great! Now that you know where your dice are, you can see that you have four Fives.  You have two natural fives and two wildcards (ones).  Let's bid 5 Fives to start.  Highlighted in red are the bid selectors.  The selector on the left represents the die count you will bid.  The one on the right represents the die face you will bid.  Change these to be 5 Fives to continue.";
		
		bidFaceLabelHint.hidden = NO;
		bidCountLabelHint.hidden = NO;
		
		[bidFaceLabelHint setImage:[PlayGameView imageForDie:DIE_5]];
		[bidCountLabelHint setText:@"5"];
		
		bidFaceLabelHint.accessibilityLabel = @"Hint: Set a die face value of 5";
		bidCountLabel.accessibilityLabel = @"Hint: Set a die count of 5";
		
		[views addObjectsFromArray:@[bidCountPlusButton,
									 bidCountMinusButton,
									 bidFaceMinusButton,
									 bidFacePlusButton]];
		
		bidCountMinusButton.enabled = YES;
		bidCountPlusButton.enabled = YES;
		bidFacePlusButton.enabled = YES;
		bidFaceMinusButton.enabled = YES;
	}
	else if (step == 2)
	{
		currentBidCount = 5;
		currentBidFace = 5;
		
		bidCountLabel.text = @"5";
		bidFaceLabel.image = [PlayGameView imageForDie:DIE_5];
		
		title = @"Bidding";
		message = @"Now that you have selected 5 Fives, let's bid this.  Highlighted in red is the bid button, tap this to bid 5 Fives.";
		[views addObject:bidButton];
		
		bidButton.enabled = YES;
	}
	else if (step == 3)
	{
		UIView* aliceDice = [player2View viewWithTag:DiceViewTag];
		UIButton* firstDie = (UIButton*)[aliceDice viewWithTag:0];
		UIButton* secondDie = (UIButton*)[aliceDice viewWithTag:1];
		
		UILabel* aliceLabel = (UILabel*)[player2View viewWithTag:PlayerLabelTag];
		UILabel* myLabel = (UILabel*)[player1View viewWithTag:PlayerLabelTag];
		
		[firstDie setImage:[PlayGameView imageForDie:DIE_3] forState:UIControlStateDisabled];
		[firstDie setImage:[PlayGameView imageForDie:DIE_3] forState:UIControlStateNormal];
		
		firstDie.accessibilityLabel = @"Alice's Die, Face Value of 3, pushed";
		[secondDie setImage:[PlayGameView imageForDie:DIE_3] forState:UIControlStateDisabled];
		[secondDie setImage:[PlayGameView imageForDie:DIE_3] forState:UIControlStateNormal];
		
		secondDie.accessibilityLabel = @"Alice's Die, Face Value of 3, pushed";
		firstDie.frame = CGRectMake(3, 0, 50, 50);
		secondDie.frame = CGRectMake(56, 0, 50, 50);
		
		aliceLabel.attributedText = gameStateLabel.attributedText = [PlayGameView formatTextString:@"Alice bid 6 3s."];
		myLabel.attributedText = [PlayGameView formatTextString:@"You bid 5 5s."];
		
		title = @"Challenging";
		message = @"Woah! Alice bid 6 threes.  We know that is unlikely, so let's challenge her.  Highlighted in red is the challenge button, tap this to challenge her.";
		
		UIButton* challengeButton = (UIButton*)[player2View viewWithTag:ChallengeButtonTag];
		challengeButton.hidden = NO;
		challengeButton.enabled = YES;
		
		[views addObject:challengeButton];
		
	}
	else if (step == 4)
	{
		message = @"The round ended!  In this screen you can see all the dice your opponents had.  Also, this screen contains info about the last round including who did what to end the round.  ";
		
		if ([self.nibName rangeOfString:@"iPad"].location != NSNotFound)
		{
			// iPad Only
			UIView* aliceDice = [player2View viewWithTag:DiceViewTag];
			UILabel* aliceLabel = (UILabel*)[player2View viewWithTag:PlayerLabelTag];
			
			int index = 0;
			for (UIButton* button in aliceDice.subviews)
			{
				switch (index) {
					case 0:
					case 1:
						break;
					case 2:
						[button setImage:[PlayGameView imageForDie:DIE_3] forState:UIControlStateDisabled];
						[button setImage:[PlayGameView imageForDie:DIE_3] forState:UIControlStateNormal];
						button.accessibilityLabel = @"Alice's Die, Face Value of 3, unpushed";
						break;
					case 3:
					case 4:
						[button setImage:[PlayGameView imageForDie:DIE_5] forState:UIControlStateDisabled];
						[button setImage:[PlayGameView imageForDie:DIE_5] forState:UIControlStateNormal];
						button.accessibilityLabel = @"Alice's Die, Face Value of 5, unpushed";
						break;
					default:
						break;
				}
				
				index++;
			}
			
			aliceLabel.attributedText = [PlayGameView formatTextString:@"Alice bid 6 3s."];
			
			gameStateLabel.attributedText = [PlayGameView formatTextString:@"Alice bid 6 3s.\nThere were 5 3s.\nYou challenged Alice's bid.\nAlice lost a die."];
			
			message = [message stringByAppendingString:@"Tap Continue Round to move on."];
		}
		else
		{
			RoundOverView *roundOverView = [[RoundOverView alloc] initWithGame:nil
																		player:nil
																  playGameView:self
															   withFinalString:nil];
			
			[self.navigationController presentViewController:roundOverView animated:YES completion:nil];
			
			message = [message stringByAppendingString:@"Tap Done to move on."];
		}
		
		
		title = @"Round Over!";
		
		if (continueRoundButton)
			[views addObject:continueRoundButton];
		
		continueRoundButton.hidden = NO;
		continueRoundButton.enabled = YES;
	}
	else if (step == 5)
	{
		UIView* myDice = [player1View viewWithTag:DiceViewTag];
		
		for (UIButton* button in myDice.subviews)
		{
			[button setImage:[PlayGameView imageForDie:DIE_4] forState:UIControlStateNormal];
			button.accessibilityLabel = @"Your Die, Face Value of 4, unpushed";
		}
		
		UIView* aliceDice = [player2View viewWithTag:DiceViewTag];
		UILabel* aliceLabel = (UILabel*)[player2View viewWithTag:PlayerLabelTag];
		
		for (UIButton* button in aliceDice.subviews)
		{
			[button setImage:[PlayGameView imageForDie:DIE_UNKNOWN] forState:UIControlStateDisabled];
			[button setImage:[PlayGameView imageForDie:DIE_UNKNOWN] forState:UIControlStateNormal];
		}
		
		((UIView*)[aliceDice.subviews objectAtIndex:4]).hidden = YES;
		
		aliceLabel.attributedText = gameStateLabel.attributedText =  [PlayGameView formatTextString:@"Alice bid 4 2s."];
		
		((UILabel*)[player1View viewWithTag:PlayerLabelTag]).text = @"You";
		
		title = @"Passes";
		message = @"It looks like you have a rare hand, all five dice of the same face.  Let's pass since we haven't already passed this round.  Tap the pass button, highlighted in red.";
		
		[views addObject:passButton];
		
		passButton.enabled = YES;
	}
	else if (step == 6)
	{
		if ([self.nibName rangeOfString:@"iPad"].location != NSNotFound)
		{
			// iPad Only
			UIView* aliceDice = [player2View viewWithTag:DiceViewTag];
			UILabel* aliceLabel = (UILabel*)[player2View viewWithTag:PlayerLabelTag];
			
			int index = 0;
			for (UIButton* button in aliceDice.subviews)
			{
				switch (index) {
					case 0:
					case 1:
						[button setImage:[PlayGameView imageForDie:DIE_2] forState:UIControlStateDisabled];
						[button setImage:[PlayGameView imageForDie:DIE_2] forState:UIControlStateNormal];
						button.accessibilityLabel = @"Alice's Die, Face Value of 2, unpushed";
						break;
					case 2:
					case 3:
						[button setImage:[PlayGameView imageForDie:DIE_4] forState:UIControlStateDisabled];
						[button setImage:[PlayGameView imageForDie:DIE_4] forState:UIControlStateNormal];
						button.accessibilityLabel = @"Alice's Die, Face Value of 4, unpushed";
						break;
					default:
						break;
				}
				
				index++;
			}
			
			aliceLabel.text = @"Alice challenged your pass.";
			gameStateLabel.attributedText = [PlayGameView formatTextString:@"You passed.\nAlice challenged your pass.\nAlice lost a die."];
			
			message = @"The round ended! Tap Continue Round, highlighted in red, to continue.";
		}
		else
		{
			RoundOverView *roundOverView = [[RoundOverView alloc] initWithGame:nil
																		player:nil
																  playGameView:self
															   withFinalString:nil];
			
			[self.navigationController presentViewController:roundOverView animated:YES completion:nil];
			
			message = @"The round ended! Tap Done, highlighted in red, to continue.";
		}
		
		title = @"Round Over!";
		
		if (continueRoundButton)
			[views addObject:continueRoundButton];
		
		continueRoundButton.enabled = YES;
		continueRoundButton.hidden = NO;
	}
	else if (step == 7)
	{
		UIView* myDice = [player1View viewWithTag:DiceViewTag];
		
		[[myDice.subviews objectAtIndex:0] setImage:[PlayGameView imageForDie:DIE_1] forState:UIControlStateNormal];
		((UIButton*)[myDice.subviews objectAtIndex:0]).accessibilityLabel = @"Your Die, Face Value of 1, unpushed";
		[[myDice.subviews objectAtIndex:1] setImage:[PlayGameView imageForDie:DIE_1] forState:UIControlStateNormal];
		((UIButton*)[myDice.subviews objectAtIndex:1]).accessibilityLabel = @"Your Die, Face Value of 1, unpushed";
		
		[[myDice.subviews objectAtIndex:2] setImage:[PlayGameView imageForDie:DIE_3] forState:UIControlStateNormal];
		((UIButton*)[myDice.subviews objectAtIndex:2]).accessibilityLabel = @"Your Die, Face Value of 3, unpushed";
		
		[[myDice.subviews objectAtIndex:3] setImage:[PlayGameView imageForDie:DIE_6] forState:UIControlStateNormal];
		((UIButton*)[myDice.subviews objectAtIndex:3]).accessibilityLabel = @"Your Die, Face Value of 6, unpushed";
		
		[[myDice.subviews objectAtIndex:4] setImage:[PlayGameView imageForDie:DIE_6] forState:UIControlStateNormal];
		((UIButton*)[myDice.subviews objectAtIndex:4]).accessibilityLabel = @"Your Die, Face Value of 6, unpushed";
		
		
		UIView* aliceDice = [player2View viewWithTag:DiceViewTag];
		UILabel* aliceLabel = (UILabel*)[player2View viewWithTag:PlayerLabelTag];
		
		for (UIButton* button in aliceDice.subviews)
		{
			[button setImage:[PlayGameView imageForDie:DIE_UNKNOWN] forState:UIControlStateDisabled];
			[button setImage:[PlayGameView imageForDie:DIE_UNKNOWN] forState:UIControlStateNormal];
			button.accessibilityLabel = @"Alice's Die, Unknown Face Value, unpushed";
		}
		
		((UIView*)[aliceDice.subviews objectAtIndex:4]).hidden = YES;
		((UIView*)[aliceDice.subviews objectAtIndex:3]).hidden = YES;
		
		aliceLabel.attributedText = gameStateLabel.attributedText = [PlayGameView formatTextString:@"Alice bid 4 6s."];
		
		((UILabel*)[player1View viewWithTag:PlayerLabelTag]).text = @"You";
		
		title = @"Pushing";
		message = @"Pushing is when you reveal your dice to your opponents as a way of increasing the confidence in your bid.  When you push, your unpushed dice are rerolled.  Let's push all our sixes, highlighted in red.";
		
		[views addObject:[myDice.subviews objectAtIndex:0]];
		((UIButton*)[myDice.subviews objectAtIndex:0]).accessibilityHint = @"Tap to push";
		[views addObject:[myDice.subviews objectAtIndex:1]];
		((UIButton*)[myDice.subviews objectAtIndex:1]).accessibilityHint = @"Tap to push";
		
		[views addObject:[myDice.subviews objectAtIndex:3]];
		((UIButton*)[myDice.subviews objectAtIndex:3]).accessibilityHint = @"Tap to push";
		
		[views addObject:[myDice.subviews objectAtIndex:4]];
		((UIButton*)[myDice.subviews objectAtIndex:4]).accessibilityHint = @"Tap to push";
		
		
		((UIButton*)[myDice.subviews objectAtIndex:0]).enabled = YES;
		((UIButton*)[myDice.subviews objectAtIndex:1]).enabled = YES;
		((UIButton*)[myDice.subviews objectAtIndex:3]).enabled = YES;
		((UIButton*)[myDice.subviews objectAtIndex:4]).enabled = YES;
	}
	else if (step == 8)
	{
		title = @"Pushing";
		message = @"Until you hit Bid, you can change which dice you are going to push.  In our case we don't want to do this though.  Bid 7 sixes to continue.";
		
		bidFaceLabelHint.hidden = NO;
		bidCountLabelHint.hidden = NO;
		
		[bidFaceLabelHint setImage:[PlayGameView imageForDie:DIE_6]];
		[bidCountLabelHint setText:@"7"];
		
		bidFaceLabelHint.accessibilityLabel = @"Hint: Set a die face value of 6";
		bidCountLabel.accessibilityLabel = @"Hint: Set a die count of 7";
		
		[views addObject:bidCountMinusButton];
		[views addObject:bidCountPlusButton];
		[views addObject:bidFaceMinusButton];
		[views addObject:bidFacePlusButton];
		
		bidCountMinusButton.enabled = YES;
		bidCountPlusButton.enabled = YES;
		bidFacePlusButton.enabled = YES;
		bidFaceMinusButton.enabled = YES;
	}
	else if (step == 9)
	{
		if ([self.nibName rangeOfString:@"iPad"].location != NSNotFound)
		{
			// iPad Only
			UIView* myDice = [player1View viewWithTag:DiceViewTag];
			UIView* aliceDice = [player2View viewWithTag:DiceViewTag];
			UILabel* aliceLabel = (UILabel*)[player2View viewWithTag:PlayerLabelTag];
			
			int index = 0;
			for (UIButton* button in aliceDice.subviews)
			{
				switch (index) {
					case 0:
					case 1:
						[button setImage:[PlayGameView imageForDie:DIE_1] forState:UIControlStateDisabled];
						[button setImage:[PlayGameView imageForDie:DIE_1] forState:UIControlStateNormal];
						
						button.accessibilityLabel = @"Alice's Die, Face Value of 1, unpushed";
						break;
					case 2:
						[button setImage:[PlayGameView imageForDie:DIE_2] forState:UIControlStateDisabled];
						[button setImage:[PlayGameView imageForDie:DIE_2] forState:UIControlStateNormal];
						
						button.frame = CGRectMake(button.frame.origin.x, 0, button.frame.size.width, button.frame.size.height);
						button.accessibilityLabel = @"Alice's Die, Face Value of 2, unpushed";
						break;
					case 3:
					case 4:
						[button setImage:[PlayGameView imageForDie:DIE_6] forState:UIControlStateDisabled];
						[button setImage:[PlayGameView imageForDie:DIE_6] forState:UIControlStateNormal];
						
						button.accessibilityLabel = @"Alice's Die, Face Value of 6, unpushed";
						
						if (index == 4)
							button.frame = CGRectMake(button.frame.origin.x, 15, button.frame.size.width, button.frame.size.height);
						break;
					default:
						break;
				}
				
				index++;
			}
			
			index = 0;
			for (UIButton* button in myDice.subviews)
			{
				switch (index) {
					case 0:
					case 1:
						[button setImage:[PlayGameView imageForDie:DIE_1] forState:UIControlStateDisabled];
						[button setImage:[PlayGameView imageForDie:DIE_1] forState:UIControlStateNormal];
						
						button.accessibilityLabel = @"Your Die, Face Value of 1, pushed";
						button.frame = CGRectMake(button.frame.origin.x, 0, button.frame.size.width, button.frame.size.height);
						break;
					case 2:
					case 3:
						[button setImage:[PlayGameView imageForDie:DIE_6] forState:UIControlStateDisabled];
						[button setImage:[PlayGameView imageForDie:DIE_6] forState:UIControlStateNormal];
						
						button.accessibilityLabel = @"Your Die, Face Value of 6, pushed";
						button.frame = CGRectMake(button.frame.origin.x, 0, button.frame.size.width, button.frame.size.height);
						break;
					case 4:
						[button setImage:[PlayGameView imageForDie:DIE_6] forState:UIControlStateDisabled];
						[button setImage:[PlayGameView imageForDie:DIE_6] forState:UIControlStateNormal];
						
						button.accessibilityLabel = @"Your Die, Face Value of 6, unpushed";
						button.frame = CGRectMake(button.frame.origin.x, 15, button.frame.size.width, button.frame.size.height);
						break;
					default:
						break;
				}
				
				index++;
			}
			
			aliceLabel.text = @"Alice challenged your bid.";
			gameStateLabel.attributedText = [PlayGameView formatTextString:@"You bid 7 6s.\nThere were 7 6s.\nAlice challenged your bid.\nAlice lost a die."];
			
			[[myDice.subviews objectAtIndex:2] setImage:[PlayGameView imageForDie:DIE_6] forState:UIControlStateNormal];
			message = @"The round ended! Tap Continue Round, highlighted in red, to continue.";
		}
		else
		{
			RoundOverView *roundOverView = [[RoundOverView alloc] initWithGame:nil
																		player:nil
																  playGameView:self
															   withFinalString:nil];
			
			[self.navigationController presentViewController:roundOverView animated:YES completion:nil];
			message = @"The round ended! Tap Done, highlighted in red, to continue.";
		}
		
		title = @"Round Over!";
		
		
		if (continueRoundButton)
			[views addObject:continueRoundButton];
		continueRoundButton.enabled = YES;
		continueRoundButton.hidden = NO;
	}
	else if (step == 10)
	{
		title = @"Done!";
		message = @"Congratulations on finishing the tutorial!  Now you are all set for playing Liar's Dice on your own against the AI, your friends, and/or random opponents.";
		
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
														message:message
													   delegate:self
											  cancelButtonTitle:@"Exit Tutorial"
											  otherButtonTitles:nil];
		
		alert.tag = TUTORIAL;
		
		if (!isSoarOnlyGame)
			[alert show];
		
		DiceDatabase* database = [[DiceDatabase alloc] init];
		[database setHasSeenTutorial];
		
		return;
	}
	
	step++;
	
	CABasicAnimation* pulse = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
	pulse.fromValue = (id)[UIColor redColor].CGColor;
	pulse.toValue = (id)[UIColor clearColor].CGColor;
	pulse.duration = 2.0;
	pulse.autoreverses = YES;
	pulse.removedOnCompletion = NO;
	//pulse.fillMode = kCAFillModeBoth;
	pulse.repeatCount = HUGE_VALF;
	
	for (UIView* view in views)
	{
		[view.layer setCornerRadius:5.0f];
		[view.layer addAnimation:pulse forKey:@"backgroundColor"];
	}
	
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:self
										  cancelButtonTitle:@"Exit Tutorial"
										  otherButtonTitles:@"Okay", nil];
	alert.tag = TUTORIAL;
	if (!isSoarOnlyGame)
		[alert show];
}

- (void)displayHistoryView:(id)sender
{
	NSString* device = [UIDevice currentDevice].model;
	device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];
	
	NSMutableArray* array = [NSMutableArray arrayWithArray:[self.game.gameState roundHistory]];
	[array addObject:[NSArray arrayWithArray:[self.game.gameState history]]];
	
	HistoryView* view = [[HistoryView alloc] initWithHistory:array];
	
	if ([device isEqualToString:@"iPhone"])
		[self.navigationController pushViewController:view animated:YES];
	else
	{
		view.modalPresentationStyle = UIModalPresentationFormSheet;
		
		if (self.navigationController)
			[self.navigationController presentViewController:view animated:YES completion:^(){}];
		else
		{
			MultiplayerView* mView = self.multiplayerView;
			[mView.navigationController presentViewController:view animated:YES completion:^(){}];
		}
	}
}

@end
