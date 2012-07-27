//
//  iPhoneMainMenu.h
//  Lair's Dice
//
//  Created by Alex Turner on 7/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Lair_s_DiceAppDelegate_iPhone.h"

@interface iPhoneMainMenu : UIViewController <UITextFieldDelegate> {
    Lair_s_DiceAppDelegate_iPhone *delegate;
    
    UIButton *searchForGames;
    UIButton *help;
    
    UITextField *name;
	
	UISwitch *server;
}

@property (nonatomic, assign) Lair_s_DiceAppDelegate_iPhone *delegate;

@property (nonatomic, retain) IBOutlet UIButton *searchForGames;
@property (nonatomic, retain) IBOutlet UIButton *help;

@property (nonatomic, retain) IBOutlet UITextField *name;

@property (nonatomic, retain) IBOutlet UISwitch *server;

- (IBAction)buttonClicked:(UIButton *)sender;

- (IBAction)serverValueChanged:(UISwitch *)server;

@end
