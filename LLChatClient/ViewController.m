//
//  ViewController.m
//  LLChatClient
//
//  Created by luo luo on 22/08/2017.
//  Copyright © 2017 luo luo. All rights reserved.
//

#import "ViewController.h"
#import "AsyncSocket.h"
#import "ChatProtocol.h"

@interface ViewController ()<AsyncSocketDelegate>
@property (weak, nonatomic) IBOutlet UITextField *userNameTF;
@property (weak, nonatomic) IBOutlet UITextField *passwordTF;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController{
    //用于连接服务端的socket
    AsyncSocket *_clientSocket;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //使用AsyncSocket和TCP协议实现客户端
    //功能:
    //  1.客户端连接服务端
    //      10.3.132.7 5678
    //  2.客户端给服务端发送消息
    //  3.服务端接收消息
    
    //TCP特性
    //1.有连接的, 发送数据之前首先连接服务器
    //2.可靠的, 数据发送过去一般不会有数据丢失等问题
    //3.速度相对UDP较慢
    
    
    //创建
    _clientSocket = [[AsyncSocket alloc] initWithDelegate:self];
    
    //TCP需要连接服务器才能发送数据
    //注意: 不是一旦执行连接方法就连接成功的
    NSError *error = nil;
    // 10.3.132.7   127.0.0.1
    [_clientSocket connectToHost:@"192.168.1.103" onPort:5678 withTimeout:-1 error:&error];
    if(error != nil)
    {
        NSLog(@"连接方法执行失败");
    }

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark ClickAction
- (IBAction)loginAction:(UIButton *)sender {
    //创建登录请求
    ChatLoginRequest request;
    request.head.type = ChatRequestTypeLogin;
    strcpy(request.username, self.userNameTF.text.UTF8String);
    strcpy(request.password, self.passwordTF.text.UTF8String);
    
    //发送请求
    NSData *sendData = [[NSData alloc] initWithBytes:&request length:sizeof(ChatLoginRequest)];
    [_clientSocket writeData:sendData withTimeout:-1 tag:100];
}

- (IBAction)RegisterAction:(UIButton *)sender {
    //创建请求
    ChatRegisterRequest request;
    request.head.type = ChatRequestTypeRegister;
    strcpy(request.username,self.userNameTF.text.UTF8String);
    strcpy(request.password,self.passwordTF.text.UTF8String);
    
    //发送
    NSData *data = [[NSData alloc] initWithBytes:&request length:sizeof(ChatRegisterRequest)];
    [_clientSocket writeData:data withTimeout:-1 tag:100];
}
- (IBAction)uploadImageAction:(UIButton *)sender {
    ChatUploadHeadImageRequest request;
    request.head.type = ChatRequestTypeUploadHeadImage;
    
    NSData *data = UIImagePNGRepresentation([UIImage imageNamed:@"yiluyasha.png"]);
    
    
    request.head.length = (int)data.length;
    Byte *image = (Byte *)[data bytes];
    strcpy(request.username,self.userNameTF.text.UTF8String);
    memset(request.picture, 0, sizeof(request.picture));
    memcpy(request.picture, image, data.length);
    NSLog(@"真实长度:%d headlenght:%d",(int)data.length,request.head.length);
    //发送
    NSData *data2 = [[NSData alloc] initWithBytes:&request length:sizeof(ChatUploadHeadImageRequest)];
    [_clientSocket writeData:data2 withTimeout:-1 tag:100];
    NSLog(@"SendDataLenght:%d",(int)data2.length);
}

#pragma mark AsyncSocketDelegate
//代理方法, 当发送完数据之后执行
-(void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    //准备读取数据
    [_clientSocket readDataWithTimeout:-1 tag:100];
}
//代理方法, 当接收到数据之后执行
-(void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    ChatResponseHead head;
    [data getBytes:&head length:sizeof(ChatResponseHead)];
    NSLog(@"code=%d message=%s",head.statusCode,head.message);
}



//代理方法, 当连接成功后执行
-(void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"连接成功");
}


-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


@end
