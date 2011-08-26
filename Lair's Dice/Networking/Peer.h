//
//  Peer.h
//  Lair's Dice
//
//  Created by Alex Turner on 7/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#ifndef PEER_H
#define PEER_H

#import <Foundation/Foundation.h>

#import <GameKit/Gamekit.h>

#import "WifiServer.h"
#import "WifiClient.h"

#ifndef USER_STRUCT
#define USER_STRUCT 1
//User struct containing their name and unique id
typedef struct {
	NSString *name;
	int uniqueID;
} User;
#endif

#define Proto_PeerIDSeperator @"|EndOfID|"

typedef enum {
	NETWORK_ACK,					// no packet
	NETWORK_COINTOSS,				// decide who is going to be the server
	NETWORK_OTHER,				    // other
	NETWORK_HEARTBEAT				// send of entire state at regular intervals
} packetCodes;

@protocol ServerProtocol <NSObject>
@required
- (void)clientConnected:(User)clientName;
- (void)clientDisconnected:(User)clientName;
- (void)clientSentData:(NSString *)data client:(User)client;

- (BOOL)canAcceptConnections;

- (void)showAlert:(NSString *)title withContents:(NSString *)contents;

- (void)showWifi:(BOOL)enabled;
- (void)showBluetooth:(BOOL)enabled;
@end

@protocol ClientProtocol <NSObject>
@required
- (void)connectedToServer:(NSString *)serverName;
- (void)disconnectedFromServer:(NSString *)serverName;

- (void)serverSentData:(NSString *)data;

- (void)canceledPeerPicker;

@property (nonatomic, assign) int uniqueID;
@end

@interface Peer : NSObject <GKPeerPickerControllerDelegate, GKSessionDelegate, WifiServerProtocol, WifiClientProtocol, WifiConnectionDelegate> {
    GKSession		*gameSession;
	int				gameUniqueID;
	int				gamePacketNumber;
	
    NSMutableArray	*gamePeerIds;
    NSMutableDictionary *uniqueIDsToPeerIDs;
    NSMutableDictionary *peerIDsToName;
    NSMutableDictionary    *lastHeartbeatDates;
	
	NSMutableDictionary *peerIDsToUniqueIDs;
    
    id delegate;
    
    NSString *displayName;
	
	//Wifi Stuff
	WifiServer *wifiServer;
	WifiClient *wifiClient;
	
	NSMutableArray *wifiConnections;
	
	BOOL usingWifi;
	
	BOOL localhost;
}

- (id)init:(BOOL)server delegate:(id)delegateForPeer connectToLocalhost:(BOOL)connectToLocalhost;
- (id)init:(BOOL)server;

- (void)invalidateSession:(GKSession *)session;

- (void)sendNetworkPacket:(GKSession *)session packetID:(int)packetID withData:(void *)data ofLength:(int)length reliable:(BOOL)howtosend withPeerID:(NSString *)peerID andUniqueID:(int)uniqueID;

- (void)startPicker;

- (void) goToMainMenu;

- (id)getWifiConnection;

@property(nonatomic, assign) id <NSObject> delegate;

@property(nonatomic, retain) GKSession	  *gameSession;
@property(nonatomic, copy)	 NSMutableArray *gamePeerIds;
@property(nonatomic, retain) NSMutableDictionary *lastHeartbeatDates;
@property(nonatomic, retain) NSMutableDictionary *namesToPeerIDs;
@property(nonatomic, retain) NSMutableDictionary *peerIDsToName;
@property(nonatomic, retain) NSString *displayName;

@end

#endif
