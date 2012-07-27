//
//  GameRecordView.h
//  Liars Dice
//
//  Created by Miller Tinkerhess on 5/3/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GameRecordView : UITableViewController {
    NSArray *games;
}

@property (readwrite, retain) NSArray *games;

@end
