//
//  PooRobotControlViewController.m
//  MyRobot
//
//  Created by crazypoo on 14/9/3.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import "PooRobotControlViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

@interface PooRobotControlViewController ()<JSAnalogueStickDelegate>
{
    EV3Device *devicData;
    UISlider *goSlider;
    UISlider *leftRightSlider;
    JSDPad *dPad;
    JSButton *aButton;
    JSButton *bButton;
    NSMutableArray *_pressedButtons;
    
    UIButton *closeSharingBtn;
    UIButton *connectBtn;
    
    UIButton *connect;
    UIButton *stopBtn;
    
    dispatch_queue_t videoFrameProcessQueue;
}

@property(nonatomic, strong) NSDate *timingDate;

@property (strong,nonatomic) UIView *videoPreviewView;
@property (strong,nonatomic) UIView *videosView;
@property (strong,nonatomic) UIImageView *aImageView;

@property(nonatomic, strong) UIImage *frameImage;
@property(nonatomic, strong) CIImage *ciImage;
@property(nonatomic, strong) CIContext *ciContext;

@property (strong,nonatomic) MCSession *session;
@property (strong,nonatomic) MCAdvertiserAssistant *advertiserAssistant;
@property (strong,nonatomic) MCBrowserViewController *browserController;

@property(nonatomic, strong) AVCaptureSession *AVSession;

- (NSString *)stringForDirection:(JSDPadDirection)direction;

@end

@implementation PooRobotControlViewController

-(id)initDeviceData:(EV3Device *)data
{
    self = [super init];
    if (self) {
        devicData = data;
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [Utils alertVCWithTitle:@"页面功能选择" message:@"选择该页面功能" cancelTitle:@"接收" okTitle:@"广播" shouIn:self okAction:^{
        [self createPlayerView];
    } cancelAction:^{
        [self createCarPlayerView];
    }];
}

-(void)createPlayerView
{
    [self createDefultData:@"Robot_Advertiser"];
    //创建广播
    self.advertiserAssistant = [[MCAdvertiserAssistant alloc]initWithServiceType:@"cmj-stream" discoveryInfo:nil session:self.session];
    self.advertiserAssistant.delegate = self;
    [self.advertiserAssistant start];
    
    [self createVideoView:0];
    
    [self createGamePadView];
}

-(void)createCarPlayerView
{
    [self createDefultData:@"Robot"];
    
    self.browserController = [[MCBrowserViewController alloc]initWithServiceType:@"cmj-stream" session:self.session];
    self.browserController.delegate = self;
    [self presentViewController:self.browserController animated:YES completion:nil];
    
    [self createVideoView:1];
}

-(void)createDefultData:(NSString *)peerIDs
{
    MCPeerID *peerID = [[MCPeerID alloc]initWithDisplayName:peerIDs];
    self.session = [[MCSession alloc]initWithPeer:peerID];
    self.session.delegate = self;
}

-(void)createVideoView:(NSInteger)viewType
{
    self.videosView = [UIView new];
    self.videosView.backgroundColor = kRandomColor;
    [self.view addSubview:self.videosView];
    [self.videosView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(HEIGHT_NAVBAR);
        switch (viewType) {
            case 0:
            {
                make.bottom.equalTo(self.view.mas_centerY);
            }
                break;
            default:
            {
                make.bottom.equalTo(self.view);
            }
                break;
        }
    }];
    
    self.aImageView = [UIImageView new];
    [self.videosView addSubview:self.aImageView];
    [self.aImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self.videosView);
    }];
    
    self.videoPreviewView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 90, 135)];
    self.videoPreviewView.backgroundColor = kRandomColor;
    [self.videosView addSubview:self.videoPreviewView];
    [self.videoPreviewView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self.videosView);
        make.width.offset(90);
        make.height.offset(135);
    }];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = self.videoPreviewView.bounds;
    UIBezierPath *roundedPath = [UIBezierPath bezierPathWithRoundedRect:maskLayer.bounds byRoundingCorners:UIRectCornerTopLeft cornerRadii:CGSizeMake(5.0, 5.0)];
    maskLayer.fillColor = [[UIColor whiteColor] CGColor];
    maskLayer.backgroundColor = [[UIColor clearColor] CGColor];
    maskLayer.path = [roundedPath CGPath];
    self.videoPreviewView.layer.mask = maskLayer;
    
    [self setupCaptureSession];
}

-(void)createGamePadView
{
    UIView *customView = [UIView new];
    customView.backgroundColor = kRandomColor;
    [self.view addSubview:customView];
    [customView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.top.equalTo(self.videosView.mas_bottom);
    }];
    
    if (isIPad) {
        dPad = [[JSDPad alloc] initWithFrame:CGRectMake(20, 20, 300, 300)];
        aButton = [[JSButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 140,  140, 120, 120)];
        bButton = [[JSButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 120, 244, 120, 120)];
    }
    else
    {
        dPad = [[JSDPad alloc] initWithFrame:CGRectMake(20, 20, 150, 150)];
        aButton = [[JSButton alloc] initWithFrame:CGRectMake(200, 80, 60, 60)];
        bButton = [[JSButton alloc] initWithFrame:CGRectMake(240, 144, 60, 60)];
    }
    dPad.delegate = self;
    [customView addSubview:dPad];
    
    [[aButton titleLabel] setText:@"A"];
    [aButton setBackgroundImage:[UIImage imageNamed:@"button"]];
    [aButton setBackgroundImagePressed:[UIImage imageNamed:@"button-pressed"]];
    aButton.delegate = self;
    [customView addSubview:aButton];
    
    [[bButton titleLabel] setText:@"B"];
    [bButton setBackgroundImage:[UIImage imageNamed:@"button"]];
    [bButton setBackgroundImagePressed:[UIImage imageNamed:@"button-pressed"]];
    bButton.delegate = self;
    [customView addSubview:bButton];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
//    if (isIPad) {
//        dPad = [[JSDPad alloc] initWithFrame:CGRectMake(20, self.view.frame.size.height - 320, 300, 300)];
//        aButton = [[JSButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 140, self.view.frame.size.height - 140, 120, 120)];
//        bButton = [[JSButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 120, self.view.frame.size.height - 244, 120, 120)];
//
//    }
//    else
//    {
//        dPad = [[JSDPad alloc] initWithFrame:CGRectMake(20, self.view.frame.size.height - 170, 150, 150)];
//        aButton = [[JSButton alloc] initWithFrame:CGRectMake(200, self.view.frame.size.height - 80, 60, 60)];
//        bButton = [[JSButton alloc] initWithFrame:CGRectMake(240, self.view.frame.size.height - 144, 60, 60)];
//    }
//    dPad.delegate = self;
////    [self.view addSubview:dPad];
//
//    [[aButton titleLabel] setText:@"A"];
//    [aButton setBackgroundImage:[UIImage imageNamed:@"button"]];
//    [aButton setBackgroundImagePressed:[UIImage imageNamed:@"button-pressed"]];
//    aButton.delegate = self;
//    [self.view addSubview:aButton];
//
//    [[bButton titleLabel] setText:@"B"];
//    [bButton setBackgroundImage:[UIImage imageNamed:@"button"]];
//    [bButton setBackgroundImagePressed:[UIImage imageNamed:@"button-pressed"]];
//    bButton.delegate = self;
//    [self.view addSubview:bButton];
//
//    _pressedButtons = [NSMutableArray new];
//
//
////    isSendData = YES;
////    isMatchStarted = NO;
//    self.timingDate = [NSDate date];
//
//    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
//
//    videoPreviewView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 90, 135)];
//    videoPreviewView.layer.masksToBounds = YES;
//    CAShapeLayer *maskLayer = [CAShapeLayer layer];
//    maskLayer.frame = videoPreviewView.bounds;
//    UIBezierPath *roundedPath = [UIBezierPath bezierPathWithRoundedRect:maskLayer.bounds byRoundingCorners:UIRectCornerTopLeft cornerRadii:CGSizeMake(5.0, 5.0)];
//    maskLayer.fillColor = [[UIColor whiteColor] CGColor];
//    maskLayer.backgroundColor = [[UIColor clearColor] CGColor];
//    maskLayer.path = [roundedPath CGPath];
//    videoPreviewView.layer.mask = maskLayer;
//
////    [self setupCaptureSession];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:@"WillResignActive" object:[UIApplication sharedApplication]];
//
//
//    connect = [UIButton buttonWithType:UIButtonTypeCustom];
//    connect.backgroundColor = [UIColor redColor];
//    [connect addTarget:self action:@selector(onConnectTap:) forControlEvents:UIControlEventTouchUpInside];
//    [connect setTitle:@"连接" forState:UIControlStateNormal];
//    [self.view addSubview:connect];
//
//    stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    stopBtn.backgroundColor = [UIColor grayColor];
//    [stopBtn addTarget:self action:@selector(onCloseSharingTap:) forControlEvents:UIControlEventTouchUpInside];
//    [stopBtn setTitle:@"取消" forState:UIControlStateNormal];
//    [self.view addSubview:stopBtn];
//
//
//    if (isIPad) {
//        videosView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 700)];
//        connect.frame = CGRectMake(400, 800, 100, 100);
//        stopBtn.frame = CGRectMake(500, 800, 100, 100);
//    }
//    else
//    {
//        videosView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 350)];
//        connect.frame = CGRectMake(130, 380, 50, 50);
//        stopBtn.frame = CGRectMake(180, 380, 50, 50);
//    }
//    aImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, videosView.frame.size.height)];
//    [self.view addSubview:videosView];
//    [videosView addSubview:aImageView];
//    [videosView addSubview:videoPreviewView];
//
//    JSAnalogueStick *aaaaa = [[JSAnalogueStick alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
//    aaaaa.delegate = self;
//    [self.view addSubview:aaaaa];
}

- (void)onConnectTap:(id)sender
{
//    [self startPicker];
}

- (void)onCloseSharingTap:(id)sender
{
//    [self stopSharing];
}

- (void)willResignActive
{
//    [self stopSharing];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)stringForDirection:(JSDPadDirection)direction
{
    NSString *string = nil;
    
    switch (direction) {
        case JSDPadDirectionNone:
            string = @"None";
            break;
        case JSDPadDirectionUp:
            string = @"Up";
            break;
        case JSDPadDirectionDown:
            string = @"Down";
            break;
        case JSDPadDirectionLeft:
            string = @"Left";
            break;
        case JSDPadDirectionRight:
            string = @"Right";
            break;
        case JSDPadDirectionUpLeft:
            string = @"Up Left";
            break;
        case JSDPadDirectionUpRight:
            string = @"Up Right";
            break;
        case JSDPadDirectionDownLeft:
            string = @"Down Left";
            break;
        case JSDPadDirectionDownRight:
            string = @"Down Right";
            break;
        default:
            string = @"None";
            break;
    }
    
    return string;
}

#pragma mark - JSDPadDelegate

- (void)dPad:(JSDPad *)dPad didPressDirection:(JSDPadDirection)direction
{
    if ([[self stringForDirection:direction] isEqualToString:@"Up"])
    {
        NSLog(@"我按了上按钮");
        [devicData turnMotorAtPort:EV3OutputPortB power:-100];
        [devicData turnMotorAtPort:EV3OutputPortC power:-100];
    }
    else if([[self stringForDirection:direction] isEqualToString:@"Down"])
    {
        NSLog(@"下按钮");
        [devicData turnMotorAtPort:EV3OutputPortB power:100];
        [devicData turnMotorAtPort:EV3OutputPortC power:100];
    }
    else if([[self stringForDirection:direction] isEqualToString:@"Left"])
    {
        NSLog(@"左按钮");
        [devicData turnMotorAtPort:EV3OutputPortA power:-100];

    }
    else if([[self stringForDirection:direction] isEqualToString:@"Right"])
    {
        NSLog(@"右按钮");
        [devicData turnMotorAtPort:EV3OutputPortA power:100];
    }
    else if([[self stringForDirection:direction] isEqualToString:@"Up Left"])
    {
        NSLog(@"上左按钮");
        [devicData turnMotorAtPort:EV3OutputPortB power:-100];
        [devicData turnMotorAtPort:EV3OutputPortC power:-100];
        [devicData turnMotorAtPort:EV3OutputPortA power:-100];
    }
    else if([[self stringForDirection:direction] isEqualToString:@"Up Right"])
    {
        NSLog(@"上右按钮");
        [devicData turnMotorAtPort:EV3OutputPortB power:-100];
        [devicData turnMotorAtPort:EV3OutputPortC power:-100];
        [devicData turnMotorAtPort:EV3OutputPortA power:100];
    }
    else if([[self stringForDirection:direction] isEqualToString:@"Down Left"])
    {
        NSLog(@"下左按钮");
        [devicData turnMotorAtPort:EV3OutputPortB power:100];
        [devicData turnMotorAtPort:EV3OutputPortC power:100];
        [devicData turnMotorAtPort:EV3OutputPortA power:-100];
    }
    else if([[self stringForDirection:direction] isEqualToString:@"Down Right"])
    {
        NSLog(@"下右按钮");
        [devicData turnMotorAtPort:EV3OutputPortB power:100];
        [devicData turnMotorAtPort:EV3OutputPortC power:100];
        [devicData turnMotorAtPort:EV3OutputPortA power:100];
    }
}

- (void)dPadDidReleaseDirection:(JSDPad *)dPad
{
    NSLog(@"Releasing DPad");
    [devicData turnMotorAtPort:EV3OutputPortB power:0];
    [devicData turnMotorAtPort:EV3OutputPortC power:0];
    [devicData turnMotorAtPort:EV3OutputPortA power:0];
}

#pragma mark - JSButtonDelegate

- (void)buttonPressed:(JSButton *)button
{
    if ([_pressedButtons containsObject:button])
    {
        NSLog(@"Button is already being tracked as pressed");
        return;
    }
    
    if ([button isEqual:aButton])
    {
        [_pressedButtons addObject:aButton];
        NSLog(@"我按了a");
    }
    else if ([button isEqual:bButton])
    {
        [_pressedButtons addObject:bButton];
        NSLog(@"我按了b");
        [devicData stopMotorAtPort:EV3OutputAll];
    }
}

- (void)buttonReleased:(JSButton *)button
{
    if ([_pressedButtons containsObject:button] == NO)
    {
        NSLog(@"Button has already been released");
        return;
    }
    
    if ([button isEqual:aButton])
    {
        [_pressedButtons removeObject:aButton];
    }
    else if ([button isEqual:bButton])
    {
        [_pressedButtons removeObject:bButton];
        [devicData turnMotorAtPort:EV3OutputPortA power:0];
        [devicData turnMotorAtPort:EV3OutputPortB power:0];
        [devicData turnMotorAtPort:EV3OutputPortC power:0];
    }
}

//- (void)stopSharing
//{
//    [videosView setHidden:YES];
//    [AVSession stopRunning];
//    if(self.gameSession != nil){
//        [self.gameSession disconnectFromAllPeers];
//        [self.gameSession setAvailable:NO];
//        [self.gameSession setDelegate:nil];
//        [self.gameSession setDataReceiveHandler:nil withContext:NULL];
//
//        self.gameSession = nil;
//    }
//    isSendData = NO;
//}
//
//- (void)startSharing
//{
//    [videosView setHidden:NO];
//    [AVSession startRunning];
//    isSendData = YES;
//}
//
//#pragma mark - GameKit Peer Picker
//
//-(void)startPicker
//{
//    GKPeerPickerController *picker = [[GKPeerPickerController alloc] init];
//    picker.delegate = self;
//    [picker show];
//}
//
//-(void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker
//{
//    picker.delegate = nil;
//}
//
//- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type
//{
//    return [[GKSession alloc] initWithSessionID:nil displayName:nil sessionMode:GKSessionModePeer];
//}
//
//- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session
//{
//    self.gamePeerID = peerID;
//
//    self.gameSession = session;
//    [self.gameSession setDisconnectTimeout:2.0];
//    [self.gameSession setAvailable:YES];
//    self.gameSession.delegate = self;
//    [self.gameSession setDataReceiveHandler:self withContext:NULL];
//
//    [self startSharing];
//
//    [picker dismiss];
//    picker.delegate = nil;
//
//}
//
//-(void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context
//{
//    int dataInKB = (int)data.length/1024;
//    NSLog(@"data length %ld B = %d KB", data.length, dataInKB);
//
//    if(data.length > 0)
//    {
//        if(data.length < 10){
//            NSLog(@"got a byte");
//            isSendData = YES;
//        }
//        else{
//            NSLog(@"got image");
//            NSLog(@"Time taken: %f", [[NSDate date] timeIntervalSinceDate:self.timingDate]);
//            NSData *aByte = [@"1" dataUsingEncoding:NSUTF8StringEncoding];
//            NSLog(@"send a byte");
//            self.timingDate = [NSDate date];
//
//            [self.gameSession sendData:aByte toPeers:[NSArray arrayWithObjects:self.gamePeerID,nil] withDataMode:GKSendDataReliable error:nil];
//
//            UIImage *aImage = [UIImage imageWithData:data];
//            [aImageView setImage:aImage];
//        }
//    }
//}
//
//#pragma mark - GKSessionDelegate
//- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
//{
//
//}
//
//-(void)session:(GKSession *)session didFailWithError:(NSError *)error
//{
//    NSLog(@"connection failed with error %@", error);
//}
//
//- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
//{
//    if(state == GKPeerStateDisconnected || state == GKPeerStateUnavailable){
//        [self stopSharing];
//    }
//}
//
//- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
//{
//
//}

#pragma mark - Video capture
- (void)setupCaptureSession
{

    self.AVSession = [[AVCaptureSession alloc] init];

    self.AVSession.sessionPreset = AVCaptureSessionPresetMedium;

    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if(input){
        [self.AVSession addInput:input];
    }
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [self.AVSession addOutput:output];

    dispatch_queue_t videoQueue = dispatch_queue_create("com.deutschinc.videoQueue", DISPATCH_QUEUE_SERIAL);
    [output setSampleBufferDelegate:self queue:videoQueue];
//    dispatch_release(videoQueue);

    videoFrameProcessQueue = dispatch_queue_create("com.deutschinc._videoFrameProcessQueue", DISPATCH_QUEUE_SERIAL);

    output.videoSettings = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];

    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.AVSession];
    previewLayer.frame = self.videoPreviewView.bounds;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.videoPreviewView.layer addSublayer:previewLayer];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{

//    if(isSendData){
//        isSendData = NO;
        CFRetain(sampleBuffer);

        kWeakSelf(self);
        dispatch_async(videoFrameProcessQueue, ^{
            CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

            weakself.ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
            weakself.ciContext = [CIContext contextWithOptions:nil];
            CGImageRef cgImageRef = [weakself.ciContext createCGImage:weakself.ciImage fromRect:weakself.ciImage.extent];

            weakself.frameImage = [UIImage imageWithCGImage:cgImageRef scale:1.0 orientation:UIImageOrientationRight];
            CGImageRelease(cgImageRef);

            NSError *error=nil;
            [self.session sendData:UIImageJPEGRepresentation(weakself.frameImage, 1) toPeers:[self.session connectedPeers] withMode:MCSessionSendDataUnreliable error:&error];
            
            NSLog(@"开始发送数据...");
            if (error) {
                NSLog(@"发送数据过程中发生错误，错误信息：%@",error.localizedDescription);
            }
            
            CFRelease(sampleBuffer);
        });

//    }

}

//#pragma mark - Game Center, GKMatchmakerViewControllerDelegate
//
//-(void)auth_localPlayer{
//
//    __weak PooRobotControlViewController *roBot = self;
//    __weak GKLocalPlayer *localPlayers = localPlayer;
//
//    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
//        if (viewController != nil)
//        {
//            NSLog(@"User is not auth");
//            [roBot showAuthenticationDialogWhenReasonable:viewController];
//        }
//        else if (localPlayers.isAuthenticated)
//        {
//            [roBot authenticatedPlayer:localPlayers];
//        }
//        else
//        {
//            NSLog(@"User auth failed");
//            //[self disableGameCenter];
//        }
//
//    };
//}
//
//-(void)showAuthenticationDialogWhenReasonable:(UIViewController *) loginVC{
//    [self.view addSubview:loginVC.view];
//}
//
//-(void)authenticatedPlayer:(GKLocalPlayer *) _localPlayer
//{
//    NSLog(@"User is authed");
//}
//
//-(void)showGameCenter
//{
//    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
//    gameCenterController.gameCenterDelegate = self;
//    [self presentViewController: gameCenterController animated: YES completion:nil];
//}
//
//-(void)setupMatch
//{
//    GKMatchRequest *request = [[GKMatchRequest alloc] init];
//    request.minPlayers = 2;
//    request.maxPlayers = 2;
//
//
//    GKMatchmaker *matchMaker = [GKMatchmaker sharedMatchmaker];
//    [matchMaker startBrowsingForNearbyPlayersWithHandler:^(GKPlayer * _Nonnull player, BOOL reachable) {
//        if(reachable){
//            NSLog(@"reachable");
//        }
//    }];
//
//    GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
//    mmvc.matchmakerDelegate = self;
//
//    [self presentViewController:mmvc animated:YES completion:nil];
//}
//
//-(void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController
//{
//    [self dismissViewControllerAnimated:YES completion:nil];
//}
//
//-(void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
//{
//    [self dismissViewControllerAnimated:YES completion:nil];
//}
//
//-(void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match
//{
//    [self dismissViewControllerAnimated:YES completion:nil];
//    gameMatch = match;
//    match.delegate = self;
//    if (!isMatchStarted && match.expectedPlayerCount == 0)
//    {
//        isMatchStarted = YES;
//        NSLog(@"found player");
//    }
//}
//
//- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
//{
//
//}

//- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
//{
//
//}


-(void)analogueStickDidChangeValue:(JSAnalogueStick *)analogueStick
{
    if (analogueStick.xValue == 0|| 0 < analogueStick.yValue < 1)
    {
        //上
        NSLog(@"下");
//        [devicData turnMotorAtPort:EV3OutputPortB power:-100];
//        [devicData turnMotorAtPort:EV3OutputPortC power:-100];
    }
    else if (-1<analogueStick.yValue&&analogueStick.yValue<0&&analogueStick.xValue == 0)
    {
        NSLog(@"上");
    }
    else if (analogueStick.xValue<0||analogueStick.xValue>-1||0.2>analogueStick.yValue > 0)
    {
        NSLog(@"zuo");
    }

    NSLog(@"%f>>>>>%f>>>>>>>>%f>>>>>>%f",analogueStick.xValue,analogueStick.yValue,analogueStick.center.x,analogueStick.center.y);
}

-(void)analogueStickTouchEnd:(JSAnalogueStick *)stick
{
    [devicData turnMotorAtPort:EV3OutputPortA power:0];
    [devicData turnMotorAtPort:EV3OutputPortB power:0];
    [devicData turnMotorAtPort:EV3OutputPortC power:0];
}

#pragma mark - MCSession代理方法
-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    NSLog(@"didChangeState");
    switch(state){
        case MCSessionStateConnected:
            NSLog(@"连接成功.");
            [self.AVSession startRunning];
            break;
        case MCSessionStateConnecting:
            NSLog(@"正在连接...");
            break;
        default:
            NSLog(@"连接失败.");
            break;
    }
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    NSLog(@"开始接收数据...");
    //接收文字信息
    NSLog(@"%@", [NSThread currentThread]);//(<NSThread: 0x170270540>{number = 3, name = (null)})
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *aImage = [UIImage imageWithData:data];
        [self.aImageView setImage:aImage];
    });
}

- (void)session:(MCSession *)session
didReceiveStream:(NSInputStream *)stream
       withName:(NSString *)streamName
       fromPeer:(MCPeerID *)peerID
{
    
}

- (void)session:(MCSession *)session
didStartReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID
   withProgress:(NSProgress *)progress
{
    
}

- (void)session:(MCSession *)session
didFinishReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID
          atURL:(nullable NSURL *)localURL
      withError:(nullable NSError *)error
{
    
}

#pragma mark - MCBrowserViewController代理方法
-(void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
    NSLog(@"已选择");
    [self.browserController dismissViewControllerAnimated:YES completion:nil];
}
-(void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
    NSLog(@"取消浏览.");
    [self.browserController dismissViewControllerAnimated:YES completion:nil];
}

@end
