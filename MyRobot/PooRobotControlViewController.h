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

#import <AVFoundation/AVFoundation.h>

#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface PooRobotControlViewController : UIViewController<JSAnalogueStickDelegate,JSButtonDelegate,JSDPadDelegate, MCAdvertiserAssistantDelegate,MCSessionDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,MCBrowserViewControllerDelegate,UIPopoverControllerDelegate>

-(id)initDeviceData:(EV3Device *)data;
@end
