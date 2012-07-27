//
//  PopoverViewController.h
//  Lair's Dice
//
//  Created by Alex Turner on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PopoverViewController : UIViewController {
    NSString *contents;
}

- (id)initWithContents:(NSString *)contents;

@end
