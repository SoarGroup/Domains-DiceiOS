//
//  TableViewController.h
//  UM Liars Dice
//
//  Created by Alex Turner on 12/30/14.
//
//

#import <UIKit/UIKit.h>

@interface HistoryTableViewController : UITableViewController

@property (strong, readwrite) NSArray* history;

- (id)initWithHistory:(NSArray*)history;

@end
