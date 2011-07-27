//
//  Peer.h
//  Lair's Dice
//
//  Created by Alex Turner on 7/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GameKit/Gamekit.h>

typedef enum {
	NETWORK_ACK,					// no packet
	NETWORK_COINTOSS,				// decide who is going to be the server
	NETWORK_OTHER,				    // other
	NETWORK_HEARTBEAT				// send of entire state at regular intervals
} packetCodes;

@protocol ServerProtocol <NSObject>
@required
- (void)clientConnected:(NSString *)clientName;
- (void)clientDisconnected:(NSString *)clientName;
- (void)clientSentData:(NSString *)data client:(NSString *)client;

- (BOOL)canAcceptConnections;
@end

@protocol ClientProtocol <NSObject>
@required
- (void)connectedToServer:(NSString *)serverName;
- (void)disconnectedFromServer:(NSString *)serverName;

- (void)serverSentData:(NSString *)data;

- (void)canceledPeerPicker;
@end

@interface Peer : NSObject <GKPeerPickerControllerDelegate, GKSessionDelegate> {
    GKSession		*gameSession;
	int				gameUniqueID;
	int				gamePacketNumber;
	
    NSMutableArray	*gamePeerIds;
    NSMutableDictionary *namesToPeerIDs;
    NSMutableDictionary *peerIDsToName;
    NSMutableDictionary    *lastHeartbeatDates;
    
    id delegate;
}

- (id)init:(BOOL)server;

- (void)invalidateSession:(GKSession *)session;

- (void)sendNetworkPacket:(GKSession *)session packetID:(int)packetID withData:(void *)data ofLength:(int)length reliable:(BOOL)howtosend withPeerID:(NSString *)peerID;

- (void)startPicker;

- (void)setDelegate:(id)delegate;

@property(nonatomic, retain) GKSession	  *gameSession;
@property(nonatomic, copy)	 NSMutableArray *gamePeerIds;
@property(nonatomic, retain) NSMutableDictionary *lastHeartbeatDates;
@property(nonatomic, retain) NSMutableDictionary *namesToPeerIDs;
@property(nonatomic, retain) NSMutableDictionary *peerIDsToName;

@end
