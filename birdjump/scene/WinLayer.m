//
//  WinLayer.m
//  birdjump
//
//  Created by Eric on 12-11-21.
//  Copyright (c) 2012年 Symetrix. All rights reserved.
//

#import "WinLayer.h"
#import "MenuLayer.h"
#import "BirdSprite.h"
#import "BonusSprite.h"

#define mPI 3.1415f

enum{
    tMenu=111,
    tRefresh,
    tNextLevel,
};

enum{
    tParticle,
};

@implementation WinLayer{
    BOOL isUpdatingScore;
    float scoreTemp;
    
}
@synthesize scoreLabel;
@synthesize score;
@synthesize loopSound;
@synthesize birdSprite;



-(id) init
{
	[super init];
    
    NSUserDefaults* def=[NSUserDefaults standardUserDefaults];
    int currentLevel=[def integerForKey:UDF_LEVEL_SELECTED];
    [def setInteger:currentLevel forKey:UDF_LEVEL_PASSED];
    
    if (IS_IPHONE_5) {
        [self setBgWithFileName:@"bg-568h@2x.jpg"];
    }else{
        [self setBgWithFileName:SD_OR_HD(@"bg.jpg")];
    }
    [self initSpriteSheet];
    
    
    //旋转金币圈动画
    CCNode* bonusNode1=[CCNode node];
    CCNode* bonusNode2=[CCNode node];
    int radius1=IS_IPAD? 100:50;
    int radius2=IS_IPAD? 200:100;
    int count=10;
    CGPoint birdPosition=ccp(self.boundingBox.size.width/2, self.boundingBox.size.height*2/3);
    for (int i=0; i<count; i++) {
        CCSprite* bs= [CCSprite spriteWithSpriteFrameName:@"atile-coin-gold.png"];
        [bonusNode1 addChild:bs];
        bs.position=ccp(radius1*cos(2*mPI/count*i), radius1*sin(2*mPI/count*i));
    }
    bonusNode1.position=birdPosition;
    [bonusNode1 runAction:[CCRepeatForever actionWithAction:[CCRotateTo actionWithDuration:4 angle:360*2]]];
    for (int i=0; i<count; i++) {
        CCSprite* bs= [CCSprite spriteWithSpriteFrameName:@"atile-coin-blue.png"];
        [bonusNode2 addChild:bs];
        bs.position=ccp(radius2*cos(2*mPI/count*i), radius2*sin(2*mPI/count*i));
    }
    bonusNode2.position=birdPosition;
    [bonusNode2 runAction:[CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:4 angle:-360*2]]];
    [self addChild:bonusNode1];
    [self addChild:bonusNode2];
    //role跳跃动画
    birdSprite=[CCSprite spriteWithSpriteFrameName:@"player01_balloon_0022.png"];
    birdSprite.position=birdPosition;
    [self addChild:birdSprite];
    
    //分数
    self.scoreLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:kWIN_SCORE_MODEL,0 ] fntFile:@"futura-48.fnt"];
    scoreLabel.position=ccp(winSize.width/2, winSize.height*1/3);
    scoreLabel.scale=HD2SD_SCALE;
    [self addChild:scoreLabel];
    isUpdatingScore=false;
    scoreTemp=0;
    //    score=100;
    [self performSelector:@selector(calculateScore) withObject:nil afterDelay:1];
    
    
    
    //操作菜单
    CCMenu* menuButton= [SpriteUtil createMenuWithFrame:@"button_menu.png" pressedColor:ccYELLOW target:self selector:@selector(menu)];
    menuButton.position=ccp(winSize.width/2-(IS_IPAD?200:100), winSize.height*1/3-(IS_IPAD?100:50));
    menuButton.Visible=NO;
    [self addChild:menuButton z:zAboveOperation tag:tMenu];
    
    CCMenu* restartButton= [SpriteUtil createMenuWithFrame:@"button_refresh.png" pressedColor:ccYELLOW target:self selector:@selector(restart)];
    restartButton.position=ccp(winSize.width/2, winSize.height*1/3-(IS_IPAD?100:50));
    restartButton.Visible=NO;
    [self addChild:restartButton z:zAboveOperation tag:tRefresh];
    
    CCMenu* nextLevelButton= [SpriteUtil createMenuWithFrame:@"button_next_level.png" pressedColor:ccYELLOW target:self selector:@selector(nextLevel)];
    nextLevelButton.position=ccp(winSize.width/2+(IS_IPAD?200:100), winSize.height*1/3-(IS_IPAD?100:50));
    nextLevelButton.Visible=NO;
    [self addChild:nextLevelButton z:zAboveOperation tag:tNextLevel];
    return self;
}

-(void)calculateScore{
    if (score>0) {
        if ([SysConfig needAudio]){
            self.loopSound = [[SimpleAudioEngine sharedEngine] soundSourceForFile:@"gamescorescreen_score_count_loop.wav"];
            loopSound.looping = YES;
            [loopSound play];
        }
        [self schedule:@selector(displayScoreAnim)  interval:0.1];
    }
    
    
}
/*
 3秒结束
 1秒显示s/3分
 1秒刷新(x=10，interval=0.1)次
 1次刷新t分
 
 x次*t分*3秒=score
 
 */
-(void)displayScoreAnim{
    scoreTemp+=score/(2.0*10);
    [scoreLabel setString:[NSString stringWithFormat:kWIN_SCORE_MODEL,scoreTemp<score?(int)scoreTemp:score]];
    if (scoreTemp>=score) {
        [self unschedule:@selector(displayScoreAnim)];
        if ([SysConfig needAudio]){
            loopSound.looping=NO;
            [loopSound stop];
            [loopSound release];
            //unloadEffect 是必须的，否则声音还是一直在响
            [[SimpleAudioEngine sharedEngine] unloadEffect:@"gamescorescreen_score_count_loop.wav"];
        }
        [self performSelector:@selector(displayBirdAnim) withObject:nil afterDelay:0.5f];
        [self performSelector:@selector(showMenuButton) withObject:nil afterDelay:0.5f];
    }
    
}
-(void)showMenuButton{
    CCMenu* m=(CCMenu*)[self getChildByTag:tMenu];
    m.visible=YES;
    CCMenu* r=(CCMenu*)[self getChildByTag:tRefresh];
    r.visible=YES;
    CCMenu* n=(CCMenu*)[self getChildByTag:tNextLevel];
    n.visible=YES;
}
-(void)displayBirdAnim{
    if ([SysConfig needAudio]){
        [[SimpleAudioEngine sharedEngine] playEffect:@"cheer.wav"];
    }
    NSArray* upAnimFrames=[NSArray arrayWithObjects:
                           [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"player01_balloon_0023.png"],
                           [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"player01_balloon_0022.png"],
                           nil];
    //4)创建动画对象
    CCAnimation *upAnim = [CCAnimation
                           animationWithSpriteFrames:upAnimFrames delay:0.2f];
    [birdSprite runAction: [CCRepeatForever actionWithAction:
                            [CCAnimate actionWithAnimation:upAnim]]];
    
    CCParticleSystem *particles = [CCParticleSystemQuad particleWithFile:@"winstart.plist"];
    [particles setPosition:ccp(birdSprite.position.x, birdSprite.position.y- 200 )];
    [self addChild:particles z:1 tag:tParticle];
    [self performSelector:@selector(stopParitcle:) withObject:particles afterDelay:3] ;
    
}
-(void)stopParitcle:(CCParticleSystem*)p{
    [p stopSystem];
}
-(void)initSpriteSheet{
    //init---- character.png
    [BirdSprite initSpriteSheet:self];
    [BonusSprite initSpriteSheet:self];
    //初始化按钮sheet
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:SD_HD_PLIST(@"button_sheet.plist")];
    CCSpriteBatchNode *buttonSpriteSheet = [CCSpriteBatchNode
                                            batchNodeWithFile:@"button_sheet.png"];
    //这里tCharacterManager的z要在tSpriteManager之上，这样此才不会被覆盖
    [self addChild:buttonSpriteSheet z:zButtonSpriteSheet tag:tButtonManager];
}

-(void) menu
{
	CCScene *sc = [CCScene node];
	[sc addChild:[MenuLayer node]];
	[[CCDirector sharedDirector] replaceScene:  [CCTransitionSplitRows transitionWithDuration:1.0f scene:sc]];
}
-(void) restart
{
	CCScene *sc =[GameLayer scene];
    [[CCDirector sharedDirector] replaceScene: [CCTransitionSplitRows transitionWithDuration:1.0f scene:sc]];
}
-(void)nextLevel{
    NSUserDefaults* def=[NSUserDefaults standardUserDefaults];
    int currentLevel=[def integerForKey:UDF_LEVEL_SELECTED];
    if (currentLevel<kMAX_LEVEL_REAL) {
        [def setInteger:currentLevel+1 forKey:UDF_LEVEL_SELECTED];
        CCScene *sc =[GameLayer scene];
        [[CCDirector sharedDirector] replaceScene: [CCTransitionSplitRows transitionWithDuration:1.0f scene:sc]];
    }
}

@end
