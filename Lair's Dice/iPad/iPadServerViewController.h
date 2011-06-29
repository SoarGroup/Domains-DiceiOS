//
//  iPadServerViewController.h
//  Lair's Dice
//
//  Created by Alex on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface iPadServerViewController : UIViewController {
    UITextView *console;
}

@property (nonatomic, retain) IBOutlet UITextView *console;

- (void)logToConsole:(NSString *)message;

@end
