//
//  PooRobotControlViewController.h
//  MyRobot
//
//  Created by crazypoo on 14/9/3.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EV3Device.h"

#import "JSDPad.h"
#import "JSButton.h"
#import "JSAnalogueStick.h"

#import <GameKit/GameKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PooRobotControlViewController : UIViewController<JSAnalogueStickDelegate,JSButtonDelegate,JSDPadDelegate,GKPeerPickerControllerDelegate, GKSessionDelegate, GKMatchmakerViewControllerDelegate, GKMatchDelegate, GKGameCenterControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

-(id)initDeviceData:(EV3Device *)data;
@end
