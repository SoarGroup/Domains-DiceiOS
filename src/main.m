//
//  main.m
//  Liar's Dice
//
//  Created by Alex on 6/29/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[])
{
	[[NSThread currentThread] setName:@"Main Liar's Dice Thread"];

	int retVal = UIApplicationMain(argc, argv, nil, nil);
	return retVal;
}
