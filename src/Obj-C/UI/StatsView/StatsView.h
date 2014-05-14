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

@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;
@property (retain, atomic) DiceDatabase* database;

@end
