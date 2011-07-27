    //
    //  Agent.m
    //  iSoar
    //
    //  Created by Alex on 6/21/11.
    //  Copyright 2011 __MyCompanyName__. All rights reserved.
    //

#import "Agent.h"
#import "PlayerState.h"
#import "Die.h"
#import "HistoryItem.h"

#include <map>

    //#include "sml_Events.h"

void sdb(char * command, sml::Agent *agent)
{
        //printf("%s", agent->ExecuteCommandLine(command));
}

class DiceSMLData {
public:
    sml::Identifier *idState;
	sml::Identifier *idPlayers;
	sml::Identifier *idAffordances;
	sml::WMElement *idHistory;
	sml::WMElement *idRounds;
	
	DiceSMLData(sml::Identifier *idState, sml::Identifier *idPlayers, sml::Identifier *idAffordances, sml::WMElement *idHistory, sml::WMElement *idRounds) {
		this->idState = idState;
		this->idPlayers = idPlayers;
		this->idAffordances = idAffordances;
		this->idHistory = idHistory;
		this->idRounds = idRounds;
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

@interface Agent()

- (DiceSMLData *) GameStateToWM:(DiceGameState *)game withInputLink:(sml::Identifier *) inputLink andMyPlayerIDIs:(int) playerID;

- (BOOL) handleAgentCommandsWithGameState:(DiceGameState *)gameState andPlayerID:(int)playerID withNeedsRefreshBool:(BOOL *)refreshAr withInformation:(turnInformationSentFromTheClient *)information withErrors:(int)errors;

@end

@implementation Agent

- (id)init:(BOOL)connect
{
    self = [super init];
    if (self) {        
            //kernel = sml::Kernel::CreateKernelInNewThread(sml::Kernel::kDefaultLibraryName, 0);
        if (connect)
        {
            kernel = sml::Kernel::CreateRemoteConnection(false, "141.212.109.214", 12121);
            remoteConnected = YES;
        }
        else
            kernel = sml::Kernel::CreateKernelInNewThread(sml::Kernel::kDefaultLibraryName, 0);
        
        if (kernel->HadError())
            return nil;
        
        
        static int number = 1;
        name = [[NSString alloc] initWithFormat:@"Soar Agent %i", number];
        number++;
        
        const char* string = [name UTF8String];
        agent = kernel->CreateAgent(string);
        if (agent == NULL)
            return nil;
        
            //agent->RegisterForPrintEvent(sml::smlEVENT_PRINT, DiceSMLData::PrintEventHandler, NULL);
        
            //agent->RegisterForRunEvent(sml::smlEVENT_BEFORE_ELABORATION_CYCLE, DiceSMLData::RunEventHandler, NULL);
        
        /*agent->ExecuteCommandLine("timers -d");
         agent->SetOutputLinkChangeTracking(true);*/
        
        int seed = rand() % RAND_MAX;
                
        agent->ExecuteCommandLine([[NSString stringWithFormat:@"srand %i", seed] UTF8String]);
        
        NSString *path;
        if (!remoteConnected)
            path = [NSString stringWithFormat:@"source \"%@\"", [[NSBundle mainBundle] pathForResource:@"dice-p0-m0-c0" ofType:@"soar" inDirectory:@""]];
        else
            path = @"source \"\"/Users/bluechill/Desktop/2011 Soar Summer Work/Lair's Dice/Lair's Dice/Soar/Soar Rules/dice-p0-m0-c0.soar\"";
        
        NSLog(@"Path:%@", path);
        
#define LENGTH_OF_FILE 18
        
        NSString *directory;
        if (!remoteConnected)
            directory = [NSString stringWithFormat:@"cd \"%@\"", [path substringToIndex:[path length] - LENGTH_OF_FILE]];
        else
            directory = @"cd \"/Users/bluechill/Desktop/2011 Soar Summer Work/Lair's Dice/Lair's Dice/Soar/Soar Rules/\"";
        
        std::cout << agent->ExecuteCommandLine([directory UTF8String]) << std::endl;
        
        std::cout << agent->ExecuteCommandLine([path UTF8String]) << std::endl;
        
        if (connect)
            std::cout << agent->ExecuteCommandLine("watch 5") << std::endl;
        
        agent->InitSoar();
    }
    return self;
}

- (void)cleanup
{
    cleanup = true;
    kernel->Shutdown();
    delete kernel;
}

- (void)dealloc
{
    [super dealloc];
}

- (NSString*)name
{
    return name;
}

- (turnInformationSentFromTheClient)isMyTurn:(turnInformationToSendToClient)turnInfo
{
    if (cleanup)
    {
        turnInformationSentFromTheClient information;
        information.action = (ActionsAbleToSend)-2;
        return information;
    }
    
    BOOL agentSlept = NO;
    BOOL agentHalted = NO;
    BOOL needsRefresh = YES;
    
    DiceSMLData *newData = NULL;
    
    turnInformationSentFromTheClient *information = (turnInformationSentFromTheClient *)calloc(1, sizeof(turnInformationSentFromTheClient));
    
    do {
        if (cleanup)
        {
            turnInformationSentFromTheClient information;
            information.action = (ActionsAbleToSend)-2;
            return information;
        }
        
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
                newData = [self GameStateToWM:turnInfo.gameState withInputLink:agent->GetInputLink() andMyPlayerIDIs:turnInfo.playerID];
            }
            
            needsRefresh = NO;
        }
        
        do {   
            if (cleanup)
            {
                turnInformationSentFromTheClient information;
                information.action = (ActionsAbleToSend)-2;
                return information;
            }
            
            //if (!remoteConnected)
                agent->RunSelfTilOutput();
            //else
            //    agent->RunSelf(0);
            
            sml::smlRunState agentState = agent->GetRunState();
            agentHalted = (agentState == sml::sml_RUNSTATE_HALTED || agentState == sml::sml_RUNSTATE_INTERRUPTED);
            while (agentHalted);
            
            if (cleanup)
            {
                turnInformationSentFromTheClient information;
                information.action = (ActionsAbleToSend)-2;
                return information;
            }
        } while (!agentHalted && (agent->GetNumberCommands() == 0));
        
        if (cleanup)
        {
            turnInformationSentFromTheClient information;
            information.action = (ActionsAbleToSend)-2;
            return information;
        }
        
        if (agent->GetNumberCommands() != 0)
        {
                // Pack needsRefresh in array to use as output
                // variable.
            BOOL *refreshAr = (BOOL*)calloc(1, sizeof(BOOL));
            
            *refreshAr = needsRefresh;
            agentSlept = [self handleAgentCommandsWithGameState:turnInfo.gameState andPlayerID:turnInfo.playerID withNeedsRefreshBool:refreshAr withInformation:information withErrors:turnInfo.errors];
            needsRefresh = *refreshAr;
            
            free(refreshAr);
        }
        
        if (cleanup)
        {
            turnInformationSentFromTheClient information;
            information.action = (ActionsAbleToSend)-2;
            return information;
        }
        
    } while (!agentSlept && (agent->GetNumberCommands() == 0));
    
        //NSLog(@"State: %s", agent->ExecuteCommandLine("print -d 10 s1"));
    if (cleanup)
    {
        turnInformationSentFromTheClient information;
        information.action = (ActionsAbleToSend)-2;
        return information;
    }
    
    if (agentSlept)
    {
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
        if (needsRefresh)
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
    
    information->errorString = [[NSString alloc] init];
    [information->errorString autorelease];
    
    turnInformationSentFromTheClient info = *information;
    free(information);
    
    return info;
}

- (void)drop
{
    
}

- (DiceSMLData *)GameStateToWM:(DiceGameState *)game withInputLink:(sml::Identifier *)inputLink andMyPlayerIDIs:(int) playerID
{
    using namespace sml;
    
    Identifier *idState = NULL;
    Identifier *idPlayers = NULL;
    Identifier *idAffordances = NULL;
    WMElement *idHistory = NULL;
    WMElement *idRounds = NULL;
    
    idState = inputLink->CreateIdWME("state");
    idPlayers = inputLink->CreateIdWME("players");
    idAffordances = inputLink->CreateIdWME("affordances");
    
    PlayerState *selfPlayer = [game player:playerID];
    
    idState->CreateStringWME("special", ([game usingSpecialRules] ? "true" : "false"));
    idState->CreateStringWME("inprogress", ([game isGameInProgress] ? "true" : "false"));
    
    std::map<int, void*> playerMap;
    int victorID = -1;
    if ([game hasAPlayerWonTheGame])
        victorID = [[game gameWinner] playerID];
    
    char * status;
    
    switch ([game playerStatus:playerID]) {
        case Lost:
            status = const_cast<char*>((const char*)"lost");
            break;
        case Won:
            status = const_cast<char*>((const char*)"won");
            break;
        default:
            status = const_cast<char*>((const char*)"play");
            break;
    };
    
    idPlayers->CreateStringWME("mystatus", status);
    
    for (PlayerState *player in [game players])
    {
        if ([player isKindOfClass:[PlayerState class]])
        {
            Identifier *playerId = idPlayers->CreateIdWME("player");
            playerId->CreateIntWME("id", [player playerID]);
            playerId->CreateStringWME("name", [[player playerName] UTF8String]);
            playerId->CreateStringWME("exists", ([player hasThePlayerLost] ? "true" : "false"));
            Identifier *cup = playerId->CreateIdWME("cup");
            
            if (selfPlayer == player)
            {
                if ([[player unPushedDice] count])
                {
                    cup->CreateIntWME("count", [[player unPushedDice] count]);
                    for (Die* hiddenDie in [player unPushedDice])
                    {
                        Identifier *die = cup->CreateIdWME("die");
                        die->CreateIntWME("face", [hiddenDie dieValue]);
                    }
                }
                else
                {
                    cup->CreateIntWME("count", 0);
                }
                Identifier *cupTotals = cup->CreateIdWME("totals");
                
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
            NSArray* pushedDice = [player pushedDice];
            
            if ([pushedDice count])
            {
                pushed->CreateIntWME("count", [pushedDice count]);
                for (Die* pushedDie in pushedDice)
                {
                    if ([pushedDie isKindOfClass:[Die class]])
                    {
                        Identifier *die = pushed->CreateIdWME("die");
                        die->CreateIntWME("face", [pushedDie dieValue]);
                    }
                }
            }
            else
            {
                pushed->CreateIntWME("count", 0);
            }
            
            Identifier *pushedTotals = pushed->CreateIdWME("totals");
            
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
            
            if (selfPlayer == player)
            {
                idPlayers->CreateSharedIdWME("me", playerId);
            }
            
            if ([game currentPlayer] == player)
            {
                idPlayers->CreateSharedIdWME("current", playerId);
            }
            
            if (victorID == [player playerID])
            {
                idPlayers->CreateSharedIdWME("victor", playerId);
            }
            
            playerMap[[player playerID]] = static_cast<void*>(playerId);
        }
        
    }
    
    Identifier *bid = idAffordances->CreateIdWME("action");
    bid->CreateStringWME("name", "bid");
    bid->CreateStringWME("available", ([selfPlayer canBid] ? "true" : "false"));
    
    Identifier *challenge = idAffordances->CreateIdWME("action");
    challenge->CreateStringWME("name", "challenge");
    
    BOOL canChallengeBid = [selfPlayer canChallengeBid];
    BOOL canChallengePass = [selfPlayer canChallengeLastPass];
    
    challenge->CreateStringWME("available", ((!canChallengeBid && !canChallengePass) ? "false" : "true"));
    
    if (canChallengeBid)
    {
        int target = [[game previousBid] playerID];
        challenge->CreateSharedIdWME("target", static_cast<Identifier *>(playerMap[target]));
    }
    else if (canChallengePass)
    {
        int target = [game lastPassPlayerID];
        challenge->CreateSharedIdWME("target", static_cast<Identifier *>(playerMap[target]));
        target = [game secondLastPassPlayerID];
        if (target != -1)
        {
            challenge->CreateSharedIdWME("target", static_cast<Identifier *>(playerMap[target]));
        }
    }
    
    Identifier *exact = idAffordances->CreateIdWME("action");
    exact->CreateStringWME("name", "exact");
    exact->CreateStringWME("available", ([selfPlayer canExact] ? "true" : "false"));
    
    Identifier *pass = idAffordances->CreateIdWME("action");
    pass->CreateStringWME("name", "pass");
    pass->CreateStringWME("available", ([selfPlayer canPass] ? "true" : "false"));
    
    Identifier *push = idAffordances->CreateIdWME("action");
    push->CreateStringWME("name", "push");
    push->CreateStringWME("available", ([selfPlayer canPush] ? "true" : "false"));
    
    Identifier *accept = idAffordances->CreateIdWME("action");
    accept->CreateStringWME("name", "accept");
    accept->CreateStringWME("available", ([selfPlayer canAccept] ? "true" : "false"));
    
    
    
    
    NSArray* history = [game history];
    int roundLength = [history count];
    
    if (roundLength == 0)
    {
        idHistory = inputLink->CreateStringWME("history", "nil");
        idState->CreateStringWME("last-bid", "nil");
    }
    else
    {
        idHistory = inputLink->CreateIdWME("history");
        Identifier *prev = idHistory->ConvertToIdentifier();
        Identifier *lastBid = NULL;
        
        for (int i = roundLength - 1; i >= 0; --i)
        {
            HistoryItem *item = [history objectAtIndex:i];
            
            int historyPlayerId = [[item player] playerID];
            if (static_cast<Identifier *>(playerMap[historyPlayerId]) != NULL)
            {
                prev->CreateSharedIdWME("player", static_cast<Identifier *>(playerMap[historyPlayerId]));
            }
            
            char *action;
            switch ([item type]) {
                case ACCEPT:
                    action = const_cast<char*>((const char*)"accept");
                    break;
                case BID:
                    action = const_cast<char*>((const char*)"bid");
                    break;
                case PUSH:
                    action = const_cast<char*>((const char*)"push");
                    break;
                case CHALLENGE_BID:
                    action = const_cast<char*>((const char*)"challenge_bid");
                    break;
                case CHALLENGE_PASS:
                    action = const_cast<char*>((const char*)"challenge_pass");
                    break;
                case EXACT:
                    action = const_cast<char*>((const char*)"exact");
                    break;
                case PASS:
                    action = const_cast<char*>((const char*)"pass");
                    break;
                case ILLEGAL:
                    action = const_cast<char*>((const char*)"illegal");
                    break;
            }
            
            prev->CreateStringWME("action", action);
            
            if ((lastBid == NULL) && [item type] == BID)
            {
                lastBid = idState->CreateSharedIdWME("last-bid", prev);
            }
            
            if ([item type] == BID)
            {
                Bid *itemBid = [item bid];
                prev->CreateIntWME("multiplier", [itemBid numberOfDice]);
                prev->CreateIntWME("face", [itemBid rankOfDie]);
            }
            else if ([item type] == CHALLENGE_BID || [item type] == CHALLENGE_PASS)
            {
                int challengeTarget = [item value];
                if (static_cast<Identifier *>(playerMap[challengeTarget]) != NULL)
                {
                    prev->CreateSharedIdWME("target", static_cast<Identifier *>(playerMap[challengeTarget]));
                }
                
                prev->CreateStringWME("result", [item result] == 1 ? "success" : "failure");
                
            }
            else if ([item type] == EXACT)
            {
                prev->CreateStringWME("result", [item result] == 1 ? "success" : "failure");
            }
            
            if (i == 0)
            {
                prev->CreateStringWME("next", "nil");
            }
            else
            {
                prev = prev->CreateIdWME("next");
            }
        }
        
        if (lastBid == NULL)
        {
            idState->CreateStringWME("last-bid", "nil");
        }
    }
    
    NSArray* rounds = [game roundHistory];
    int numRounds = [rounds count];
    
    if (numRounds == 0)
    {
        idRounds = inputLink->CreateStringWME("rounds", "nil");
    }
    else
    {
        idRounds = inputLink->CreateIdWME("rounds");
        Identifier *prev = idRounds->ConvertToIdentifier();
        
        for (int i = 0; i < numRounds; ++i)
        {
            prev->CreateIntWME("id", i);
            NSArray* round = [rounds objectAtIndex:i];
            HistoryItem *roundEnd = [round objectAtIndex:[round count] - 1];
            
            int playerId = [[roundEnd player] playerID];
            if (static_cast<Identifier *>(playerMap[playerId]) != NULL)
            {
                prev->CreateSharedIdWME("player", static_cast<Identifier *>(playerMap[playerId]));
            }
            
            char *action;
            switch ([roundEnd type]) {
                case ACCEPT:
                    action = const_cast<char*>((const char*)"accept");
                    break;
                case BID:
                    action = const_cast<char*>((const char*)"bid");
                    break;
                case PUSH:
                    action = const_cast<char*>((const char*)"push");
                    break;
                case CHALLENGE_BID:
                    action = const_cast<char*>((const char*)"challenge_bid");
                    break;
                case CHALLENGE_PASS:
                    action = const_cast<char*>((const char*)"challenge_pass");
                    break;
                case EXACT:
                    action = const_cast<char*>((const char*)"exact");
                    break;
                case PASS:
                    action = const_cast<char*>((const char*)"pass");
                    break;
                case ILLEGAL:
                    action = const_cast<char*>((const char*)"illegal");
                    break;
            }
            
            prev->CreateStringWME("action", action);
            
            if ([roundEnd type] == CHALLENGE_BID || [roundEnd type] == CHALLENGE_PASS)
            {
                
                int challengeValue = [roundEnd value];
                if (static_cast<Identifier *>(playerMap[challengeValue]))
                {
                    prev->CreateSharedIdWME("target", static_cast<Identifier *>(playerMap[challengeValue]));
                }
                
                prev->CreateStringWME("result", [roundEnd result] == 1 ? "success" : "failure");
            }
            else if ([roundEnd type] == EXACT)
            {
                prev->CreateStringWME("result", [roundEnd result] == 1 ? "success" : "failure");
            }
            
            if (i == 1)
            {
                prev->CreateStringWME("next", "nil");
            }
            else
            {
                prev = prev->CreateIdWME("next");
            }
        }
    }
    
    return new DiceSMLData(idState, idPlayers, idAffordances, idHistory, idRounds);
}

- (BOOL) handleAgentCommandsWithGameState:(DiceGameState *)gameState andPlayerID:(int)playerID withNeedsRefreshBool:(BOOL *)needsRefresh withInformation:(turnInformationSentFromTheClient *)info withErrors:(int)errors
{
    turnInformationSentFromTheClient information;
    
    information.action = (ActionsAbleToSend) 0;
    information.bid = nil;
    information.diceToPush = nil;
    information.errorString = nil;
    information.targetOfChallenge = nil;
    
    BOOL agentSlept = NO;
    
    for (int j = 0; j < agent->GetNumberCommands(); j++)
    {
        
        sml::Identifier *ident = agent->GetCommand(j);
        NSString *attrName = [NSString stringWithUTF8String:ident->GetAttribute()];
        NSString *commandStatus = @"";
        if (ident->GetParameterValue("status") != NULL)
            commandStatus = [NSString stringWithUTF8String:ident->GetParameterValue("status")];
        
        if (![commandStatus isEqualToString:@""] && [commandStatus isEqualToString:@"complete"])
        {
            continue;
        }
        
        if (![attrName isEqualToString:@"qna-query"])
        {
            if ([attrName isEqualToString:@"bid"])
            {
                Bid *bid = [[Bid alloc] initWithPlayerID:playerID andThereBeing:[[NSString stringWithUTF8String:ident->GetParameterValue("multiplier")] intValue] eachBeing:[[NSString stringWithUTF8String:ident->GetParameterValue("face")] intValue]];
                information.action = A_BID;
                
                information.bid = bid;
                
                *needsRefresh = YES;
            }
            else if ([attrName isEqualToString:@"exact"])
            {
                information.action = A_EXACT;
                
                *needsRefresh = YES;
            }
            else if ([attrName isEqualToString:@"accept"])
            {
                information.action = (ActionsAbleToSend) -1;
                
                *needsRefresh = YES;
            }
            else if ([attrName isEqualToString:@"push"])
            {
                BOOL goodCommand = YES;
                int faces[ident->GetNumberChildren()];
                
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
                    information.action = A_PUSH;
                    
                    NSMutableArray *muteArray = [[NSMutableArray alloc] init];
                    for (int i = 0;i < ident->GetNumberChildren();i++) {
                        NSNumber *number = [NSNumber numberWithInt:faces[i]];
                        if ([number isKindOfClass:[NSNumber class]]) {
                            Die *newDie = [[Die alloc] initWithNumber:[number intValue]];
                            [newDie autorelease];
                            [muteArray addObject:newDie];
                        }
                    }
                    
                    NSArray *staticArray = [[NSArray alloc] initWithArray:muteArray];
                    [staticArray autorelease];
                    [muteArray release];
                    information.diceToPush = staticArray;
                    
                    *needsRefresh = YES;
                }
            }
            else if ([attrName isEqualToString:@"challenge"])
            {
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
                {
                    if ([[[gameState lastHistoryItem] player] playerID] == target)
                    {
                        if ([[gameState lastHistoryItem] type] == A_PASS)
                            information.action = A_CHALLENGE_PASS;
                        else
                            information.action = A_CHALLENGE_BID;
                    }
                    else if ([[[[gameState history] objectAtIndex:[[gameState history] count] - 2] player] playerID] == target)
                    {
                        HistoryItem* item = [[gameState history] objectAtIndex:[[gameState history] count] - 2];
                        if ([item type] == A_PASS)
                            information.action = A_CHALLENGE_PASS;
                        else
                            information.action = A_CHALLENGE_BID;
                    }
                    else
                    {
                        NSLog(@"Input Link: %s", agent->ExecuteCommandLine("print -d 10 i2"));
                        NSLog(@"Output Link: %s", agent->ExecuteCommandLine("print -d 10 i3"));
                    }
                    
                    information.targetOfChallenge = [[gameState player:target] playerName];
                    
                    *needsRefresh = YES;
                }
            }
            else if ([attrName isEqualToString:@"pass"])
            {
                information.action = A_PASS;
                
                *needsRefresh = YES;
            }
            else if ([attrName isEqualToString:@"sleep"])
            {
                agentSlept = YES;
                information.action = A_SLEEP;
            }
            else
            {
                information.action = (ActionsAbleToSend) -1;
                information.errorString = [@"Wanted to " stringByAppendingString:attrName];
                
                ident->AddStatusError();
            }
            
            if (ident->GetParameterValue("status") == NULL && errors == 0)
                ident->AddStatusComplete();
            else if (errors > 0)
            {
                j--;
                continue;
            }
        }
        else
        {
            //No QNA
        }
    }
    
    *info = information;
    
    return agentSlept;
}

- (void)newRound:(NSArray *)arrayOfDice
{
    
}

- (void)showPublicInformation:(DiceGameState *)gameState
{
    
}

@end
