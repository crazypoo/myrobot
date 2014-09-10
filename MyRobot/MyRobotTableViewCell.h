//
//  MyRobotTableViewCell.h
//  MyRobot
//
//  Created by crazypoo on 14/9/1.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyRobotTableViewCell : UITableViewCell
@property (nonatomic,strong) UIImageView *sensorImage;
@property (nonatomic,strong) UILabel *portLabel;
@property (nonatomic,strong) UILabel *nameLabel;
@property (nonatomic,strong) UILabel *dataLabel;
@end
