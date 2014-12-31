//
//  HistoryTableViewController.m
//  UM Liars Dice
//
//  Created by Alex Turner on 12/30/14.
//
//

#import "HistoryTableViewController.h"

#import <GameKit/GameKit.h>

#import "HistoryItem.h"
#import "DiceLocalPlayer.h"
#import "DiceRemotePlayer.h"
#import "SoarPlayer.h"
#import "PlayGameView.h"
#import "UIImage+ImageEffects.h"

@interface HistoryTableViewController ()

@end

@implementation HistoryTableViewController

@synthesize history;

- (id)initWithHistory:(NSArray*)historyArray
{
	self = [super init];
	
	if (self)
		self.history = historyArray;
	
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.history.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [(NSArray*)[self.history objectAtIndex:section] count];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [NSString stringWithFormat:@"Round %li", (long)self.history.count - section];
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	NSMutableArray* array = [NSMutableArray array];
	
	for (NSInteger i = self.history.count;i > 0;--i)
		[array addObject:[NSString stringWithFormat:@"%li", (long)i]];
	
	return array;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
	if (sectionTitle == nil)
		return nil;
	
	// Create label with section title
	UILabel *label = [[UILabel alloc] init];
	label.frame = CGRectMake(20, -4, 300, 30);
	label.backgroundColor = [UIColor clearColor];
	label.textColor = [UIColor blackColor];
	label.font = [UIFont boldSystemFontOfSize:16];
	label.text = sectionTitle;
	
	// Create header view and add label as a subview
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
	[view addSubview:label];
	view.backgroundColor = [UIColor whiteColor];
	
	return view;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
	return index;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HistoryTableViewCell"];
    
	if (cell == nil)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"HistoryTableViewCell"];
	
	HistoryItem* item = [[self.history objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	
	cell.textLabel.attributedText = [item asHistoryString];
	cell.textLabel.accessibilityLabel = [item accessibleText];
	
	__block UIImage* profileImage = [UIImage imageNamed:@"YouPlayer.png"];
	
	PlayerState* state = item.player;
	id<Player> playerPtr = state.playerPtr;
	
	if ([playerPtr isKindOfClass:DiceLocalPlayer.class] || [playerPtr isKindOfClass:DiceRemotePlayer.class])
	{
		if ([playerPtr isKindOfClass:DiceRemotePlayer.class])
			profileImage = [UIImage imageNamed:@"HumanPlayer.png"];
		
		// Works for DiceRemotePlayer too
		DiceLocalPlayer* player = playerPtr;
		
		if (player.handler || ([playerPtr isKindOfClass:DiceLocalPlayer.class] && [GKLocalPlayer localPlayer].isAuthenticated))
		{
			dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
			
			GKPlayer* gkPlayer = player.participant.player;
			
			if ([playerPtr isKindOfClass:DiceLocalPlayer.class] && [GKLocalPlayer localPlayer].isAuthenticated)
				gkPlayer = [GKLocalPlayer localPlayer];
			
			[gkPlayer loadPhotoForSize:GKPhotoSizeNormal withCompletionHandler:^(UIImage* photo, NSError* error)
			 {
				 if (photo)
					 profileImage = photo;
				 
				 dispatch_semaphore_signal(semaphore);
			 }];
			
			while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
		}
	}
	else if ([playerPtr isKindOfClass:SoarPlayer.class])
		profileImage = [UIImage imageNamed:@"SoarPlayer.png"];
	
	cell.imageView.image = profileImage;
	
	// set the accessory view:
	cell.accessoryType =  UITableViewCellAccessoryNone;
	cell.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1.0];
	
    return cell;
}

@end
