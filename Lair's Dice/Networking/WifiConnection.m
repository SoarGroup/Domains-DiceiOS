//
//  WifiConnection.m
//  Lair's Dice
//
//  Created by Alex Turner on 8/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

//Based off of MIT licensed code made by Peter Bakhyryev

#import "WifiConnection.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <CFNetwork/CFSocketStream.h>

//C Function handlers for CF events
void readStreamHandler(CFReadStreamRef stream, CFStreamEventType eventType, void *info);
void writeStreamHandler(CFWriteStreamRef stream, CFStreamEventType eventType, void *info);

@interface WifiConnection ()

@property (nonatomic,assign) int port;
@property (nonatomic,assign) CFSocketNativeHandle connectionHandle;

- (void)clean;

- (BOOL)setupSocketStreams;

- (void)readStreamHandleEvent:(CFStreamEventType)event;
- (void)writeStreamHandleEvent:(CFStreamEventType)event;

- (void)readFromStreamIntoIncomingBuffer;

- (void)writeOutgoingBufferToStream;

@end

@implementation WifiConnection

@synthesize connectionDelegate;
@synthesize host, port;
@synthesize connectionHandle;
@synthesize bonjourNetService;
@synthesize hasConnected;

- (void)clean
{
	readStream = nil;
	isReadStreamOpen = NO;
	
	writeStream = nil;
	isWriteStreamOpen = NO;
	
	incomingDataBuffer = nil;
	outgoingDataBuffer = nil;
	
	bonjourNetService = nil;
	host = nil;
	
	connectionHandle = -1;
	packetBodySize = -1;
}

- (void)dealloc
{
	[self clean];
	
	if (host)
		[host release];
	
	host = nil;
	port = -1;
	connectionDelegate = nil;
	
	[super dealloc];
}

- (id)initWithHostAddress:(NSString *)_host andPort:(int)_port
{
	self = [super init];
	if (self)
	{
		[self clean];
		
		self.host = _host;
		self.port = _port;
	}
	
	return self;
}

- (id)initWithNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle
{
	self = [super init];
	if (self)
	{
		[self clean];
		
		self.connectionHandle = nativeSocketHandle;
	}
	
	return self;
}

- (id)initWithNetService:(NSNetService *)netService
{
	[self clean];
	
	if ([netService hostName] != nil)
	{
		return [self initWithHostAddress:[netService hostName] andPort:[netService port]];
	}
	
	self.bonjourNetService = netService;
	
	return self;
}

- (BOOL)connect
{
	hasClosed = NO;
	hasConnected = YES;
	
	if ( host != nil ) {
		CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (CFStringRef)self.host,
										   self.port, &readStream, &writeStream);
		
		return [self setupSocketStreams];
	}
	else if ( connectionHandle != -1 ) {
		CFStreamCreatePairWithSocket(kCFAllocatorDefault, connectionHandle,
									 &readStream, &writeStream);
		
		// Do the rest
		return [self setupSocketStreams];
	}
	else if ( bonjourNetService != nil ) {
		if ( bonjourNetService.hostName != nil ) {
			CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
											   (CFStringRef)bonjourNetService.hostName, bonjourNetService.port, &readStream, &writeStream);
			return [self setupSocketStreams];
		}
		
		// Start resolving
		bonjourNetService.delegate = self;
		[bonjourNetService resolveWithTimeout:5.0];
		return YES;
	}
	
	return NO;
}

- (BOOL)setupSocketStreams
{
	if (readStream == nil || writeStream == nil)
	{
		[self close];
		
		return NO;
	}
	
	incomingDataBuffer = [[NSMutableData alloc] init];
	outgoingDataBuffer = [[NSMutableData alloc] init];
	
	CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
	CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
	
	CFOptionFlags registeredEvents =	kCFStreamEventOpenCompleted |
	kCFStreamEventHasBytesAvailable |
	kCFStreamEventCanAcceptBytes |
	kCFStreamEventEndEncountered |
	kCFStreamEventErrorOccurred;
	
	CFStreamClientContext clientContex = { 0, self, NULL, NULL };
	
	CFReadStreamSetClient(readStream, registeredEvents, readStreamHandler, &clientContex);
	CFWriteStreamSetClient(writeStream, registeredEvents, writeStreamHandler, &clientContex);
	
	CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	CFWriteStreamScheduleWithRunLoop(writeStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	
	if (!CFReadStreamOpen(readStream) || !CFWriteStreamOpen(writeStream))
	{
		[self close];
		return NO;
	}
	
	if (!host)
	{
		struct sockaddr_storage peer;
		socklen_t peerlen = sizeof(peer);
		
		char ip_addr[INET6_ADDRSTRLEN];
		
		if (getpeername(connectionHandle, (struct sockaddr *)&peer, &peerlen) == 0) {
			if (peer.ss_family == AF_INET) {
				struct sockaddr_in *s = (struct sockaddr_in *)&peer;
				port = ntohs(s->sin_port);
				inet_ntop(AF_INET, &s->sin_addr, ip_addr, sizeof(ip_addr));
			} else {
				struct sockaddr_in6 *s = (struct sockaddr_in6 *)&peer;
				port = ntohs(s->sin6_port);
				inet_ntop(AF_INET6, &s->sin6_addr, ip_addr, sizeof(ip_addr));
			}
		}
		
		host = [[NSString stringWithUTF8String:ip_addr] retain];
	}
	
	return YES;
}

- (void)close
{
	if (hasClosed)
		return;
	
	if (readStream != nil) {
		CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
		CFReadStreamClose(readStream);
		CFRelease(readStream);
		readStream = NULL;
	}
	
	if (writeStream != nil) {
		CFWriteStreamUnscheduleFromRunLoop(writeStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
		CFWriteStreamClose(writeStream);
		CFRelease(writeStream);
		writeStream = NULL;
	}
	
	[incomingDataBuffer release];
	incomingDataBuffer = NULL;
	
	[outgoingDataBuffer release];
	outgoingDataBuffer = NULL;
	
	if ( bonjourNetService != nil ) {
		[bonjourNetService stop];
		bonjourNetService = nil;
	}
	
	[self clean];
	
	hasClosed = YES;
}

- (void)sendNetworkPacket:(NSData *)packet
{
	NSData* rawPacket = packet;
	
	int packetLength = [rawPacket length];
	[outgoingDataBuffer appendBytes:&packetLength length:sizeof(int)];
	
	[outgoingDataBuffer appendData:rawPacket];
	
	[self writeOutgoingBufferToStream];
}

//C Functions for the read & write stream handlers
void readStreamHandler(CFReadStreamRef stream, CFStreamEventType eventType, void *info)
{
	WifiConnection *connection = (WifiConnection *)info;
	[connection readStreamHandleEvent:eventType];
}

void writeStreamHandler(CFWriteStreamRef stream, CFStreamEventType eventType, void *info)
{
	WifiConnection *connection = (WifiConnection *)info;
	[connection writeStreamHandleEvent:eventType];
}

- (void)readStreamHandleEvent:(CFStreamEventType)event
{
	if (event == kCFStreamEventOpenCompleted)
	{
		isReadStreamOpen = YES;
		
		return;
	}
	
	if (event == kCFStreamEventHasBytesAvailable)
	{
		[self readFromStreamIntoIncomingBuffer];
		
		return;
	}
	
	if (event == kCFStreamEventEndEncountered || event == kCFStreamEventErrorOccurred)
	{
		[self close];
		
		if ( !isReadStreamOpen || !isWriteStreamOpen )
			[connectionDelegate connectionAttemptFailed:self];
		else
			[connectionDelegate connectionTerminated:self];
		
		return;
	}
}

- (void)readFromStreamIntoIncomingBuffer
{
	UInt8 buffer[1024];
	
	while (CFReadStreamHasBytesAvailable(readStream))
	{
		CFIndex length = CFReadStreamRead(readStream, buffer, sizeof(buffer));
		
		if (length <= 0)
		{
			[self close];
			[connectionDelegate connectionTerminated:self];
			return;
		}
		
		[incomingDataBuffer appendBytes:buffer length:length];
	}
	
	while (YES)
	{
		if (packetBodySize == -1)
		{
			if ([incomingDataBuffer length] >= sizeof(int))
			{
				memcpy(&packetBodySize, [incomingDataBuffer bytes], sizeof(int));
				
				NSRange rangeToDelete = {0, sizeof(int)};
				[incomingDataBuffer replaceBytesInRange:rangeToDelete withBytes:NULL length:0];
			}
			else
			{
				break;
			}
		}
		
		if ([incomingDataBuffer length] >= packetBodySize)
		{
			NSData *rawData = [NSData dataWithBytes:[incomingDataBuffer bytes] length:packetBodySize];
			NSData *packet = rawData;
			
			[connectionDelegate receivedNetworkPacket:packet via:self];
			
			NSRange rangeToDelete = {0, packetBodySize};
			[incomingDataBuffer replaceBytesInRange:rangeToDelete withBytes:NULL length:0];
			
			packetBodySize = -1;
		}
		else
			break;
	}
}

- (void)writeStreamHandleEvent:(CFStreamEventType)event
{
	if (event == kCFStreamEventOpenCompleted)
	{
		isWriteStreamOpen = YES;
		
		return;
	}
	
	if (event == kCFStreamEventCanAcceptBytes)
	{
		[self writeOutgoingBufferToStream];
		
		return;
	}
	
	if (event == kCFStreamEventErrorOccurred || event == kCFStreamEventEndEncountered)
	{
		[self close];
		
		if (!readStream || !writeStream)
			[connectionDelegate connectionAttemptFailed:self];
		else
			[connectionDelegate connectionTerminated:self];
	}
}

- (void)writeOutgoingBufferToStream
{
	if (!readStream || !writeStream)
		return;
	
	if ([outgoingDataBuffer length] == 0)
		return;
	
	if (!CFWriteStreamCanAcceptBytes(writeStream))
		return;
	
	CFIndex bytesWrittenToSocket = CFWriteStreamWrite(writeStream, [outgoingDataBuffer bytes], [outgoingDataBuffer length]);
	
	if (bytesWrittenToSocket == -1)
	{
		[self close];
		[connectionDelegate connectionTerminated:self];
		return;
	}
	else if (bytesWrittenToSocket != [outgoingDataBuffer length])
	{
		NSLog(@"TEST!");
	}
	
	if (bytesWrittenToSocket <= [outgoingDataBuffer length])
	{
		NSRange range = {0, bytesWrittenToSocket};
		[outgoingDataBuffer replaceBytesInRange:range withBytes:NULL length:0];
	}
	
	if ([outgoingDataBuffer length] >= bytesWrittenToSocket)
		[outgoingDataBuffer replaceBytesInRange:NSMakeRange(0, [outgoingDataBuffer length]) withBytes:NULL length:0];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
	if (sender != bonjourNetService)
		return;
	
	NSLog(@"%@", errorDict);
	NSLog(@"%@", [errorDict description]);	
	
	[connectionDelegate connectionAttemptFailed:self];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	if (sender != bonjourNetService)
		return;
	
	self.host = [sender hostName];
	self.port = [sender port];
	
	self.bonjourNetService = nil;
	
	if (![self connect])
	{
		[connectionDelegate connectionAttemptFailed:self];
		[self close];
	}
}

@end
