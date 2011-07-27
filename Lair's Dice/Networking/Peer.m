//
//  Peer.m
//  Lair's Dice
//
//  Created by Alex Turner on 7/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Peer.h"

typedef enum {
	kStateStartGame,
	kStatePicker,
	kStateMultiplayer,
	kStateMultiplayerCointoss,
	kStateMultiplayerReconnect
} gameStates;

//
// for the sake of simplicity tank1 is the server and tank2 is the client
//
typedef enum {
	kServer,
	kClient
} gameNetwork;

@implementation Peer

@synthesize gamePeerIds, gameSession, lastHeartbeatDates, namesToPeerIDs, peerIDsToName;

- (id)init:(BOOL)server
{
    self = [super init];
    if (self)
    {
        gameSession = nil;
        
        lastHeartbeatDates = [[NSMutableDictionary alloc] init];
        gamePeerIds = [[NSMutableArray alloc] init];
        namesToPeerIDs = [[NSMutableDictionary alloc] init];
        peerIDsToName = [[NSMutableDictionary alloc] init];
        
        gameUniqueID = (server ? 10 : 0);
    }
    return self;
}

- (void)dealloc
{
    [self invalidateSession:gameSession];
    
    if (gameUniqueID == 10)
        [gameSession release];
    
    gameSession = nil;
    
    [namesToPeerIDs release];
    [gamePeerIds release];
    [peerIDsToName release];
    [lastHeartbeatDates release];
    [super dealloc];
}

-(void)startPicker {
	if (gameUniqueID != 10)
    {
        
        GKPeerPickerController*		picker;
        
        picker = [[GKPeerPickerController alloc] init]; // note: picker is released in various picker delegate methods when picker use is done.
        picker.delegate = self;
        picker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
        [picker show]; // show the Peer Picker
    }
    else
    {
        gameSession = [self peerPickerController:0 sessionForConnectionType:GKPeerPickerConnectionTypeNearby];
        [gameSession retain];
        gameSession.delegate = self;
        [gameSession setDataReceiveHandler:self withContext:NULL];
        gameSession.available = YES;
        gameSession.disconnectTimeout = 500;
    }
}

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker { 
	// Peer Picker automatically dismisses on user cancel. No need to programmatically dismiss.
    
	// autorelease the picker. 
	picker.delegate = nil;
    [picker release]; 
	
	// invalidate and release game session if one is around.
	if(self.gameSession != nil)	{
		[self invalidateSession:self.gameSession];
		self.gameSession = nil;
	}
    
    [delegate canceledPeerPicker];
}

/*
 *	Note: No need to implement -peerPickerController:didSelectConnectionType: delegate method since this app does not support multiple connection types.
 *		- see reference documentation for this delegate method and the GKPeerPickerController's connectionTypesMask property.
 */

//
// Provide a custom session that has a custom session ID. This is also an opportunity to provide a session with a custom display name.
//
- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type { 
	GKSession *session = [[GKSession alloc] initWithSessionID:@"liarsdice" displayName:[[UIDevice currentDevice] name] sessionMode:GKSessionModePeer]; 
    
    if (gameUniqueID == 10)
        session.available = NO;
    
	return [session autorelease]; // peer picker retains a reference, so autorelease ours so we don't leak.
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session { 
	// Remember the current peer.
    
	[gamePeerIds addObject:peerID];  // copy
    [namesToPeerIDs setObject:peerID forKey:[session displayNameForPeer:peerID]];
	
	// Make sure we have a reference to the game session and it is set up
	self.gameSession = session; // retain
	self.gameSession.delegate = self; 
	[self.gameSession setDataReceiveHandler:self withContext:NULL];
	
	// Done with the Peer Picker so dismiss it.
	[picker dismiss];
	picker.delegate = nil;
	[picker autorelease];
}

#pragma mark -
#pragma mark Session Related Methods

//
// invalidate session
//
- (void)invalidateSession:(GKSession *)session {
	if(session != nil) {
		[session disconnectFromAllPeers]; 
		session.available = NO; 
		[session setDataReceiveHandler: nil withContext: NULL]; 
		session.delegate = nil; 
	}
}

#pragma mark Data Send/Receive Methods

/*
 * Getting a data packet. This is the data receive handler method expected by the GKSession. 
 * We set ourselves as the receive data handler in the -peerPickerController:didConnectPeer:toSession: method.
 */
- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context { 
	/*static int lastPacketTime = -1;
     unsigned char *incomingPacket = (unsigned char *)[data bytes];
     int *pIntData = (int *)&incomingPacket[0];
     //
     // developer  check the network time and make sure packers are in order
     //
     int packetTime = pIntData[0];
     int packetID = pIntData[1];
     if(packetTime < lastPacketTime && packetID != NETWORK_COINTOSS) {
     return;	
     }
     
     lastPacketTime = packetTime;
     switch( packetID ) {
     case NETWORK_COINTOSS:
     {
     // coin toss to determine roles of the two players
     int coinToss = pIntData[2];
     // if other player's coin is higher than ours then that player is the server
     if(coinToss > gameUniqueID) {
     NSLog(@"CLIENT!");
     }
     else
     {
     NSLog(@"SERVER!");
     }
     }
     break;
     case NETWORK_OTHER:
     {
     // received a missile fire event from other player, update other player's firing status*/
    if ([data isKindOfClass:[NSMutableData class]] || [data isKindOfClass:[NSData class]])
    {
        NSKeyedUnarchiver *archiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        NSString *newMessage = (NSString *)[archiver decodeObject];
        [archiver release];
        
        if ([newMessage isEqualToString:@"HEARTBEAT"])
            return;
        
        if (gameUniqueID == 10)
            [delegate clientSentData:newMessage client:peer];
        else
            [delegate serverSentData:newMessage];
    }
    /*}
     break;
     case NETWORK_HEARTBEAT:
     {
     // Received heartbeat data with other player's position, destination, and firing status.
     // update heartbeat timestamp
     
     [lastHeartbeatDates removeObjectForKey:peer];
     [lastHeartbeatDates setObject:[NSDate date] forKey:peer];
     }
     break;
     default:
     // error
     break;
     }*/
}

- (void)sendNetworkPacket:(GKSession *)session packetID:(int)packetID withData:(void *)data ofLength:(int)length reliable:(BOOL)howtosend withPeerID:(NSString *)peerID {
	/*// the packet we'll send is resued
     static unsigned char networkPacket[1024];
     const unsigned int packetHeaderSize = 2 * sizeof(int); // we have two "ints" for our header
     
     if(length < (1024 - packetHeaderSize)) { // our networkPacket buffer size minus the size of the header info
     int *pIntData = (int *)&networkPacket[0];
     // header info
     pIntData[0] = gamePacketNumber++;
     pIntData[1] = packetID;
     // copy data in after the header
     memcpy( &networkPacket[packetHeaderSize], data, length ); 
     */
    if ([(id)data isKindOfClass:[NSMutableData class]] || [(id)data isKindOfClass:[NSData class]])
    {
        NSLog(@"Data Mutable: %i\nData Not Mutable: %i", [(id)data isKindOfClass:[NSMutableData class]], [(id)data isKindOfClass:[NSData class]]);
        if(howtosend == YES) { 
            if (gameUniqueID != 10)
            {
                [session sendDataToAllPeers:[NSData dataWithBytes:[(NSData *)data bytes] length:[(NSData *)data length]] withDataMode:GKSendDataReliable error:nil];
            }
            else
            {
                [session sendData:[NSData dataWithBytes:[(NSData *)data bytes] length:[(NSData *)data length]] toPeers:[NSArray arrayWithObjects:peerID, nil] withDataMode:GKSendDataReliable error:nil];
            }
        } else {
            if (gameUniqueID != 10)
            {
                [session sendDataToAllPeers:[NSData dataWithBytes:[(NSData *)data bytes] length:[(NSData *)data length]] withDataMode:GKSendDataUnreliable error:nil];
            }
            else
            {
                [session sendData:[NSData dataWithBytes:[(NSData *)data bytes] length:[(NSData *)data length]] toPeers:[NSArray arrayWithObjects:peerID, nil] withDataMode:GKSendDataReliable error:nil];
            }
        }
    }
	/*}*/
}

#pragma mark GKSessionDelegate Methods

// we've gotten a state change in the session
- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state { 
	/*if(self.gameState == kStatePicker) {
     return;				// only do stuff if we're in multiplayer, otherwise it is probably for Picker
     }*/
	
    if (state == GKPeerStateConnected)
    {
        [namesToPeerIDs setObject:[session displayNameForPeer:peerID] forKey:peerID];
        [peerIDsToName setObject:peerID forKey:[session displayNameForPeer:peerID]];
        
        if (gameUniqueID == 10)
            [delegate clientConnected:peerID];
        else
            [delegate connectedToServer:peerID];
    }
    
	if(state == GKPeerStateDisconnected) {
		// We've been disconnected from the other peer.
        if (gameUniqueID == 10)
            [delegate clientDisconnected:peerID];
        else
            [delegate disconnectedFromServer:peerID];
	} 
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    NSLog(@"Got connection request from %@ whose peerID is %@", [session displayNameForPeer:peerID], peerID);
    if (gameUniqueID == 10)
    {
        if ([delegate canAcceptConnections])
            [session acceptConnectionFromPeer:peerID error:nil];
        else
            [session denyConnectionFromPeer:peerID];
    }
    else
        [session denyConnectionFromPeer:peerID];
}

- (void)setDelegate:(id)class
{
    if ([class conformsToProtocol:@protocol(ServerProtocol)] && gameUniqueID == 0)
        return;
    else if ([class conformsToProtocol:@protocol(ClientProtocol)] && gameUniqueID == 10)
        return;
    
    delegate = class;
}

@end
