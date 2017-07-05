//
//  customViewController.m
//  testCamera
//
//  Created by Jeavil on 16/8/25.
//  Copyright © 2016年 L. All rights reserved.
//
#define WIDTH  [UIScreen mainScreen].bounds.size.width
#define HEIGHT  [UIScreen mainScreen].bounds.size.height
#define User_Pics @"UserPics"
#define styleColor 0xB49B64
#define RIGHT_BORDER WIDTH * 0.8
#define LEFT_BORDER WIDTH * 0.2
#define DOCUMENT_PATH   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject
#define SEQMAP_PATH [NSString stringWithFormat:@"%@%@res",DOCUMENT_PATH,@"/"]
#import "customViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreMotion/CoreMotion.h>
#import <TGOSGFramework/TGOSGFramework.h>
#import "TopTools.h"
#import "picturePathsViewController.h"

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

typedef  void(^L_AlertActionBlock)(NSString *info);


@interface customViewController ()<AVCaptureFileOutputRecordingDelegate,AVAudioPlayerDelegate>{

    CMMotionManager *motionManager;
    NSString *picPath;//序列图路径
    SDKHandle *customHandle;
    
    long int   count;
    double     glassHeight;//镜架高度
    double     verticalAngle;//翻滚角
    double     featherDistance;//镜腿
    double     glassModelScale;//眼镜模型
    
    double originY;//调整上下滑动的精度获取touchbegean的原始Y坐标
    double originX;
    BOOL singleV;
    BOOL singleH;
    BOOL bothV;
    BOOL bothH;
    BOOL mediateScale;
    
    NSTimer *timer;
    NSTimer *resetTimer;
    
    UIImage *left_sideImage;
    UIImage *left_centerImage;
    UIImage *right_sideImage;
    UIImage *right_centerImage;
    
     NSTimer *myTime;
    UIImageView *heardView;
    UIButton *stopBtn;
    UIButton *startBtn;
    UIImageView *blueView;
    UIImageView *direction;
    UIView *leftView;
    float Vx;
    BOOL isStart;//判断是否开始录制视频
    BOOL isOk;//判断蓝线是否是第二次回到起点

    
}
@property (nonatomic, strong)UILabel *gyroscopeLabel;

@property (strong,nonatomic) AVCaptureSession *captureSession;//负责输入和输出设备之间的数据传递
@property (strong,nonatomic) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property (strong,nonatomic) AVCaptureMovieFileOutput *captureMovieFileOutput;//视频输出流
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//相机拍摄预览图层
@property (assign,nonatomic) BOOL enableRotation;//是否允许旋转（注意在视频录制过程中禁止屏幕旋转）
@property (assign,nonatomic) CGRect *lastBounds;//旋转的前大小
@property (assign,nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;//后台任务标识

@property (nonatomic, strong)AVAudioPlayer *audioPlayer;//录音播放

@property (nonatomic, strong)UIImageView *faceImageView;

@property (strong, nonatomic)  UIView *L_FooView;
@property (strong, nonatomic) UIImageView *Line;
@property (strong, nonatomic) UIView *circle;


@property (nonatomic, strong)UIView *viewContainer;

@property (nonatomic, strong)NSMutableArray *modelArrays;//眼镜模型
@end

static BOOL upOrDown = NO;
static BOOL isRecord = NO;
@implementation customViewController

- (NSMutableArray *)modelArrays{
        if (!_modelArrays) {
            _modelArrays = [NSMutableArray array];
            NSString *bundlePath = [[NSBundle mainBundle]pathForResource:@"glasses" ofType:@"bundle"];
            NSBundle *glassBundle = [NSBundle bundleWithPath:bundlePath];
            NSString *filePath = [glassBundle pathForResource:@"" ofType:@"gst"];
            NSRange range = [filePath rangeOfString:@"/" options:NSBackwardsSearch];
            NSString* fileFrontPath = [filePath substringToIndex:range.location];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            NSError *error = nil;
            NSArray* fileList = [[NSArray alloc] init];
            //fileList便是包含有该文件夹下所有文件的文件名及文件夹名的数组
            fileList = [fileManager contentsOfDirectoryAtPath:fileFrontPath error:&error];
            for (int i =0 ;i<fileList.count;i++){
                NSString* fileFullName =[fileFrontPath stringByAppendingFormat:@"%@%@",@"/",fileList[i]];
                NSString* fileNameExt = [fileFullName pathExtension];
                if([fileNameExt isEqual: @"gst"])
                {
                    [_modelArrays addObject:fileFullName];
                    
                }
            }
        }
        return _modelArrays;
   
}

-(AVAudioPlayer *)audioPlayer{
    if (!_audioPlayer) {
        NSString *urlStr=[[NSBundle mainBundle]pathForResource:@"newtopVideo.wav" ofType:nil];
        NSLog(@"%@",urlStr);
        NSURL *url = nil;
        if (urlStr) {
            url=[NSURL fileURLWithPath:urlStr];
        }
        NSError *error=nil;
        //初始化播放器，注意这里的Url参数只能时文件路径，不支持HTTP Url
        _audioPlayer=[[AVAudioPlayer alloc]initWithContentsOfURL:url error:&error];
        //设置播放器属性
        _audioPlayer.numberOfLoops=0;//设置为0不循环
        _audioPlayer.delegate=self;
        [_audioPlayer prepareToPlay];//加载音频文件到缓存
        if(error){
            NSLog(@"初始化播放器过程发生错误,错误信息:%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioPlayer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _viewContainer = [[UIView alloc]initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT)];
    [self.view addSubview:_viewContainer];
#if USE_MODELVIDEO == 1
    Vx = -(0.3 * WIDTH / 112.5) * 10;
#else
    Vx = -(0.3 * WIDTH / 112.5);
#endif
    isOk = NO;
    isStart = NO;
    _gyroscopeLabel = [[UILabel alloc]initWithFrame:CGRectMake(WIDTH / 6, 46, WIDTH / 3 * 2, 90)];
    _gyroscopeLabel.numberOfLines = 3;
    _gyroscopeLabel.textAlignment = NSTextAlignmentCenter;
    [_gyroscopeLabel setTextColor:[UIColor blackColor]];
    
    [_viewContainer addSubview:_gyroscopeLabel];
    //陀螺仪
    motionManager = [[CMMotionManager alloc]init];
    if (motionManager.gyroAvailable) {
        motionManager.gyroUpdateInterval = 1.0;
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
            //地平线夹角
            //   NSLog(@"aaaaa%.0f",(M_PI_2-atan2(motionManager.deviceMotion.gravity.x, motionManager.deviceMotion.gravity.z))*180/M_PI);
            //俯仰角
            double tanX = (atan(motion.gravity.z/motion.gravity.y))*180/M_PI;
            if (tanX < 10 && tanX >-10) {
                //手机正常放置
                heardView.layer.borderColor = [UIColor greenColor].CGColor;
                startBtn.userInteractionEnabled = YES;
                if (!isStart) {
                    //[self labelHint:@"请把头部放在竖线中间，点击录制按钮"];
                    [self labelHint: NSLocalizedString(@"请把头部放在竖线中间，点击录制按钮",@"")];
                    
                }
            }else{
                //手机未垂直放置
                heardView.layer.borderColor = [UIColor redColor].CGColor;
                startBtn.userInteractionEnabled = NO;
                if (!isStart) {
                    //[self labelHint:@"请把手机竖直放置"];
                    [self labelHint:NSLocalizedString(@"请把手机竖直放置",@"")];
                }
            }
        }];
    }else{
        // _gyroscopeLabel.text = @"This device has no gyroscope";
    }
    
    [self creatView];
    // Do any additional setup after loading the view from its nib.
    [self initNumbers];
    [self initCaptureSession];
    [self initTimer];

}

- (void)creatView{
    
    blueView = [[UIImageView alloc]initWithFrame:CGRectMake(WIDTH / 2 - 2, HEIGHT / 5 - 30, 5, HEIGHT / 5 * 4 - 40)];
    blueView.image = [UIImage imageNamed:@"蓝线"];
    [_viewContainer addSubview:blueView];
    //人头
    heardView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, WIDTH * 0.6 , WIDTH * 0.6 / 390 * 490)];
    heardView.center = CGPointMake(self.view.center.x, self.view.center.y);
    heardView.image = [UIImage imageNamed:@"onboarding-head"];
    heardView.layer.borderWidth = 4;
    heardView.layer.borderColor = [UIColor redColor].CGColor;
    
    [_viewContainer addSubview:heardView];
    
    
    leftView = [[UIView alloc]initWithFrame:CGRectMake(WIDTH / 6 + WIDTH / 30, HEIGHT / 5, 3, HEIGHT / 2)];
    leftView.backgroundColor = [UIColor whiteColor];
    [_viewContainer addSubview:leftView];
    
    UIView *centerView = [[UIView alloc]initWithFrame:CGRectMake(WIDTH / 2, HEIGHT / 5 - 30, 1, HEIGHT / 5 * 4 - 40)];
    centerView.backgroundColor = [UIColor whiteColor];
    [_viewContainer addSubview:centerView];
    
    UIView *rightView = [[UIView alloc]initWithFrame:CGRectMake(WIDTH / 6 * 5 - WIDTH / 30, HEIGHT / 5, 3, HEIGHT / 2)];
    rightView.backgroundColor = [UIColor whiteColor];
    
    [_viewContainer addSubview:rightView];
    
    startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    startBtn.frame = CGRectMake((WIDTH-60) / 2, HEIGHT - 70, 60, 60);
    [startBtn addTarget:self action:@selector(startPic:) forControlEvents:UIControlEventTouchUpInside];
    [startBtn setImage:[UIImage imageNamed:@"拍照"] forState:UIControlStateNormal];
    // [startBtn setImage:[UIImage imageNamed:@"232。232拍照2"] forState:UIControlStateSelected];
    
    [_viewContainer addSubview:startBtn];
    
    //退出
    stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    stopBtn.frame = CGRectMake(15, HEIGHT - 63, 30, 45);
    [stopBtn addTarget:self action:@selector(cancelClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [stopBtn setImage:[UIImage imageNamed:@"返回"] forState:UIControlStateNormal];
    stopBtn.alpha = 0.5;
    
    [_viewContainer addSubview:stopBtn];
    //指向开始按钮
    direction = [[UIImageView alloc]initWithFrame:CGRectMake((WIDTH - 80) / 2 - 50, HEIGHT - 174, 47, 94)];
    direction.image = [UIImage imageNamed:@"指向"];
    direction.transform = CGAffineTransformRotate(direction.transform, -M_1_PI/2);
    [_viewContainer addSubview:direction];
    
}
- (void)initNumbers{
    count = 0;
    featherDistance = 1.0;
    glassHeight = 0.2;
    glassModelScale = 0.5;
    verticalAngle = 0.5;
}
//退出
- (void)cancelClick:(UIButton *)sender{
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark -- 创建Timer
- (void)initTimer{
    timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(DynamicLineAnimotion) userInfo:nil repeats:YES];
    [timer setFireDate:[NSDate distantFuture]];
    
}
/**上下滚动线条*/
- (void)DynamicLineAnimotion{
    CGRect rect = self.Line.frame;
    if (!upOrDown) {
      rect.origin.y = 64;
    }else{
      rect.origin.y = 64 + WIDTH;
    }
    
    [UIView animateWithDuration:2.0 animations:^{
        self.Line.frame = rect;
        upOrDown = !upOrDown;
    }];

}
/**
 
 *过场动画
 */
#pragma mark -- 过场动画开始
- (void)BeaginAnimationFoo{

    CGRect rect = self.L_FooView.frame;
    rect.size.height = WIDTH;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view bringSubviewToFront:self.L_FooView];
        [UIView animateWithDuration:2 animations:^{
            self.L_FooView.frame = rect;
            
            NSLog(@"height=%f,%f",self.L_FooView.frame.size.height,rect.size.height);
        } completion:^(BOOL finished) {
            [self.view bringSubviewToFront:self.Line];
            [timer setFireDate:[NSDate distantPast]];
        }];
    });
    
}
#pragma mark -- 过场动画结束
- (void)endAnimationFoo{
    CGRect rect = self.L_FooView.frame;
    rect.size.height = 0;
    [timer setFireDate:[NSDate distantFuture]];
    [UIView animateWithDuration:2 animations:^{
        self.L_FooView.frame = rect;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark -- 状态栏白色
- (UIStatusBarStyle)preferredStatusBarStyle{

    return UIStatusBarStyleLightContent;
}



- (void)initCaptureSession{
    
    _captureSession=[[AVCaptureSession alloc]init];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {//设置分辨率
        _captureSession.sessionPreset=AVCaptureSessionPreset1280x720;
    }
    //获得输入设备
    AVCaptureDevice *captureDevice=[self getCameraDeviceWithPosition:AVCaptureDevicePositionFront];//取得后置摄像头
    if (!captureDevice) {
        NSLog(@"取得后置摄像头时出现问题.");
        return;
    }
    //添加一个音频输入设备
    AVCaptureDevice *audioCaptureDevice=[[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    
    
    NSError *error=nil;
    //根据输入设备初始化设备输入对象，用于获得输入数据
    _captureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    AVCaptureDeviceInput *audioCaptureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:audioCaptureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    //初始化设备输出对象，用于获得输出数据
    _captureMovieFileOutput=[[AVCaptureMovieFileOutput alloc]init];
    
    //将设备输入添加到会话中
    if ([_captureSession canAddInput:_captureDeviceInput]) {
        [_captureSession addInput:_captureDeviceInput];
        [_captureSession addInput:audioCaptureDeviceInput];
        AVCaptureConnection *captureConnection=[_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([captureConnection isVideoStabilizationSupported ]) {
            captureConnection.preferredVideoStabilizationMode=AVCaptureVideoStabilizationModeAuto;
        }
    }
    
    //将设备输出添加到会话中
    if ([_captureSession canAddOutput:_captureMovieFileOutput]) {
        [_captureSession addOutput:_captureMovieFileOutput];
    }
    
    //创建视频预览层，用于实时展示摄像头状态
    _captureVideoPreviewLayer=[[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    
    CALayer *layer=self.viewContainer.layer;
    layer.masksToBounds=YES;
    //_captureVideoPreviewLayer.frame=layer.bounds;
    _captureVideoPreviewLayer.frame=CGRectMake(0, 0, WIDTH, WIDTH / 9 * 16);
    _captureVideoPreviewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;//填充模式
    //将视频预览层添加到界面中
//    [layer addSublayer:_captureVideoPreviewLayer];
   [layer insertSublayer:_captureVideoPreviewLayer below:self->heardView.layer];
    [layer insertSublayer:_captureVideoPreviewLayer below:self->blueView.layer];
    
    _enableRotation=YES;
    [self addNotificationToCaptureDevice:captureDevice];
    //[self addGenstureRecognizer];
//    [self.view bringSubviewToFront:_viewContainer];
    [_captureSession startRunning];
      resetTimer= [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateFocusAndExpose) userInfo:nil repeats:YES];
}
-(void)updateFocusAndExpose{
    if ([self cameraSupportsTapToFocus]) {
       CGPoint point = CGPointMake(WIDTH / 2.0, (WIDTH / 9 * 16) / 2.0);
        CGPoint focusPoint = [self captureDevicePointForPoint:point];
        [self focusAtPoint:focusPoint];
    }
    if ([self cameraSupportsTapToExpose]) {
      CGPoint point = CGPointMake(WIDTH / 2.0, (WIDTH / 9 * 16) / 2.0);
        CGPoint exposePoint = [self captureDevicePointForPoint:point];
        NSLog(@"exposePoint.x ==%f    expose.y==%f",exposePoint.x,exposePoint.y);
        [self exposeAtPoint:exposePoint];
    }
}
//聚焦
- (BOOL)cameraSupportsTapToFocus {
    return [[self captureDevice] isFocusPointOfInterestSupported];
}
- (AVCaptureDevice *)captureDevice {
    return _captureDeviceInput.device;
}
- (void)focusAtPoint:(CGPoint)point {
    AVCaptureDevice *device = [self captureDevice];
    if ([self cameraSupportsTapToFocus] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.focusPointOfInterest = point;
            device.focusMode = AVCaptureFocusModeAutoFocus;
            [device unlockForConfiguration];
        }
        else{
            // [self showError:error];
        }
    }
}
//曝光
- (BOOL)cameraSupportsTapToExpose {
    return [[self captureDevice] isExposurePointOfInterestSupported];
}
static const NSString *CameraAdjustingExposureContext;
- (void)exposeAtPoint:(CGPoint)point{
    AVCaptureDevice *device = [self captureDevice];
    if ([self cameraSupportsTapToExpose] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.exposurePointOfInterest = point;
            device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
            if ([device isExposureModeSupported:AVCaptureExposureModeLocked]) {
                [device addObserver:self
                         forKeyPath:@"adjustingExposure"
                            options:NSKeyValueObservingOptionNew
                            context:&CameraAdjustingExposureContext];
            }
            [device unlockForConfiguration];
        }
        else{
            //  [self showError:error];
        }
    }
}

// 将屏幕坐标系的点转换为摄像头坐标系的点
- (CGPoint)captureDevicePointForPoint:(CGPoint)point {
    
    return [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &CameraAdjustingExposureContext) {
        AVCaptureDevice *device = (AVCaptureDevice *)object;
        if (!device.isAdjustingExposure && [device isExposureModeSupported:AVCaptureExposureModeLocked]) {
            [object removeObserver:self
                        forKeyPath:@"adjustingExposure"
                           context:&CameraAdjustingExposureContext];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error;
                if ([device lockForConfiguration:&error]) {
                    device.exposureMode = AVCaptureExposureModeLocked;
                    [device unlockForConfiguration];
                }
                else{
                    //  [self showError:error];
                }
            });
        }
    }
    else{
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

#pragma mark 视频录制
- (void)startPic:(UIButton *)sender{
    isStart = YES;//开始录制
    //[self labelHint:@"请跟随蓝色竖线，左右转动头部"];
    [self labelHint:NSLocalizedString(@"请跟随蓝色竖线，左右转动头部",@"")];
    //[stopBtn removeFromSuperview];
    //[sender removeFromSuperview];
    stopBtn.alpha = 0;
    sender.alpha = 0;
    [self.audioPlayer play];
    if (myTime) {
        [myTime setFireDate:[NSDate distantPast]];
    }else{
        myTime = [NSTimer scheduledTimerWithTimeInterval:0.04 target:self selector:@selector(blueMove) userInfo:nil repeats:YES];
        [myTime setFireDate:[NSDate distantPast]];
    }
    //根据设备输出获得连接
    AVCaptureConnection *captureConnection=[self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    //根据连接取得设备输出的数据
    if (![self.captureMovieFileOutput isRecording]) {
        self.enableRotation=NO;
        //如果支持多任务则则开始多任务
        if ([[UIDevice currentDevice] isMultitaskingSupported]) {
            self.backgroundTaskIdentifier=[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        }
        //预览图层和视频方向保持一致
        captureConnection.videoOrientation=[self.captureVideoPreviewLayer connection].videoOrientation;
        //NSString *outputFielPath=[NSTemporaryDirectory() stringByAppendingString:@"myMovie.mov"];
        NSString *outputFielPath=self.videoPath;
        NSLog(@"save path is :%@",outputFielPath);
        self.videoPath = outputFielPath;
        NSURL *fileUrl=[NSURL fileURLWithPath:outputFielPath];
        [self.captureMovieFileOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
    }
    else{
        [self.captureMovieFileOutput stopRecording];//停止录制
    }

}
- (void)blueMove{
    
    CGRect rect = blueView.frame;
    
    rect.origin.x = rect.origin.x + Vx;
    [UIView animateWithDuration:0.1 animations:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            blueView.frame = rect;
        });
    }];
    //当点击录制，则关闭刷新曝光和聚焦
    
    if ((rect.origin.x < (WIDTH / 2) ) && resetTimer) {
        
        [resetTimer invalidate];
        
        resetTimer = nil;
        
        NSLog(@"注销");
    }
    //
    if (rect.origin.x <= WIDTH / 6 + WIDTH / 30) {

        Vx = -Vx;
    }
    if (rect.origin.x < WIDTH / 2 && isOk) {

        [myTime setFireDate:[NSDate distantFuture]];
        [myTime invalidate];
        myTime = nil;
        stopBtn.alpha = 1;
        startBtn.alpha = 1;
        [self.captureMovieFileOutput stopRecording];//停止录制
    }
    if (rect.origin.x > WIDTH / 6 * 5 - WIDTH / 30) {

        Vx = -Vx;
        isOk = YES;
        
    }}

#pragma mark - 视频输出代理
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"开始录制...");
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    NSLog(@"视频录制完成.");
    NSFileManager *fm = [NSFileManager defaultManager];
    picPath = [NSString stringWithFormat:@"%@/%@",SEQMAP_PATH,[TopTools uuidString]];
    [fm createDirectoryAtPath:picPath withIntermediateDirectories:YES attributes:nil error:nil];
    [self dismissViewControllerAnimated:YES completion:^{
            _testBlock(self.videoPath,picPath);
    }];
    
}
#pragma mark - 通知
/**
 *  给输入设备添加通知
 */
-(void)addNotificationToCaptureDevice:(AVCaptureDevice *)captureDevice{
    //注意添加区域改变捕获通知必须首先设置设备允许捕获
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        captureDevice.subjectAreaChangeMonitoringEnabled=YES;
    }];
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    //捕获区域发生改变
    [notificationCenter addObserver:self selector:@selector(areaChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(succeedHandle:) name:@"MessageFromStaticGlassesSDK" object:nil];
    //接收未检测到人脸消息
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nullForDetectedFace:) name:@"NodetectedFace" object:nil];
    //接收正脸消息
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(returnForMiddlePic:) name:@"MiddlePictureComplete" object:nil];
}

-(void)removeNotificationFromCaptureDevice:(AVCaptureDevice *)captureDevice{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}
/**
 *  移除所有通知
 */
-(void)removeNotification{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
}

-(void)addNotificationToCaptureSession:(AVCaptureSession *)captureSession{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    //会话出错
    [notificationCenter addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:captureSession];
}

/**
 *  设备连接成功
 *
 *  @param notification 通知对象
 */
-(void)deviceConnected:(NSNotification *)notification{
    NSLog(@"设备已连接...");
}
/**
 *  设备连接断开
 *
 *  @param notification 通知对象
 */
-(void)deviceDisconnected:(NSNotification *)notification{
    NSLog(@"设备已断开.");
}
/**
 *  捕获区域改变
 *
 *  @param notification 通知对象
 */
-(void)areaChange:(NSNotification *)notification{
    NSLog(@"捕获区域改变...");
}

/**
 *  会话出错
 *
 *  @param notification 通知对象
 */
-(void)sessionRuntimeError:(NSNotification *)notification{
    NSLog(@"会话发生错误.");
}

#pragma mark - 私有方法

/**
 *  取得指定位置的摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 摄像头设备
 */
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}

/**
 *  改变设备属性的统一操作方法
 *
 *  @param propertyChange 属性改变操作
 */
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice *captureDevice= [self.captureDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

/**
 *  @brief  AlertController弹框
 *
 *  @param  title       弹框标题
 *
 *  @param  message     弹框显示的信息
 *
 *  @param  leftStr        左侧按钮（cancle）字样
 *
 *  @param  rightStr       右侧按钮（sure）字样
 *
 *  @param  cancleBlock 取消执行操作
 *
 *  @param  sureBlock   确定执行操作
 */
- (void)presentVlertControllerForTitle:(NSString *)title andMessage:(NSString *)message left:(NSString *)leftStr andRight:(NSString *)rightStr andCancle:(L_AlertActionBlock)cancleBlock andSure:(L_AlertActionBlock)sureBlock{
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionTure = [UIAlertAction actionWithTitle:rightStr style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        sureBlock(@"取消");
        NSLog(@"确定！");
    }];
    UIAlertAction *actionFalse = [UIAlertAction actionWithTitle:leftStr style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
      
        cancleBlock(@"确定");
    }];
    [alertVc addAction:actionFalse];
    [alertVc addAction:actionTure];
    [self presentViewController:alertVc animated:YES completion:^{
        
    }];
}

#pragma mark -- 创建SDKHandke
//- (void)creatSDKHandle{
//    NSFileManager *fM = [NSFileManager defaultManager];
//    if (!customHandle) {
//        customHandle = [[SDKHandle alloc]initWithFrame:CGRectMake(0, 65, WIDTH, WIDTH)];
//        [customHandle Engine_Init];
//        [customHandle enhancePics:1 andValue:0.5];
//        [customHandle enhancePics:2 andValue:0.5];
//        [customHandle enhancePics:3 andValue:0.5];
//        customHandle.multipleTouchEnabled = YES;
//        [customHandle SetFocuswithFocus: 31];
//        [customHandle changePicturesIfNeed];
//        [self.view addSubview:customHandle];
//    }else{
//
//    }
//    picPath = [NSString stringWithFormat:@"%@/%@",SEQMAP_PATH,[TopTools uuidString]];
//    [fM createDirectoryAtPath:picPath withIntermediateDirectories:YES attributes:nil error:nil];
//    [customHandle useVideoWithVideoPath:self.videoPath andPicturePath:picPath];
//    
//    _faceImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 65, WIDTH, WIDTH)];
//    __weak customViewController *weakSelf = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [weakSelf.view addSubview:_faceImageView];//加载正脸图片
//        //[self moveHandle:YES];
//    });
//}

#pragma  -- SDKHandle通知的回调函数

/**
 *处理成功
 *
 */
- (void)succeedHandle:(NSNotification *)aNotification{
    NSLog(@"生成成功");
    isRecord = YES;
    [customHandle loadPictureWithOrder:YES andPicturePath:picPath];
    [customHandle loadGlassesModel:self.modelArrays[0]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self endAnimationFoo];
        [_faceImageView removeFromSuperview];
       
        _faceImageView.layer.borderWidth = 2;
    });
}

/**
 *处理失败
 *
 */
- (void)nullForDetectedFace:(NSNotification *)aNotification{
    isRecord = NO;
    
    self.view.userInteractionEnabled = YES;
    [customHandle loadPictureWithOrder:YES andPicturePath:picPath];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *uac = [UIAlertController alertControllerWithTitle:nil message:@"未采集到人脸，请重新录制" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ac = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
        [uac addAction:ac];
        [self presentViewController:uac animated:YES completion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [_faceImageView removeFromSuperview];
                           });
        }];
        
    });
    NSLog(@"生成失败");
}

/**
 *得到正脸图片
 *
 */
- (void)returnForMiddlePic:(NSNotification *)aNotification{
 
    NSLog(@"拿到正脸数据");
    NSData *data = (NSData *)aNotification.object;

    dispatch_async(dispatch_get_main_queue(), ^{
        _faceImageView.image = [UIImage imageWithData:data];
        self.viewContainer.hidden =YES;
        [self BeaginAnimationFoo];

    });

}

#pragma mark 触摸事件
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"%ld",(unsigned long)touches.count);
    
    NSArray *fingerArray = [[event allTouches] allObjects];
    if (fingerArray.count > 1) {
        UITouch *touch= fingerArray[0];
        UITouch *touch1 = fingerArray[1];
        CGPoint point = [touch locationInView:self.view];
        CGPoint point1 = [touch1 locationInView:self.view];
        originY = fabs(point.y - point1.y);
        originX = fabs(point.x - point1.x);
    }
    
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    count ++;
    //取得一个触摸对象（对于多点触摸可能有多个对象）
    NSArray *fingerArray = [touches allObjects];
    UITouch *touch= fingerArray[0];
    NSLog(@"%@",touch);
    
    //取得当前位置
    CGPoint current=[touch locationInView:self.view];
    //取得前一个位置
    CGPoint previous=[touch previousLocationInView:self.view];
    //*******
    float moveX = current.x - previous.x;
    float moveY = current.y - previous.y;
    if (count > 3) {
        if(touches.count == 1){
            if (fabs(moveX)/fabs(moveY)>1) {
                if (!singleH) {
                    singleV = YES;bothH = YES;bothV = YES;mediateScale = YES;
                    if(moveX > 0) {
                        [customHandle loadPictureWithOrder:YES andPicturePath:picPath];
                    } else  if(moveX < 0){
                        [customHandle loadPictureWithOrder:NO andPicturePath:picPath];
                    }
                }
            } else {//改变镜拖的灵敏度
                if (!singleV) {
                    
                    singleH = YES;bothH = YES;bothV = YES;mediateScale = YES;
                    
                    if(moveY > 0){
                        
                        glassHeight = glassHeight +0.04;
                        
                        if (glassHeight > 1.0) {
                            glassHeight = 1.0;
                        }
                    }else if (moveY < 0){
                        glassHeight = glassHeight -0.04;
                        //  glassHeight = glassHeight - 0.1;
                        if (glassHeight < 0.0) {
                            glassHeight = 0.0;
                        }
                    }
                    // NSLog(@"glassHeight %f",glassHeight);
                    [customHandle SetNosePadPos:glassHeight];
                }
            }
        }
        else if(touches.count == 2)
        {
            NSArray *arr = [touches allObjects];
            UITouch *touch1 = (UITouch *)arr[0];
            UITouch *touch2 = (UITouch *)arr[1];
            
            CGPoint current1=[touch1 locationInView:self.view];
            //取得前一个位置
            CGPoint previous1=[touch1 previousLocationInView:self.view];
            //****************捏合手势
            CGPoint current2=[touch2 locationInView:self.view];
            CGPoint previous2=[touch2 previousLocationInView:self.view];
            CGFloat cc = (current2.x - current1.x) * (current2.x - current1.x) + (current2.y - current1.y) * (current2.y - current1.y);
            CGFloat cc1 = (previous2.x - previous1.x) * (previous2.x - previous1.x) + (previous2.y - previous1.y) * (previous2.y - previous1.y);
            CGFloat occ = originX * originX + originY * originY;
            NSLog(@"cc===========================================%f",cc1);
            if (occ > 40000) {
                if (!mediateScale) {
                    singleH = YES;singleV = YES;bothH = YES;bothV = YES;
                    if (cc > cc1) {
                        glassModelScale = glassModelScale + 0.05;
                        if (glassModelScale > 1.0) {
                            glassModelScale = 1.0;
                        }
                        [customHandle setGlassModelScale:glassModelScale];
                    }else{
                        glassModelScale = glassModelScale - 0.05;
                        if (glassModelScale < 0.0) {
                            glassModelScale = 0.0;
                        }
                        [customHandle setGlassModelScale:glassModelScale];
                    }
                }
            }
            float bmoveX = current1.x - previous1.x;
            float bmoveY = current1.y - previous1.y;
            //        float bmoveX = fabs(current1.x - current2.x)/2 - fabs(previous1.x - previous2.x);
            //        float bmoveY = fabs(current1.y - current2.y)/2 - fabs(previous1.y - previous2.y);
            if (fabs(bmoveX)/fabs(bmoveY)>1) {
                if (!bothH) {
                    bothV = YES;singleH = YES;singleV = YES;mediateScale = YES;
                    if(moveX > 0) {
                        featherDistance = featherDistance -0.05;
                        if (featherDistance > 1.0) {
                            featherDistance = 1.0;
                        }
                    } else  if(moveX < 0){
                        featherDistance = featherDistance +0.05;
                        if (featherDistance < 0.0) {
                            featherDistance = 0.0;
                        }
                    }
                    [customHandle SetFeatherDistance:featherDistance];
                }
                
            } else {
                if (!bothV) {
                    bothH = YES;singleH = YES;singleV = YES;mediateScale = YES;
                    if(moveY < 0) {
                        verticalAngle = verticalAngle +0.05;
                        if (verticalAngle > 1.0) {
                            verticalAngle = 1.0;
                        }
                    } else  if(moveY > 0){
                        verticalAngle = verticalAngle -0.05;
                        if (verticalAngle < 0.0) {
                            verticalAngle = 0.0;
                        }
                    }
                    [customHandle SetGlassVerticalAngle:verticalAngle];
                }
                
            }
        }
        //    NSLog(@"UIViewController moving...");
    }//*****
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    bothH = NO;bothV = NO;singleV = NO;singleH = NO;mediateScale = NO;
    
    count = 0;
}

#pragma mark -- 按钮状态
//录制前
- (void)recordNormal{

}
//录制过程中
- (void)recordStart{

}
//录制结束
- (void)recordEnd{

}
- (void)viewWillDisappear:(BOOL)animated{
    [timer invalidate];
    [resetTimer invalidate];
    [motionManager stopDeviceMotionUpdates];
    motionManager = nil;
    NSUserDefaults *user_d = [NSUserDefaults standardUserDefaults];
    [user_d setObject:@(featherDistance) forKey:@"feather"];
    isRecord = NO;
}
-(void)dealloc{
    [self removeNotification];
    NSLog(@"dealloc");
}
/**label提示*/
- (void)labelHint:(NSString *)str{
    if ([NSThread isMainThread]) {
        _gyroscopeLabel.text = str;
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            _gyroscopeLabel.text = str;
        });
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
