//
//  MainMenu.h
//  Lair's Dice
//
//  Created by Alex on 7/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Lair_s_DiceAppDelegate_iPad;

@interface MainMenu : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>
{
    id appDelegate;
    
    UIPickerView *agentSelector;
    
    UITextView *textView;
    UITextView *networkPlayers;
    
    UIButton *startButton;
    
    NSMutableArray *arrayOfNumbers;
    
    int agents;
    int players;
	
	UIImageView *wifiLogo;
	UIImageView *bluetoothLogo;
	
	BOOL wifiEnabled;
	BOOL bluetoothEnabled;
}

@property (nonatomic, retain) IBOutlet UIPickerView *agentSelector;

@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UITextView *networkPlayers;

@property (nonatomic, retain) IBOutlet UIButton *startButton;

@property (nonatomic, retain) IBOutlet UIImageView *wifiLogo;
@property (nonatomic, retain) IBOutlet UIImageView *bluetoothLogo;

- (IBAction)didPressStartButton:(UIButton *)startButton;

@property (nonatomic, assign) id appDelegate;

- (void)addNetworkPlayer:(NSString *)name;
- (void)removeNetworkPlayer:(NSString *)name;

- (void)setWifi:(BOOL)wifi;
- (void)setBluetooth:(BOOL)bluetooth;

- (void)setEnabled;

@end
