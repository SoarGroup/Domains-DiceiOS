//
//  HowToPlayView.m
//  Liars Dice
//
//  Created by Miller Tinkerhess on 5/1/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "HowToPlayView.h"

@interface HowToPlayView ()

@end

@implementation HowToPlayView
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
    NSString* nibFile = nil;
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	
	if (screenBounds.size.height > 480)
		nibFile = @"HowToPlayView-i5";
	else
		nibFile = @"HowToPlayView";
	
    self = [super initWithNibName:nibFile bundle:nil];
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
    self.navigationItem.title = @"How To Play";
    self.navigationItem.leftBarButtonItem.title = @"Back";
    NSString *path = [[NSBundle mainBundle] pathForResource:@"rules" ofType:@"html"];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
}

- (void)dealloc {
    [webView release];
    [super dealloc];
}
@end
