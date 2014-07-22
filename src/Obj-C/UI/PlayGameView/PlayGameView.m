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

- (void)realRoundEnding;

- (void)updateUI:(NSString*)gameStateLabel;

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
@synthesize gameStateLabel;
@synthesize fullscreenButton;
@synthesize continueRoundButton;
@synthesize multiplayerView, overViews;
@synthesize images;
@synthesize playerScrollView;

@synthesize game, state, animationFinished;

@synthesize player1View, player2View, player3View, player4View, player5View, player6View, player7View, player8View, playerViews;

NSString *numberName(int number) {
    return [NSString stringWithFormat:@"%ds", number];
}

NSArray *buildDiceImages() {
    NSMutableArray *ar = [NSMutableArray array];
    // Guarenteed that DIE_1 - DIE_6 are in order in the enum
    for (int i = DIE_1; i <= MAX_IMAGE_TYPE; ++i)
        [ar addObject:[DiceGraphics imageWithType:i]];

    return ar;
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

		images = buildDiceImages();
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

	if ([self.nibName rangeOfString:@"iPad"].location == NSNotFound)
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
		showAllDice = YES;
		[self updateUI:finalString];

		canContinueRound = NO;
		self.continueRoundButton.hidden = NO;
		self.continueRoundButton.enabled = YES;

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

- (IBAction)continueRoundPressed:(UIButton*)sender
{
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
	PlayerState* localState = self.state;
	PlayerState* lastPlayerState = [[localGame.gameState lastHistoryItem] player];

	for (;[lastPlayerState playerID] > 0 && [[lastPlayerState playerPtr] isKindOfClass:SoarPlayer.class];lastPlayerState = [localGame.gameState playerStateForPlayerID:([lastPlayerState playerID] - 1)]);

	localGame.gameState.canContinueGame = YES;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"ContinueRoundPressed" object:nil];

	NSString *title = nil, *message = nil;

	if ([localGame.gameState usingSpecialRules]) {
        title = [NSString stringWithFormat:@"Special Rules!"];
        message = @"For this round: 1s aren't wild. Only players with one die may change the bid face.";
    }
    else if ([localState hasWon])
        title = [NSString stringWithFormat:@"You Win!"];
    else if ([localGame.gameState hasAPlayerWonTheGame])
        title = [NSString stringWithFormat:@"%@ Wins!", [localGame.gameState.gameWinner getDisplayName]];
    else if ([localState hasLost] && !self.hasPromptedEnd)
	{
        self.hasPromptedEnd = YES;
        title = [NSString stringWithFormat:@"You Lost the Game"];
	}
	else if (localGame.newRound && [lastPlayerState playerID] != [localState playerID])
	{
		NSString* name = [[lastPlayerState playerPtr] getDisplayName];

		title = @"Please Wait";
		message = [NSString stringWithFormat:@"Please wait until %@ has finished looking at the round overview.", name];
	}

	if (title)
		[[[UIAlertView alloc] initWithTitle:title
									message:message
								   delegate:nil
						  cancelButtonTitle:@"Okay"
						  otherButtonTitles:nil] show];

	[localGame notifyCurrentPlayer];
}

- (BOOL) roundBeginning
{
	hasTouchedBidCounterThisTurn = NO;
	hasDisplayedRoundOverview = NO;

    return NO;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = [self.nibName rangeOfString:@"iPad"].location == NSNotFound;
	self.navigationController.navigationBar.translucent = YES;

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUINotification:) name:@"UpdateUINotification" object:nil];

	DiceGame* localGame = self.game;

	if (localGame.gameState.gameWinner)
		for (id<Player> player in localGame.players)
			if ([player isKindOfClass:DiceLocalPlayer.class])
			{
				[(DiceLocalPlayer*)player end:YES];
				break;
			}

	[self updateUI];
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

	for (NSUInteger i = [localGame.players count];i < [playerViews count];i++)
		((UIView*)[playerViews objectAtIndex:i]).hidden = YES;

    [localGame startGame];

	ApplicationDelegate* delegate = localGame.appDelegate;
	GameKitGameHandler* handler = [delegate.listener handlerForGame:localGame];

	if (handler)
		[handler saveMatchData];

	if ([localGame.gameState.theNewRoundListeners count] == 0)
		[localGame.gameState addNewRoundListener:self];

	if ([[self nibName] rangeOfString:@"iPad"].location != NSNotFound)
		fullscreenButton.hidden = NO;
	else
	{
		((UIView*)[playerScrollView.subviews firstObject]).translatesAutoresizingMaskIntoConstraints = YES;

		playerScrollView.contentSize = CGSizeMake(playerScrollView.frame.size.width,
												  ([localGame.players count]-1) * 128);
	}

	NSMutableArray* reorderedPlayers = [NSMutableArray arrayWithArray:localGame.players];

	while (![[reorderedPlayers firstObject] isKindOfClass:DiceLocalPlayer.class])
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

-(UIImage *)imageForDie:(NSInteger)die
{
    if (die <= 0 || die > 6) return [self.images objectAtIndex:DIE_UNKNOWN-1];
    return [self.images objectAtIndex:(die-1)];
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
    NSString *title = [NSString stringWithFormat:@"Leave the game?"];
    NSString *message = nil;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Leave", nil];
    alert.tag = ACTION_QUIT;
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
    self.state = newState;
	[self updateUI];
}

- (void) updateCurrentBidLabels {
    self.bidCountLabel.text = [NSString stringWithFormat:@"%d", currentBidCount];
	self.bidCountLabel.accessibilityLabel = [NSString stringWithFormat:@"Bid Die Count, Face Value of %i", currentBidCount];

	[self.bidFaceLabel setImage:[self imageForDie:currentBidFace]];
	self.bidFaceLabel.accessibilityLabel = [NSString stringWithFormat:@"Bid Die Face, Face Value of %i", currentBidFace];
}

- (IBAction) dieButtonPressed:(id)sender
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
	else
		for (NSNumber* number in nonMarkedOrPushedDice)
			((UIButton*)[[player1View viewWithTag:DiceViewTag] viewWithTag:[number intValue]]).enabled = YES;

	[UIView animateWithDuration:0.3f animations:^{
		button.frame = newFrame;
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

	// State initialization
	PlayerState* localState = self.state;
	DiceGame* localGame = self.game;

	if (localGame.newRound && !hasDisplayedRoundOverview)
		[self roundEnding];

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

	NSMutableAttributedString* string = [[NSMutableAttributedString alloc] init];
	for (int i = 0;i < [headerString length];++i)
	{
		unichar characterOne = [headerString characterAtIndex:i], characterTwo = 0;

		if (i+1 < [headerString length])
			characterTwo = [headerString characterAtIndex:i+1];

		if (isdigit(characterOne) && characterTwo == 's')
		{
			int characterDigit = characterOne - '0';

			NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
			attachment.image = [self imageForDie:characterDigit];
			[attachment setBounds:CGRectMake(0, -5, gameStateLabel.font.lineHeight, gameStateLabel.font.lineHeight)];

			NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];

			[string appendAttributedString:attachmentString];

			++i;
		}
		else
			[string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%c", [headerString characterAtIndex:i]]]];
	}

	gameStateLabel.attributedText = string;
	[gameStateLabel sizeToFit];

	// Player UI
    BOOL canBid = [localState canBid];

	if (localGame.gameState.gameWinner)
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
			[nameLabelText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@ has exacted", playerName]]];

		if ([playerState playerHasPassed])
			[nameLabelText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@ has passed", playerName]]];

		if ([playerPtr isKindOfClass:DiceRemotePlayer.class] && ((DiceRemotePlayer*)playerPtr).participant.matchOutcome == GKTurnBasedMatchOutcomeQuit)
			nameLabelText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ has quit", playerName]];
		else if ([playerState hasLost])
			nameLabelText = [[NSMutableAttributedString alloc] initWithString:playerName];
		else if ([playerState hasWon])
			nameLabelText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@ won!", playerName, [playerName isEqualToString:@"You"] ? @"have" : @"has"]];

		nameLabel.accessibilityLabel = [self accessibleTextForString:nameLabelText.string];

		string = [[NSMutableAttributedString alloc] init];
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
				attachment.image = [self imageForDie:characterDigit];
				[attachment setBounds:CGRectMake(0, -5, nameLabel.font.lineHeight, nameLabel.font.lineHeight)];

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
		
		nameLabel.attributedText = string;

		// Update the spinner
		UIActivityIndicatorView* spinner = (UIActivityIndicatorView*)[view viewWithTag:ActivitySpinnerTag];

		if ([playerState isMyTurn] && [playerState playerID] != 0)
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
			if (die.hasBeenPushed || z == 0 || showAllDice || localGame.gameState.gameWinner)
				dieFace = die.dieValue;

			UIImage *dieImage = [self imageForDie:dieFace];

			UIButton* dieButton = (UIButton*)[diceView viewWithTag:dieIndex];
			dieButton.enabled = YES;

			if (dieFace == DIE_UNKNOWN || die.hasBeenPushed)
				dieButton.enabled = NO;
			else if (!die.hasBeenPushed)
				[diceNotPushed addObject:dieButton];

			[dieButton setImage:dieImage forState:UIControlStateNormal];

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

				if (!die.markedToPush)
				{
					die.markedToPush = YES;
					[diceToAnimate addObject:dieButton];
					[diceFramesToAnimate addObject:[NSValue valueWithCGRect:dieFrame]];
				}
				else
					dieButton.frame = dieFrame;
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
		buttonTitle = [NSString stringWithFormat:@"%@'s pass", buttonTitle];

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
        return;

	DiceAction* action = nil;

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
		case ACTION_QUIT:
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

@end
