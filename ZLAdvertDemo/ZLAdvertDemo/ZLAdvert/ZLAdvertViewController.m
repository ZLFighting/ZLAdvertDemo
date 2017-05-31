//
//  ZLAdvertViewController.m
//  ZLAdvertDemo
//
//  Created by zhangli on 2017/2/28.
//  Copyright © 2017年 YSMX. All rights reserved.
//

#import "ZLAdvertViewController.h"

@interface ZLAdvertViewController ()

@property (nonatomic, strong) UIWebView *webView;

@end

@implementation ZLAdvertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"点击进入广告链接";
    _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    _webView.backgroundColor = [UIColor whiteColor];
    
    if (!self.adUrl) {
        self.adUrl = @"http://www.baidu.com";
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.adUrl]];
    [_webView loadRequest:request];
    [self.view addSubview:_webView];
}

- (void)setAdUrl:(NSString *)adUrl {
    _adUrl = adUrl;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
