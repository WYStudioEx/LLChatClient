//
//  LLAudio.m
//  LLChatClient
//
//  Created by luo luo on 23/08/2017.
//  Copyright © 2017 luo luo. All rights reserved.
//

#import "LLAudio.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
/**
 *  缓存区的个数，一般3个
 */
#define kNumberAudioQueueBuffers 3

/**
 *  采样率，要转码为amr的话必须为8000
 */
#define kDefaultSampleRate 4410
#define kDefaultInputBufferSize 1024*4
#define kDefaultOutputBufferSize 1024*4 //7040
#define PackageSize 1024 //录音包，每包最大字节数

#define kXDXRecoderPCMTotalPacket           512

@interface LLAudio()
@property (assign, nonatomic) AudioQueueRef                 inputQueue;
@property (assign, nonatomic) AudioQueueRef                 outputQueue;

//录音数据
@property(nonatomic,strong)NSMutableData *recorderData;

@end
@implementation LLAudio{
    AudioQueueRef                   _inputQueue;
    AudioQueueRef                   _outputQueue;
    AudioStreamBasicDescription     _audioFormat;//存放音频格式
    
    AudioQueueBufferRef     _inputBuffers[kNumberAudioQueueBuffers];
    AudioQueueBufferRef     _outputBuffers[kNumberAudioQueueBuffers];
}
+ (instancetype)sharedInstance {
    static LLAudio *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[LLAudio alloc] init];
    });
    
    return manager;
}

-(NSMutableArray *)receiveData
{
    if (!_receiveData) {
        _receiveData = [[NSMutableArray alloc]init];
    }
    return _receiveData;
}
-(NSMutableData *)recorderData
{
    if (!_recorderData) {
        _recorderData = [[NSMutableData alloc]init];
    }
    return _recorderData;
}

//开始录音和播放
-(void)startRecoderAndPlay
{
    //设置录音和播放的参数
    [self setupAudioFormat];
    //创建一个录制音频队列
    AudioQueueNewInput (&(_audioFormat),GenericInputCallback,(__bridge void *)self,NULL,NULL,0,&_inputQueue);
    //创建一个输出队列
    AudioQueueNewOutput(&_audioFormat, GenericOutputCallback, (__bridge void *) self, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 0,&_outputQueue);
    
    NSError *error = nil;
    //设置audioSession格式 录音播放模式
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;  //设置成扬声器模式
//    audioRouteOverride = kAudioSessionOverrideAudioRoute_None;  //设置成听筒
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
                             sizeof (audioRouteOverride),
                             &audioRouteOverride);
    [[AVAudioSession sharedInstance]setActive:YES error:nil];
    //创建录制音频队列缓冲区
    for (int i = 0; i < kNumberAudioQueueBuffers; i++) {
        AudioQueueAllocateBuffer (_inputQueue,kDefaultInputBufferSize,&_inputBuffers[i]);
        
        AudioQueueEnqueueBuffer (_inputQueue,(_inputBuffers[i]),0,NULL);
    }
    
    // 创建并分配缓冲区空间 4个缓冲区
    for (int i = 0; i<kNumberAudioQueueBuffers; ++i)
    {
        AudioQueueAllocateBuffer(_outputQueue, kDefaultOutputBufferSize, &_outputBuffers[i]);
        makeSilent(_outputBuffers[i]);  //改变数据
        //插入Buttf
        AudioQueueEnqueueBuffer(_outputQueue,_outputBuffers[i],0,NULL);
    }
    Float32 gain = 1.0;                                       // 1
    // Optionally, allow user to override gain setting here 设置音量
    AudioQueueSetParameter (_outputQueue,kAudioQueueParam_Volume,gain);
    
    //开启录制队列
    AudioQueueStart(self.inputQueue, NULL);
    //开启播放队列
    AudioQueueStart(_outputQueue,NULL);
    
    
}

-(void)stop
{
    AudioQueueStop ( self.outputQueue,true);
    AudioQueueDispose (self.outputQueue, true );//并且
    AudioQueueStop ( self.inputQueue,true);
    AudioQueueDispose (self.inputQueue, true );
}

#pragma mark -  录音回调
void GenericInputCallback (
                           void                                *inUserData,
                           AudioQueueRef                       inAQ,
                           AudioQueueBufferRef                 inBuffer,
                           const AudioTimeStamp                *inStartTime,
                           UInt32                              inNumberPackets,
                           const AudioStreamPacketDescription  *inPacketDescs
                           )
{
    LLAudio *manage = (__bridge LLAudio *)(inUserData);
    if (inNumberPackets > 0) {
        NSData *pcmData = [[NSData alloc] initWithBytes:inBuffer->mAudioData length:inBuffer->mAudioDataByteSize];
        NSLog(@"pcmData长度＝%ld",(unsigned long)pcmData.length);
        if (pcmData && pcmData.length > 0) {
            //发送服务器
//            [manage handleRecorderData:pcmData];
            
            //测试播放
             [manage.receiveData addObject:pcmData];
            //@end
        }
        
    }
    AudioQueueEnqueueBuffer (inAQ,inBuffer,0,NULL);
    
}

-(void)handleRecorderData:(NSData *)data {//此处只发送长度足够736字节的数据
    [self.recorderData appendData:data];
    if (self.recorderData.length>PackageSize) {//没有等于736，确保最后一包有数据发送
        NSData *packageData=[self.recorderData subdataWithRange:NSMakeRange(0, PackageSize)];
        
        long lackLength=self.recorderData.length-PackageSize;//裁剪后剩余的长度
        NSData *lackData=[self.recorderData subdataWithRange:NSMakeRange(PackageSize, lackLength)];
        [self.recorderData setData:lackData];
        
        if (self.delegete && [self.delegete respondsToSelector:@selector(sendData:)]) {
            //发送数据
            [self.delegete sendData:packageData];
        }
        
    }
    
}


#pragma mark 播放数据装入
// 输出回调---如需播放把如下打开
void GenericOutputCallback (
                            void                 *inUserData,
                            AudioQueueRef        inAQ,
                            AudioQueueBufferRef  inBuffer
                            )
{
   
   
    LLAudio *manage = (__bridge LLAudio *)(inUserData);
     NSLog(@"播放回调现有数据包:%d",(int)manage.receiveData.count);
    if([manage.receiveData count] >0)
    {
        NSData *pcmData = [manage.receiveData objectAtIndex:0];
        NSLog(@"播放数据长度为＝%lu",(unsigned long)pcmData.length);
     
        if (pcmData) {
            if(pcmData.length < 10000){
                memcpy(inBuffer->mAudioData, pcmData.bytes, pcmData.length);//将数据拷贝到缓存
                inBuffer->mAudioDataByteSize = (UInt32)pcmData.length;
                inBuffer->mPacketDescriptionCount = 0;
            }
        }
        //测试播放
         [manage.receiveData removeObjectAtIndex:0];
        //@end
       
    }
    else
    {
        makeSilent(inBuffer);
    }
    AudioQueueEnqueueBuffer(manage.outputQueue,inBuffer,0,NULL);
}


#pragma mark 其它
// 设置录音格式
- (void)setupAudioFormat
{
    //重置下
    memset(&_audioFormat, 0, sizeof(_audioFormat));
    
    //采样率的意思是每秒需要采集的帧数
    _audioFormat.mSampleRate = kDefaultSampleRate;//[[AVAudioSession sharedInstance] sampleRate];
    
    //设置通道数,这里先使用系统的测试下 //TODO:
    _audioFormat.mChannelsPerFrame = 1;//(UInt32)[[AVAudioSession sharedInstance] inputNumberOfChannels];
    
    //设置format，怎么称呼不知道。
    _audioFormat.mFormatID = kAudioFormatLinearPCM;
    
    if (_audioFormat.mFormatID == kAudioFormatLinearPCM){
        //这个屌属性不知道干啥的。，
        _audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        //每个通道里，一帧采集的bit数目
        _audioFormat.mBitsPerChannel = 16;
        //结果分析: 8bit为1byte，即为1个通道里1帧需要采集2byte数据，再*通道数，即为所有通道采集的byte数目。
        //所以这里结果赋值给每帧需要采集的byte数目，然后这里的packet也等于一帧的数据。
        //至于为什么要这样。。。不知道。。。
        _audioFormat.mBytesPerPacket = _audioFormat.mBytesPerFrame = (_audioFormat.mBitsPerChannel / 8) * _audioFormat.mChannelsPerFrame;
        _audioFormat.mFramesPerPacket = 1;
    }
}

//把缓冲区置空
void makeSilent(AudioQueueBufferRef buffer)
{
    for (int i=0; i < buffer->mAudioDataBytesCapacity; i++) {
        buffer->mAudioDataByteSize = buffer->mAudioDataBytesCapacity;
        UInt8 * samples = (UInt8 *) buffer->mAudioData;
        samples[i]=0;
    }
}


@end
