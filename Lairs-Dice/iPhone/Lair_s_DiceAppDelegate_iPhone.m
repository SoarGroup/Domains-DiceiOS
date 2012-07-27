//
//  Lair_s_DiceAppDelegate_iPhone.m
//  Lair's Dice
//
//  Created by Alex on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSStream.h>
#import <Foundation/Foundation.h>

#import <CoreFoundation/CoreFoundation.h>

#import "Lair_s_DiceAppDelegate_iPhone.h"

#import "iPhoneViewController.h"
#import "iPhoneMainMenu.h"
#import "iPhoneHelp.h"

@interface Lair_s_DiceAppDelegate_iPhone()

- (void)send:(NSString *)message;

- (void)heartbeat;

@end

@implementation Lair_s_DiceAppDelegate_iPhone

@synthesize uniqueID;

- (id)init
{
    self = [super init];
    if (self)
    {
        //client = [[Client alloc] init];
        peer = [[Peer alloc] init:NO];
        [peer setDelegate:self];
        
        viewController = nil;
        
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(heartbeat) userInfo:nil repeats:YES];
		
		hasSentName = NO;
		
		server = nil;
    }
    return self;
}

- (void)heartbeat
{
    if (connectedToServer)
	{
        [self send:[@"HEARTBEAT:" stringByAppendingString:[[UIDevice currentDevice] name]]];
	}
}

- (void)dealloc
{
    /*[client disconnect];
     [client release];*/
    [peer release];
	[super dealloc];
}

- (void)send:(NSString *)message
{
	message = [NSString stringWithFormat:@"%i%@%@", uniqueID, Proto_PeerIDSeperator, message];
	
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:message];
    [archiver finishEncoding];
	[archiver release];
    
    [peer sendNetworkPacket:[peer gameSession] packetID:NETWORK_OTHER withData:data ofLength:[data length] reliable:YES withPeerID:serverID andUniqueID:uniqueID];
}


- (void)endTurn
{
    iPhoneViewController *iphoneViewController = (iPhoneViewController *)self->viewController;
    if (hasData && isMyTurn)
    {   
        switch (iphoneViewController->action) {
            case A_PUSH: // Never should be called
            {
                return;
            }
                break;
            case A_BID:
            {
                Bid *tempBid = [[[Bid alloc] initWithPlayerID:-1 name:@"Player" bid:iphoneViewController->numberOfDiceToBid rank:iphoneViewController->rankOfDiceToBid] autorelease];
                if ([tempBid isLegalRaise:temporaryInput.previousBid specialRules:temporaryInput.specialRules])
                {
                    inputFromClient toSend;
                    toSend.action = iphoneViewController->action;
                    toSend.bidOfThePlayer = tempBid;
                    toSend.diceToPush = iphoneViewController->diceToPush;
                    
                    NSString *dataToSend = [NetworkParser parseInputFromClient:toSend];
                    [self send:dataToSend];
                    
                    hasData = NO;
                    isMyTurn = NO;
                    [iphoneViewController->diceToPush removeAllObjects];
                    [iphoneViewController disableAllButtons];
                    
                    iphoneViewController.textView.text = @"Please wait until it's your turn!";
                }
                else
                {
                    iphoneViewController.textView.text = [NSString stringWithFormat:@"Invalid Bid!\n%@", iphoneViewController.textView.text];
                    [iphoneViewController.textView scrollRangeToVisible:NSMakeRange([iphoneViewController.textView.text length], 0)];
                }
            }
                break;
            case A_CHALLENGE_BID:
            case A_CHALLENGE_PASS:
            {
                inputFromClient toSend;
                toSend.action = iphoneViewController->action;
                
                if ([temporaryInput.validChallengeTargets count] > 1)
                {
                    NSString *message = [@"Would you like to challenge " stringByAppendingFormat:@"%@'s %@ or %@'s %@", 
                                         [temporaryInput.validChallengeTargets objectAtIndex:0],
                                         ([(NSNumber *)[temporaryInput.corespondingChallengTypes objectAtIndex:0] intValue] == A_BID ? @"bid." : @"pass."),
                                         [temporaryInput.validChallengeTargets objectAtIndex:1],
                                         ([(NSNumber *)[temporaryInput.corespondingChallengTypes objectAtIndex:1] intValue] == A_BID ? @"bid." : @"pass.")];
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Challenge" message:message delegate:viewController cancelButtonTitle:nil otherButtonTitles:
                                          [temporaryInput.validChallengeTargets objectAtIndex:0], 
                                          [temporaryInput.validChallengeTargets objectAtIndex:1],
                                          @"Cancel",
                                          nil];
                    [alert show];
                    
                    while (iphoneViewController->challengeWhich == None)
                    {
                        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
                    }
                    
                    [alert release];
                    
                    if (iphoneViewController->challengeWhich == First)
                    {
                        toSend.targetOfChallenge = [temporaryInput.validChallengeTargets objectAtIndex:0];
                    }
                    else if (iphoneViewController->challengeWhich == Second)
                    {
                        toSend.targetOfChallenge = [temporaryInput.validChallengeTargets objectAtIndex:1];
                    }
                    else
                    {
                        iphoneViewController->challengeWhich = None;
                        return;
                    }
                }
                else
                {
                    NSString *message = @"Are you sure you want to challenge ";
                    message = [message stringByAppendingFormat:@"%@'s %@", [temporaryInput.validChallengeTargets objectAtIndex:0], ([(NSNumber *)[temporaryInput.corespondingChallengTypes objectAtIndex:0] intValue] == A_BID ? @"bid." : @"pass.")];
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Challenge" message:message delegate:viewController cancelButtonTitle:nil otherButtonTitles:@"Yes", @"No", nil];
                    iphoneViewController->confirmationAlert = alert;
                    [alert show];
                    
                    while (!iphoneViewController->confirmed)
                    {
                        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
                    }
                    
                    iphoneViewController->confirmed = NO;
                    
                    [alert release];
                    
                    if (iphoneViewController->continueWithAction)
                    {
                        toSend.targetOfChallenge = [temporaryInput.validChallengeTargets objectAtIndex:0];
                    }
                    else
                        return;
                }
                
                if (iphoneViewController->continueWithAction || iphoneViewController->challengeWhich != None)
                {
                    [self send:[NetworkParser parseInputFromClient:toSend]];
                    
                    hasData = NO;
                    isMyTurn = NO;
                    [iphoneViewController->diceToPush removeAllObjects];
                    [iphoneViewController undo];
                    
                    iphoneViewController.textView.text = @"Please wait until it's your turn!";
                    
                    [iphoneViewController disableAllButtons];
                    iphoneViewController->continueWithAction = NO;
                    iphoneViewController->challengeWhich = None;
                }
            }
                break;
            case A_PASS:
            {
                inputFromClient toSend;
                toSend.action = iphoneViewController->action;
                
                [self send:[NetworkParser parseInputFromClient:toSend]];
                
                hasData = NO;
                isMyTurn = NO;
                [iphoneViewController->diceToPush removeAllObjects];
                
                iphoneViewController.textView.text = @"Please wait until it's your turn!";
                
                [iphoneViewController disableAllButtons];
            }
                break;
            case A_EXACT:
            {
                inputFromClient toSend;
                toSend.action = iphoneViewController->action;
                
                [self send:[NetworkParser parseInputFromClient:toSend]];
                
                hasData = NO;
                isMyTurn = NO;
                [iphoneViewController->diceToPush removeAllObjects];
                
                iphoneViewController.textView.text = @"Please wait until it's your turn!";
                
                [iphoneViewController disableAllButtons];
            }
                break;
            default:
                break;
        }
		
		[temporaryInput.validChallengeTargets release];
		[temporaryInput.previousBid release];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self goToiPhoneMainMenu];
    return YES;
}

- (void)connectedToServer:(NSString *)serverName
{
    serverID = serverName;
    connectedToServer = YES;
	
	if (server != nil)
	{
		id connection = [peer getWifiConnection];
		
		if (connection != nil)
			[server handleNewConnection:connection];
		else
			NSLog(@"Error: Connection was nil when we're using localhost");
	}
}

- (void)disconnectedFromServer:(NSString *)serverName
{
    iPhoneViewController *iphoneViewController = (iPhoneViewController *)viewController;
    connectedToServer = NO;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Disconnected" message:@"You have been disconnected from the server.  You will now return to the main menu." delegate:viewController cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    iphoneViewController->confirmationAlert = alert;
    [alert show];
    
    while (!iphoneViewController->confirmed)
    {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
    }
    
    iphoneViewController->confirmed = NO;
    
    [self goToiPhoneMainMenu];
}

- (void)serverSentData:(NSString *)data
{
    if (!connectedToServer)
    {
        return;
    }
    
    iPhoneViewController *iphoneViewController = (iPhoneViewController *)viewController;
    
    if ([data hasPrefix:Proto_ClientCommand])
    {
        return;
    }
    
    if ([data hasSuffix:@":CLEANUP"])
    {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Gameover" message:@"The server has terminated the game." delegate:viewController cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        iphoneViewController->confirmationAlert = alert;
        [alert show];
        
        while (!iphoneViewController->confirmed)
        {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
        }
        
        iphoneViewController->confirmed = NO;
        
        [self goToMainMenu];
        return;
    }
    
    if ([data hasPrefix:Proto_ShowAll])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Show all" message:@"The last action ended the round.  All the dice from the previous round are showing, are you ready to continue?" delegate:viewController cancelButtonTitle:nil otherButtonTitles:@"Yes", nil];
        iphoneViewController->confirmationAlert = alert;
        [alert show];
        
        while (!iphoneViewController->confirmed)
        {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
        }
        
        iphoneViewController->confirmed = NO;
        
        [self send:[NSString stringWithFormat:@"%@%@", Proto_ClientCommand, Proto_DoneShowAll]];
        
        isMyTurn = NO;
        iphoneViewController.textView.text = @"Please wait until it's your turn!";
        return;
    }
    
    if ([data hasPrefix:Proto_ReRollDice])
    {
        [iphoneViewController updateDice:[NetworkParser parseNewRound:data] withNewRound:NO];
        
        [iphoneViewController disableAllButtons];
        
        return;
    }
    
    if ([data hasPrefix:Proto_NewDice])
    {
        if ([iphoneViewController updateDice:[NetworkParser parseNewRound:data] withNewRound:YES])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Gameover" message:@"You have lost all your dice and in turn, lost the game." delegate:viewController cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
            iphoneViewController->confirmationAlert = alert;
            [alert show];
            
            while (!iphoneViewController->confirmed)
            {
                [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
            }
            
            iphoneViewController->confirmed = NO;
            
            [self goToMainMenu];
            return;
        }
        
        [iphoneViewController disableAllButtons];
        
        return;
    }
    
    if ([data hasPrefix:Proto_LastAction])
    {
        NSArray *components = [data componentsSeparatedByString:Proto_CommandDelimiter];
        
        Bid *previousBid = nil;
        ActionsAbleToSend lastAction = 0;
        ActionsAbleToSend secondToLastAction = 0;
        
        if ([components count] > 1)
        {
            for (NSString *string in components)
            {
                if ([string hasPrefix:Proto_LastAction])
                {
                    NSArray *parts = [string componentsSeparatedByString:Proto_Seperator];
                    
                    if ([[parts objectAtIndex:1] intValue] > 0)
                    {
                        lastAction = [[parts objectAtIndex:1] intValue];
                    }
                }
                else if ([string hasPrefix:Proto_PreviousBid])
                {
                    secondToLastAction = A_BID;
                    
                    NSArray *parts = [string componentsSeparatedByString:Proto_Seperator];
                    
                    int numberOfDice = 0;
                    int rankOfDice = 0;
                    
                    int i = 0;
                    for (NSString *part in parts)
                    {
                        if ([part intValue] > 0)
                        {
                            if (i == 1)
                                numberOfDice = [part intValue];
                            else
                                rankOfDice = [part intValue];
                        }
                        
                        i++;
                    }
                    
                    previousBid = [[[Bid alloc] initWithPlayerID:-1 andThereBeing:numberOfDice eachBeing:rankOfDice] autorelease];
                }
            }
        }
        else
        {
            if ([data hasPrefix:Proto_LastAction])
            {
                NSArray *parts = [data componentsSeparatedByString:Proto_Seperator];
                
                if ([[parts objectAtIndex:1] intValue] > 0)
                {
                    lastAction
                    = [[parts objectAtIndex:1] intValue];
                }
            }
        }
        
        if (lastAction == A_PASS)
        {
            iphoneViewController.textView.text = [NSString stringWithFormat:@"Last Action:\nPASS\n"];
            
            if (secondToLastAction == A_BID)
            {
                iphoneViewController.textView.text = [iphoneViewController.textView.text stringByAppendingFormat:@"\nSecond To Last Action:\n Bid %i %i%@", previousBid.numberOfDice, previousBid.rankOfDie, (previousBid.numberOfDice > 1 ? @"s" : @"")];
            }
        }
        else if (lastAction == A_BID)
        {
            iphoneViewController.textView.text = [NSString stringWithFormat:@"Last Action:\n Bid %i %i%@\n", previousBid.numberOfDice, previousBid.rankOfDie, (previousBid.numberOfDice > 1 ? @"s" : @"")];
        }
        
        return;
    }
    
    temporaryInput = [NetworkParser parseInputFromServer:data];
    
    // if ([iphoneViewController.textView.text isEqualToString:@"Please wait until it's your turn!"])
    if (!isMyTurn)
    {
        iphoneViewController.textView.text = @"It's your turn!";
        isMyTurn = YES;
    }
    else
    {
        // iphoneViewController.textView.text = [NSString stringWithFormat:@"It's your turn!\n%@", iphoneViewController.textView.text];
        iphoneViewController.textView.text = outputToSendToClient_string(&temporaryInput, NO);
    }
    
    [iphoneViewController.pass setEnabled:NO];
    [iphoneViewController.exact setEnabled:NO];
    [iphoneViewController.challenge setEnabled:NO];
    [iphoneViewController.bid setEnabled:NO];
    
    for (NSNumber *number in temporaryInput.actions)
    {
        switch ([number intValue]) {
            case A_PASS:
            {
                [iphoneViewController.pass setEnabled:YES];
            }
                break;
            case A_CHALLENGE_BID:
            {
                [iphoneViewController.challenge setEnabled:YES];
            }
                break;
            case A_CHALLENGE_PASS:
            {
                [iphoneViewController.challenge setEnabled:YES];
            }
                break;
            case A_BID:
            {
                [iphoneViewController.bid setEnabled:YES];
            }
                break;
            case A_EXACT:
            {
                [iphoneViewController.exact setEnabled:YES];
            }
                break;  
            default:
                break;
        }
    }
    
    [iphoneViewController updateDice:temporaryInput.playersDice withNewRound:NO];
    
    hasData = YES;
}

- (void)canceledPeerPicker
{
    [self goToiPhoneMainMenu];
}

- (void)goToMainGame:(NSString *)name
{
    [viewController.view removeFromSuperview];
    [viewController release];
    viewController = nil;
    
    viewController = [[iPhoneViewController alloc] initWithNibName:@"iPhoneViewController" bundle:nil];
    mainViewController = viewController;
    [(iPhoneViewController *)mainViewController setDelegate:self];
    
    [window addSubview:mainViewController.view];
    
    [window makeKeyAndVisible];
    
    isMyTurn = NO;
    [(iPhoneViewController *)mainViewController textView].text = @"Please wait until it's your turn!";
    
    if (![name isEqualToString:@""])
    {
        name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        peer.displayName = name;
    }
    
    [peer startPicker];
}

- (void)goToiPhoneMainMenu
{
    [viewController.view removeFromSuperview];
    [viewController release];
    viewController = nil;
    
    iPhoneMainMenu *menuViewController = [[iPhoneMainMenu alloc] initWithNibName:@"iPhoneMainMenu" bundle:nil];
    [menuViewController setDelegate:self];
    
    [window addSubview:menuViewController.view];
    
    viewController = menuViewController;
    mainViewController = menuViewController;
    
    [window makeKeyAndVisible];
    
    connectedToServer = NO;
}

- (void)goToiPhoneHelp
{
    [viewController.view removeFromSuperview];
    [viewController release];
    viewController = nil;
    
    iPhoneHelp *menuViewController = [[iPhoneHelp alloc] initWithNibName:@"iPhoneHelp" bundle:nil];
    [menuViewController setDelegate:self];
    
    [window addSubview:menuViewController.view];
    
    viewController = menuViewController;
    mainViewController = menuViewController;
    
    [window makeKeyAndVisible];
}

- (void)goToServer
{
	server = [[Server alloc] initWithDelegate:self];
	[server goToMainMenu];
}

- (iPadServerViewController *)goToMainServerGameWithPlayers:(int)players
{	
	[self goToMainGame:[[UIDevice currentDevice] name]];
	return nil;
}

- (MainMenu *)goToMainMenu
{
	if (![viewController isKindOfClass:[MainMenu class]])
	{
		[viewController.view removeFromSuperview];
		[viewController release];
		viewController = nil;
		
		viewController = [[MainMenu alloc] initWithNibName:@"iPhoneServer" bundle:nil];
		
		[window addSubview:viewController.view];
		[window makeKeyAndVisible];
		return (MainMenu*)viewController;
	}
	else
	{
		[self goToiPhoneMainMenu];
		[server release];
		server = nil;
		return nil;
	}
}

- (iPadHelp *)goToHelp //Should never be called on the iPhone
{
	return nil;
}

- (void)serverIsUp
{
	[peer release];
	peer = nil;
	peer = [[Peer alloc] init:NO delegate:self connectToLocalhost:YES];
	[peer startPicker];
}

@end
