//
//  HowToPlayView.h
//  Liars Dice
//
//  Created by Miller Tinkerhess on 5/1/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RulesView : UIViewController <EngineClass>
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end
