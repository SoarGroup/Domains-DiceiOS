//
//  iPhoneHelp.h
//  Lair's Dice
//
//  Created by Alex Turner on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Lair_s_DiceAppDelegate_iPhone.h"


@interface iPhoneHelp : UIViewController {
    Lair_s_DiceAppDelegate_iPhone *delegate;
}

@property (nonatomic, assign) Lair_s_DiceAppDelegate_iPhone *delegate;

- (IBAction)goToMainMenu;

@end
