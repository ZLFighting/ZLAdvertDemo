//
//  ViewController.m
//  ZLAdvertDemo
//
//  Created by zhangli on 2017/2/28.
//  Copyright © 2017年 YSMX. All rights reserved.
//

#import "HomeViewController.h"
#import "ZLAdvertViewController.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"首页";
    
    self.view.backgroundColor = [UIColor greenColor];
    
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushToAd) name:@"ZLPushToAdvert" object:nil];
}

// 进入广告链接页
- (void)pushToAd {
    
    ZLAdvertViewController *adVc = [[ZLAdvertViewController alloc] init];
    [self.navigationController pushViewController:adVc animated:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
