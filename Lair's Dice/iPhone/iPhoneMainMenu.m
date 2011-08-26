//
//  iPhoneMainMenu.m
//  Lair's Dice
//
//  Created by Alex Turner on 7/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "iPhoneMainMenu.h"


@implementation iPhoneMainMenu

@synthesize delegate, searchForGames, help, name, server;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    name.placeholder = [[UIDevice currentDevice] name];
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
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (IBAction)buttonClicked:(UIButton *)sender
{
    if ([sender.titleLabel.text isEqualToString:@"Search For Games"])
    {
		[delegate goToMainGame:name.text];
    }
    else if ([sender.titleLabel.text isEqualToString:@"Help"])
    {
        //Help Menu
        [delegate goToiPhoneHelp];
    }
	else if ([sender.titleLabel.text isEqualToString:@"Start Server"])
	{
		[delegate goToServer];
	}
}

- (BOOL)textFieldShouldReturn: (UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)serverValueChanged:(UISwitch *)server
{
	if (server != self.server)
		return;
	
	if (server.on)
	{
		[searchForGames setTitle:@"Start Server" forState:UIControlStateNormal];
		[searchForGames setTitle:@"Start Server" forState:UIControlStateHighlighted];
		[searchForGames setTitle:@"Start Server" forState:UIControlStateDisabled];
		[searchForGames setTitle:@"Start Server" forState:UIControlStateSelected];
	}
	else
	{
		[searchForGames setTitle:@"Search For Games" forState:UIControlStateNormal];
		[searchForGames setTitle:@"Search For Games" forState:UIControlStateHighlighted];
		[searchForGames setTitle:@"Search For Games" forState:UIControlStateDisabled];
		[searchForGames setTitle:@"Search For Games" forState:UIControlStateSelected];
	}
}

@end
