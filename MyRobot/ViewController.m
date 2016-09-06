//
//  ViewController.m
//  MyRobot
//
//  Created by crazypoo on 14/9/1.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import "ViewController.h"
#import "MyRobotTableViewCell.h"
#import "PooRobotControlViewController.h"
#import "EV3/EV3WifiManager.h"
#import "EV3/EV3WifiBrowserViewController.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>
{
    EV3WifiManager *ev3WifiManager;
    EV3Device *device;
    UITableView *robotTable;
    UIButton *robotTitleBUtton;
    id obj;
}

@end

@implementation ViewController

//-(void)viewDidAppear:(BOOL)animated
//{
//    if (!device) {
//        robotTitleBUtton.userInteractionEnabled = NO;
//    }
//    else
//    {
//        robotTitleBUtton.userInteractionEnabled = YES;
//    }
//}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIView *robotTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    
    robotTitleBUtton = [UIButton buttonWithType:UIButtonTypeCustom];
    robotTitleBUtton.frame = CGRectMake(0, 0, robotTitleView.frame.size.width, robotTitleView.frame.size.height);
    [robotTitleBUtton setTitle:@"屌丝机器人" forState:UIControlStateNormal];
    [robotTitleBUtton addTarget:self action:@selector(goToControlView:) forControlEvents:UIControlEventTouchUpInside];
    [robotTitleView addSubview:robotTitleBUtton];
    
    
    
    self.navigationItem.titleView = robotTitleView;
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *leftMenu =[UIButton buttonWithType:UIButtonTypeCustom];
    leftMenu.frame = CGRectMake(0, 8, 50, 30);
    [leftMenu setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [leftMenu setTitle:@"连接" forState:UIControlStateNormal];
    [leftMenu addTarget:self action:@selector(showLeftMenu:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftMenu];
    
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = CGRectMake(0, 8, 50, 30);
    [rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [rightButton setTitle:@"关于" forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(showRightMenu:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];

    
    ev3WifiManager = [EV3WifiManager sharedInstance];
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(refreshData) userInfo:nil repeats:YES];
    
    robotTable = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    robotTable.dataSource = self;
    robotTable.delegate = self;
    [self.view addSubview:robotTable];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showLeftMenu:(id)sender
{
    EV3WifiBrowserViewController *browserViewController = [[EV3WifiBrowserViewController alloc] init];
    [self presentViewController:browserViewController animated:YES completion:nil];
}

-(void)showRightMenu:(id)sender
{
    UIViewController *viewController = [[UIViewController alloc] init];
    viewController.view.frame = self.view.bounds;
    viewController.view.backgroundColor = [UIColor whiteColor];
    
    UILabel *version = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, self.view.frame.size.width, 40)];
    version.textAlignment = NSTextAlignmentCenter;
    version.text = [NSString stringWithFormat:@"Version : %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    [viewController.view addSubview:version];
    
    [self.navigationController pushViewController:viewController animated:YES];
}

-(void)refreshData
{
    device = ev3WifiManager.devices.allValues.lastObject;
    [robotTable reloadData];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (device)
    {
        return 8;
    }
    else
    {
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 120;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MyRobotTableViewCell *cell = [[MyRobotTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.userInteractionEnabled = NO;
    
    if (device) {
        
        switch (indexPath.row) {
            case 0:
                cell.portLabel.text = @"PORTA";
                cell.nameLabel.text = device.sensorPortA.typeString;
                cell.imageView.image = device.sensorPortA.image;
                cell.dataLabel.text = [NSString stringWithFormat:@"Raw Data:%d",device.sensorPortA.data];
                break;
            case 1:
                cell.portLabel.text = @"PORTB";
                cell.nameLabel.text = device.sensorPortB.typeString;
                cell.imageView.image = device.sensorPortB.image;
                cell.dataLabel.text = [NSString stringWithFormat:@"Raw Data:%d",device.sensorPortB.data];
                break;
            case 2:
                cell.portLabel.text = @"PORTC";
                cell.nameLabel.text = device.sensorPortC.typeString;
                cell.imageView.image = device.sensorPortC.image;
                cell.dataLabel.text = [NSString stringWithFormat:@"Raw Data:%d",device.sensorPortC.data];
                break;
            case 3:
                cell.portLabel.text = @"PORTD";
                cell.nameLabel.text = device.sensorPortD.typeString;
                cell.imageView.image = device.sensorPortD.image;
                cell.dataLabel.text = [NSString stringWithFormat:@"Raw Data:%d",device.sensorPortD.data];
                break;
            case 4:
                cell.portLabel.text = @"PORT1";
                cell.nameLabel.text = device.sensorPort1.typeString;
                cell.imageView.image = device.sensorPort1.image;
                cell.dataLabel.text = [NSString stringWithFormat:@"Raw Data:%d",device.sensorPort1.data];
                break;
            case 5:
                cell.portLabel.text = @"PORT2";
                cell.nameLabel.text = device.sensorPort2.typeString;
                cell.imageView.image = device.sensorPort2.image;
                cell.dataLabel.text = [NSString stringWithFormat:@"Raw Data:%d",device.sensorPort2.data];
                break;
            case 6:
                cell.portLabel.text = @"PORT3";
                cell.nameLabel.text = device.sensorPort3.typeString;
                cell.imageView.image = device.sensorPort3.image;
                cell.dataLabel.text = [NSString stringWithFormat:@"Raw Data:%d",device.sensorPort3.data];
                break;
            case 7:
                cell.portLabel.text = @"PORT4";
                cell.nameLabel.text = device.sensorPort4.typeString;
                cell.imageView.image = device.sensorPort4.image;
                cell.dataLabel.text = [NSString stringWithFormat:@"Raw Data:%d",device.sensorPort4.data];
                break;
                
            default:
                break;
        }
        
    }
    else
    {
        cell.textLabel.text = @"正在等待连接EV3!";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return cell;
}

-(void)goToControlView:(id)sender
{
    PooRobotControlViewController *control = [[PooRobotControlViewController alloc] initDeviceData:device];
    [self.navigationController pushViewController:control animated:YES];
}
@end
