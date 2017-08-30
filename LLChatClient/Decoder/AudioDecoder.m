//
//  AudioDecoder.m
//  LLChatClient
//
//  Created by luo luo on 29/08/2017.
//  Copyright © 2017 luo luo. All rights reserved.
//

#import "AudioDecoder.h"


@implementation AudioDecoder

void *aac_decoder_create(int sample_rate, int channels, int bit_rate)
{
    AACDFFmpeg *pComponent = (AACDFFmpeg *)malloc(sizeof(AACDFFmpeg));
     av_register_all();
    AVCodec *pCodec = avcodec_find_decoder(AV_CODEC_ID_AAC);
    if (pCodec == NULL)
    {
        printf("find aac decoder error\r\n");
        return 0;
    }
    // 创建显示contedxt
    pComponent->pCodecCtx = avcodec_alloc_context3(pCodec);
    pComponent->pCodecCtx->channels = channels;
    pComponent->pCodecCtx->sample_rate = sample_rate;
    pComponent->pCodecCtx->bit_rate = bit_rate;
    if(avcodec_open2(pComponent->pCodecCtx, pCodec, NULL) < 0)
    {
        printf("open codec error\r\n");
        return 0;
    }
    
    pComponent->pFrame = av_frame_alloc();
    
    
    uint64_t out_channel_layout = channels < 2 ? AV_CH_LAYOUT_MONO:AV_CH_LAYOUT_STEREO;
    int out_nb_samples = 1024;
    enum AVSampleFormat out_sample_fmt = AV_SAMPLE_FMT_S16;
    
    pComponent->au_convert_ctx = swr_alloc();
    pComponent->au_convert_ctx = swr_alloc_set_opts(pComponent->au_convert_ctx, out_channel_layout, out_sample_fmt, sample_rate,
                                                    out_channel_layout, AV_SAMPLE_FMT_FLTP, sample_rate, 0, NULL);
    swr_init(pComponent->au_convert_ctx);
    int out_channels = av_get_channel_layout_nb_channels(out_channel_layout);
    pComponent->out_buffer_size = av_samples_get_buffer_size(NULL, out_channels, out_nb_samples, out_sample_fmt, 1);
    
    return (void *)pComponent;
}

int aac_decode_frame(void *pParam, unsigned char *pData, int nLen, unsigned char *pPCM, unsigned int *outLen)
{
    AACDFFmpeg *pAACD = (AACDFFmpeg *)pParam;
    AVPacket packet;
    av_init_packet(&packet);
    
    packet.size = nLen;
    packet.data = pData;
    
    int got_frame = 0;
    int nRet = 0;
    if (packet.size > 0)
    {
        nRet = avcodec_decode_audio4(pAACD->pCodecCtx, pAACD->pFrame, &got_frame, &packet);
        if (nRet < 0)
        {
            printf("avcodec_decode_audio4:%d\r\n",nRet);
            printf("avcodec_decode_audio4 %d  sameles = %d  outSize = %d\r\n", nRet, pAACD->pFrame->nb_samples, pAACD->out_buffer_size);
            return nRet;
        }
        
        if(got_frame)
        {
            swr_convert(pAACD->au_convert_ctx, &pPCM, pAACD->out_buffer_size, (const uint8_t **)pAACD->pFrame->data, pAACD->pFrame->nb_samples);
            *outLen = pAACD->out_buffer_size;
        }
    }
    
    av_free_packet(&packet);
    if (nRet > 0)
    {
        return 0;
    }
    return -1;
}

void aac_decode_close(void *pParam)
{
    AACDFFmpeg *pComponent = (AACDFFmpeg *)pParam;
    if (pComponent == NULL)
    {
        return;
    }
    
    swr_free(&pComponent->au_convert_ctx);
    
    if (pComponent->pFrame != NULL)
    {
        av_frame_free(&pComponent->pFrame);
        pComponent->pFrame = NULL;
    }
    
    if (pComponent->pCodecCtx != NULL)
    {
        avcodec_close(pComponent->pCodecCtx);
        avcodec_free_context(&pComponent->pCodecCtx);
        pComponent->pCodecCtx = NULL;
    }
    
    free(pComponent);
}
@end
