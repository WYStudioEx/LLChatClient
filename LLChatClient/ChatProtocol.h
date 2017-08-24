//
//  ChatProtocol.h
//  TCPClientDemo1407
//
//  Created by mac on 14-10-13.
//  Copyright (c) 2014年 zhang jian. All rights reserved.
//

#ifndef TCPClientDemo1407_ChatProtocol_h
#define TCPClientDemo1407_ChatProtocol_h

//聊天客户端和服务端的通讯协议
#define LLChatStart "LLChatStart"
//定义请求头结构体
typedef enum ChatRequestType {
    ChatRequestTypeUnkonw =0,
    ChatRequestTypeRegister=1,
    ChatRequestTypeLogin,
    ChatRequestTypeLogout,
    ChatRequestTypeSendMessage,
    ChatRequestTypeReciveMessage,
    ChatRequestTypeUploadHeadImage,
    ChatRequestTypeDeleteHeadImage,
    ChatRequestTypeAudioMessage,
}ChatRequestType;

typedef struct ChatRequestHead
{
    ChatRequestType type;   //请求类型
    int subType;    //请求子类型
    int length; //附加内容长度
    char start[12];//作为标识信息的开始头
}ChatRequestHead;



//响应头
typedef struct ChatResponseHead
{
    int statusCode; //状态码
    char message[128];
}ChatResponseHead;

//=========注册请求=========
typedef struct ChatRegisterRequest
{
    ChatRequestHead head;
    char username[32];
    char password[32];
    char email[64];
}ChatRegisterRequest;

//========登录请求=======
typedef struct ChatLoginRequest
{
    ChatRequestHead head;
    char username[32];
    char password[32];
}ChatLoginRequest;

//========上传头像=======
typedef struct ChatUploadHeadImageRequest
{
    ChatRequestHead head;
    char username[32];
    Byte picture[80000];//限制图片8M
}ChatUploadHeadImageRequest;

//========语音消息=======
typedef struct ChatAudioMessageRequest
{
    ChatRequestHead head;
    char username[32];
    Byte audioData[736];//没包大小736
}ChatAudioMessageRequest;

#endif
