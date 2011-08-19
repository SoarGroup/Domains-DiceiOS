//
//  PopoverViewController.m
//  Lair's Dice
//
//  Created by Alex Turner on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PopoverViewController.h"


@implementation PopoverViewController

- (id)initWithContents:(NSString *)content
{
    self = [super init];
    if (self)
    {
        contents = content;
    }
    return self;
}
- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
/*- (void)loadView
{
    
}*/

- (void)viewWillAppear:(BOOL)animated
{
    UITextView *textView = [[[UITextView alloc] init] autorelease];
    
    CGRect frame;
    frame.origin.x = 0.0;
    frame.origin.y = 0.0;
    frame.size.width = 350.0;
    frame.size.height = 250.0;
    
    textView.frame = frame;
    
    textView.editable = NO;
    textView.text = contents;
    
    textView.backgroundColor = [UIColor blackColor];
    textView.textColor = [UIColor whiteColor];

    textView.font = [UIFont fontWithName:@"Helvetica" size:25.0f];;
    
    [self.view addSubview:textView];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.contentSizeForViewInPopover = CGSizeMake(350.0, 150.0);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
            interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

@end
