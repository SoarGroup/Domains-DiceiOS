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
    Lair_s_DiceAppDelegate_iPad *delegate;
}

@property (nonatomic, assign) Lair_s_DiceAppDelegate_iPad *delegate;

- (IBAction)done;

@end
