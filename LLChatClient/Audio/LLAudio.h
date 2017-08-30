//
//  LLAudio.h
//  LLChatClient
//
//  Created by luo luo on 23/08/2017.
//  Copyright © 2017 luo luo. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LLAudioDelegete <NSObject>

@optional
@property(nonatomic,copy)NSString *audioData;
-(void)sendData:(NSData *)data;

@end

@interface LLAudio : NSObject
+ (instancetype)sharedInstance ;
//开始录音和播放
-(void)startRecoderAndPlay;
//接收录音数据的数组，本用来放入播放队列
@property(nonatomic,strong) NSMutableArray *receiveData;

@property(nonatomic,weak)id<LLAudioDelegete> delegete;

@end
