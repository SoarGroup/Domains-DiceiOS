//
//  GameKitGameHandler.m
//  UM Liars Dice
//
//  Created by Alex Turner on 5/8/14.
//
//

#import "GameKitGameHandler.h"
#import "SoarPlayer.h"
#import "MultiplayerMatchData.h"
#import "PlayGameView.h"
#import "ApplicationDelegate.h"

#import "bzlib.h"

@implementation GameKitGameHandler

+ (NSData *)bzip2:(NSData*)data
{
	int bzret, buffer_size = 1000000;
	bz_stream stream = { 0 };
	stream.next_in = (char*)[data bytes];
	stream.avail_in = (unsigned int)[data length];
	unsigned int compression = 9; // should be a value between 1 and 9 inclusive
	
	NSMutableData * buffer = [NSMutableData dataWithLength:buffer_size];
	stream.next_out = [buffer mutableBytes];
	stream.avail_out = buffer_size;
	
	NSMutableData * compressed = [NSMutableData data];
	
	BZ2_bzCompressInit(&stream, compression, 0, 0);
	@try {
		do {
			bzret = BZ2_bzCompress(&stream, (stream.avail_in) ? BZ_RUN : BZ_FINISH);
			if (bzret != BZ_RUN_OK && bzret != BZ_STREAM_END)
				@throw [NSException exceptionWithName:@"bzip2" reason:@"BZ2_bzCompress failed" userInfo:nil];
			
			[compressed appendBytes:[buffer bytes] length:(buffer_size - stream.avail_out)];
			stream.next_out = [buffer mutableBytes];
			stream.avail_out = buffer_size;
		} while(bzret != BZ_STREAM_END);
	}
	@finally {
		BZ2_bzCompressEnd(&stream);
	}
	
	return compressed;
}

+ (NSData *)bunzip2:(NSData*)data
{
	if ([data length] == 0)
		return nil;
	
	int bzret;
	bz_stream stream = { 0 };
	stream.next_in = (char*)[data bytes];
	stream.avail_in = (unsigned int)[data length];
	
	const int buffer_size = 10000;
	NSMutableData * buffer = [NSMutableData dataWithLength:buffer_size];
	stream.next_out = [buffer mutableBytes];
	stream.avail_out = buffer_size;
	
	NSMutableData * decompressed = [NSMutableData data];
	
	BZ2_bzDecompressInit(&stream, 0, NO);
	@try {
		do {
			bzret = BZ2_bzDecompress(&stream);
			if (bzret != BZ_OK && bzret != BZ_STREAM_END)
				@throw [NSException exceptionWithName:@"bzip2" reason:@"BZ2_bzDecompress failed" userInfo:nil];
			
			[decompressed appendBytes:[buffer bytes] length:(buffer_size - stream.avail_out)];
			stream.next_out = [buffer mutableBytes];
			stream.avail_out = buffer_size;
		} while(bzret != BZ_STREAM_END);
	}
	@finally {
		BZ2_bzDecompressEnd(&stream);
	}
	
	return decompressed;
}

+ (NSData*)archiveAndCompressObject:(NSObject*)object
{
	NSData* archive = [NSKeyedArchiver archivedDataWithRootObject:object];
	return [GameKitGameHandler bzip2:archive];
}

+ (NSObject*)uncompressAndUnarchiveObject:(NSData*)data
{
	NSData* uncompressed;
	@try {
		uncompressed = [GameKitGameHandler bunzip2:data];
	}
	@catch (NSException *exception) {
		return nil;
	}
	return [NSKeyedUnarchiver unarchiveObjectWithData:uncompressed];
}

@synthesize localPlayer, remotePlayers, match, participants, localGame;

- (id)initWithDiceGame:(DiceGame*)lGame withLocalPlayer:(DiceLocalPlayer*)lPlayer withRemotePlayers:(NSArray*)rPlayers withMatch:(GKTurnBasedMatch *)gkMatch
{
	self = [super init];

	if (self)
	{
		self.localGame = lGame;
		self.localPlayer = lPlayer;
		self.remotePlayers = rPlayers;
		matchHasEnded = NO;
		match = gkMatch;

		participants = [match participants];
	}

	return self;
}

- (void) saveMatchData
{
	if (matchHasEnded || ![[[match currentParticipant] player].playerID isEqualToString:[[GKLocalPlayer localPlayer] playerID]])
		return;

	NSData* updatedMatchData = [GameKitGameHandler archiveAndCompressObject:localGame];

	ApplicationDelegate* delegate = [UIApplication sharedApplication].delegate;
	DDLogGameKit(@"Updated Match Data SHA1 Hash: %@", [delegate sha1HashFromData:updatedMatchData]);

	[match saveCurrentTurnWithMatchData:updatedMatchData completionHandler:^(NSError* error)
	{
		DDLogGameKit(@"Sent match data!");

		if (error)
			DDLogError(@"Error upon saving match data: %@\n", error.description);
	}];
}

- (void) updateMatchData
{
	if (matchHasEnded)
		return;

	if (!self.remotePlayers)
	{
		NSMutableArray* remotes = [[NSMutableArray alloc] init];
		for (DiceRemotePlayer* player in self.localGame.players)
		{
			if ([player isKindOfClass:DiceRemotePlayer.class])
				[remotes addObject:player];
		}

		self.remotePlayers = remotes;
	}

	[match loadMatchDataWithCompletionHandler:^(NSData* matchData, NSError* error)
	 {
		 if (!error)
		 {
			 for (int i = 0;i < [self->match.participants count];++i)
			 {
				 GKTurnBasedParticipant* p = [self->match.participants objectAtIndex:i];
				 NSString* oldPlayerID = ((GKTurnBasedParticipant*)[self->participants objectAtIndex:i]).player.playerID;
				 NSString* newPlayerID = p.player.playerID;

				 if ((oldPlayerID == nil && newPlayerID != nil) ||
					 ![oldPlayerID isEqualToString:newPlayerID])
				 {
					 NSMutableArray* array = [NSMutableArray arrayWithArray:self->participants];

					 [array replaceObjectAtIndex:i withObject:p];

					 self->participants = array;

					 for (DiceRemotePlayer* remote in self->remotePlayers)
					 {
						 NSString* remotePlayerID = [remote getGameCenterName];
						 if ((remotePlayerID == nil && oldPlayerID == nil) ||
							 [remotePlayerID isEqualToString:oldPlayerID])
						 {
							 [remote setParticipant:p];
							 break;
						 }
					 }
				 }
			 }

			 ApplicationDelegate* delegate = [UIApplication sharedApplication].delegate;
			 DDLogGameKit(@"Updated Match Data Retrieved SHA1 Hash: %@", [delegate sha1HashFromData:matchData]);

			 DiceGame* updatedGame = (DiceGame*)[GameKitGameHandler uncompressAndUnarchiveObject:matchData];

			 [updatedGame.gameState decodePlayers:self->match withHandler:self];

			 if (updatedGame.gameState.players &&
				 [updatedGame.gameState.players count] > 0)
				 updatedGame.players = [NSArray arrayWithArray:updatedGame.gameState.players];

			 updatedGame.gameState.players = updatedGame.players;

			 [self->localGame updateGame:updatedGame];
		 }
		 else
			 DDLogError(@"Error upon loading match data: %@\n", error.description);
	 }];
}

- (void) matchHasEnded
{
	matchHasEnded = YES;

	[localGame end];
}

- (void) advanceToRemotePlayer:(DiceRemotePlayer*)player
{
	if (matchHasEnded)
		return;

	NSData* updatedMatchData = [GameKitGameHandler archiveAndCompressObject:localGame];

	ApplicationDelegate* delegate = [UIApplication sharedApplication].delegate;
	DDLogGameKit(@"Updated Match Data SHA1 Hash: %@", [delegate sha1HashFromData:updatedMatchData]);

	NSMutableArray* nextPlayers = [NSMutableArray arrayWithArray:participants];

	for (int i = 0;i < nextPlayers.count;++i)
	{
		GKTurnBasedParticipant* p = [nextPlayers objectAtIndex:i];
		if (!p.player.playerID || [p.player.playerID isEqualToString:[player getGameCenterName]])
		{
			[nextPlayers removeObjectAtIndex:i];
			[nextPlayers insertObject:p atIndex:0];
			break;
		}
	}

	for (GKTurnBasedParticipant* p in nextPlayers)
	{
		NSString* gID = p.player.playerID;

		for (PlayerState* state in localGame.gameState.playerStates)
		{
			BOOL equal = [[[state playerPtr] getGameCenterName] isEqualToString:gID];

			if (!equal)
				continue;

			if ([state hasLost])
				p.matchOutcome = GKTurnBasedMatchOutcomeLost;
			else if ([state hasWon])
				p.matchOutcome = GKTurnBasedMatchOutcomeWon;
			else
				p.matchOutcome = GKTurnBasedMatchOutcomeNone;

			break;
		}
	}

	DDLogDebug(@"Next Players: %@", nextPlayers);

	[match endTurnWithNextParticipants:nextPlayers turnTimeout:172800 /*2 days*/ matchData:updatedMatchData completionHandler:^(NSError* error)
	 {
		 if (error)
			 DDLogError(@"Error advancing to next player: %@\n", error.description);
	 }];
}

- (GKTurnBasedParticipant*)myParticipant
{
	for (GKTurnBasedParticipant* participant in [match participants])
	{
		if ([participant player].playerID == [[GKLocalPlayer localPlayer] playerID])
			return participant;
	}

	return nil;
}

- (void) playerQuitMatch:(id<Player>)player withRemoval:(BOOL)remove
{
	if (matchHasEnded)
		return;

	if ([player isKindOfClass:SoarPlayer.class])
		[self saveMatchData];
	else if ([player isKindOfClass:DiceLocalPlayer.class])
	{
		NSMutableArray* localParticipants = [[NSMutableArray alloc] init];

		for (GKTurnBasedParticipant* participant in [match participants])
		{
			if (participant != [self myParticipant])
				[localParticipants addObject:participant];
		}

		GKTurnBasedMatchOutcome outcome;

		PlayerState* state = [[localGame gameState] getPlayerState:[player getID]];

		if ([state hasLost])
			outcome = GKTurnBasedMatchOutcomeLost;
		else
			outcome = GKTurnBasedMatchOutcomeQuit;

		void (^completionHandler)(NSError* error) = ^(NSError* error){
			if (error)
				DDLogError(@"Error when player quit: %@\n", error.description);

			if (remove)
				[self->match removeWithCompletionHandler:^(NSError* removeError)
				 {
					 if (removeError)
						 DDLogError(@"Error Removing Match: %@\n", removeError.description);
				 }];
		};

		if ([[match currentParticipant].player.playerID isEqual:[GKLocalPlayer localPlayer].playerID])
			[match participantQuitInTurnWithOutcome:outcome nextParticipants:localParticipants turnTimeout:172800 /* 2 days */ matchData:[GameKitGameHandler archiveAndCompressObject:localGame] completionHandler:completionHandler];
		else
			[match participantQuitOutOfTurnWithOutcome:outcome withCompletionHandler:completionHandler];
	}
}

- (BOOL) endMatchForAllParticipants
{
	if (matchHasEnded)
		return YES;

	for (GKTurnBasedParticipant* gktbp in match.participants)
	{
		PlayerState* state = nil;

		for (PlayerState* other in [[localGame gameState] playerStates])
		{
			if ([[[localGame.players objectAtIndex:other.playerID] getGameCenterName] isEqualToString:[gktbp player].playerID])
			{
				state = other;
				break;
			}
		}

		if ([state hasLost])
			gktbp.matchOutcome = GKTurnBasedMatchOutcomeLost;
		else if ([state hasWon])
			gktbp.matchOutcome = GKTurnBasedMatchOutcomeWon;
		else if (![state hasWon] && ![state hasLost])
			gktbp.matchOutcome = GKTurnBasedMatchOutcomeQuit;
	}

	[match endMatchInTurnWithMatchData:[GameKitGameHandler archiveAndCompressObject:localGame] completionHandler:^(NSError* error)
	 {
		 if (error)
			 DDLogError(@"Error ending match: %@\n", error.description);
	 }];

	return YES;
}

- (GKTurnBasedMatch*)getMatch
{
	return match;
}

@end
