//
//  iPadHelp.h
//  Lair's Dice
//
//  Created by Alex Turner on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Lair_s_DiceAppDelegate_iPad.h"


@interface iPadHelp : UIViewController {
    Server *delegate;
}

@property (nonatomic, assign) Server *delegate;

- (IBAction)done;

@end
