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
#import "GameKitAchievementHandler.h"
#import "ApplicationDelegate.h"

#include <map>
#include <unordered_map>

void printHandler(sml::smlPrintEventId id, void *d, sml::Agent *a, char const *m)
{
	[[NSThread currentThread] setName:@"Soar Agent Thread"];
	
	DiceDatabase* database = [[DiceDatabase alloc] init];
	
	if ([database hasSoarLoggingEnabled])
	{
		NSString* message = [NSString stringWithUTF8String:m];
		
//		NSArray* split = [message componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		
		NSArray *paths = NSSearchPathForDirectoriesInDomains
		(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		
		NSString *fileName = [NSString stringWithFormat:@"%@/SoarLog.log", documentsDirectory];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:fileName])
			[[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil];
		
		NSString* toWrite = [[NSString alloc] initWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil];
		toWrite = [toWrite stringByAppendingString:message];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:fileName])
			[[NSFileManager defaultManager] removeItemAtPath:fileName error:nil];
		
		[toWrite writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
		
//		for (NSString* string in split)
//			DDLogCSoar(@"%@", string);
	}
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

std::unordered_map<unsigned long, sml::Agent*> agents;
dispatch_queue_t agent_queue;

static sml::Kernel* kernel;
static NSLock* kernelLock;

@interface SoarPlayer()

- (DiceSMLData *) GameStateToWM:(sml::Identifier *) inputLink;
- (void) doTurn;

@end

@interface NSThread (empty)

+ (void)stopThread;

@end

@implementation NSThread (empty)

+ (void)stopThread
{
	[[NSThread currentThread] cancel];
	CFRunLoopStop(CFRunLoopGetCurrent());
}

@end

@implementation SoarPlayer

@synthesize name, playerState, playerID, game, turnLock, handler, participant, difficulty;

+ (void)destroyThread:(NSLock*)lock
{
	[kernelLock lock];
	
	sml::Agent* agent = agents[(unsigned long)lock];
	
	if (!agent)
	{
		[kernelLock unlock];
		return;
	}
	
	agents.erase(agents.find((unsigned long)lock));
	
	kernel->DestroyAgent(agent);
	
	[kernelLock unlock];
}

+ (std::unordered_map<unsigned long, sml::Agent*>&) agents
{
	return agents;
}

+ (sml::Kernel*) kernel
{
	return kernel;
}

NSMutableArray* usedNames = [NSMutableArray array];
NSArray* names = [NSArray arrayWithObjects:@"Alice", @"Bob", @"Carol", @"Decker", @"Erin", @"Maize", @"Rosie", @"Sarah", @"Thomas", @"Watson", @"Athena", @"Blue", @"Carter", @"Nyx", @"Ellie", @"Floyd", @"Jane", @"Kirk", @"Hemera", @"Ares", @"Zeus", @"Hades", @"Hera", @"Erebus", @"Sol", @"Vesta", @"Ceres", @"Scylla", @"Vox", @"Aura", @"Angela", @"Jarvis", @"Auto", @"The Bard",  nil];

+ (NSString*) makePlayerName
{
	if ([usedNames count] >= [names count])
		[usedNames removeAllObjects];
	
	NSString* playerName = nil;
	
	do {
		NSUInteger randomIndex = arc4random() % [names count];
		playerName = [names objectAtIndex:randomIndex];
	} while ([usedNames containsObject:playerName]);
	
	[usedNames addObject:playerName];
	
	return playerName;
}

+ (void)initialize
{
	if (self == [SoarPlayer class])
	{
		kernelLock = [[NSLock alloc] init];

		[kernelLock lock];
#ifdef DEBUG
		DiceDatabase* database = [[DiceDatabase alloc] init];

		NSString* remoteIP = [database valueForKey:@"Debug:RemoteIP"];

		if (remoteIP && [remoteIP length] != 0)
		{
			const char* ipAddress = [remoteIP UTF8String];

			kernel = sml::Kernel::CreateRemoteConnection(true, ipAddress);
		}
		else
			kernel = sml::Kernel::CreateKernelInNewThread(sml::Kernel::kSuppressListener);
#else
		kernel = sml::Kernel::CreateKernelInNewThread(sml::Kernel::kSuppressListener);
#endif
        
		agent_queue = dispatch_queue_create("edu.umich.Soar", NULL);

		if (kernel->HadError())
		{
			DDLogError(@"Kernel: %s", kernel->GetLastErrorDescription());
			kernel = nil;
		}

		[kernelLock unlock];
	}
}

- (id)initWithGame:(DiceGame*)aGame connentToRemoteDebugger:(BOOL)connect lock:(NSLock *)aLock withGameKitGameHandler:(GameKitGameHandler*)gkgHandler difficulty:(int)diff
{
	return [self initWithGame:aGame connentToRemoteDebugger:connect lock:aLock withGameKitGameHandler:gkgHandler difficulty:diff name:[SoarPlayer makePlayerName]];
}

- (void)runLoop
{
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    
    NSMachPort *dummyPort = [[NSMachPort alloc] init];
    [runLoop addPort:dummyPort forMode:NSDefaultRunLoopMode];
    
    while (![[NSThread currentThread] isCancelled])
        [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
}

- (id)initWithGame:(DiceGame*)aGame connentToRemoteDebugger:(BOOL)connect lock:(NSLock *)aLock withGameKitGameHandler:(GameKitGameHandler*)gkgHandler difficulty:(int)diff name:(NSString*)aName;
{
    self = [super init];
    if (self)
	{
        self.turnLock = aLock;
        self.game = aGame;
		handler = gkgHandler;
		didNotify = NO;

		DiceDatabase* database = [[DiceDatabase alloc] init];

        [turnLock lock];

        self.name = aName;

		if (!self.name)
			name = [SoarPlayer makePlayerName];

		if (agents.find((unsigned long)aLock) == agents.end())
		{
			[kernelLock lock];
			// No Agent created yet for this lock
			agents[(unsigned long)aLock] = kernel->CreateAgent([[NSString stringWithFormat:@"Soar-%p-%f", aLock, [[NSDate date] timeIntervalSince1970]] UTF8String]);

			if (agents[(unsigned long)aLock] == NULL)
			{
				DDLogError(@"Kernel (Agent Creation): %s", kernel->GetLastErrorDescription());
				[turnLock unlock];
				return nil;
			}
            
			agents[(unsigned long)aLock]->RegisterForPrintEvent(sml::smlEVENT_PRINT, printHandler, NULL);

			NSUInteger seed = aGame.randomGenerator->integerSeed;

			if (aGame.randomGenerator->integerSeed == NO_SEED)
				seed = [aGame.randomGenerator randomNumber];

            DDLogDebug(@"Agent Seed: %lu", (unsigned long)seed);
			agents[(unsigned long)aLock]->ExecuteCommandLine([[NSString stringWithFormat:@"srand %lu", (unsigned long)seed] UTF8String]);

			NSString *path;

			// This is where we specify the root .soar file that will source the Soar agent.
			// We want this to be dice-agent-new, but right now that breaks the agent
			// so we're loading dice-p0-m0-c0 instead.

			if (diff == -1)
				difficulty = (int)[database getDifficulty]; // Safe conversion due to difficulties not requiring long precision (there is only a couple)
			else
				difficulty = diff;

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

			if (!kernel->IsRemoteConnection())
			{
				path = [NSString stringWithFormat:@"source \"%@\"", [[NSBundle mainBundle] pathForResource:ruleFile ofType:@"soar" inDirectory:@""]];

				std::string result = agents[(unsigned long)aLock]->ExecuteCommandLine([path UTF8String]);
				
				if ([database hasSoarLoggingEnabled])
					std::cout << result << std::endl;
			}
			else
			{
				path = [NSString stringWithFormat:@"source \"/Users/bluechill/Developer/SoarGroupProjects/SoarDice-iOS/src/Soar Agent/%@.soar\"", ruleFile];

				std::cout << agents[(unsigned long)aLock]->ExecuteCommandLine([path UTF8String]) << std::endl;

				path = [NSString stringWithFormat:@"source \"/LiarsDice/%@.soar\"", ruleFile];

				std::cout << agents[(unsigned long)aLock]->ExecuteCommandLine([path UTF8String]) << std::endl;
			}
			[kernelLock unlock];

			DDLogCSoar(@"Path: %@", path);

			if (![database hasSoarLoggingEnabled])
				std::cout << agents[(unsigned long)aLock]->ExecuteCommandLine("watch 0") << std::endl;
			else
				std::cout << agents[(unsigned long)aLock]->ExecuteCommandLine("watch 5") << std::endl;
			
			agents[(unsigned long)aLock]->InitSoar();
		}

		[turnLock unlock];
    }
    return self;
}

- (void) end
{}

- (void)itsYourTurn
{
	DiceDatabase* database = [[DiceDatabase alloc] init];
	
	if ([database hasSoarLoggingEnabled])
	{
		NSArray *paths = NSSearchPathForDirectoriesInDomains
		(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		
		NSString *fileName = [NSString stringWithFormat:@"%@/SoarLog.log", documentsDirectory];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:fileName])
			[[NSFileManager defaultManager] removeItemAtPath:fileName error:nil];
	}
	
	dispatch_async(agent_queue, ^{
		[self doTurn];
	});
}

- (void)showErrorAlert
{
	if (![NSThread isMainThread])
	{
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self showErrorAlert];
		});

		return;
	}
	
	NSLog(@"Soar Crash!");

	[[[UIAlertView alloc] initWithTitle:@"Soar Error!" message:@"Unfortunately, Soar has encountered an error in processing and reasoning.  Please report an issue at github.com/SoarGroup/Domains-DiceiOS/issues.  Please exit the game, go to settings, and tap \"Send Log Files.\"  This will send us the logs for the last game and any additional details, such as the log file for Soar if enabled." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil]  show];

	DiceGame* localGame = self.game;
	ApplicationDelegate* delegate = localGame.appDelegate;
	[delegate.achievements updateAchievements:nil];
}

- (void) restartSoar
{
	[self showErrorAlert];

	PlayerState* localState = self.playerState;
	DiceGameState* state = localState.gameState;

	[state playerLosesRound:self.playerID];
	[state createNewRound];

	id <Player> gameWinner = state.gameWinner;
	if (gameWinner)
		[gameWinner notifyHasWon];
}

- (void) doTurn
{
	[[NSThread currentThread] setName:@"Soar Agent Turn Thread"];

	DiceGame* localGame = self.game;
	PlayerState* localState = self.playerState;
	if ([[NSThread currentThread] isCancelled] || localGame.gameState.currentTurn != self.playerID || localGame.gameState.hasAPlayerWonTheGame || localState.hasLost)
		return;
	
    [turnLock lock];

	agents[(unsigned long)turnLock]->InitSoar();

//    DDLogCSoar(@"Agent do turn");
	
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
            
            newData = [self GameStateToWM:agents[(unsigned long)turnLock]->GetInputLink()];

            needsRefresh = NO;
        }

		double startTime = [[NSDate date] timeIntervalSince1970];

        do {
			if (localGame.gameState.hasAPlayerWonTheGame || localState.hasLost)
			{
				[turnLock unlock];
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
				return;
			}
			
			if (!agentInterrupted)
			{
				DDLogDebug(@"Input Link: %s", agents[(unsigned long)turnLock]->ExecuteCommandLine("p -d 100 s1"));
				agents[(unsigned long)turnLock]->RunSelfTilOutput();
				DDLogDebug(@"Awesome");
			}
            
            sml::smlRunState agentState = agents[(unsigned long)turnLock]->GetRunState();
            agentHalted = agentState == sml::sml_RUNSTATE_HALTED;

			agentInterrupted = agentState == sml::sml_RUNSTATE_INTERRUPTED;

			int timeoutLimit = 15;
			
			if ([[[DiceDatabase alloc] init] hasSoarLoggingEnabled])
				timeoutLimit = 120;
			
			if (!agentInterrupted && (startTime + timeoutLimit) < [[NSDate date] timeIntervalSince1970])
			{
				[turnLock unlock];

				DDLogDebug(@"Restarting Soar due to timeout");
				
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
				
				if (((ApplicationDelegate*)[UIApplication sharedApplication].delegate)->isSoarOnlyRunning)
					return [self showErrorAlert];

				return [self restartSoar];
			}

			if (agentInterrupted)
			{
				const char* printResult = agents[(unsigned long)turnLock]->ExecuteCommandLine("p -sS");

				NSString* printString = [NSString stringWithUTF8String:printResult];
				NSInteger lines = [[printString componentsSeparatedByCharactersInSet:
									[NSCharacterSet newlineCharacterSet]] count];
				
				DiceDatabase* database = [[DiceDatabase alloc] init];
				if (lines > 95 && ![database hasSoarLoggingEnabled])
				{
					[turnLock unlock];
					
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

					DDLogDebug(@"Restarting Soar due to goal stack depth exceeded");
					
					if (((ApplicationDelegate*)[UIApplication sharedApplication].delegate)->isSoarOnlyRunning)
						return [self showErrorAlert];

					return [self restartSoar];
				}
				else if (lines > 95 && [database hasSoarLoggingEnabled])
					return [self showErrorAlert];
			}
			
			if ([[NSThread currentThread] isCancelled])
			{
				[turnLock unlock];
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
				return;
			}
        } while (!agentHalted && (agents[(unsigned long)turnLock]->GetNumberCommands() == 0));
        
        if (agents[(unsigned long)turnLock]->GetNumberCommands() != 0)
            [self handleAgentCommandsWithRefresh:&needsRefresh sleep:&agentSlept];
		
		if ([[NSThread currentThread] isCancelled])
		{
			[turnLock unlock];
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
			return;
		}
    } while (!agentSlept);

//	DDLogCSoar(@"Halting agent");
	sml::WMElement *halter = NULL;
	if (!agentHalted)
	{
		halter = agents[(unsigned long)turnLock]->GetInputLink()->CreateStringWME("halt", "now");
		agents[(unsigned long)turnLock]->RunSelfTilOutput();
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

//    DDLogCSoar(@"Agent done");

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
 
//    DDLogCSoar(@"Beginning GameStateToWM");
	
    Identifier *idState = NULL;
    Identifier *idPlayers = NULL;
    Identifier *idAffordances = NULL;
    WMElement *idHistory = NULL;
    WMElement *idRounds = NULL;
    
    idState = inputLink->CreateIdWME("state");
    idPlayers = inputLink->CreateIdWME("players");
    idAffordances = inputLink->CreateIdWME("affordances");

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
		id <Player> gameWinner = gameState.gameWinner;
        victorID = [gameWinner getID];
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
		NSString* playerIDString = [playerThing getGameCenterName];

		if (playerIDString == nil || [playerIDString isEqualToString:@"Soar"])
			playerIDString = [playerThing getDisplayName];

        PlayerState *player = [gameState getPlayerState:[playerThing getID]];
        Identifier *playerId = idPlayers->CreateIdWME("player");
        playerId->CreateIntWME("id", [player playerID]);
        playerId->CreateStringWME("name", [playerIDString UTF8String]);
        playerId->CreateStringWME("exists", ([player hasLost] ? "false" : "true"));
        Identifier *cup = playerId->CreateIdWME("cup");
        
        if (localState == player)
        {
            if ([[player unPushedDice] count] > 0)
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

        if ([pushedDice count] > 0)
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
    bid->CreateStringWME("name", "bid");
    bid->CreateStringWME("available", ([localState canBid] ? "true" : "false"));
    
    Identifier *challenge = idAffordances->CreateIdWME("action");
    challenge->CreateStringWME("name", "challenge");
    
    BOOL canChallengeBid = [localState canChallengeBid];
    BOOL canChallengePass = [localState canChallengeLastPass];
    
    challenge->CreateStringWME("available", (canChallengeBid || canChallengePass) ? "true" : "false");
    
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
        if (target != -1 && target != self.playerID)
            challenge->CreateSharedIdWME("target", static_cast<Identifier *>(playerMap[target]));
    }
    
    Identifier *exact = idAffordances->CreateIdWME("action");
    exact->CreateStringWME("name", "exact");
    exact->CreateStringWME("available", ([localState canExact] ? "true" : "false"));
    
    Identifier *pass = idAffordances->CreateIdWME("action");
    pass->CreateStringWME("name", "pass");
    pass->CreateStringWME("available", ([localState canPass] ? "true" : "false"));
    
    Identifier *push = idAffordances->CreateIdWME("action");
    push->CreateStringWME("name", "push");
    push->CreateStringWME("available", ([localState canPush] ? "true" : "false"));
    
    Identifier *accept = idAffordances->CreateIdWME("action");
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
				case ACTION_LOST:
					action = const_cast<char*>((const char*)"lost");
					break;
				case ACTION_QUIT:
					action = const_cast<char*>((const char*)"quit");
					break;
				default:
				{
                    action = const_cast<char*>((const char*)"");
					DDLogDebug(@"Impossible Situation? SoarPlayer.mm:810");
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
				case ACTION_LOST:
					action = const_cast<char*>((const char*)"lost");
					break;
				case ACTION_QUIT:
					action = const_cast<char*>((const char*)"quit");
					break;
				default:
				{
                    action = const_cast<char*>((const char*)"");

					DDLogDebug(@"Impossible Situation? SoarPlayer.mm:921");
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
            }
        }
    }
//        DDLogCSoar(@"Ending GameStateToWM");
    return new DiceSMLData(idState, idPlayers, idAffordances, idHistory, idRounds);
}

// Should only be called if turnLock is locked.
- (void) handleAgentCommandsWithRefresh:(BOOL *)needsRefresh sleep:(BOOL *)sleep;
{
//    DDLogCSoar(@"Agent handling agent commands");
    *sleep = NO;
    DiceAction *action = nil;
    NSArray *diceToPush = nil;
    for (int j = 0; j < agents[(unsigned long)turnLock]->GetNumberCommands(); j++)
    {
        sml::Identifier *ident = agents[(unsigned long)turnLock]->GetCommand(j);
        NSString *attrName = [NSString stringWithUTF8String:ident->GetAttribute()];

//        DDLogCSoar(@"Command from output link, j=%d, command=%@", j, attrName);
		
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
				// Hack
				*sleep = YES;

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
                            [mut addObject:[[Die alloc] initWithNumber:[number intValue] withIdentifier:-1]];
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
                DiceGame* localGame = self.game;
                [localGame notifyCurrentPlayer];
				return;
            }
            else
            {
				DDLogError(@"Error: agent attempted to use command \"%@\"", attrName);
                
                ident->AddStatusError();
            }
            
            if (ident->GetParameterValue("status") == NULL /* && errors == 0 */)
            {
                ident->AddStatusComplete();
            }
        }
        else
        {}
    }

	GameKitGameHandler* localHandler = self.handler;
	DiceGame* localGame = self.game;

    if (action != nil)
    {
//        DDLogCSoar(@"Agent performing action: %@", action);
        if (diceToPush != nil)
        {
//            DDLogCSoar(@"Pushing dice: %@", diceToPush);
            action.push = diceToPush;
        }

		[turnLock unlock];
		[localGame handleAction:action notify:NO];
		[turnLock lock];
        *needsRefresh = YES;
    }
    else if (diceToPush != nil)
    {
//        DDLogCSoar(@"Agent just pushing, %@", diceToPush);
        DiceAction *new_action = [DiceAction pushAction:self.playerID push:diceToPush];

		[turnLock unlock];
		[localGame handleAction:new_action notify:YES];
		[turnLock lock];
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
	return [NSString stringWithFormat:@"Soar-%@", self.name];
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

- (NSDictionary*)dictionaryValue
{
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	
	[dictionary setValue:[NSNumber numberWithInteger:playerID] forKey:@"playerID"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"localPlayer"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"soarPlayer"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"remotePlayer"];
	[dictionary setValue:[NSNumber numberWithInt:difficulty] forKey:@"difficultySetting"];
	
	return dictionary;
}

@end
