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

@synthesize history, sizingCell;

- (id)initWithHistory:(NSArray*)historyArray
{
	self = [super init];
	
	if (self)
	{
		self.history = historyArray;
		
		self.sizingCell = [[HistoryTableViewCell alloc] initWithReuseIdentifier:nil];
		self.sizingCell.autoresizingMask = UIViewAutoresizingFlexibleWidth; // this must be set for the cell heights to be calculated correctly in landscape
		self.sizingCell.hidden = YES;
		
		[self.tableView addSubview:self.sizingCell];
		
		self.sizingCell.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 0);
	}
	
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
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

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [HistoryTableViewCell minimumHeight];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	HistoryItem* item = [[self.history objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	
	CGFloat calculatedHeight = 0;
	
	// determine which dyanmic height method to use
	self.sizingCell.message = item;
	
	[self.sizingCell setNeedsLayout];
	[self.sizingCell layoutIfNeeded];
	
	NSAttributedString *cellText = [item asHistoryString];
	
	calculatedHeight = [self.sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
	
	return calculatedHeight + cellText.size.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *autoCellId = @"autoCell";
	
	HistoryTableViewCell *cell = nil;
	HistoryItem* item = [[self.history objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	
	NSString *cellId = autoCellId;
		
	cell = [tableView dequeueReusableCellWithIdentifier:cellId];
		
	if (cell == nil) {
		cell = [[HistoryTableViewCell alloc] initWithReuseIdentifier:cellId];
	}
	
	cell.message = item;
	
	return cell;
}

@end
