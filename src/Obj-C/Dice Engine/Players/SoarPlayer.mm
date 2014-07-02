//
//  Agent.m
//  Liar's Dice
//
//  Created by Alex on 6/21/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "SoarPlayer.h"
#import "PlayerState.h"
#import "Die.h"
#import "HistoryItem.h"
#import "DiceGameState.h"
#import "DiceGame.h"

#import "DiceDatabase.h"

#include <map>


void testWme(sml::WMElement *wme)
{
    const char *name = wme->GetIdentifierName();
    // NSLog(@"Testing wme \"%s\"", name);
    if (strlen(name) < 2)
		NSLog(@"Identifier name too short! \"%s\"", name);
}

void sdb(char * command, sml::Agent *agent)
{
    //printf("%s", agent->ExecuteCommandLine(command));
}

void printHandler(sml::smlPrintEventId id, void *d, sml::Agent *a, char const *m) {
	[[NSThread currentThread] setName:@"Soar Agent Thread"];

    NSLog(@"%s> %s", a->GetAgentName(), m);
}

class DiceSMLData {
public:
    sml::Identifier *idState;
	sml::Identifier *idPlayers;
	sml::Identifier *idAffordances;
	sml::WMElement *idHistory;
	sml::WMElement *idRounds;
	
	DiceSMLData(sml::Identifier *m_idState, sml::Identifier *m_idPlayers, sml::Identifier *m_idAffordances, sml::WMElement *m_idHistory, sml::WMElement *m_idRounds) {
		this->idState = m_idState;
		this->idPlayers = m_idPlayers;
		this->idAffordances = m_idAffordances;
		this->idHistory = m_idHistory;
		this->idRounds = m_idRounds;
	}
};

typedef enum {
    eq = 0,
    ge,
    gt,
    le,
    lt,
    ne,
    neq
} Predicate;

@interface SoarPlayer()

- (DiceSMLData *) GameStateToWM:(sml::Identifier *) inputLink;
- (void) doTurn:(NSNumber*)arg;

/*
 - (BOOL) handleAgentCommandsWithGameState:(DiceGameState *)gameState andPlayerID:(int)playerID withNeedsRefreshBool:(BOOL *)refreshAr withInformation:(turnInformationSentFromTheClient *)information withErrors:(int)errors;
 */

@end

static int agentCount = 0;

@implementation SoarPlayer

@synthesize name, playerState, playerID, game, turnLock, handler, participant;

+ (NSString*) makePlayerName
{
    switch (agentCount) {
        case 1:
            return @"Alice";
            break;
        case 2:
            return @"Bob";
        case 3:
            return @"Carol";
		case 4:
			return @"Chuck";
		case 5:
			return @"Craig";
		case 6:
			return @"Dan";
		case 7:
			return @"Erin";
        default:
		{
			DiceDatabase *database = [[DiceDatabase alloc] init];

            return [database getPlayerName];
		}
    }
}

- (id)initWithGame:(DiceGame*)aGame connentToRemoteDebugger:(BOOL)connect lock:(NSLock *)aLock withGameKitGameHandler:(GameKitGameHandler *)gkgHandler;
{
    self = [super init];
    if (self)
	{
        self.turnLock = aLock;
        self.game = aGame;
		handler = gkgHandler;

		DiceDatabase* database = [[DiceDatabase alloc] init];
#ifdef DEBUG
		NSString* remoteIP = [database valueForKey:@"Debug:RemoteIP"];

		if (remoteIP && [remoteIP length] != 0)
		{
			const char* ipAddress = [remoteIP UTF8String];

			kernel = sml::Kernel::CreateRemoteConnection(true, ipAddress);
			remoteConnected = YES;
		}
		else
#endif
			kernel = sml::Kernel::CreateKernelInNewThread(sml::Kernel::kSuppressListener);

        [turnLock lock];

		if (kernel->HadError())
		{
			NSLog(@"Kernel: %s", kernel->GetLastErrorDescription());
			[turnLock unlock];
			return nil;
		}

		agentCount++;

		if (agentCount >= 8)
			agentCount = 1;

        self.name = [SoarPlayer makePlayerName];

        const char* string = [name UTF8String];
        agent = kernel->CreateAgent(string);
        if (agent == nil)
        {
			NSLog(@"Kernel (Agent): %s", kernel->GetLastErrorDescription());
            [turnLock unlock];
            return nil;
        }

#ifdef DEBUG
        agent->RegisterForPrintEvent(sml::smlEVENT_PRINT, printHandler, NULL);
#endif

        int seed = arc4random_uniform(RAND_MAX);
        
        agent->ExecuteCommandLine([[NSString stringWithFormat:@"srand %i", seed] UTF8String]);
        
        NSString *path;
        
        // This is where we specify the root .soar file that will source the Soar agent.
        // We want this to be dice-agent-new, but right now that breaks the agent
        // so we're loading dice-p0-m0-c0 instead.

		int difficulty = (int)[database getDifficulty]; // Safe conversion due to difficulties not requiring long precision (there is only a couple)
		
        NSString *ruleFile = nil; /*@"dice-pmh"; @"dice-p0-m0-c0"; */
        
		switch (difficulty)
		{
			default:
			case 0:
			{
				ruleFile = @"dice-easy";
				break;
			}
			case 1:
			{
				ruleFile = @"dice-medium";
				break;
			}
			case 2:
			{
				ruleFile = @"dice-hard";
				break;
			}
			case 3:
			{
				ruleFile = @"dice-harder";
				break;
			}
			case 4:
			{
				ruleFile = @"dice-hardest";
				break;
			}
		}
		
        if (!remoteConnected)
        {
            path = [NSString stringWithFormat:@"source \"%@\"", [[NSBundle mainBundle] pathForResource:ruleFile ofType:@"soar" inDirectory:@""]];
        }
        else
        {
            path = [NSString stringWithFormat:@"source \"/Users/bluechill/Developer/SoarGroupProjects/SoarDice-iOS/src/Soar Agent/%@.soar\"", ruleFile];
        }
        
        NSLog(@"Path: %@", path);
        
        std::cout << agent->ExecuteCommandLine([path UTF8String]) << std::endl;
        std::cout << agent->ExecuteCommandLine("watch 0") << std::endl;
        
        agent->InitSoar();
        [turnLock unlock];
    }
    return self;
}

- (void) end
{
	[turnLock lock];
		agent = nil;

		kernel->Shutdown();
		delete kernel;
		kernel = nil;
    [turnLock unlock];
}

- (void)dealloc
{
	NSLog(@"Soar Player Release\n");

	if (agent)
	{
		[turnLock lock];
			agent = nil;

			kernel->Shutdown();
			delete kernel;
			kernel = nil;
		[turnLock unlock];
	}
}

- (void)itsYourTurn
{
    [NSThread detachNewThreadSelector:@selector(doTurn:) toTarget:self withObject:[NSNumber numberWithInt:0]];
}

- (void)showErrorAlert
{
	if (![NSThread isMainThread])
	{
		[self performSelectorOnMainThread:@selector(showErrorAlert) withObject:nil waitUntilDone:YES];
		return;
	}

	[[[UIAlertView alloc] initWithTitle:@"Soar Error!" message:@"Unfortunately, Soar has someone managed to get into a situation where it can no longer continue.  After trying to restart it five times, it still continues to do this and so we consider Soar to be 'crashed.'  Unfortunately, this means your game will no longer function, therefore we recommend you quit the game." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil]  show];
}

- (void) doTurn:(NSNumber*)turnCount
{
	[[NSThread currentThread] setName:@"Soar Agent Turn Thread"];

    [turnLock lock];
    if (agent == nil) {
        [turnLock unlock];
        return;   
    }
    NSLog(@"Agent do turn");
    
    BOOL agentSlept = NO;
    BOOL agentHalted = NO;
	BOOL agentInterrupted = NO;
    BOOL needsRefresh = YES;
    
    DiceSMLData *newData = NULL;

    do {
        if (needsRefresh)
        {
            if (newData != NULL)
            {
                newData->idState->DestroyWME();
                newData->idPlayers->DestroyWME();
                newData->idAffordances->DestroyWME();
                newData->idHistory->DestroyWME();
                newData->idRounds->DestroyWME();
                delete newData;
                newData = NULL;
            }
            
            if (agent != NULL)
            {
                newData = [self GameStateToWM:agent->GetInputLink()];
            }
            
            needsRefresh = NO;
        }

		double startTime = [[NSDate date] timeIntervalSince1970];
        
        do {
			if (agent == NULL)
				continue;

            if (!agentInterrupted)
				agent->RunSelfTilOutput();
            
            sml::smlRunState agentState = agent->GetRunState();
            agentHalted = agentState == sml::sml_RUNSTATE_HALTED;

			if (!agentInterrupted)
				agentInterrupted = agentState == sml::sml_RUNSTATE_INTERRUPTED;

			if (!agentInterrupted && (startTime + 5) < [[NSDate date] timeIntervalSince1970])
			{
				[turnLock unlock];

				NSLog(@"Restarting Soar due to timeout: %i", [turnCount intValue]);

				if ([turnCount intValue] > 5)
					return [self showErrorAlert];
				else
					return [self doTurn:[NSNumber numberWithInt:([turnCount intValue] + 1)]];
			}

        } while (!agentHalted && agent != NULL && (agent->GetNumberCommands() == 0));
        
        if (agent != NULL && agent->GetNumberCommands() != 0)
        {
            [self handleAgentCommandsWithRefresh:&needsRefresh sleep:&agentSlept];
        }
    } while (!agentSlept && !agentHalted);

    if (agent != NULL)
    {
        NSLog(@"Halting agent");
        sml::WMElement *halter = NULL;
        if (!agentHalted)
        {
            halter = agent->GetInputLink()->CreateStringWME("halt", "now");
            agent->RunSelfTilOutput();
        }
        
        // reinitialize agent
        if (halter != NULL)
        {
            halter->DestroyWME();
        }
        
        if (newData != NULL)
        {
            newData->idState->DestroyWME();
            newData->idPlayers->DestroyWME();
            newData->idAffordances->DestroyWME();
            newData->idHistory->DestroyWME();
            newData->idRounds->DestroyWME();
            delete newData;
            newData = NULL;
        }
        
        agent->InitSoar();
    }
    else
    {
        NSLog(@"Agent performed commands");
        if (needsRefresh && newData != NULL)
        {
            newData->idState->DestroyWME();
            newData->idPlayers->DestroyWME();
            newData->idAffordances->DestroyWME();
            newData->idHistory->DestroyWME();
            newData->idRounds->DestroyWME();
            delete newData;
            newData = NULL;
        }
    }
    
    NSLog(@"Agent done");
    
    if (newData != NULL)
    {
        newData->idState->DestroyWME();
        newData->idPlayers->DestroyWME();
        newData->idAffordances->DestroyWME();
        newData->idHistory->DestroyWME();
        newData->idRounds->DestroyWME();
        delete newData;
        newData = NULL;
    }
    
    [turnLock unlock];
}

- (void)drop
{}

- (DiceSMLData *)GameStateToWM:(sml::Identifier *)inputLink
{
    using namespace sml;
 
    NSLog(@"Beginning GameStateToWM");
    
    Identifier *idState = NULL;
    Identifier *idPlayers = NULL;
    Identifier *idAffordances = NULL;
    WMElement *idHistory = NULL;
    WMElement *idRounds = NULL;
    
    idState = inputLink->CreateIdWME("state");
    testWme(idState);
    idPlayers = inputLink->CreateIdWME("players");
    testWme(idPlayers);
    idAffordances = inputLink->CreateIdWME("affordances");
    testWme(idAffordances);

	DiceGame* localGame = self.game;
	PlayerState* localState = self.playerState;
    DiceGameState *gameState = localGame.gameState;
    
    idState->CreateStringWME("special", ([gameState usingSpecialRules] ? "true" : "false"));
    idState->CreateStringWME("inprogress", ([gameState isGameInProgress] ? "true" : "false"));
    
    std::map<NSInteger, void*> playerMap;
    int victorID = -1;
    
    BOOL playerHasWon = [gameState hasAPlayerWonTheGame];
    if (playerHasWon)
    {
        victorID = [[gameState gameWinner] getID];
    }
    
    NSString *status = nil;
    
    switch ([gameState playerStatus:localState.playerID]) {
        case Lost:
            status = @"lost";
            break;
        case Won:
            status = @"won";
            break;
        default:
            status = @"play";
            break;
    };
    
    idPlayers->CreateStringWME("mystatus", [status UTF8String]);
    
    for (id <Player> playerThing in [gameState players])
    {
        PlayerState *player = [gameState getPlayerState:[playerThing getID]];
        Identifier *playerId = idPlayers->CreateIdWME("player");
        testWme(playerId);
        playerId->CreateIntWME("id", [player playerID]);
        playerId->CreateStringWME("name", [player.playerName UTF8String]);
        playerId->CreateStringWME("exists", ([player hasLost] ? "false" : "true"));
        Identifier *cup = playerId->CreateIdWME("cup");
        testWme(cup);
        
        if (localState == player)
        {
            if ([[player unPushedDice] count] > 0)
            {
                cup->CreateIntWME("count", [[player unPushedDice] count]);
                for (Die* hiddenDie in [player unPushedDice])
                {
                    Identifier *die = cup->CreateIdWME("die");
                    testWme(die);
                    die->CreateIntWME("face", [hiddenDie dieValue]);
                }
            }
            else
            {
                cup->CreateIntWME("count", 0);
            }
            Identifier *cupTotals = cup->CreateIdWME("totals");
            testWme(cupTotals);
            
            int ones = 0;
            int twos = 0;
            int threes = 0;
            int fours = 0;
            int fives = 0;
            int sixes = 0;
            
            for (Die *die in [player unPushedDice])
            {
                if ([die isKindOfClass:[Die class]])
                {
                    switch ([die dieValue])
                    {
                        case 1:
                            ones++;
                            break;
                        case 2:
                            twos++;
                            break;
                        case 3:
                            threes++;
                            break;
                        case 4:
                            fours++;
                            break;
                        case 5:
                            fives++;
                            break;
                        case 6:
                            sixes++;
                            break;
                        default:
                            break;
                    }
                }
            }
            
            cupTotals->CreateIntWME("1", ones);
            cupTotals->CreateIntWME("2", twos);
            cupTotals->CreateIntWME("3", threes);
            cupTotals->CreateIntWME("4", fours);
            cupTotals->CreateIntWME("5", fives);
            cupTotals->CreateIntWME("6", sixes);
        }
        else
        {
            cup->CreateIntWME("count", [[player unPushedDice] count]);
        }
        
        Identifier *pushed = playerId->CreateIdWME("pushed");
        testWme(pushed);
        NSArray* pushedDice = [player pushedDice];

        if ([pushedDice count] > 0)
        {
            pushed->CreateIntWME("count", [pushedDice count]);
            for (Die* pushedDie in pushedDice)
            {
                if ([pushedDie isKindOfClass:[Die class]])
                {
                    Identifier *die = pushed->CreateIdWME("die");
                    testWme(die);
                    die->CreateIntWME("face", [pushedDie dieValue]);
                }
            }
        }
        else
        {
            pushed->CreateIntWME("count", 0);
        }
        
        Identifier *pushedTotals = pushed->CreateIdWME("totals");
        testWme(pushedTotals);
        
        int ones = 0;
        int twos = 0;
        int threes = 0;
        int fours = 0;
        int fives = 0;
        int sixes = 0;
        
        for (Die *die in pushedDice)
        {
            if ([die isKindOfClass:[Die class]])
            {
                switch ([die dieValue]) {
                    case 1:
                        ones++;
                        break;
                    case 2:
                        twos++;
                        break;
                    case 3:
                        threes++;
                        break;
                    case 4:
                        fours++;
                        break;
                    case 5:
                        fives++;
                        break;
                    case 6:
                        sixes++;
                        break;
                    default:
                        break;
                }
            }
        }
        
        pushedTotals->CreateIntWME("1", ones);
        pushedTotals->CreateIntWME("2", twos);
        pushedTotals->CreateIntWME("3", threes);
        pushedTotals->CreateIntWME("4", fours);
        pushedTotals->CreateIntWME("5", fives);
        pushedTotals->CreateIntWME("6", sixes);
        
        if (localState == player)
        {
            idPlayers->CreateSharedIdWME("me", playerId);
        }
        
        if ([gameState getCurrentPlayerState] == player)
        {
            idPlayers->CreateSharedIdWME("current", playerId);
        }
        
        if (victorID == player.playerID)
        {
            idPlayers->CreateSharedIdWME("victor", playerId);
        }
        
        playerMap[player.playerID] = static_cast<void*>(playerId);
        
    }
    
    Identifier *bid = idAffordances->CreateIdWME("action");
    testWme(bid);
    bid->CreateStringWME("name", "bid");
    bid->CreateStringWME("available", ([localState canBid] ? "true" : "false"));
    
    Identifier *challenge = idAffordances->CreateIdWME("action");
    testWme(challenge);
    challenge->CreateStringWME("name", "challenge");
    
    BOOL canChallengeBid = [localState canChallengeBid];
    BOOL canChallengePass = [localState canChallengeLastPass];
    
    challenge->CreateStringWME("available", ((!canChallengeBid && !canChallengePass) ? "false" : "true"));
    
    if (canChallengeBid)
    {
        NSInteger target = [[gameState previousBid] playerID];
        challenge->CreateSharedIdWME("target", static_cast<Identifier *>(playerMap[target]));
    }
    else if (canChallengePass)
    {
        NSInteger target = [gameState lastPassPlayerID];
        challenge->CreateSharedIdWME("target", static_cast<Identifier *>(playerMap[target]));
        target = [gameState secondLastPassPlayerID];
        if (target != -1)
        {
            challenge->CreateSharedIdWME("target", static_cast<Identifier *>(playerMap[target]));
        }
    }
    
    Identifier *exact = idAffordances->CreateIdWME("action");
    testWme(exact);
    exact->CreateStringWME("name", "exact");
    exact->CreateStringWME("available", ([localState canExact] ? "true" : "false"));
    
    Identifier *pass = idAffordances->CreateIdWME("action");
    testWme(pass);
    pass->CreateStringWME("name", "pass");
    pass->CreateStringWME("available", ([localState canPass] ? "true" : "false"));
    
    Identifier *push = idAffordances->CreateIdWME("action");
    testWme(push);
    push->CreateStringWME("name", "push");
    push->CreateStringWME("available", ([localState canPush] ? "true" : "false"));
    
    Identifier *accept = idAffordances->CreateIdWME("action");
    testWme(accept);
    accept->CreateStringWME("name", "accept");
    accept->CreateStringWME("available", ([localState canAccept] ? "true" : "false"));
    
    NSArray* history = [gameState history];
    NSInteger roundLength = [history count];
	
	NSInteger lastActionHistoryItem = 0;
	int numberHistoryItems = 0;
	
	for (NSInteger i = roundLength - 1; i >= 0; --i)
	{
		HistoryItem *item = [history objectAtIndex:i];
		if (item.historyType == actionHistoryItem)
		{
			lastActionHistoryItem = i;
			numberHistoryItems++;
		}
	}
    
    if (numberHistoryItems == 0)
    {
        idHistory = inputLink->CreateStringWME("history", "nil");
        idState->CreateStringWME("last-bid", "nil");
    }
    else
    {
        idHistory = inputLink->CreateIdWME("history");
        testWme(idHistory);
        Identifier *prev = idHistory->ConvertToIdentifier();
        Identifier *lastBid = NULL;
        
        for (NSInteger i = roundLength - 1; i >= 0; --i)
        {
            HistoryItem *item = [history objectAtIndex:i];
            if (item.historyType != actionHistoryItem)
            {
                continue;
            }

			PlayerState* itemState = [item player];
            int historyPlayerId = [itemState playerID];
            if (static_cast<Identifier *>(playerMap[historyPlayerId]) != NULL)
            {
                prev->CreateSharedIdWME("player", static_cast<Identifier *>(playerMap[historyPlayerId]));
            }
            
            char *action = NULL;
            switch (item.actionType) {
                case ACTION_ACCEPT:
                    action = const_cast<char*>((const char*)"accept");
                    break;
                case ACTION_BID:
                    action = const_cast<char*>((const char*)"bid");
                    break;
                case ACTION_PUSH:
                    action = const_cast<char*>((const char*)"push");
                    break;
                case ACTION_CHALLENGE_BID:
                    action = const_cast<char*>((const char*)"challenge_bid");
                    break;
                case ACTION_CHALLENGE_PASS:
                    action = const_cast<char*>((const char*)"challenge_pass");
                    break;
                case ACTION_EXACT:
                    action = const_cast<char*>((const char*)"exact");
                    break;
                case ACTION_PASS:
                    action = const_cast<char*>((const char*)"pass");
                    break;
                case ACTION_ILLEGAL:
                    action = const_cast<char*>((const char*)"illegal");
                    break;
				case ACTION_QUIT:
				default:
				{
					NSLog(@"Impossible Situation? HistoryItem.m:128");
					break;
				}
            }
            
            prev->CreateStringWME("action", action);
            
            if ((lastBid == NULL) && item.actionType == ACTION_BID)
            {
                lastBid = idState->CreateSharedIdWME("last-bid", prev);
            }
            
            if (item.actionType == ACTION_BID)
            {
                Bid *itemBid = [item bid];
                prev->CreateIntWME("multiplier", [itemBid numberOfDice]);
                prev->CreateIntWME("face", [itemBid rankOfDie]);
            }
            else if (item.actionType == ACTION_CHALLENGE_BID || item.actionType == ACTION_CHALLENGE_PASS)
            {
                int challengeTarget = [item value];
                if (static_cast<Identifier *>(playerMap[challengeTarget]) != NULL)
                {
                    prev->CreateSharedIdWME("target", static_cast<Identifier *>(playerMap[challengeTarget]));
                }
                
                prev->CreateStringWME("result", [item result] == 1 ? "success" : "failure");
                
            }
            else if (item.actionType == ACTION_EXACT)
            {
                prev->CreateStringWME("result", [item result] == 1 ? "success" : "failure");
            }
            
            if (i == lastActionHistoryItem)
            {
                prev->CreateStringWME("next", "nil");
            }
            else
            {
                prev = prev->CreateIdWME("next");
                testWme(prev);
            }
        }
        
        if (lastBid == NULL)
        {
            idState->CreateStringWME("last-bid", "nil");
        }
    }
    
    NSArray* rounds = [gameState roundHistory];
    NSInteger numRounds = [rounds count];
    
    if (numRounds == 0)
    {
        idRounds = inputLink->CreateStringWME("rounds", "nil");
    }
    else
    {
        idRounds = inputLink->CreateIdWME("rounds");
        testWme(idRounds);
        Identifier *prev = idRounds->ConvertToIdentifier();
        
        for (int i = 0; i < numRounds; ++i)
        {
            prev->CreateIntWME("id", i);
            NSArray* round = [rounds objectAtIndex:i];
            HistoryItem *roundEnd = [round objectAtIndex:[round count] - 1];

			PlayerState* roundEndState = roundEnd.player;
            int playerId = roundEndState.playerID;
            if (static_cast<Identifier *>(playerMap[playerId]) != NULL)
            {
                prev->CreateSharedIdWME("player", static_cast<Identifier *>(playerMap[playerId]));
            }
            
            char *action = NULL;
            switch (roundEnd.actionType) {
                case ACTION_ACCEPT:
                    action = const_cast<char*>((const char*)"accept");
                    break;
                case ACTION_BID:
                    action = const_cast<char*>((const char*)"bid");
                    break;
                case ACTION_PUSH:
                    action = const_cast<char*>((const char*)"push");
                    break;
                case ACTION_CHALLENGE_BID:
                    action = const_cast<char*>((const char*)"challenge_bid");
                    break;
                case ACTION_CHALLENGE_PASS:
                    action = const_cast<char*>((const char*)"challenge_pass");
                    break;
                case ACTION_EXACT:
                    action = const_cast<char*>((const char*)"exact");
                    break;
                case ACTION_PASS:
                    action = const_cast<char*>((const char*)"pass");
                    break;
                case ACTION_ILLEGAL:
                    action = const_cast<char*>((const char*)"illegal");
                    break;
				case ACTION_QUIT:
				default:
				{
					NSLog(@"Impossible Situation? HistoryItem.m:128");
					break;
				}
            }
            
            prev->CreateStringWME("action", action);
            
            if (roundEnd.actionType == ACTION_CHALLENGE_BID || roundEnd.actionType == ACTION_CHALLENGE_PASS)
            {
                
                int challengeValue = [roundEnd value];
                if (static_cast<Identifier *>(playerMap[challengeValue]))
                {
                    prev->CreateSharedIdWME("target", static_cast<Identifier *>(playerMap[challengeValue]));
                }
                
                prev->CreateStringWME("result", [roundEnd result] == 1 ? "success" : "failure");
            }
            else if (roundEnd.actionType == ACTION_EXACT)
            {
                prev->CreateStringWME("result", [roundEnd result] == 1 ? "success" : "failure");
            }
            
            if (i == (numRounds-1))
            {
                prev->CreateStringWME("next", "nil");
            }
            else
            {
                prev = prev->CreateIdWME("next");
                testWme(prev);
            }
        }
    }
        NSLog(@"Ending GameStateToWM");
    return new DiceSMLData(idState, idPlayers, idAffordances, idHistory, idRounds);
}

// Should only be called if turnLock is locked.
- (void) handleAgentCommandsWithRefresh:(BOOL *)needsRefresh sleep:(BOOL *)sleep;
{
    NSLog(@"Agent handling agent commands");
    *sleep = NO;
    DiceAction *action = nil;
    NSArray *diceToPush = nil;
    for (int j = 0; j < agent->GetNumberCommands(); j++)
    {
        sml::Identifier *ident = agent->GetCommand(j);
        NSString *attrName = [NSString stringWithUTF8String:ident->GetAttribute()];
        
        NSLog(@"Command from output link, j=%d, command=%@", j, attrName);
        
        NSString *commandStatus = @"";
        if (ident->GetParameterValue("status") != NULL)
        {
            commandStatus = [NSString stringWithUTF8String:ident->GetParameterValue("status")];
        }
        
        if ([commandStatus isEqualToString:@"complete"])
        {
            continue;
        }
        
        if (![attrName isEqualToString:@"qna-query"])
        {
            if ([attrName isEqualToString:@"bid"])
            {
                action = [DiceAction bidAction:self.playerID
                                         count:[[NSString stringWithUTF8String:ident->GetParameterValue("multiplier")] intValue]
                                          face:[[NSString stringWithUTF8String:ident->GetParameterValue("face")] intValue]
                                          push:nil];
            }
            else if ([attrName isEqualToString:@"exact"])
            {
                action = [DiceAction exactAction:self.playerID];
            }
            else if ([attrName isEqualToString:@"accept"])
            {
                action = [DiceAction acceptAction:self.playerID];
            }
            else if ([attrName isEqualToString:@"push"])
            {
                BOOL goodCommand = YES;
                int* faces = new int[ident->GetNumberChildren()];
                
                for (int k = 0; k < ident->GetNumberChildren(); k++)
                {
                    if (goodCommand)
                    {
                        sml::WMElement *child = ident->GetChild(k);
                        NSString *attr = [NSString stringWithUTF8String:child->GetAttribute()];
                        if (![attr isEqualToString:@"die"])
                        {
                            goodCommand = NO;
                            continue;
                        }
                        
                        sml::Identifier *childId = child->ConvertToIdentifier();
                        if (childId == NULL)
                        {
                            goodCommand = NO;
                            continue;
                        }
                        
                        if (childId->GetNumberChildren() != 1)
                        {
                            goodCommand = NO;
                            continue;
                        }
                        sml::WMElement *face = childId->GetChild(0);
                        if (![[NSString stringWithUTF8String:face->GetAttribute()] isEqualToString:@"face"])
                        {
                            goodCommand = NO;
                            continue;
                        }
                        
                        sml::IntElement *intFace = face->ConvertToIntElement();
                        if (intFace == NULL)
                        {
                            goodCommand = NO;
                            continue;
                        }
                        if (goodCommand)
                        {
                            faces[k] = (int) ident->GetChild(k)->ConvertToIdentifier()->GetChild(0)->ConvertToIntElement()->GetValue();
                        }
                    }
                }
                
                if (goodCommand)
                {
                    
                    NSMutableArray *mut = [[NSMutableArray alloc] init];
                    for (int i = 0;i < ident->GetNumberChildren();i++) {
                        NSNumber *number = [NSNumber numberWithInt:faces[i]];

                        if ([number isKindOfClass:[NSNumber class]])
                            [mut addObject:[[Die alloc] initWithNumber:[number intValue]] ];
                    }
                    
                    diceToPush = [[NSArray alloc] initWithArray:mut];
                }
				
				delete[] faces;
            }
            else if ([attrName isEqualToString:@"challenge"])
            {
                // Hack.
                *sleep = YES;
                
                long target = -1;
                
                if (ident->GetNumberChildren() == 1)
                {
                    sml::WMElement *targetWme = ident->FindByAttribute("target", 0);
                    
                    if ((targetWme != NULL) && (targetWme->ConvertToIntElement() != NULL))
                    {
                        target = targetWme->ConvertToIntElement()->GetValue();
                    }
                }
                
                if (target != -1)
					action = [DiceAction challengeAction:self.playerID target:target];
            }
            else if ([attrName isEqualToString:@"pass"])
            {
                action = [DiceAction passAction:self.playerID push:nil];
            }
            else if ([attrName isEqualToString:@"sleep"])
            {
                *sleep = YES;
            }
            else
            {
				NSLog(@"Error: agent attempted to use command \"%@\"", attrName);
                
                ident->AddStatusError();
            }
            
            if (ident->GetParameterValue("status") == NULL /* && errors == 0 */)
            {
                ident->AddStatusComplete();
            }
            else if (NO /* errors > 0 */)
            {
                j--;
                continue;
            }
        }
        else
        {}
    }

	DiceGame* localGame = self.game;
	GameKitGameHandler* localHandler = self.handler;
    
    if (action != nil)
    {
        NSLog(@"Agent performing action of type: %d", action.actionType);
        if (diceToPush != nil)
        {
            NSLog(@"Pushing dice, count: %lu", (unsigned long)[diceToPush count]);
            action.push = diceToPush;           
        }
        [localGame handleAction:action];
        *needsRefresh = YES;
    }
    else if (diceToPush != nil)
    {
        NSLog(@"Agent just pushing, count: %lu", (unsigned long)[diceToPush count]);
        DiceAction *new_action = [DiceAction pushAction:self.playerID push:diceToPush];
        [localGame handleAction:new_action];
    }

	if (localHandler)
		[localHandler saveMatchData];
}

- (void)newRound:(NSArray *)arrayOfDice
{}

- (void)showPublicInformation:(DiceGameState *)gameState
{}

- (void)reroll:(NSArray *)arrayOfDice
{}

// Methods from Player protocol

- (NSString *)getDisplayName {
    return self.name;
}

- (NSString *)getGameCenterName
{
	return @"Soar";
}

- (void) updateState:(PlayerState*)state {
    self.playerState = state;
}

- (int) getID {
    return self.playerID;
}

- (void) setID:(int)anID {
    self.playerID = anID;
}

- (void) notifyHasLost
{}

- (void) notifyHasWon
{}

- (void)removeHandler
{
	self.handler = nil;
}

@end
