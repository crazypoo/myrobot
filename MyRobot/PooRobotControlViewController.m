//
//  PooRobotControlViewController.m
//  MyRobot
//
//  Created by crazypoo on 14/9/3.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import "PooRobotControlViewController.h"
#import "EV3DirectCommander.h"

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

@interface PooRobotControlViewController ()
{
    EV3Device *devicData;
    UISlider *goSlider;
    UISlider *leftRightSlider;
    JSDPad *dPad;
    JSButton *aButton;
    JSButton *bButton;
    NSMutableArray *_pressedButtons;
    
    UIImageView *aImageView;
    UIButton *closeSharingBtn;
    UIButton *connectBtn;
    UIView *videosView;
    UIView *videoPreviewView;
    
    UIButton *connect;
    UIButton *stopBtn;
    
    NSString *gamePeerID;
    GKSession *gameSession;
    
    GKMatch *gameMatch;
    BOOL isMatchStarted;
    GKLocalPlayer *localPlayer;
    
    AVCaptureSession *AVSession;
    __block BOOL isSendData;
    __block UIImage *frameImage;
    __block CIImage *ciImage;
    __block CIContext *ciContext;
    
    dispatch_queue_t videoFrameProcessQueue;

}

@property(nonatomic, strong) NSDate *timingDate;

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
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (isIPad) {
        dPad = [[JSDPad alloc] initWithFrame:CGRectMake(20, self.view.frame.size.height - 320, 300, 300)];
        aButton = [[JSButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 140, self.view.frame.size.height - 140, 120, 120)];
        bButton = [[JSButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 120, self.view.frame.size.height - 244, 120, 120)];

    }
    else
    {
        dPad = [[JSDPad alloc] initWithFrame:CGRectMake(20, self.view.frame.size.height - 170, 150, 150)];
        aButton = [[JSButton alloc] initWithFrame:CGRectMake(200, self.view.frame.size.height - 80, 60, 60)];
        bButton = [[JSButton alloc] initWithFrame:CGRectMake(240, self.view.frame.size.height - 144, 60, 60)];
    }
    dPad.delegate = self;
    [self.view addSubview:dPad];
    
    [[aButton titleLabel] setText:@"A"];
    [aButton setBackgroundImage:[UIImage imageNamed:@"button"]];
    [aButton setBackgroundImagePressed:[UIImage imageNamed:@"button-pressed"]];
    aButton.delegate = self;
    [self.view addSubview:aButton];
    
    [[bButton titleLabel] setText:@"B"];
    [bButton setBackgroundImage:[UIImage imageNamed:@"button"]];
    [bButton setBackgroundImagePressed:[UIImage imageNamed:@"button-pressed"]];
    bButton.delegate = self;
    [self.view addSubview:bButton];
    
    _pressedButtons = [NSMutableArray new];

    
    isSendData = YES;
    isMatchStarted = NO;
    self.timingDate = [NSDate date];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    videoPreviewView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 90, 135)];
    videoPreviewView.layer.masksToBounds = YES;
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = videoPreviewView.bounds;
    UIBezierPath *roundedPath = [UIBezierPath bezierPathWithRoundedRect:maskLayer.bounds byRoundingCorners:UIRectCornerTopLeft cornerRadii:CGSizeMake(5.0, 5.0)];
    maskLayer.fillColor = [[UIColor whiteColor] CGColor];
    maskLayer.backgroundColor = [[UIColor clearColor] CGColor];
    maskLayer.path = [roundedPath CGPath];
    videoPreviewView.layer.mask = maskLayer;
    
    [self setupCaptureSession];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:@"WillResignActive" object:[UIApplication sharedApplication]];
    
    
    connect = [UIButton buttonWithType:UIButtonTypeCustom];
    connect.backgroundColor = [UIColor redColor];
    [connect addTarget:self action:@selector(onConnectTap:) forControlEvents:UIControlEventTouchUpInside];
    [connect setTitle:@"连接" forState:UIControlStateNormal];
    [self.view addSubview:connect];
    
    stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    stopBtn.backgroundColor = [UIColor grayColor];
    [stopBtn addTarget:self action:@selector(onCloseSharingTap:) forControlEvents:UIControlEventTouchUpInside];
    [stopBtn setTitle:@"取消" forState:UIControlStateNormal];
    [self.view addSubview:stopBtn];
    
    
    if (isIPad) {
        videosView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 700)];
        connect.frame = CGRectMake(400, 800, 100, 100);
        stopBtn.frame = CGRectMake(500, 800, 100, 100);
    }
    else
    {
        videosView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 350)];
        connect.frame = CGRectMake(130, 380, 50, 50);
        stopBtn.frame = CGRectMake(180, 380, 50, 50);
    }
    aImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, videosView.frame.size.height)];
    [self.view addSubview:videosView];
    [videosView addSubview:aImageView];
    [videosView addSubview:videoPreviewView];

    
}

- (void)onConnectTap:(id)sender
{
    [self startPicker];
}

- (void)onCloseSharingTap:(id)sender
{
    [self stopSharing];
}

- (void)willResignActive
{
    [self stopSharing];
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

- (void)stopSharing
{
    [videosView setHidden:YES];
    [AVSession stopRunning];
    if(gameSession != nil){
        [gameSession disconnectFromAllPeers];
        
        [gameSession setAvailable:NO];
        [gameSession setDelegate:nil];
        [gameSession setDataReceiveHandler:nil withContext:NULL];
        
        gameSession = nil;
    }
    isSendData = NO;
}

- (void)startSharing
{
    [videosView setHidden:NO];
    [AVSession startRunning];
    isSendData = YES;
}

#pragma mark - GameKit Peer Picker

-(void)startPicker
{
    GKPeerPickerController *picker;
    picker = [[GKPeerPickerController alloc] init];
    picker.delegate = self;
    [picker show];
}

-(void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker
{
    picker.delegate = nil;
}

- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type
{
    return [[GKSession alloc] initWithSessionID:nil displayName:nil sessionMode:GKSessionModePeer];
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session
{
    gamePeerID = peerID;
    
    gameSession = session;
    [gameSession setDisconnectTimeout:2.0];
    [gameSession setAvailable:YES];
    gameSession.delegate = self;
    [gameSession setDataReceiveHandler:self withContext:NULL];
    
    [self startSharing];
    
    [picker dismiss];
    picker.delegate = nil;
    
}

-(void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context
{
    int dataInKB = (int)data.length/1024;
    NSLog(@"data length %ld B = %d KB", data.length, dataInKB);
    
    if(data.length > 0)
    {
        if(data.length < 10){
            NSLog(@"got a byte");
            isSendData = YES;
        }
        else{
            NSLog(@"got image");
            NSLog(@"Time taken: %f", [[NSDate date] timeIntervalSinceDate:self.timingDate]);
            NSData *aByte = [@"1" dataUsingEncoding:NSUTF8StringEncoding];
            NSLog(@"send a byte");
            self.timingDate = [NSDate date];
            
            [gameSession sendData:aByte toPeers:[NSArray arrayWithObjects:gamePeerID,nil] withDataMode:GKSendDataReliable error:nil];
            
            UIImage *aImage = [UIImage imageWithData:data];
            [aImageView setImage:aImage];
        }
    }
}

#pragma mark - GKSessionDelegate
- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    
}

-(void)session:(GKSession *)session didFailWithError:(NSError *)error
{
    NSLog(@"connection failed with error %@", error);
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    if(state == GKPeerStateDisconnected || state == GKPeerStateUnavailable){
        [self stopSharing];
    }
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
    
}

#pragma mark - Video capture
- (void)setupCaptureSession
{
    
    AVSession = [[AVCaptureSession alloc] init];
    
    AVSession.sessionPreset = AVCaptureSessionPresetMedium;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if(input){
        [AVSession addInput:input];
    }
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [AVSession addOutput:output];
    
    dispatch_queue_t videoQueue = dispatch_queue_create("com.deutschinc.videoQueue", DISPATCH_QUEUE_SERIAL);
    [output setSampleBufferDelegate:self queue:videoQueue];
//    dispatch_release(videoQueue);
    
    videoFrameProcessQueue = dispatch_queue_create("com.deutschinc._videoFrameProcessQueue", DISPATCH_QUEUE_SERIAL);
    
    output.videoSettings = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:AVSession];
    previewLayer.frame = videoPreviewView.bounds;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [videoPreviewView.layer addSublayer:previewLayer];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    if(isSendData){
        isSendData = NO;
        CFRetain(sampleBuffer);
        
        dispatch_async(videoFrameProcessQueue, ^{
            CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            
            ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
            ciContext = [CIContext contextWithOptions:nil];
            CGImageRef cgImageRef = [ciContext createCGImage:ciImage fromRect:ciImage.extent];
            
            frameImage = [UIImage imageWithCGImage:cgImageRef scale:1.0 orientation:UIImageOrientationRight];
            CGImageRelease(cgImageRef);
            
            [gameSession sendData:UIImageJPEGRepresentation(frameImage, 0.2) toPeers:[NSArray arrayWithObjects:gamePeerID,nil] withDataMode:GKSendDataReliable error:nil];
            
            CFRelease(sampleBuffer);
        });
        
    }
    
}

#pragma mark - Game Center, GKMatchmakerViewControllerDelegate

-(void)auth_localPlayer{
    
    __weak PooRobotControlViewController *roBot = self;
    __weak GKLocalPlayer *localPlayers = localPlayer;

    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
        if (viewController != nil)
        {
            NSLog(@"User is not auth");
            [roBot showAuthenticationDialogWhenReasonable:viewController];
        }
        else if (localPlayers.isAuthenticated)
        {
            [roBot authenticatedPlayer:localPlayers];
        }
        else
        {
            NSLog(@"User auth failed");
            //[self disableGameCenter];
        }
        
    };
}

-(void)showAuthenticationDialogWhenReasonable:(UIViewController *) loginVC{
    [self.view addSubview:loginVC.view];
}

-(void)authenticatedPlayer:(GKLocalPlayer *) _localPlayer
{
    NSLog(@"User is authed");
}

-(void)showGameCenter
{
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    gameCenterController.gameCenterDelegate = self;
    [self presentViewController: gameCenterController animated: YES completion:nil];
}

-(void)setupMatch
{
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = 2;
    request.maxPlayers = 2;
    
    
    GKMatchmaker *matchMaker = [GKMatchmaker sharedMatchmaker];
    [matchMaker startBrowsingForNearbyPlayersWithReachableHandler:^(NSString *playerID, BOOL reachable){
        if(reachable){
            NSLog(@"reachable");
        }
    }];
    
    GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
    mmvc.matchmakerDelegate = self;
    
    [self presentViewController:mmvc animated:YES completion:nil];
}

-(void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match
{
    [self dismissViewControllerAnimated:YES completion:nil];
    gameMatch = match;
    match.delegate = self;
    if (!isMatchStarted && match.expectedPlayerCount == 0)
    {
        isMatchStarted = YES;
        NSLog(@"found player");
    }
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
{
    
}

@end
