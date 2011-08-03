//
//  iPhonem
//  Lair's Dice
//
//  Created by Alex on 7/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "iPhoneViewController.h"

@interface iPhoneViewController()

- (int)dieNumber:(UIImage*)imageToCheck;
- (void)undo;
- (UIImage *)imageForDieNumber:(int)dieNumber wasPushed:(BOOL)pushed;

- (int)numberOfDice;

@end

@interface UIButton (ButtonTitleUtils)

- (void)setTitle:(NSString *)title;

@end

@implementation UIButton (ButtonTitleUtils)

- (void)setTitle:(NSString *)title
{
    [self setTitle:title forState:UIControlStateNormal];
    [self setTitle:title forState:UIControlStateHighlighted];
    [self setTitle:title forState:UIControlStateSelected];
    [self setTitle:title forState:UIControlStateDisabled];
}

@end

@implementation iPhoneViewController

@synthesize pushDie1, pushDie2, pushDie3, pushDie4, pushDie5, die1, die2, die3, die4, die5, pass, exact, challenge, bid, number, dieValue, delegate, textView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        NSMutableArray *arrayOfDice = [NSMutableArray array];
        
        for (int i = 0; i < 40;i++)
            [arrayOfDice addObject:[NSNumber numberWithInt:(i + 1)]];
        
        maxNumberOfDice = [[NSArray alloc] initWithArray:arrayOfDice];
        numberOfSidesOnADice = [[NSArray alloc] initWithObjects:
                                [NSNumber numberWithInt:1],
                                [NSNumber numberWithInt:2],
                                [NSNumber numberWithInt:3],
                                [NSNumber numberWithInt:4],
                                [NSNumber numberWithInt:5],
                                [NSNumber numberWithInt:6],
                                nil];
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Dice" ofType:@"png"];
        dieOne = [UIImage imageWithContentsOfFile:filePath];
        filePath = [[NSBundle mainBundle] pathForResource:@"Dice2" ofType:@"png"];
        dieTwo = [UIImage imageWithContentsOfFile:filePath];
        filePath = [[NSBundle mainBundle] pathForResource:@"Dice3" ofType:@"png"];
        dieThree = [UIImage imageWithContentsOfFile:filePath];
        filePath = [[NSBundle mainBundle] pathForResource:@"Dice4" ofType:@"png"];
        dieFour = [UIImage imageWithContentsOfFile:filePath];
        filePath = [[NSBundle mainBundle] pathForResource:@"Dice5" ofType:@"png"];
        dieFive = [UIImage imageWithContentsOfFile:filePath];
        filePath = [[NSBundle mainBundle] pathForResource:@"Dice6" ofType:@"png"];
        dieSix = [UIImage imageWithContentsOfFile:filePath];
        
        diceToPush = [[NSMutableArray alloc] init];
        
        numberOfDiceToBid = 1;
        rankOfDiceToBid = 1;
        diceAlreadyPushed = 0;
        
        challengeWhich = None;
        
        previousPushed.pushedDice1 = NO;
        previousPushed.pushedDice2 = NO;
        previousPushed.pushedDice3 = NO;
        previousPushed.pushedDice4 = NO;
        previousPushed.pushedDice5 = NO;
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
    
    [pushDie1 setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [pushDie2 setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [pushDie3 setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [pushDie4 setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [pushDie5 setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    
    [pass setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [challenge setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [exact setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [bid setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Dice" ofType:@"png"];
    dieOne = [UIImage imageWithContentsOfFile:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:@"Dice2" ofType:@"png"];
    dieTwo = [UIImage imageWithContentsOfFile:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:@"Dice3" ofType:@"png"];
    dieThree = [UIImage imageWithContentsOfFile:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:@"Dice4" ofType:@"png"];
    dieFour = [UIImage imageWithContentsOfFile:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:@"Dice5" ofType:@"png"];
    dieFive = [UIImage imageWithContentsOfFile:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:@"Dice6" ofType:@"png"];
    dieSix = [UIImage imageWithContentsOfFile:filePath];
    
    filePath = [[NSBundle mainBundle] pathForResource:@"DicePushed" ofType:@"png"];
    dieOnePushed = [UIImage imageWithContentsOfFile:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:@"Dice2Pushed" ofType:@"png"];
    dieTwoPushed = [UIImage imageWithContentsOfFile:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:@"Dice3Pushed" ofType:@"png"];
    dieThreePushed = [UIImage imageWithContentsOfFile:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:@"Dice4Pushed" ofType:@"png"];
    dieFourPushed = [UIImage imageWithContentsOfFile:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:@"Dice5Pushed" ofType:@"png"];
    dieFivePushed = [UIImage imageWithContentsOfFile:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:@"Dice6Pushed" ofType:@"png"];
    dieSixPushed = [UIImage imageWithContentsOfFile:filePath];
    
    [dieOne retain];
    [dieTwo retain];
    [dieThree retain];
    [dieFour retain];
    [dieFive retain];
    [dieSix retain];
    
    [dieOnePushed retain];
    [dieTwoPushed retain];
    [dieThreePushed retain];
    [dieFourPushed retain];
    [dieFivePushed retain];
    [dieSixPushed retain];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [dieOne release];
    [dieTwo release];
    [dieThree release];
    [dieFour release];
    [dieFive release];
    [dieSix release];
    
    [dieOnePushed release];
    [dieTwoPushed release];
    [dieThreePushed release];
    [dieFourPushed release];
    [dieFivePushed release];
    [dieSixPushed release];
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
    if (pickerView.tag == 0)
        return 40;
    else
        return 6;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    if (pickerView.tag == 1)
    {
        return 50.0;
    }
    else
    {
        return 50.0;
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row
          forComponent:(NSInteger)component reusingView:(UIView *)view
{
    if (pickerView.tag == 0)
    {
        NSString *returnString = @"";
        returnString = [(NSNumber *)[maxNumberOfDice objectAtIndex:row] stringValue];
        
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.text = returnString;
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor clearColor];
        
        label.font = [UIFont fontWithName:@"Helvetica" size:25];
    
        label.frame = CGRectMake(0.0, 0, 50.0, 50.0);
        
        label.textAlignment = UITextAlignmentCenter;
        
        return label;
    }
    else
    {
        NSString *dieNumber = @"";
        
        if ([(NSNumber *)[numberOfSidesOnADice objectAtIndex:row] intValue] != 1)
            dieNumber = [(NSNumber *)[numberOfSidesOnADice objectAtIndex:row] stringValue];
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:[@"DiceiPhoneScroller" stringByAppendingFormat:@"%@", dieNumber]  ofType:@"png"];
        UIImage *die = [UIImage imageWithContentsOfFile:filePath];
        
        UIImageView *dieImageView = [[[UIImageView alloc] initWithImage:die] autorelease];
        
        dieImageView.frame = CGRectMake(0, 0, 40, 40);
                
        return dieImageView;
    }
}

- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (thePickerView.tag == 0) //Agent selector
        numberOfDiceToBid = [(NSNumber *)[maxNumberOfDice objectAtIndex:row] intValue];
    else
        rankOfDiceToBid = [(NSNumber *)[numberOfSidesOnADice objectAtIndex:row] intValue];
}

- (int)dieNumber:(UIImage*)imageToCheck
{
    if ([UIImagePNGRepresentation(imageToCheck) isEqualToData:UIImagePNGRepresentation(dieOne)])
        return 1;
    else if ([UIImagePNGRepresentation(imageToCheck) isEqualToData:UIImagePNGRepresentation(dieTwo)])
        return 2;
    else if ([UIImagePNGRepresentation(imageToCheck) isEqualToData:UIImagePNGRepresentation(dieThree)])
        return 3;
    else if ([UIImagePNGRepresentation(imageToCheck) isEqualToData:UIImagePNGRepresentation(dieFour)])
        return 4;
    else if ([UIImagePNGRepresentation(imageToCheck) isEqualToData:UIImagePNGRepresentation(dieFive)])
        return 5;
    else if ([UIImagePNGRepresentation(imageToCheck) isEqualToData:UIImagePNGRepresentation(dieSix)])
        return 6;
    else if ([UIImagePNGRepresentation(imageToCheck) isEqualToData:UIImagePNGRepresentation(dieOnePushed)])
        return 1;
    else if ([UIImagePNGRepresentation(imageToCheck) isEqualToData:UIImagePNGRepresentation(dieTwoPushed)])
        return 2;
    else if ([UIImagePNGRepresentation(imageToCheck) isEqualToData:UIImagePNGRepresentation(dieThreePushed)])
        return 3;
    else if ([UIImagePNGRepresentation(imageToCheck) isEqualToData:UIImagePNGRepresentation(dieFourPushed)])
        return 4;
    else if ([UIImagePNGRepresentation(imageToCheck) isEqualToData:UIImagePNGRepresentation(dieFivePushed)])
        return 5;
    else if ([UIImagePNGRepresentation(imageToCheck) isEqualToData:UIImagePNGRepresentation(dieSixPushed)])
        return 6;
    
    return -1;
}

- (UIImage *)imageForDieNumber:(int)dieNumber wasPushed:(BOOL)pushed
{
    switch (dieNumber)
    {
        case 1:
        {
            if (pushed)
                return dieOnePushed;
            else
                return dieOne;
        }
            break;
        case 2:
        {
            if (pushed)
                return dieTwoPushed;
            else
                return dieTwo;
        }
            break;
        case 3:
        {
            if (pushed)
                return dieThreePushed;
            else
                return dieThree;
        }
            break;
        case 4:
        {
            if (pushed)
                return dieFourPushed;
            else
                return dieFour;
        }
            break;
        case 5:
        {
            if (pushed)
                return dieFivePushed;
            else
                return dieFive;
        }
            break;
        case 6:
        {
            if (pushed)
                return dieSixPushed;
            else
                return dieSix;
        }
            break;
        default:
            break;
    }
    
    return nil;
}

- (int)numberOfDice
{
    int numberOfDiceNotHidden = 0;
    
    if (!die1.hidden)
        numberOfDiceNotHidden++;
    
    if (!die2.hidden)
        numberOfDiceNotHidden++;
    
    if (!die3.hidden)
        numberOfDiceNotHidden++;
    
    if (!die4.hidden)
        numberOfDiceNotHidden++;
    
    if (!die5.hidden)
        numberOfDiceNotHidden++;
    
    return numberOfDiceNotHidden;
}

- (IBAction)didClickButton:(UIButton *)sender
{
    if ([sender.titleLabel.text hasPrefix:@"Push"] || [sender.titleLabel.text hasPrefix:@"Pull"])
    {
        switch (sender.tag) {
            case 0:
            {
                if (!pushedDie1)
                {
                    if (diceAlreadyPushed < ([self numberOfDice] - 1))
                    {
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die1.image]]];
                        pushedDie1 = YES;
                        
                        die1.image = [self imageForDieNumber:[self dieNumber:die1.image] wasPushed:pushedDie1];
                        
                        [pushDie1 setTitle:@"Pull"];
                        diceAlreadyPushed++;
                    }
                    else
                    {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Push" message:@"You can only push at most 4 of your dice! You can't push all of them. Pull at least one of your dice to be able to push this one." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                        confirmationAlert = alert;
                        [alert show];
                        [alert release];
                    }
                }
                else
                {
                    pushedDie1 = NO;
                    
                    [diceToPush removeAllObjects];
                    if (pushedDie1 && !previousPushed.pushedDice1)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die1.image]]];
                    if (pushedDie2 && !previousPushed.pushedDice2)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die2.image]]];
                    if (pushedDie3 && !previousPushed.pushedDice3)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die3.image]]];
                    if (pushedDie4 && !previousPushed.pushedDice4)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die4.image]]];
                    if (pushedDie5 && !previousPushed.pushedDice5)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die5.image]]];
                    
                    die1.image = [self imageForDieNumber:[self dieNumber:die1.image] wasPushed:pushedDie1];
                    
                    [pushDie1 setTitle:@"Push"];
                    diceAlreadyPushed--;
                }
            }
                break;
            case 1:
            {
                if (!pushedDie2)
                {
                    if (diceAlreadyPushed < ([self numberOfDice] - 1))
                    {
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die2.image]]];
                        pushedDie2 = YES;
                        
                        die2.image = [self imageForDieNumber:[self dieNumber:die2.image] wasPushed:pushedDie2];
                        
                        [pushDie2 setTitle:@"Pull"];
                        diceAlreadyPushed++;
                    }
                    else
                    {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Push" message:@"You can only push at most 4 of your dice! You can't push all of them. Pull at least one of your dice to be able to push this one." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                        confirmationAlert = alert;
                        [alert show];
                        [alert release]; 
                    }
                }
                else
                {
                    pushedDie2 = NO;
                    
                    [diceToPush removeAllObjects];
                    if (pushedDie1 && !previousPushed.pushedDice1)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die1.image]]];
                    if (pushedDie2 && !previousPushed.pushedDice2)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die2.image]]];
                    if (pushedDie3 && !previousPushed.pushedDice3)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die3.image]]];
                    if (pushedDie4 && !previousPushed.pushedDice4)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die4.image]]];
                    if (pushedDie5 && !previousPushed.pushedDice5)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die5.image]]];
                    
                    die2.image = [self imageForDieNumber:[self dieNumber:die2.image] wasPushed:pushedDie2];
                    
                    [pushDie2 setTitle:@"Push"];
                    diceAlreadyPushed--;
                }
            }
                break;
            case 2:
            {
                if (!pushedDie3)
                {
                    if (diceAlreadyPushed < ([self numberOfDice] - 1))
                    {
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die3.image]]];
                        pushedDie3 = YES;
                        
                        die3.image = [self imageForDieNumber:[self dieNumber:die3.image] wasPushed:pushedDie3];
                        
                        [pushDie3 setTitle:@"Pull"];
                        diceAlreadyPushed++;
                    }
                    else
                    {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Push" message:@"You can only push at most 4 of your dice! You can't push all of them. Pull at least one of your dice to be able to push this one." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                        confirmationAlert = alert;
                        [alert show];
                        [alert release]; 
                    }
                }
                else
                {
                    pushedDie3 = NO;
                    
                    [diceToPush removeAllObjects];
                    if (pushedDie1 && !previousPushed.pushedDice1)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die1.image]]];
                    if (pushedDie2 && !previousPushed.pushedDice2)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die2.image]]];
                    if (pushedDie3 && !previousPushed.pushedDice3)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die3.image]]];
                    if (pushedDie4 && !previousPushed.pushedDice4)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die4.image]]];
                    if (pushedDie5 && !previousPushed.pushedDice5)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die5.image]]];
                    
                    die3.image = [self imageForDieNumber:[self dieNumber:die3.image] wasPushed:pushedDie3];
                    
                    [pushDie3 setTitle:@"Push"];
                    diceAlreadyPushed--;
                }
            }
                break;
            case 3:
            {
                if (!pushedDie4)
                {
                    if (diceAlreadyPushed < ([self numberOfDice] - 1))
                    {
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die4.image]]];
                        pushedDie4 = YES;
                        
                        die4.image = [self imageForDieNumber:[self dieNumber:die4.image] wasPushed:pushedDie4];
                        
                        [pushDie4 setTitle:@"Pull"];
                        diceAlreadyPushed++;
                    }
                    else
                    {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Push" message:@"You can only push at most 4 of your dice! You can't push all of them. Pull at least one of your dice to be able to push this one." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                        confirmationAlert = alert;
                        [alert show];
                        [alert release]; 
                    }
                }
                else
                {
                    pushedDie4 = NO;
                    
                    [diceToPush removeAllObjects];
                    if (pushedDie1 && !previousPushed.pushedDice1)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die1.image]]];
                    if (pushedDie2 && !previousPushed.pushedDice2)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die2.image]]];
                    if (pushedDie3 && !previousPushed.pushedDice3)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die3.image]]];
                    if (pushedDie4 && !previousPushed.pushedDice4)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die4.image]]];
                    if (pushedDie5 && !previousPushed.pushedDice5)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die5.image]]];
                    
                    die4.image = [self imageForDieNumber:[self dieNumber:die4.image] wasPushed:pushedDie4];
                    
                    [pushDie4 setTitle:@"Push"];
                    diceAlreadyPushed--;
                }
            }
                break;
            case 4:
            {
                if (!pushedDie5)
                {
                    if (diceAlreadyPushed < ([self numberOfDice] - 1))
                    {
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die5.image]]];
                        pushedDie5 = YES;
                        
                        die5.image = [self imageForDieNumber:[self dieNumber:die5.image] wasPushed:pushedDie5];
                        
                        [pushDie5 setTitle:@"Pull"];
                        diceAlreadyPushed++;
                    }
                    else
                    {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Push" message:@"You can only push at most 4 of your dice! You can't push all of them. Pull at least one of your dice to be able to push this one." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                        confirmationAlert = alert;
                        [alert show];
                        [alert release]; 
                    }
                }
                else
                {
                    pushedDie5 = NO;
                    
                    [diceToPush removeAllObjects];
                    if (pushedDie1 && !previousPushed.pushedDice1)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die1.image]]];
                    if (pushedDie2 && !previousPushed.pushedDice2)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die2.image]]];
                    if (pushedDie3 && !previousPushed.pushedDice3)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die3.image]]];
                    if (pushedDie4 && !previousPushed.pushedDice4)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die4.image]]];
                    if (pushedDie5 && !previousPushed.pushedDice5)
                        [diceToPush addObject:[NSNumber numberWithInt:[self dieNumber:die5.image]]];
                    
                    die5.image = [self imageForDieNumber:[self dieNumber:die5.image] wasPushed:pushedDie5];
                    
                    [pushDie5 setTitle:@"Push"];
                    diceAlreadyPushed--;
                }
            }
                break;
            default:
                break;
        }
    }
    else if ([sender.titleLabel.text hasPrefix:@"Pass!"])
    {
        action = A_PASS;
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirmation" message:@"Are you sure you want to pass?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Yes", @"No", nil];
        confirmationAlert = alert;
        [alert show];
        
        while (!confirmed)
        {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
        }
        
        [alert release];
        
        confirmed = NO;
        
        if (continueWithAction)
            [delegate endTurn];
        
        [self undo];
        [diceToPush removeAllObjects];
        
        continueWithAction = NO;
    }
    else if ([sender.titleLabel.text hasPrefix:@"Exact!"])
    {
        action = A_EXACT;
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirmation" message:@"Are you sure you want to exact?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Yes", @"No", nil];
        confirmationAlert = alert;
        [alert show];
        
        while (!confirmed)
        {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
        }
        
        [alert release];
        
        confirmed = NO;
        
        if (continueWithAction)
            [delegate endTurn];
        
        [self undo];
        [diceToPush removeAllObjects];
        
        continueWithAction = NO;
    }
    else if ([sender.titleLabel.text hasPrefix:@"Challenge!"])
    {
        action = A_CHALLENGE_BID;
        
        [self undo];
        [diceToPush removeAllObjects];
        [delegate endTurn];
    }
    else if ([sender.titleLabel.text hasPrefix:@"Bid!"])
    {
        confirmed = NO;
        
        action = A_BID;
        
        NSString *message = [[@"Are you sure you want to bid " stringByAppendingFormat:@"%i %i", numberOfDiceToBid, rankOfDiceToBid] stringByAppendingString:(numberOfDiceToBid > 1 ? @"s" : @"")];
        
        if ([diceToPush count])
        {
            message = [message stringByAppendingString:@" and push"];
            
            int i = 0;
            for (NSNumber *die in diceToPush)
            {
                if (i == 0)
                    message = [message stringByAppendingFormat:@" a %i", [die intValue]];
                else if ((i + 1) == [diceToPush count])
                    message = [message stringByAppendingFormat:@" and a %i", [die intValue]];
                else
                    message = [message stringByAppendingFormat:@" %i", [die intValue]];
                
                if ((i + 1) < [diceToPush count])
                    message = [message stringByAppendingString:@","];
                    
                i++;
            }
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirmation" message:message delegate:self cancelButtonTitle:nil otherButtonTitles:@"Yes", @"No", nil];
        confirmationAlert = alert;
        [alert show];
        
        while (!confirmed)
        {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
        }
        
        [alert release];
        
        confirmed = NO;
        
        if (continueWithAction)
        {
            previousPushed.pushedDice1 = pushedDie1;
            previousPushed.pushedDice2 = pushedDie2;
            previousPushed.pushedDice3 = pushedDie3;
            previousPushed.pushedDice4 = pushedDie4;
            previousPushed.pushedDice5 = pushedDie5;
            
            [delegate endTurn];
            
            [diceToPush removeAllObjects];
        }
        
        continueWithAction = NO;
    }
}

- (BOOL)updateDice:(NSArray *)diceAsNumbers withNewRound:(BOOL)newRound
{
    if (newRound)
    {
        pushedDie1 = NO;
        pushedDie2 = NO;
        pushedDie3 = NO;
        pushedDie4 = NO;
        pushedDie5 = NO;
        
        previousPushed.pushedDice1 = NO;
        previousPushed.pushedDice2 = NO;
        previousPushed.pushedDice3 = NO;
        previousPushed.pushedDice4 = NO;
        previousPushed.pushedDice5 = NO;
        
        diceAlreadyPushed = 0;
    }
    
    for (int i = 0;i < [diceAsNumbers count];i++)
    {
        NSNumber *dice = [diceAsNumbers objectAtIndex:i];
        if ([dice isKindOfClass:[NSNumber class]])
        {
            switch (i + 1) {
                case 1:
                    die1.image = [self imageForDieNumber:[dice intValue] wasPushed:pushedDie1];
                    break;
                case 2:
                    die2.image = [self imageForDieNumber:[dice intValue] wasPushed:pushedDie2];
                    break;
                case 3:
                    die3.image = [self imageForDieNumber:[dice intValue] wasPushed:pushedDie3];
                    break;
                case 4:
                    die4.image = [self imageForDieNumber:[dice intValue] wasPushed:pushedDie4];
                    break;
                case 5:
                    die5.image = [self imageForDieNumber:[dice intValue] wasPushed:pushedDie5];
                    break;
                default:
                    break;
            }
        }
    }
    
    if (newRound)
    {
        die1.image = [self imageForDieNumber:[self dieNumber:die1.image] wasPushed:NO];
        die2.image = [self imageForDieNumber:[self dieNumber:die2.image] wasPushed:NO];
        die3.image = [self imageForDieNumber:[self dieNumber:die3.image] wasPushed:NO];
        die4.image = [self imageForDieNumber:[self dieNumber:die4.image] wasPushed:NO];
        die5.image = [self imageForDieNumber:[self dieNumber:die5.image] wasPushed:NO];
    }
    
    BOOL lost = NO;
    
    switch ([diceAsNumbers count]) {
        case 0:
        {
            die1.hidden = YES;
            die2.hidden = YES;
            die3.hidden = YES;
            die4.hidden = YES;
            die5.hidden = YES;
            
            pushDie1.hidden = YES;
            pushDie2.hidden = YES;
            pushDie3.hidden = YES;
            pushDie4.hidden = YES;
            pushDie5.hidden = YES;
            
            lost = YES;
        }
            break;
            
        case 1:
        {
            die1.hidden = NO;
            die2.hidden = YES;
            die3.hidden = YES;
            die4.hidden = YES;
            die5.hidden = YES;
            
            pushDie1.hidden = NO;
            pushDie2.hidden = YES;
            pushDie3.hidden = YES;
            pushDie4.hidden = YES;
            pushDie5.hidden = YES; 
        }
            break;
        case 2:
        {
            die1.hidden = NO;
            die2.hidden = NO;
            die3.hidden = YES;
            die4.hidden = YES;
            die5.hidden = YES;
            
            pushDie1.hidden = NO;
            pushDie2.hidden = NO;
            pushDie3.hidden = YES;
            pushDie4.hidden = YES;
            pushDie5.hidden = YES;
        }
            break;
        case 3:
        {
            die1.hidden = NO;
            die2.hidden = NO;
            die3.hidden = NO;
            die4.hidden = YES;
            die5.hidden = YES;
            
            pushDie1.hidden = NO;
            pushDie2.hidden = NO;
            pushDie3.hidden = NO;
            pushDie4.hidden = YES;
            pushDie5.hidden = YES;
        }
            break;
        case 4:
        {
            die1.hidden = NO;
            die2.hidden = NO;
            die3.hidden = NO;
            die4.hidden = NO;
            die5.hidden = YES;
            
            pushDie1.hidden = NO;
            pushDie2.hidden = NO;
            pushDie3.hidden = NO;
            pushDie4.hidden = NO;
            pushDie5.hidden = YES;
        }
            break;
        case 5:
        {
            die1.hidden = NO;
            die2.hidden = NO;
            die3.hidden = NO;
            die4.hidden = NO;
            die5.hidden = NO;
            
            pushDie1.hidden = NO;
            pushDie2.hidden = NO;
            pushDie3.hidden = NO;
            pushDie4.hidden = NO;
            pushDie5.hidden = NO;
        }
            break;
        default:
            break;
    }
    
    [pushDie1 setEnabled:(previousPushed.pushedDice1 ? NO : YES)];
    [pushDie2 setEnabled:(previousPushed.pushedDice2 ? NO : YES)];
    [pushDie3 setEnabled:(previousPushed.pushedDice3 ? NO : YES)];
    [pushDie4 setEnabled:(previousPushed.pushedDice4 ? NO : YES)];
    [pushDie5 setEnabled:(previousPushed.pushedDice5 ? NO : YES)];
    
    return lost;
}

- (void)undo
{
    [pushDie1 setEnabled:(previousPushed.pushedDice1 ? NO : YES)];
    [pushDie2 setEnabled:(previousPushed.pushedDice2 ? NO : YES)];
    [pushDie3 setEnabled:(previousPushed.pushedDice3 ? NO : YES)];
    [pushDie4 setEnabled:(previousPushed.pushedDice4 ? NO : YES)];
    [pushDie5 setEnabled:(previousPushed.pushedDice5 ? NO : YES)];
    
    if (previousPushed.pushedDice1 == NO && pushedDie1 == YES)
        diceAlreadyPushed--;
    
    if (previousPushed.pushedDice2 == NO && pushedDie2 == YES)
        diceAlreadyPushed--;
    
    if (previousPushed.pushedDice3 == NO && pushedDie3 == YES)
        diceAlreadyPushed--;
    
    if (previousPushed.pushedDice4 == NO && pushedDie4 == YES)
        diceAlreadyPushed--;
    
    if (previousPushed.pushedDice5 == NO && pushedDie5 == YES)
        diceAlreadyPushed--;
    
    pushedDie1 = previousPushed.pushedDice1;
    pushedDie2 = previousPushed.pushedDice2;
    pushedDie3 = previousPushed.pushedDice3;
    pushedDie4 = previousPushed.pushedDice4;
    pushedDie5 = previousPushed.pushedDice5;
    
    [pushDie1 setTitle:(pushedDie1 ? @"Pull" : @"Push")];
    [pushDie2 setTitle:(pushedDie2 ? @"Pull" : @"Push")];
    [pushDie3 setTitle:(pushedDie3 ? @"Pull" : @"Push")];
    [pushDie4 setTitle:(pushedDie4 ? @"Pull" : @"Push")];
    [pushDie5 setTitle:(pushedDie5 ? @"Pull" : @"Push")];
    
    die1.image = [self imageForDieNumber:[self dieNumber:die1.image] wasPushed:pushedDie1];
    die2.image = [self imageForDieNumber:[self dieNumber:die2.image] wasPushed:pushedDie2];
    die3.image = [self imageForDieNumber:[self dieNumber:die3.image] wasPushed:pushedDie3];
    die4.image = [self imageForDieNumber:[self dieNumber:die4.image] wasPushed:pushedDie4];
    die5.image = [self imageForDieNumber:[self dieNumber:die5.image] wasPushed:pushedDie5];
    
    diceAlreadyPushed = (pushedDie1 ? 1 : 0) +
                        (pushedDie1 ? 1 : 0) +
                        (pushedDie1 ? 1 : 0) +
                        (pushedDie1 ? 1 : 0) +
                        (pushedDie1 ? 1 : 0);
    
    [diceToPush removeAllObjects];
}

// Called when an alert button is tapped.
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == confirmationAlert)
    {
        if (buttonIndex == 0)
        {
            //Yes
            confirmed = YES;
            continueWithAction = YES;
        }
        else
        {
            //No
            confirmed = YES;
            continueWithAction = NO;
        }
    }
    else
    {
        if (buttonIndex == 0)
        {
            //Challenge the first one
            challengeWhich = First;
        }
        else if (buttonIndex == 1)
        {
            //Challenge the second one
            challengeWhich = Second;
        }
        else
        {
            //User canceled
            challengeWhich = Cancel;
        }
    }
}

- (void)disableAllButtons
{
    [pushDie1 setEnabled:NO];
    [pushDie2 setEnabled:NO];
    [pushDie3 setEnabled:NO];
    [pushDie4 setEnabled:NO];
    [pushDie5 setEnabled:NO];
    
    [pass setEnabled:NO];
    [exact setEnabled:NO];
    [challenge setEnabled:NO];
    [bid setEnabled:NO];
}

@end
