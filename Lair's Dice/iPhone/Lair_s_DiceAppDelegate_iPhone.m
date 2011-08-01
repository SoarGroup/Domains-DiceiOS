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

@interface UIButton (ButtonTitleUtils)

- (void)setTitle:(NSString *)title;

@end

@implementation UIButton (ButtonTitleUtils)

- (void)setTitle:(NSString *)title
{
    [self setTitle:title forState:UIControlStateNormal];
    [self setTitle:title forState:UIControlStateHighlighted];
    [self setTitle:title forState:UIControlStateSelected];
    [self setTitle:title forState:UIControlStateDisabled];
}

@end

@interface Lair_s_DiceAppDelegate_iPhone()

- (void)send:(NSString *)message;

- (void)heartbeat;

@end

@implementation Lair_s_DiceAppDelegate_iPhone

- (id)init
{
    self = [super init];
    if (self)
    {
        //client = [[Client alloc] init];
        peer = [[Peer alloc] init:NO];
        [peer setDelegate:self];
        
        [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(heartbeat) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)heartbeat
{
    if (connectedToServer)
        [self send:@"HEARTBEAT"];
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
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:message];
    [archiver finishEncoding];
    
    [peer sendNetworkPacket:[peer gameSession] packetID:NETWORK_OTHER withData:data ofLength:[data length] reliable:YES withPeerID:serverID];
}


- (void)endTurn
{
    if (hasData && isMyTurn)
    {   
        switch (viewController->action) {
            case A_PUSH: // Never should be called
            {
                return;
            }
                break;
            case A_BID:
            {
                Bid *tempBid = [[Bid alloc] initWithPlayerID:-1 andThereBeing:viewController->numberOfDiceToBid eachBeing:viewController->rankOfDiceToBid];
                if ([tempBid isLegalRaise:temporaryInput.previousBid specialRules:temporaryInput.specialRules])
                {
                    inputFromClient toSend;
                    toSend.action = viewController->action;
                    toSend.bidOfThePlayer = tempBid;
                    toSend.diceToPush = viewController->diceToPush;
                    
                    NSString *dataToSend = [NetworkParser parseInputFromClient:toSend];
                    [self send:dataToSend];
                    
                    hasData = NO;
                    isMyTurn = NO;
                    [viewController->diceToPush removeAllObjects];
                    [viewController disableAllButtons];
                    
                    viewController.textView.text = @"Please wait untill it's your turn!";
                }
                else
                {
                    viewController.textView.text = [NSString stringWithFormat:@"Invalid Bid!\n%@", viewController.textView.text];
                    [viewController.textView scrollRangeToVisible:NSMakeRange([viewController.textView.text length], 0)];
                }
                
            }
                break;
            case A_CHALLENGE_BID:
            case A_CHALLENGE_PASS:
            {
                inputFromClient toSend;
                toSend.action = viewController->action;
                
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
                    
                    while (viewController->challengeWhich == None)
                    {
                        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
                    }
                    
                    [alert release];
                    
                    if (viewController->challengeWhich == First)
                    {
                        toSend.targetOfChallenge = [temporaryInput.validChallengeTargets objectAtIndex:0];
                    }
                    else if (viewController->challengeWhich == Second)
                    {
                        toSend.targetOfChallenge = [temporaryInput.validChallengeTargets objectAtIndex:1];
                    }
                    else
                    {
                        viewController->challengeWhich = None;
                        return;
                    }
                }
                else
                {
                    NSString *message = @"Are you sure you want to challenge ";
                    message = [message stringByAppendingFormat:@"%@'s %@", [temporaryInput.validChallengeTargets objectAtIndex:0], ([(NSNumber *)[temporaryInput.corespondingChallengTypes objectAtIndex:0] intValue] == A_BID ? @"bid." : @"pass.")];
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Challenge" message:message delegate:viewController cancelButtonTitle:nil otherButtonTitles:@"Yes", @"No", nil];
                    viewController->confirmationAlert = alert;
                    [alert show];
                    
                    while (!viewController->confirmed)
                    {
                        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
                    }
                    
                    viewController->confirmed = NO;
                    
                    [alert release];
                    
                    if (viewController->continueWithAction)
                    {
                        toSend.targetOfChallenge = [temporaryInput.validChallengeTargets objectAtIndex:0];
                    }
                    else
                        return;
                }
                
                if (viewController->continueWithAction || viewController->challengeWhich != None)
                {
                    [self send:[NetworkParser parseInputFromClient:toSend]];
                    
                    hasData = NO;
                    isMyTurn = NO;
                    [viewController->diceToPush removeAllObjects];
                    
                    viewController.textView.text = @"Please wait untill it's your turn!";
                    
                    [viewController disableAllButtons];
                    viewController->continueWithAction = NO;
                    viewController->challengeWhich = None;
                }
            }
                break;
            case A_PASS:
            {
                inputFromClient toSend;
                toSend.action = viewController->action;
                
                [self send:[NetworkParser parseInputFromClient:toSend]];
                
                hasData = NO;
                isMyTurn = NO;
                [viewController->diceToPush removeAllObjects];
                
                viewController.textView.text = @"Please wait untill it's your turn!";
                
                [viewController disableAllButtons];
            }
                break;
            case A_EXACT:
            {
                inputFromClient toSend;
                toSend.action = viewController->action;
                
                [self send:[NetworkParser parseInputFromClient:toSend]];
                
                hasData = NO;
                isMyTurn = NO;
                [viewController->diceToPush removeAllObjects];
                
                viewController.textView.text = @"Please wait untill it's your turn!";
                
                [viewController disableAllButtons];
            }
                break;
            default:
                break;
        }
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self goToMainMenu];
    return YES;
}

- (void)connectedToServer:(NSString *)serverName
{
    serverID = serverName;
    connectedToServer = YES;
}

- (void)disconnectedFromServer:(NSString *)serverName
{
    connectedToServer = NO;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Disconnected" message:@"You have been disconnected from the server.  You will now return to the main menu." delegate:viewController cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    viewController->confirmationAlert = alert;
    [alert show];
    
    while (!viewController->confirmed)
    {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
    }
    
    viewController->confirmed = NO;
    
    [self goToMainMenu];
}

- (void)serverSentData:(NSString *)data
{
    if ([data hasPrefix:@"C:"])
    {
        return;
    }
    
    if ([data isEqualToString:[NSString stringWithFormat:@"%@:CLEANUP", [[UIDevice currentDevice] name]]])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Gameover" message:@"The server has terminated the game." delegate:viewController cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        viewController->confirmationAlert = alert;
        [alert show];
        
        while (!viewController->confirmed)
        {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
        }
        
        viewController->confirmed = NO;
        
        [self goToMainMenu];
        return;
    }
    else if ([data hasSuffix:@":CLEANUP"])
    {
        return;
    }
    
    if ([data hasPrefix:@"SHOWALL"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Show all" message:@"The last action ended the round.  All the dice from the previous round are showing, are you ready to continue?" delegate:viewController cancelButtonTitle:nil otherButtonTitles:@"Yes", nil];
        viewController->confirmationAlert = alert;
        [alert show];
        
        while (!viewController->confirmed)
        {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
        }
        
        viewController->confirmed = NO;
        
        [self send:@"C:DONESHOWALL"];
        return;
    }
    
    if ([data hasPrefix:@"RDICE"])
    {
        [viewController updateDice:[NetworkParser parseNewRound:data] withNewRound:NO];
        
        return;
    }
    
    if ([data hasPrefix:@"NDICE"])
    {
        if ([viewController updateDice:[NetworkParser parseNewRound:data] withNewRound:YES])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Gameover" message:@"You have lost all your dice and in turn, lost the game." delegate:viewController cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
            viewController->confirmationAlert = alert;
            [alert show];
            
            while (!viewController->confirmed)
            {
                [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
            }
            
            viewController->confirmed = NO;
            
            [self goToMainMenu];
            return;
        }
        
        [viewController.pushDie1 setEnabled:NO];
        [viewController.pushDie2 setEnabled:NO];
        [viewController.pushDie3 setEnabled:NO];
        [viewController.pushDie4 setEnabled:NO];
        [viewController.pushDie5 setEnabled:NO];
        
        [viewController.pushDie1 setTitle:@"Push"];
        [viewController.pushDie2 setTitle:@"Push"];
        [viewController.pushDie3 setTitle:@"Push"];
        [viewController.pushDie4 setTitle:@"Push"];
        [viewController.pushDie5 setTitle:@"Push"];
        
        [viewController.pass setEnabled:NO];
        [viewController.exact setEnabled:NO];
        [viewController.challenge setEnabled:NO];
        [viewController.bid setEnabled:NO];
        
        return;
    }
    
    if ([data hasPrefix:@"LACTION"])
    {
        NSArray *components = [data componentsSeparatedByString:@"\n"];
        
        Bid *previousBid = nil;
        ActionsAbleToSend lastAction = 0;
        ActionsAbleToSend secondToLastAction = 0;
        
        if ([components count] > 1)
        {
            for (NSString *string in components)
            {
                if ([string hasPrefix:@"LACTION"])
                {
                    NSArray *parts = [string componentsSeparatedByString:@"_"];
                    
                    if ([[parts objectAtIndex:1] intValue] > 0)
                    {
                        lastAction = [[parts objectAtIndex:1] intValue];
                    }
                }
                else if ([string hasPrefix:@"PBID"])
                {
                    secondToLastAction = A_BID;
                    
                    NSArray *parts = [string componentsSeparatedByString:@"_"];
                    
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
            if ([data hasPrefix:@"LACTION"])
            {
                NSArray *parts = [data componentsSeparatedByString:@"_"];
                
                if ([[parts objectAtIndex:1] intValue] > 0)
                {
                    lastAction
                        = [[parts objectAtIndex:1] intValue];
                }
            }
        }
        
        if (lastAction == A_PASS)
        {
            viewController.textView.text = [NSString stringWithFormat:@"Last Action:\nPASS\n"];
            
            if (secondToLastAction == A_BID)
            {
                viewController.textView.text = [viewController.textView.text stringByAppendingFormat:@"\nSecond To Last Action:\n Bid %i %i%@", previousBid.numberOfDice, previousBid.rankOfDie, (previousBid.numberOfDice > 1 ? @"s" : @"")];
            }
        }
        else if (lastAction == A_BID)
        {
            viewController.textView.text = [NSString stringWithFormat:@"Last Action:\n Bid %i %i%@\n", previousBid.numberOfDice, previousBid.rankOfDie, (previousBid.numberOfDice > 1 ? @"s" : @"")];
        }
        
        return;
    }
    
    temporaryInput = [NetworkParser parseInputFromServer:data];
    
    if ([viewController.textView.text isEqualToString:@"Please wait untill it's your turn!"])
        viewController.textView.text = @"It's your turn!";
    else
        viewController.textView.text = [NSString stringWithFormat:@"It's your turn!\n%@", viewController.textView.text];
    
    [viewController.pass setEnabled:NO];
    [viewController.exact setEnabled:NO];
    [viewController.challenge setEnabled:NO];
    [viewController.bid setEnabled:NO];
    
    for (NSNumber *number in temporaryInput.actions)
    {
        switch ([number intValue]) {
            case A_PASS:
            {
                [viewController.pass setEnabled:YES];
            }
                break;
            case A_CHALLENGE_BID:
            {
                [viewController.challenge setEnabled:YES];
            }
                break;
            case A_CHALLENGE_PASS:
            {
                [viewController.challenge setEnabled:YES];
            }
                break;
            case A_BID:
            {
                [viewController.bid setEnabled:YES];
            }
                break;
            case A_EXACT:
            {
                [viewController.exact setEnabled:YES];
            }
                break;  
            default:
                break;
        }
    }
    
    [viewController updateDice:temporaryInput.playersDice withNewRound:NO];
    
    hasData = YES;
    isMyTurn = YES;
}

- (void)canceledPeerPicker
{
    [self goToMainMenu];
}

- (void)goToMainGame:(NSString *)name
{
    [mainMenuViewController.view removeFromSuperview];
    [mainMenuViewController release];
    
    viewController = [[iPhoneViewController alloc] initWithNibName:@"iPhoneViewController" bundle:nil];
    mainViewController = viewController;
    [(iPhoneViewController *)mainViewController setDelegate:self];
    
    [window addSubview:mainViewController.view];
    
    [window makeKeyAndVisible];
    
    [(iPhoneViewController *)mainViewController textView].text = @"Please wait untill it's your turn!";
    
    if (![name isEqualToString:@""])
        peer.displayName = name;
    
    [peer startPicker];
}

- (void)goToMainMenu
{
    if (mainMenuViewController)
    {
        if ([mainMenuViewController view])
            [[mainMenuViewController view] removeFromSuperview];
        [mainMenuViewController release];
    }
    
    mainMenuViewController = [[iPhoneMainMenu alloc] initWithNibName:@"iPhoneMainMenu" bundle:nil];
    [mainMenuViewController setDelegate:self];
    
    [window addSubview:mainMenuViewController.view];
    
    mainViewController = mainMenuViewController;
    
    [window makeKeyAndVisible];
}

- (void)goToHelp
{
    [mainMenuViewController.view removeFromSuperview];
    [mainMenuViewController release];
    
    mainMenuViewController = [[iPhoneHelp alloc] initWithNibName:@"iPhoneHelp" bundle:nil];
    [mainMenuViewController setDelegate:self];
    
    [window addSubview:mainMenuViewController.view];
    
    mainViewController = mainMenuViewController;
    
    [window makeKeyAndVisible];
}

@end
