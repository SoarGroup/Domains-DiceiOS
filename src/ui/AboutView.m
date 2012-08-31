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

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
		
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
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
}

- (void)viewDidUnload
{
	[self setWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [webView release];
    [super dealloc];
}
@end
