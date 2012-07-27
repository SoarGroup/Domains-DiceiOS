//
//  DiceHistoryView.h
//  Liars Dice
//
//  Created by Miller Tinkerhess on 10/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlayerState.h"

@interface DiceHistoryView : UIViewController {
    UITextView *historyLabel;
    PlayerState *state;
}

- (id) initWithPlayerState:(PlayerState *)state;

- (IBAction)backPressed:(id)sender;

@property (nonatomic, retain) IBOutlet UITextView *historyLabel;

@property (readwrite, retain) PlayerState *state;

@end
