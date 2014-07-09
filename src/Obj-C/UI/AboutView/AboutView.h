//
//  AboutView.h
//  Liars Dice
//
//  Created by Alex Turner on 8/31/12.
//
//

#import <UIKit/UIKit.h>

@interface AboutView : UIViewController <UIWebViewDelegate, EngineClass>
@property (retain, nonatomic) IBOutlet UIWebView *webView;

@end
