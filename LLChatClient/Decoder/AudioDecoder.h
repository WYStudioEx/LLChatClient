//
//  AudioDecoder.h
//  LLChatClient
//
//  Created by luo luo on 29/08/2017.
//  Copyright © 2017 luo luo. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "libavformat/avformat.h"
#include "libswresample/swresample.h"
#include "libavcodec/avcodec.h"

typedef struct AACDFFmpeg {
    AVCodecContext *pCodecCtx;
    AVFrame *pFrame;
    struct SwrContext *au_convert_ctx;
    int out_buffer_size;
} AACDFFmpeg;

@interface AudioDecoder : NSObject

void *aac_decoder_create(int sample_rate, int channels, int bit_rate);
int aac_decode_frame(void *pParam, unsigned char *pData, int nLen, unsigned char *pPCM, unsigned int *outLen);
void aac_decode_close(void *pParam);

@end
