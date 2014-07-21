//
//  RecordStatsView.h
//  Liars Dice
//
//  Created by Miller Tinkerhess on 5/3/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DiceDatabase.h"

@interface StatsView : UIViewController
{
	int lineCount;
}

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, atomic) DiceDatabase* database;

@end
