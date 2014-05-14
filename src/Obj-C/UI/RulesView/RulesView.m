//
//  HowToPlayView.m
//  Liars Dice
//
//  Created by Miller Tinkerhess on 5/1/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "RulesView.h"

@interface RulesView ()

@end

@implementation RulesView
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
	NSString* device = [UIDevice currentDevice].model;
	device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];

	if ([device isEqualToString:@"iPhone"])
		device = @"";

    return [super initWithNibName:[@"RulesView" stringByAppendingString:device] bundle:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = @"Rules";
    self.navigationItem.leftBarButtonItem.title = @"Main Menu";
    NSString *path = [[NSBundle mainBundle] pathForResource:@"rules" ofType:@"html"];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
}

- (void)dealloc {
    [webView release];
    [super dealloc];
}
@end
