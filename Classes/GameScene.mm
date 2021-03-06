//
//  HelloWorldLayer.m
//  Cocos2dLesson1
//
//  Created by Max Wittek on 3/4/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#define COCOS2D_DEBUG 1

// Import the interfaces
#import <MediaPlayer/MediaPlayer.h> 
#import "CCTouchDispatcher.h"
#import "GameScene.h"
#import "HODCircle.h"
#import "osu-import.h.mm"
#import "HODSlider.h"
#import "HODSpinner.h"
#import "HitObjectDisplay.h.mm"
#import "SqlHandler.h"
#import "Scoreboard.h"
#import "FRCurve.h"
#import "CCNodeExtension.h"
#import "ResultsScreen.h"

#include "TargetConditionals.h"


#include <list>
#include <iostream>
using std::cout;
using std::endl;
using std::vector;
using std::list;

CCLabelTTF * scoreLabel;
int score;

list<HitObjectDisplay*> hods;

int zOrder = INT_MAX-5;


HitObjectDisplay* HODFactory(HitObject* hitObject, int r, int g, int b) {
	if(hitObject->objectType & 1) { // bitmask for normal
		return [[[HODCircle alloc] initWithHitObject:hitObject red:r green:g blue:b initialScale: 1.0] retain];
	}
	
	else if(hitObject->objectType & 2) {
		return [[[HODSlider alloc] initWithHitObject:hitObject red:r green:g blue:b initialScale: 1.0] retain];
	}
	
	else {
		NSLog(@"so, like, should be spawning an HODspinner. da fuk?");
		return [[[HODSpinner alloc] initWithHitObject:hitObject red:150 green:0 blue:0] retain];
	}
	return 0;
}

// HelloWorld implementation

@implementation GameScene
@synthesize beatmap;
@synthesize timeAllowanceMs;
@synthesize durationMs;
@synthesize scoreBoard;
@synthesize black;

+(id) sceneWithBeatmap: (Beatmap*)beatmap_;
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	GameScene *layer = [GameScene node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// tell the layer we're using this beatmap, and start animation
	[layer startSceneWithBeatmap:beatmap_];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init] )) {
		
		self.isTouchEnabled = YES;
		
		paused = false;
		numPopped = 0;
		beatmap = 0;
#if !TARGET_IPHONE_SIMULATOR
		musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
#endif
		
		// Initialize Scoreboard
		scoreBoard = [[Scoreboard alloc] init];
		[self addChild:scoreBoard z:1];
		
		timeAllowanceMs = 150;
		durationMs = 750;
		comboIndex = 0;
		
		//CCSprite * blackbox = [CCSprite spriteWithFile:@"wehavetogoblack.png"];
		//blackbox.position=ccp(480/2,320/2);
		//blackbox.opacity = 200;
		//[self addChild:blackbox z: INT_MAX];
		
		
	}
	return self;
}

- (void) startSceneWithBeatmap:(Beatmap*)beatmap_ {
	
	beatmap = beatmap_;
	if(!beatmap) exit(0); // TODO: make an errmsg
	
	[self schedule:@selector(nextFrame:)];
	
	// this shit don't work in the simulator
#if !TARGET_IPHONE_SIMULATOR
	
	@try {
		// Music Stuff
		
		MPMediaQuery * query = [[MPMediaQuery alloc] init];
		[query addFilterPredicate: [MPMediaPropertyPredicate
										predicateWithValue: [NSString stringWithUTF8String:(beatmap->Title).c_str()]
										forProperty: MPMediaItemPropertyTitle]];
		
		[query addFilterPredicate: [MPMediaPropertyPredicate
									predicateWithValue: [NSString stringWithUTF8String:(beatmap->Artist).c_str()]
									forProperty: MPMediaItemPropertyArtist]];
		
		if([[query items] count] == 0) {
			NSLog(@"CANT PALY THIS SONG OH SHIIIIIII");
		}
		
		[musicPlayer setQueueWithQuery:query];
		
		[musicPlayer play];
		
		//Letterboxes
		
		CCSprite  * left_curtain = [CCSprite spriteWithFile:@"left_curtain.png"];
		CCSprite  * right_curtain = [CCSprite spriteWithFile:@"right_curtain.png"];
		left_curtain.position = ccp(40, 320/2);
		right_curtain.position = ccp(440, 320/2);
		
		[left_curtain setScale:0.5];
		[right_curtain setScale:0.5];
		[self addChild:left_curtain];
		[self addChild:right_curtain];
		// Artwork
		MPMediaItem * currentItem = musicPlayer.nowPlayingItem;
		MPMediaItemArtwork *artwork = [currentItem valueForProperty:MPMediaItemPropertyArtwork];
		UIImage * artworkImage;
		artworkImage = [artwork imageWithSize:CGSizeMake(320, 320)];
		albumArt = [CCSprite spriteWithCGImage:[artworkImage CGImage]];
		albumArt.position = ccp(480/2, 320/2);
		if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2){
			//iPhone 4
			[albumArt setScale:0.5];
		}
		[self addChild:albumArt z:0];
		
		//[musicPlayer setCurrentPlaybackTime:100]; // skip intro, usually 18
		//[musicPlayer setCurrentPlaybackTime:60];
		//[musicPlayer setCurrentPlaybackTime:30];
		
		
	} @catch(NSException *e) {
		cout << "no music playing dawg" << endl;
	}
#endif
	
	// test out slider stuff in the simulator
#if TARGET_IPHONE_SIMULATOR
	while(beatmap->hitObjects.front()->objectType & 1 || beatmap->hitObjects.front()->objectType & 2)
		beatmap->hitObjects.pop_front();
	HitObject* o = beatmap->hitObjects.front();
	HitObjectDisplay * hod = HODFactory(o, 0, 120, 0);
	[self addChild:hod];
	[hod appearWithDuration:1.5];
#endif
	
}




-(void)fadeout {
	
	if(musicPlayer.volume > 0.05) {
		musicPlayer.volume = musicPlayer.volume - 0.05;
		[self performSelector: @selector(fadeout) withObject: nil afterDelay: 0.05 ];
	} else { [musicPlayer pause]; }
}

- (void) nextFrame:(ccTime)dt {
	
	double milliseconds = [musicPlayer currentPlaybackTime] * 1000.0f;
	milliseconds += 850; // offset for gee norm
	
	
	if(beatmap->hitObjects.empty()) {
		//exit(0);
		// wait 3 seconds and then go to another scene
	}
	
	
	while(!beatmap->hitObjects.empty()) {
		HitObject * o = beatmap->hitObjects.front(); 
		
		if(milliseconds > o->startTimeMs) {
			cout << o->x << " " << o->y << endl;
			cout << "making a HitObject at time " << o->startTimeMs << endl;
			
			// give a different color to each combo group
			if(o->number == 1) comboIndex++;
			ccColor3B col = beatmap->comboColors[comboIndex % 4];
			
			HitObjectDisplay * hod = HODFactory(o, col.r, col.g, col.b );
			[self addChild:hod z:zOrder--];
			[hod appearWithDuration: durationMs / 1000.];
			hods.push_back(hod);
			beatmap->hitObjects.pop_front();
			
			numPopped++;
		}
		else
			break;
	}
	
	
	if(hods.empty()) {
		zOrder = INT_MAX - 5;
	} // reset z-order to topmost. cuz we can.
	
	while(!hods.empty()) {
		//HitObject * o = hods.front().hitObject;
		if(milliseconds > [hods.front() disappearTime]) {
			HitObjectDisplay * c = hods.front();
			
			
			[self spawnReaction: [c pointsAtDisappearTime] pos:ccp([c hitObject]->x, [c hitObject]->y)];
			
			hods.pop_front();
			[self removeChild:c cleanup:true];
			// [c release];
		}
		else {
			break;
		}
	}
	
	if(beatmap->hitObjects.size() == 1)
		cout << **(beatmap->hitObjects.begin()) << endl;
	
	if(beatmap->hitObjects.size() == 1)
		if( abs((*(beatmap->hitObjects.begin()))->x) > 500)
			beatmap->hitObjects.clear();
	
	if(hods.empty() && beatmap->hitObjects.empty()) {
		//if(numPopped == 10) {
		//[self fadeout];
		//[self pauseSchedulerAndActions];
		//[self pauseTimersForHierarchy];
		
		id finishAction = [CCCallBlock actionWithBlock:^{
			[self pauseSchedulerAndActions];
			[[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.5f scene:[ResultsScreen sceneWithBeatmap:beatmap scoreboard:scoreBoard]]];
			
		}];
		[self runAction: [CCSequence actions:[CCDelayTime actionWithDuration:1.0], finishAction, nil]];
	}
	
}

- (void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch * touch = [touches anyObject];	
	CGPoint location = [self convertTouchToNodeSpace: touch];
	
	if([touches count] > 1) {
		/*
		 if(!pausedLabel)
		 pausedLabel = [[CCLabelTTF labelWithString:@"PAUSED" fontName:@"Helvetica" fontSize:48] retain];
		 */
		
		if(!paused) {
			[musicPlayer pause];
			paused = true;
			
			black = [CCSprite spriteWithFile:@"wehavetogoblack.png"];
			black.position = ccp(480/2,320/2);
			black.scale = 2.0;
			black.opacity = 0;
			[self addChild:black z:INT_MAX-1];
			CCSprite * cont1 = [CCSprite spriteWithFile:@"continue.png"];
			CCSprite * quit1 = [CCSprite spriteWithFile:@"quit.png"];
			CCMenuItemSprite * cont = [CCMenuItemSprite itemFromNormalSprite:cont1 selectedSprite:nil target:self selector:@selector(continueGame:)];
			CCMenuItemSprite * quit = [CCMenuItemSprite itemFromNormalSprite:quit1 selectedSprite:nil target:self selector:@selector(backToMain:)];
			menu = [CCMenu menuWithItems:cont,quit,nil];
			[menu setPosition:ccp(480/2,320/2)];
			cont.scale = .5;
			quit.scale = .5;
			cont.position = ccp(-100,25);
			quit.position = ccp(75,0);
			[self addChild:menu z:INT_MAX];
			
			[self pauseTimersForHierarchy];
			
			[black runAction:[CCFadeTo actionWithDuration:0.2 opacity:255*.5]];
			
		} else {
			
		}
	}
	
	
	if(!hods.empty()) {
		
		double milliseconds = [musicPlayer currentPlaybackTime] * 1000.0f;
		milliseconds += 850; // offset for gee norm
		
		// iterate through everying in "hods"
		list<HitObjectDisplay*>::iterator hodIter = hods.begin();
		list<HitObjectDisplay*>::iterator hodsEnd = hods.end();
		for(; hodIter != hodsEnd; ++hodIter) {
			HitObjectDisplay * hod = *hodIter;
			if([hod wasHit: location atTime: milliseconds]) {
				// wasHit should remove the object if it needed to be removed
				cout << "hit something!" << endl;;
				break;
			}
		}
		if(hodIter == hodsEnd) {
			// Tapped somewhere on the screen that doesn't correspond to a HitObject.
			// Reset the multiplier back to 1x.
		}
		
		
	}
}

- (void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if(!hods.empty()) {
		UITouch* touch = [touches anyObject];
		CGPoint location = [self convertTouchToNodeSpace: touch];
		
		double milliseconds = [musicPlayer currentPlaybackTime] * 1000.0f;
		milliseconds += 850; // offset for gee norm
		
		HitObjectDisplay * hod = (*hods.begin()); // first HOD
		[hod wasHeld:location atTime:milliseconds];
	}
	/*
	 CGPoint location = [self convertTouchToNodeSpace: touch];
	 [(HODSlider*)[self getChildByTag:0] slider].position = ccp(location.x, location.y);
	 */
}

- (void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	//NSLog(@"hey i was called ~neato");
}


// this is generally caleld by one of the HitObjectDisplays.
- (void) removeHitObjectDisplay: (HitObjectDisplay*)hod {
	hods.remove(hod);
	[self removeChild:hod cleanup:true];
}

// type is 300, 100, 0
- (void) spawnReaction: (int)type pos: (CGPoint)pos {
	
	NSLog(@"in spawn reaction, should change score....");	
	CCSprite *burst;
	
	// change this to fail, blue, and red
	if (type == 1000){
		burst = [CCSprite spriteWithFile:@"starburst-128.png"];
		burst.scale = 2;
	}
	else if(type == 300) {
		burst = [CCSprite spriteWithFile:@"starburst-128.png"];
	} else if(type == 100) {
		burst = [CCSprite spriteWithFile:@"starburst-blue-128.png"];
	} else if (type == 0) {
		burst = [CCSprite spriteWithFile:@"fail-128.png"];
	}
	else if (type == -1){
		burst = [CCSprite spriteWithFile:@"fail-128.png"];
		burst.scale = 3;
		type = 0;
	}
	[scoreBoard hitWith:type];
	
	
	id removeAction = [CCCallBlock actionWithBlock:^{
		[self removeChild:burst cleanup:true];
	}];
	
	burst.position = pos;
	//burst.scale = 0.75;
	[burst runAction: [CCFadeOut actionWithDuration:0.1]];
	[burst runAction: [CCSequence actions:[CCRotateBy actionWithDuration:0.1 angle:0], removeAction, nil] ];
	[self addChild:burst z: INT_MAX];
}


// on "dealloc" you need to release all your retained objects

-(void) continueGame:(id) sender
{
	[self removeChild:black cleanup:true];
	[self removeChild:menu cleanup:true];
	[self resumeTimersForHierarchy];
	[albumArt runAction:[CCFadeTo actionWithDuration:0.01 opacity:255]];

	[musicPlayer play];
	paused = false;
}
-(void) backToMain:(id)sender
{
	
	[[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.5f scene:[MenuScene scene]]];
}

- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
