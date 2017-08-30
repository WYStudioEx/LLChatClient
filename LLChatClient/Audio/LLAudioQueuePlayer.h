//
//  LLAudioQueuePlayer.h
//  LLChatClient
//
//  Created by luo luo on 29/08/2017.
//  Copyright © 2017 luo luo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#define kXDXRecoderAACFramesPerPacket       1024


@interface LLAudioQueuePlayer : NSObject{
    
}

//接收录音数据的数组，本用来放入播放队列
@property(nonatomic,strong) NSMutableArray *receiveData;

-(void)setAudioFormat:(AudioStreamBasicDescription )format;

+ (instancetype)sharedInstance;
//开始播放
-(void)startPlay;
-(void)stop;
@end
