//
//  HistoryView.h
//  UM Liars Dice
//
//  Created by Alex Turner on 12/30/14.
//
//

#import <UIKit/UIKit.h>

#import "HistoryTableViewController.h"

@interface HistoryView : UIViewController

- (id)initWithHistory:(NSArray*)history;

@property (strong, readwrite) IBOutlet UITableView* historyTableView;
@property (strong, readwrite) NSArray* history;
@property (strong, readwrite) HistoryTableViewController* controller;

- (IBAction)donePressed:(id)sender;

@end
