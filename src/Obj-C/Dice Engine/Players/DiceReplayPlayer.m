//
//  DiceLocalPlayer.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DiceReplayPlayer.h"
#import "DiceAction.h"
#import "Die.h"

#import "PlayGame.h"
#import "PlayGameView.h"

#import "DiceGame.h"

@implementation DiceReplayPlayer

@synthesize name, playerState, gameViews, actions, replayFile;

- (id)initWithReplayFile:(NSString *)file
{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.name = @"ReplayPlayer";
        playerID = -1;
		gameViews = [[NSMutableArray alloc] init];
        
        actions = [[NSMutableArray alloc] init];
        replayFile = file;
    }
    
    return self;
}

- (NSString*) getDisplayName
{
    return self.name;
}

- (NSString*) getGameCenterName
{
    return self.name;
}

- (void) updateState:(PlayerState*)state
{
    self.playerState = state;
	PlayerState* playerStateLocal = self.playerState;
	for (PlayGameView* view in self.gameViews)
		[view updateState:playerStateLocal];
}

- (int) getID
{
    return playerID;
}

- (void) setID:(int)anID
{
    playerID = anID;
    
    self.name = [NSString stringWithFormat:@"ReplayPlayer-%i", playerID];
    
    [actions removeAllObjects];
    
    NSError* error;
    NSString* fileContents = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"replay" ofType:@"txt"]
                                                       encoding:NSUTF8StringEncoding
                                                          error:&error];
    
    if (!error)
    {
        NSArray* lines = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSRegularExpression *logExpression = [NSRegularExpression regularExpressionWithPattern:@"\\[GAMEHISTORY\\] \\[(.*)\\] \\[(.*)\\] \\[(.*)\\] \\(ActionType: (\\d)\\) \\(PlayerID: (\\d)\\) \\(Count: (\\d*)\\) \\(Face: (\\d)\\) \\(Push:(( \\d)*)\\) \\(TargetID: (\\d)\\)"
                                                                                       options:0
                                                                                         error:nil];
        for (NSString* line in lines)
        {
            NSArray *matches = [logExpression matchesInString:line
                                                      options:0
                                                        range:NSMakeRange(0, [line length])];
            for (NSTextCheckingResult *match in matches)
            {
                NSRange actionTypeRange, playerIDRange, countRange, faceRange, pushRange, targetRange;
                NSString* actionTypeString, *playerIDString, *countString, *faceString, *pushString, *targetString;
                
                actionTypeRange = [match rangeAtIndex:4];
                playerIDRange = [match rangeAtIndex:5];
                countRange = [match rangeAtIndex:6];
                faceRange = [match rangeAtIndex:7];
                pushRange = [match rangeAtIndex:8];
                targetRange = [match rangeAtIndex:match.numberOfRanges-1];
                
                actionTypeString = [line substringWithRange:actionTypeRange];
                playerIDString = [line substringWithRange:playerIDRange];
                countString = [line substringWithRange:countRange];
                faceString = [line substringWithRange:faceRange];
                pushString = [line substringWithRange:pushRange];
                targetString = [line substringWithRange:targetRange];
                
                DiceAction* action = [[DiceAction alloc] init];
                action.actionType = [actionTypeString intValue];
                action.playerID = [playerIDString intValue];
                action.count = [countString intValue];
                action.face = [faceString intValue];
                action.targetID = [targetString intValue];
                
                NSMutableArray* push = [NSMutableArray array];
                NSArray* pushSplit = [pushString componentsSeparatedByString:@" "];
                
                for (NSString* string in pushSplit)
                {
                    if ([string length] == 0)
                        continue;
                    
                    [push addObject:string];
                }
                
                if (action.playerID != playerID)
                    break;
                
                //DDLogDebug(@"Line: %@", line);
                
                action.push = push;
                [actions addObject:action];
            }
        }
    }
    else
        DDLogFatal(@"Unable to read replay file!");
}

- (void) itsYourTurn
{
	for (PlayGameView* view in self.gameViews)
	{
		[view updateUI];

		UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,
									view.gameStateLabel);
	}
    
    if (actions.count == 0)
        return;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        PlayerState* state = self->playerState;
        DiceGameState* gameState = state.gameState;
        DiceGame* localGame = gameState.game;
        
        DiceAction* action = [self->actions firstObject];
        
        BOOL notify = YES;
        if (action.actionType == ACTION_CHALLENGE_BID ||
            action.actionType == ACTION_CHALLENGE_PASS ||
            action.actionType == ACTION_EXACT)
            localGame.gameState.canContinueGame = notify = NO;
        
        if ([action.push count] != 0)
        {
            NSMutableArray* arrayOfDice = [NSMutableArray arrayWithArray:state.arrayOfDice];
            NSMutableArray* push = [NSMutableArray array];
            
            for (NSString* string in action.push)
            {
                int dieValue = [string intValue];
                
                for (int i = 0;i < arrayOfDice.count;++i)
                {
                    Die* die = [arrayOfDice objectAtIndex:i];
                    
                    if (die.dieValue == dieValue && !die.hasBeenPushed)
                    {
                        [push addObject:die];
                        [arrayOfDice removeObjectAtIndex:i];
                        break;
                    }
                }
            }
            
            assert(push.count == action.push.count);
            
            action.push = push;
        }
        
        DDLogDebug(@"Action: %@", action);
        
        [localGame handleAction:action notify:notify];
        [self->actions removeObjectAtIndex:0];
    });
}

- (void)notifyHasLost
{}

- (void)notifyHasWon
{}

- (void) end
{}

- (void) end:(BOOL)showAlert
{
    if (![NSThread isMainThread] || !showAlert)
        return;
    
    for (PlayGameView* localView in self.gameViews)
    {
        if (localView == nil || localView.navigationController.visibleViewController != localView)
            return;
        
        id<Player> gameWinner = localView.game.gameState.gameWinner;
        NSString* winner = [gameWinner getDisplayName];
        NSString* winString = @"Wins";
        
        if ([winner isEqualToString:@"You"])
            winString = @"Win";
        
        NSString *title = [NSString stringWithFormat:@"%@ %@!", winner, winString];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Okay", nil];
        [alert show];
    }
}

- (void)removeHandler
{}

- (void)setParticipant:(GKTurnBasedParticipant *)participant
{}

- (void)setHandler:(GameKitGameHandler *)handler
{}

@end
