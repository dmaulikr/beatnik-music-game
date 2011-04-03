//
//  Scoreboard.mm
//  musicGame
//
//  Created by Max Kolasinski on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Scoreboard.h"

@implementation Scoreboard

@synthesize score;
@synthesize combo;
@synthesize dig5;
@synthesize dig4;
@synthesize dig3;
@synthesize dig2;
@synthesize dig1;
@synthesize dig0;

- (id) init
{
	if (self = [super init] )
	{
		[self setScore:0];
		[self setCombo:0];
	}
	return self;
}

- (void) hitFull
{
	[self setCombo: [self combo] + 1];
	if ([self combo] > 39){
		[self setScore: [self score] + 400];
	}
	if ([self combo] > 29){
		[self setScore: [self score] + 300];
	}
	if ([self combo] > 19){
		[self setScore: [self score] + 200];
	}
	if ([self combo] > 9){
		[self setScore: [self score] + 100];
	}
}

- (void) hitHalf
{
	[self setCombo: [self combo] + 1];
	if ([self combo] > 39){
		[self setScore: [self score] + 200];
	}
	if ([self combo] > 29){
		[self setScore: [self score] + 150];
	}
	if ([self combo] > 19){
		[self setScore: [self score] + 100];
	}
	if ([self combo] > 9){
		[self setScore: [self score] + 50];
	}
}

- (void) hitMiss
{
	[self setCombo:0];
}

- (void) updateScore
{
	//here we'll use clever bitmasking tricks to get each digit individually
	NSNumber * tempScore = [NSNumber numberWithInt:score];
}
- (void) dealloc
{
	[score release];
	[super dealloc];
}

@end