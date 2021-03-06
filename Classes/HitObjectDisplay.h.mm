//
//  CCHitObject.h
//  Cocos2dLesson1
//
//  Created by Max Wittek on 3/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "osu-import.h.mm"

@class GameScene; // forward decl???

@interface HitObjectDisplay : CCLayer {
	HitObject * hitObject;
	int red;
	int green;
	int blue;
	double initialScale;
	int disappearTimeMs;
}

- (id) initWithHitObject: (HitObject*)hitObject_ red: (int)r green: (int)g blue: (int)b;
- (id) initWithHitObject: (HitObject*)hitObject_ red: (int)r green: (int)g blue: (int)b initialScale: (double)s;
- (void) appearWithDuration: (double)duration;
- (void) setOpacity: (GLubyte) opacity;


- (int) disappearTime;
- (int) pointsAtDisappearTime;
- (BOOL) wasHit: (CGPoint)location atTime: (NSTimeInterval)time;
- (BOOL) wasHeld: (CGPoint)location atTime: (NSTimeInterval)time;
- (void) wasReleased;

// for editor
- (void) regenTexture;

// shortcut to cast parent as a GameScene
- (GameScene*) gsParent;

// stuff pertaining to touch processing

@property HitObject* hitObject;

@end
