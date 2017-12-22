# ZLAdvertDemo
启动页加载广告

目前市场上很多APP(如淘宝、美团、微博、UC)在启动图加载完毕后，还会显示几秒的广告，右上角都有个跳过按钮可以选择立即跳过这个广告，有的APP在点击广告页之后还会进入一个广告页。
他们玩的乐此不疲，产品汪们见了自然也是不会放过这个效果:
![](https://github.com/ZLFighting/ZLAdvertDemo/blob/master/ZLAdvertDemo/截图.png)

> 思路如下:
1. 封装广告页, 展现跳过按钮实现倒计时功能
2. 判断广告页面是否更新。异步下载新图片, 删除老图片
3. 广告页显示
4. 广告页点击后展示页

废话少说,这边先上核心代码了:

### 一. 封装广告页, 展现跳过按钮实现倒计时功能

ZLAdvertView.h: 先封装出来广告页,露出显示广告页面方法和图片路径
```
#import <UIKit/UIKit.h>

#define kscreenWidth [UIScreen mainScreen].bounds.size.width
#define kscreenHeight [UIScreen mainScreen].bounds.size.height
#define kUserDefaults [NSUserDefaults standardUserDefaults]
static NSString *const adImageName = @"adImageName";
static NSString *const adUrl = @"adUrl";

@interface ZLAdvertView : UIView

/**
*  显示广告页面方法
*/
- (void)show;

/**
*  图片路径
*/
@property (nonatomic, copy) NSString *filePath;

@end
```
ZLAdvertView.m:

核心代码见下面代码块:
```
#import "ZLAdvertView.h"

@interface ZLAdvertView ()

@property (nonatomic, strong) UIImageView *adView;

@property (nonatomic, strong) UIButton *countBtn;

@property (nonatomic, strong) NSTimer *countTimer;

@property (nonatomic, assign) int count;

@end

// 广告显示的时间
static int const showtime = 3;

```
**1. 为广告页面添加一个点击手势，跳转到广告页面.**

```
@implementation ZLAdvertView

- (NSTimer *)countTimer {

if (!_countTimer) {
_countTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countDown) userInfo:nil repeats:YES];
}
return _countTimer;
}

- (instancetype)initWithFrame:(CGRect)frame {

if (self = [super initWithFrame:frame]) {

// 1.广告图片
_adView = [[UIImageView alloc] initWithFrame:frame];
_adView.userInteractionEnabled = YES;
_adView.contentMode = UIViewContentModeScaleAspectFill;
_adView.clipsToBounds = YES;
// 为广告页面添加一个点击手势，跳转到广告页面
UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pushToAd)];
[_adView addGestureRecognizer:tap];

// 2.跳过按钮
CGFloat btnW = 60;
CGFloat btnH = 30;
_countBtn = [[UIButton alloc] initWithFrame:CGRectMake(kscreenWidth - btnW - 24, btnH, btnW, btnH)];
[_countBtn addTarget:self action:@selector(removeAdvertView) forControlEvents:UIControlEventTouchUpInside];
[_countBtn setTitle:[NSString stringWithFormat:@"跳过%d", showtime] forState:UIControlStateNormal];
_countBtn.titleLabel.font = [UIFont systemFontOfSize:15];
[_countBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
_countBtn.backgroundColor = [UIColor colorWithRed:38 /255.0 green:38 /255.0 blue:38 /255.0 alpha:0.6];
_countBtn.layer.cornerRadius = 4;

[self addSubview:_adView];
[self addSubview:_countBtn];

}
return self;
}

- (void)setFilePath:(NSString *)filePath {

_filePath = filePath;
_adView.image = [UIImage imageWithContentsOfFile:filePath];
}

- (void)pushToAd {

[self removeAdvertView];

[[NSNotificationCenter defaultCenter] postNotificationName:@"ZLPushToAdvert" object:nil userInfo:nil];
}
```
**2. 广告页面的跳过按钮倒计时功能可以通过定时器或者GCD实现(这里以广告倒计时3s 做例子)**

```
- (void)countDown {

_count --;
[_countBtn setTitle:[NSString stringWithFormat:@"跳过%d",_count] forState:UIControlStateNormal];
if (_count == 0) {

[self removeAdvertView];
}
}

// 广告页面的跳过按钮倒计时功能可以通过定时器或者GCD实现
- (void)show {

// 倒计时方法1：GCD
//    [self startCoundown];

// 倒计时方法2：定时器
[self startTimer];
UIWindow *window = [UIApplication sharedApplication].keyWindow;
[window addSubview:self];
}

// 定时器倒计时
- (void)startTimer {

_count = showtime;
[[NSRunLoop mainRunLoop] addTimer:self.countTimer forMode:NSRunLoopCommonModes];
}

// GCD倒计时
- (void)startCoundown {

__weak __typeof(self) weakSelf = self;
__block int timeout = showtime + 1; //倒计时时间 + 1
dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0 * NSEC_PER_SEC, 0); //每秒执行
dispatch_source_set_event_handler(_timer, ^{
if(timeout <= 0){ //倒计时结束，关闭
dispatch_source_cancel(_timer);
dispatch_async(dispatch_get_main_queue(), ^{

[weakSelf removeAdvertView];

});
}else{

dispatch_async(dispatch_get_main_queue(), ^{
[_countBtn setTitle:[NSString stringWithFormat:@"跳过%d",timeout] forState:UIControlStateNormal];
});
timeout--;
}
});
dispatch_resume(_timer);
}

// 移除广告页面
- (void)removeAdvertView {

// 停掉定时器
[self.countTimer invalidate];
self.countTimer = nil;

[UIView animateWithDuration:0.3f animations:^{

self.alpha = 0.f;

} completion:^(BOOL finished) {

[self removeFromSuperview];

}];

}

@end
```

### 二. 判断广告页面是否更新。异步下载新图片, 删除老图片
因为广告页的内容要实时显示，在无网络状态或者网速缓慢的情况下不能延迟加载，或者等到首页出现了再加载广告页。所以这里不采用网络请求广告接口去获取图片地址然后加载图片的方式，而是先将图片异步下载到本地，并保存图片名，每次打开app时先根据本地存储的图片名查找沙盒中是否存在该图片，如果存在，则显示广告页。
在AppDelegate.m 里:
```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[HomeViewController alloc] init]];
[self.window makeKeyAndVisible];

// 设置启动页广告
[self setupAdvert];

return YES;
}
```
**1. 判断沙盒中是否存在广告图片，如果存在，直接显示**
```
/**
*  设置启动页广告
*/
- (void)setupAdvert {

// 1.判断沙盒中是否存在广告图片，如果存在，直接显示
NSString *filePath = [self getFilePathWithImageName:[kUserDefaults valueForKey:adImageName]];

BOOL isExist = [self isFileExistWithFilePath:filePath];
if (isExist) { // 图片存在

ZLAdvertView *advertView = [[ZLAdvertView alloc] initWithFrame:self.window.bounds];
advertView.filePath = filePath;
[advertView show];
}

// 2.无论沙盒中是否存在广告图片，都需要重新调用广告接口，判断广告是否更新
[self getAdvertisingImage];
}

/**
*  判断文件是否存在
*/
- (BOOL)isFileExistWithFilePath:(NSString *)filePath {

NSFileManager *fileManager = [NSFileManager defaultManager];
BOOL isDirectory = FALSE;
return [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
}
```
**2. 无论沙盒中是否存在广告图片，都需要重新调用获取广告接口，判断广告是否更新**
```
/**
*  初始化广告页面
*/
- (void)getAdvertisingImage {

// TODO 请求广告接口
// 这里原本应该采用广告接口，现在用一些固定的网络图片url代替
NSArray *imageArray = @[
@"https://ss2.baidu.com/-vo3dSag_xI4khGko9WTAnF6hhy/super/whfpf%3D425%2C260%2C50/sign=a4b3d7085dee3d6d2293d48b252b5910/0e2442a7d933c89524cd5cd4d51373f0830200ea.jpg",
@"https://ss0.baidu.com/-Po3dSag_xI4khGko9WTAnF6hhy/super/whfpf%3D425%2C260%2C50/sign=a41eb338dd33c895a62bcb3bb72e47c2/5fdf8db1cb134954a2192ccb524e9258d1094a1e.jpg",
@"http://c.hiphotos.baidu.com/image/w%3D400/sign=c2318ff84334970a4773112fa5c8d1c0/b7fd5266d0160924c1fae5ccd60735fae7cd340d.jpg"
];
NSString *imageUrl = imageArray[arc4random() % imageArray.count];

// 获取图片名:43-130P5122Z60-50.jpg
NSArray *stringArr = [imageUrl componentsSeparatedByString:@"/"];
NSString *imageName = stringArr.lastObject;

// 拼接沙盒路径
NSString *filePath = [self getFilePathWithImageName:imageName];
BOOL isExist = [self isFileExistWithFilePath:filePath];
if (!isExist){ // 如果该图片不存在，则删除老图片，下载新图片

[self downloadAdImageWithUrl:imageUrl imageName:imageName];
}
}
```
**3. 异步下载新图片, 删除老图片**
```
/**
*  下载新图片
*/
- (void)downloadAdImageWithUrl:(NSString *)imageUrl imageName:(NSString *)imageName {

dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
UIImage *image = [UIImage imageWithData:data];

NSString *filePath = [self getFilePathWithImageName:imageName]; // 保存文件的名称

if ([UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES]) {// 保存成功
NSLog(@"保存成功");
[self deleteOldImage];
[kUserDefaults setValue:imageName forKey:adImageName];
[kUserDefaults synchronize];
// 如果有广告链接，将广告链接也保存下来
}else{
NSLog(@"保存失败");
}

});
}

/**
*  删除旧图片
*/
- (void)deleteOldImage {

NSString *imageName = [kUserDefaults valueForKey:adImageName];
if (imageName) {
NSString *filePath = [self getFilePathWithImageName:imageName];
NSFileManager *fileManager = [NSFileManager defaultManager];
[fileManager removeItemAtPath:filePath error:nil];
}
}

/**
*  根据图片名拼接文件路径
*/
- (NSString *)getFilePathWithImageName:(NSString *)imageName {

if (imageName) {

NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask, YES);
NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:imageName];

return filePath;
}

return nil;
}
```

### 三. 广告页显示。
广告页的显示代码可以放在AppDeleate中，也可以放在首页的控制器中。如果代码是在AppDelegate中，可以通过发送通知的方式，让首页push到广告详情页.

首页控制器HomeViewController.m:
```
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
@end
```

### 四.  广告页点击后展示页。
如果点击广告需要跳转广告详情页面，那么广告链接地址也需要用NSUserDefaults存储。注意：广告详情页面是从首页push进去的
广告链接页ZLAdvertViewController.h :
```
//  广告链接页
#import <UIKit/UIKit.h>

@interface ZLAdvertViewController : UIViewController

@property (nonatomic, copy) NSString *adUrl;

@end
```

ZLAdvertViewController.m :
```
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
@end
```

**注意:**
广告页面的底部和启动图的底部一般都是相同的，给用户的错觉就是启动图加载完之后把广告图放在了启动图上，而且不能有偏差。所以我们开发要图时需要提醒美工在制作广告图的时候要注意下。

![启动页进入广告.gif](https://github.com/ZLFighting/ZLAdvertDemo/blob/master/ZLAdvertDemo/启动页广告.gif)
![启动页跳过广告.gif](https://github.com/ZLFighting/ZLAdvertDemo/blob/master/ZLAdvertDemo/启动页跳过广告.gif)


如果需要启动动态页跳过的这种启动页方案 ,请移步: [iOS-启动动态页跳过设计思路](https://github.com/ZLFighting/ZLStartPageDemo)

您的支持是作为程序媛的我最大的动力, 如果觉得对你有帮助请送个Star吧,谢谢啦
