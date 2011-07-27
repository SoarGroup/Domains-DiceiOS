//
//  MainMenu.m
//  Lair's Dice
//
//  Created by Alex on 7/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainMenu.h"

#import "Lair_s_DiceAppDelegate_iPad.h"

@implementation MainMenu

@synthesize agentSelector, textView, startButton, appDelegate, networkPlayers;

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
    agentSelector = nil;
    networkPlayers = nil;
    textView = nil;
    startButton = nil;
    [arrayOfNumbers release];
    [super dealloc];
}

- (void)addNetworkPlayer:(NSString *)name
{
    networkPlayers.text = [NSString stringWithFormat:@"%@%@\n", networkPlayers.text, name];
    [networkPlayers scrollRangeToVisible:NSMakeRange([networkPlayers.text length], 0)];
    
    players++;
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
    
    arrayOfNumbers = [[NSMutableArray alloc] initWithObjects:
                      [NSNumber numberWithInt:0],
                      [NSNumber numberWithInt:1],
                      [NSNumber numberWithInt:2],
                      [NSNumber numberWithInt:3],
                      [NSNumber numberWithInt:4],
                      [NSNumber numberWithInt:5], 
                      [NSNumber numberWithInt:6],
                      [NSNumber numberWithInt:7],
                      [NSNumber numberWithInt:8],
                      nil];
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

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [arrayOfNumbers count];
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *returnString = @"";
    
    if (thePickerView.tag == 0) //Agent selector
        returnString = [(NSNumber *)[arrayOfNumbers objectAtIndex:row] stringValue];
    else
        returnString = [(NSNumber *)[arrayOfNumbers objectAtIndex:row] stringValue];
    
    return returnString;
}

- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (thePickerView.tag == 0) //Agent selector
        agents = [(NSNumber *)[arrayOfNumbers objectAtIndex:row] intValue];
}

- (IBAction)didPressStartButton:(UIButton *)startButton
{
    if ([startButton.titleLabel.text isEqualToString:@"Help"])
    {
        [appDelegate goToHelp];
        return;
    }
    
    if ((agents + players) > 8)
        textView.text = @"Error: You can only have a maximum of 8 players!";
    else if ((agents + players) < 2)
        textView.text = @"Error: You need at least two players!";
    else
        [appDelegate startTheGameWithNumberOfAgents:agents players:players];
}

- (void)removeNetworkPlayer:(NSString *)name
{
    NSString *newText = [networkPlayers.text stringByReplacingOccurrencesOfString:[name stringByAppendingString:@"\n"] withString:@""];
    networkPlayers.text = newText;
}

@end
