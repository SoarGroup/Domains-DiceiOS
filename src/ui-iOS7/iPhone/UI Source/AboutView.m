//
//  AboutView.m
//  Liars Dice
//
//  Created by Alex Turner on 8/31/12.
//
//

#import "AboutView.h"

@interface AboutView ()

@end

@implementation AboutView
@synthesize webView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:@"AboutView" bundle:nil];
	
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = @"About Liar's Dice";
    self.navigationItem.leftBarButtonItem.title = @"Back";
    NSString *path = [[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
	[webView setDelegate:self];
}

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if ( inType == UIWebViewNavigationTypeLinkClicked ) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
	
    return YES;
}

- (void)dealloc {
    [webView release];
    [super dealloc];
}
@end
