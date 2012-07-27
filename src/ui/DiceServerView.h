//
//  DiceServerView.h
//  Lair's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DiceGame.h"
#import "DiceApplicationDelegate.h"

@interface DiceServerView : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    DiceGame *game;
    UITableView *playerNameList;
    DiceApplicationDelegate *appDelegate;
}

@property(readwrite, retain) DiceApplicationDelegate *appDelegate;

-(DiceServerView*)initWithGame:(DiceGame*)game;

@property(readwrite, retain) DiceGame *game;
@property (nonatomic, retain) IBOutlet UITableView *playerNameList;

- (IBAction)quitGame:(id)sender;
- (IBAction)startGamePressed:(id)sender;
- (IBAction)addSoarAgentPressed:(id)sender;

@end
