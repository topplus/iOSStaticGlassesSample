//
//  pictureViewController.m
//  three_topplusvisionDemo
//
//  Created by Jeavil on 16/1/19.
//  Copyright © 2016年 topplusvision. All rights reserved.
//
#define WIDTH  [UIScreen mainScreen].bounds.size.width
#define HEIGHT  [UIScreen mainScreen].bounds.size.height
#define MEDIA_TYPE_MOIVE  [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary].lastObject
#define DOCUMENT_PATH   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject
#define SEQMAP_PATH [NSString stringWithFormat:@"%@%@res",DOCUMENT_PATH,@"/"]
#define Heard_HEIGHT self.navigationController.navigationBar.bounds.size.height
#import "picturePathsViewController.h"
#import "TopImagePicController.h"
#import "SVProgressHUD/SVProgressHUD.h"
#import "ViewController.h"
#import <TGOSGFramework/TGOSGFramework.h>
#import "multipleViewController.h"
#import "TopTools.h"
@interface picturePathsViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIPickerViewDataSource,UIPickerViewDelegate>{
    UILabel *label;
    SDKHandle *handle;
    long int   count;
    double     glassHeight;//镜架高度
    double     verticalAngle;//翻滚角
    double     featherDistance;//镜腿
    double     glassModelScale;//眼镜模型
    NSInteger finger;
    CGFloat navheight;
    double originY;//调整上下滑动的精度获取touchbegean的原始Y坐标
    double originX;
    BOOL singleV;
    BOOL singleH;
    BOOL bothV;
    BOOL bothH;
    BOOL mediateScale;
    
    UIImageView *imageView;
    UIView *viewForImage;
    NSTimer *timer;
    int picCount;
    int modelCount;
    UIView *blueMask;
    BOOL changeFrame;
    
    UIImageView *lightView;
    int demovVideoCount;//表示第几个demovideo
    UIImageView *middleImageView;
    UIButton *multipleBtn;
    
    UIScrollView *scroll;
    NSMutableArray *imageViews;
}
@property (nonatomic, strong) NSMutableArray *modelNames;
@property (nonatomic, strong) UIPickerView *picker;
@end

@implementation picturePathsViewController
- (NSMutableArray *)modelNames{
    
    if(!_modelNames)
    {
        _modelNames = [NSMutableArray array];
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
                [_modelNames addObject:fileFullName];
            }
        }
        [_modelNames insertObject:@"录制视频后，请选择一副眼镜" atIndex:0];
    }
    
    return _modelNames;
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                
                                [UIColor blackColor],
                                
                                NSForegroundColorAttributeName, nil];
    
    [self.navigationController.navigationBar setTitleTextAttributes:attributes];
    
    self.navigationController.navigationBar.tintColor = [UIColor blackColor]; //定义导航栏颜色
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self allNumbers];
    [self creatHandle];
    //[self creatStep];//美颜
    //[self creatLabelFace];//人脸类型
    //[self creatCutBtn];//CUT OUT
    
    [self creatMultipleBtn];
#ifdef All_Gst
    [self creatPicker];
#else
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, HEIGHT - (WIDTH / 3) - 30, WIDTH, (WIDTH / 3) + 30)];
    view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:view];
    [self creatScrollView];
#endif

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(test:) name:@"MessageFromStaticGlassesSDK" object:nil];
    //接收未检测到人脸消息
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(testForDetectedFace:) name:@"NodetectedFace" object:nil];
    //接收正脸消息
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(testForMiddlePic:) name:@"MiddlePictureComplete" object:nil];
    
}

//人脸类型
- (void)creatLabelFace{
    
    label = [[UILabel alloc]initWithFrame:CGRectMake(WIDTH - 100, 70, 100, 50)];
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    [label setTintColor:[UIColor blackColor]];
    [self.view addSubview:label];
}
- (void)creatCutBtn{
    
    UIButton *cutBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cutBtn.frame = CGRectMake(0, 120, 50,50);
    [cutBtn addTarget:self action:@selector(cutOutPicture:) forControlEvents:UIControlEventTouchUpInside];
    [cutBtn setTitle:@"cut" forState:UIControlStateNormal];
    [self.view addSubview:cutBtn];
}
//截图
- (void)cutOutPicture:(UIButton *)sender{
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    CGSize imageSize = CGSizeZero;
    if (UIInterfaceOrientationIsPortrait(orientation))
        imageSize = [UIScreen mainScreen].bounds.size;
    else
        imageSize = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
    {
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, window.center.x, window.center.y);
        CGContextConcatCTM(context, window.transform);
        CGContextTranslateCTM(context, -window.bounds.size.width * window.layer.anchorPoint.x, -window.bounds.size.height * window.layer.anchorPoint.y);
        
        // Correct for the screen orientation
        
        if(orientation == UIInterfaceOrientationLandscapeLeft)
        {
            CGContextRotateCTM(context, (CGFloat)M_PI_2);
            CGContextTranslateCTM(context, 0, -imageSize.width);
        }
        else if(orientation == UIInterfaceOrientationLandscapeRight)
        {
            CGContextRotateCTM(context, (CGFloat)-M_PI_2);
            CGContextTranslateCTM(context, -imageSize.height, 0);
        }
        else if(orientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            CGContextRotateCTM(context, (CGFloat)M_PI);
            CGContextTranslateCTM(context, -imageSize.width, -imageSize.height);
        }
        
        if([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)])
            [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO];
        else
            [window.layer renderInContext:UIGraphicsGetCurrentContext()];
        
        CGContextRestoreGState(context);
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    CGRect rect = CGRectMake(0, 140, 2*WIDTH, 2*WIDTH);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    UIImage * imge = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    UIImageWriteToSavedPhotosAlbum(imge, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    UIGraphicsEndImageContext();
    
}
- (void)image:(NSString *)videoFileName didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    [SVProgressHUD showSuccessWithStatus:@"已保存到系统相册"];
    
}
- (void)creatStep{
    
    UISegmentedControl *segment = [[UISegmentedControl alloc]initWithFrame:CGRectMake(0, 70, 210, 50)];
    [segment insertSegmentWithTitle:@"美白" atIndex:0 animated:YES];
    [segment insertSegmentWithTitle:@"磨皮" atIndex:1 animated:YES];
    [segment insertSegmentWithTitle:@"美白磨皮" atIndex:2 animated:YES];
    [segment insertSegmentWithTitle:@"原图" atIndex:3 animated:YES];
    [segment addTarget:self action:@selector(segmentClick:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:segment];
}
- (void)segmentClick:(UISegmentedControl *)sender{
    int index = (int)sender.selectedSegmentIndex;
    self.view.userInteractionEnabled = NO;
    if (handle) {
        if (index != 3) {
            [SVProgressHUD showWithStatus:@"美颜中..."];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                    self.view.userInteractionEnabled = YES;
                });
            });
        }else{
            
            
            self.view.userInteractionEnabled = YES;
        }
        
    }
}

- (void)allNumbers{
    count = 0;
    featherDistance = 1.0;
    glassHeight = 0.2;
    glassModelScale = 0.5;
    verticalAngle = 0.5;
    picCount = 0;
    modelCount = 0;
    demovVideoCount = 1;
}
//初始化picker
- (void)creatPicker{
    _picker = [[UIPickerView alloc]initWithFrame:CGRectMake(0, HEIGHT - 162, WIDTH, 162)];
    _picker.backgroundColor = [UIColor clearColor];
    _picker.delegate = self;
    [self.view addSubview:_picker];
    [self.view bringSubviewToFront:self.picker];
}

//创建滚动视图展示模型图片
- (void)creatScrollView{
    imageViews = [[NSMutableArray alloc]init];
    NSArray *picArray = @[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
    CGFloat scrollY = HEIGHT - (WIDTH / 3) - 30;
    CGFloat scrollHeight = (WIDTH / 3) + 30;
    CGFloat itemScroll = WIDTH / 3;
    
    scroll = [[UIScrollView alloc]initWithFrame:CGRectMake(0, scrollY, WIDTH, scrollHeight)];
    scroll.contentSize = CGSizeMake((WIDTH / 3) * (self.modelNames.count - 1), WIDTH / 3);
    for (int i = 1; i < self.modelNames.count; i++) {
        
        NSString *imagePath = [[NSBundle mainBundle]pathForResource:picArray[i-1] ofType:@"jpg"];
        UIImageView *simageView = [[UIImageView alloc]initWithFrame:CGRectMake(itemScroll * (i-1), 0, itemScroll, itemScroll)];
        simageView.highlightedImage = [UIImage imageNamed:@"background.png"];
        //simageView.image = [UIImage imageNamed:@"background.png"];
        simageView.userInteractionEnabled = YES;
        //[simageView addGestureRecognizer:tap];
        [scroll addSubview:simageView];
        [imageViews addObject:simageView];
        //显示眼镜
        UIImageView *glassesImgView = [[UIImageView alloc]initWithFrame:CGRectMake(2, itemScroll / 4, itemScroll - 4, itemScroll / 2)];
        glassesImgView.clipsToBounds = YES;
        glassesImgView.userInteractionEnabled = YES;
        glassesImgView.tag = 200 + i;
        //添加点击手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(modelImageTap:)];
        [glassesImgView addGestureRecognizer:tap];
        
        UIImageView *completeImgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, -(itemScroll/3), itemScroll, itemScroll)];
        // completeImgView.userInteractionEnabled = YES;
        completeImgView.image = [UIImage imageWithContentsOfFile:imagePath];
        // [completeImgView addGestureRecognizer:tap];
        [glassesImgView addSubview:completeImgView];
        
        [simageView addSubview:glassesImgView];
        
        //
        UILabel *slabel = [[UILabel alloc]initWithFrame:CGRectMake((WIDTH / 3) * (i-1) - 5, (WIDTH / 3), WIDTH / 3,30)];
        // slabel.text = str;
        slabel.textAlignment = NSTextAlignmentCenter;
        slabel.backgroundColor = [UIColor whiteColor];
        [slabel setFont:[UIFont systemFontOfSize:18]];
        [scroll addSubview:slabel];
        //
    }
    //    for (int j = 1; j < self.modelNames.count; j++) {
    //        UIImageView *blue = [[UIImageView alloc]initWithFrame:CGRectMake((WIDTH / 3) * j + 1, 30, 2, 50)];
    //        blue.backgroundColor = [UIColor grayColor];
    //        [scroll addSubview:blue];
    //    }
    
    [self.view addSubview:scroll];
    //    UIImageView *currentImageView = [[UIImageView alloc]initWithFrame:CGRectMake(WIDTH/3, HEIGHT - (WIDTH/3) - 30, WIDTH/3, WIDTH/3)];
    //    currentImageView.image = [UIImage imageNamed:@"background.png"];
    //    [self.view addSubview:currentImageView];
}

#pragma mark 模型图片的tap手势
- (void)modelImageTap:(UITapGestureRecognizer *)sender{
    if (sender.view.tag - 200 > 2 && sender.view.tag - 200 < 10) {
        [UIView animateWithDuration:0.3 animations:^{
            CGPoint point = scroll.contentOffset;
            point.x = (sender.view.tag - 200 - 2) * (WIDTH/3);
            scroll.contentOffset = point;
        }];
    }
    
    for (UIImageView *tempView in imageViews) {
        tempView.highlighted = NO;
    }
    UIImageView *senderImageView = (UIImageView *)sender.view.superview;
    senderImageView.highlighted = YES;
    //    senderImageView.image = [UIImage imageNamed:@"background.png"];
    
    
    [UIView animateWithDuration:1 delay:1 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionRepeat animations:^{
        
    } completion:^(BOOL finished) {
        
    }];
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^{
        [handle loadGlassesModel:self.modelNames[sender.view.tag - 200]];
        
    });
}


- (void)creatHandle{
    
    CGFloat x,y,width,height;
    x = 5;
    y =  Heard_HEIGHT;
    width = self.view.bounds.size.width - 10;
    height = width;
    handle = [[SDKHandle alloc] initWithFrame:CGRectMake(x, 70, width, height)];
    handle.contentMode = UIViewContentModeScaleAspectFit;
    //[handle setImageMirroredStatus:YES];//是否镜像
    //[handle SetNormalizedScale:YES];
    [handle Engine_Init];
    [handle enhancePics:1 andValue:0.5];
    [handle enhancePics:2 andValue:0.5];
    [handle SetFocuswithFocus: 31];
    
#ifdef RELEASE
    NSLog(@"RELEASE");
    [handle saveLogToFile:nil];

#endif

    handle.multipleTouchEnabled = YES;
    [self.view addSubview:handle];
    
    
    if (self.vidoPath) {
        // [SVProgressHUD showWithStatus:@"加载中，请稍候。。。"];
        [handle useVideoWithVideoPath:self.vidoPath andPicturePath:self.picPath];
        self.view.userInteractionEnabled = NO;
    }else{
        [handle changePicturesIfNeed];
        [handle loadPictureWithOrder:YES andPicturePath:self.picPath];
        dispatch_async(dispatch_get_main_queue(), ^{
            [handle loadGlassesModel:self.modelNames[0]];
        });
    }
    
    // [self beginAnimation];
}

//开始动画
- (void)beginAnimation{
    CGFloat x,y,width,height;
    x = 0;
    y =  Heard_HEIGHT;
    width = self.view.bounds.size.width;
    height = width;
    timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(changeImage) userInfo:nil repeats:YES];
    
    //
    viewForImage = [[UIView alloc]initWithFrame:CGRectMake(x, 70, width, height)];
    viewForImage.clipsToBounds = YES;
    viewForImage.backgroundColor = [UIColor clearColor];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view addSubview:viewForImage];
    });
    //
    imageView = [[UIImageView alloc]initWithFrame:CGRectMake(x, 0, width, height)];
    imageView.alpha = 0;
    imageView.clipsToBounds = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    //    NSString *picpath = [[NSBundle mainBundle]pathForResource:@"1" ofType:@"png"];
    //    imageView.image = [UIImage imageWithContentsOfFile:picpath];
    dispatch_async(dispatch_get_main_queue(), ^{
        [viewForImage addSubview:imageView];
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:2 animations:^{
            imageView.alpha = 0.7;
            [timer setFireDate:[NSDate distantPast]];
        }];
    });
    //添加动画_mask
    blueMask = [[UIView alloc]initWithFrame:CGRectMake(0, 70, width, 0)];
    lightView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 70, WIDTH, 10)];
    lightView.image = [UIImage imageNamed:@"flashlight.png"];
    blueMask.alpha = 0.5;
    UIColor *color = [UIColor colorWithRed:5/255.0 green:175/255.0 blue:214/255.0 alpha:0.7];
    blueMask.backgroundColor = color;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view addSubview:blueMask];
        [UIView animateWithDuration:2 animations:^{
            
            CGRect rect = blueMask.frame;
            rect.size.height = WIDTH;
            blueMask.frame = rect;
        }];
    });
}
//结束动画
- (void)stopAnimation{
    [timer setFireDate:[NSDate distantFuture]];
    [timer invalidate];
    timer = nil;
    //移除lightView
    if (lightView) {
        [lightView removeFromSuperview];
        lightView = nil;
    }
    //   NSString *path = [[NSBundle mainBundle]pathForResource:@"1" ofType:@"png"];
    dispatch_async(dispatch_get_main_queue(), ^{
        //   imageView.image = [UIImage imageWithContentsOfFile:path];
        //  imageView.alpha = 0.7;
        [UIView animateWithDuration:2 animations:^{
            CGRect rect = viewForImage.frame;
            rect.size.height = 0;
            viewForImage.frame = rect;
            //蓝色帷幕消失
            CGRect blueRect = blueMask.frame;
            blueRect.size.height = 0;
            blueMask.frame = blueRect;
        }];
        
    });
    
    
}
//timer的selector
- (void)changeImage{
    picCount++;
    if (picCount % 4 == 0) {
        //white
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view addSubview:lightView];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:2 animations:^{
                if (picCount % 8 == 0) {
                    CGRect rect = lightView.frame;
                    rect.origin.y -= WIDTH + 70;
                    lightView.frame = rect;
                }else{
                    CGRect rect = lightView.frame;
                    rect.origin.y = WIDTH + 70;
                    lightView.frame = rect;
                }
            }];
            
        });
    }

}
//列表
- (void)creatMultipleBtn{
    
    multipleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    multipleBtn.frame = CGRectMake(0, 0, 60, 30);
    [multipleBtn addTarget:self action:@selector(multipleClick:) forControlEvents:UIControlEventTouchUpInside];
    [multipleBtn setTitle:NSLocalizedString(@"列表",@"") forState:UIControlStateNormal];
    multipleBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    // [multipleBtn setImage:[UIImage imageNamed:@"列表"] forState:UIControlStateNormal];
    [multipleBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:multipleBtn];
}
//multipleClick:
- (void)multipleClick:(UIButton *)sender{
    [handle saveAdjustedAttitude];
    multipleViewController *mvc = [[multipleViewController alloc]init];
    NSInteger index = [handle middleIndex];
    if (index == -1) {
        return;
    }
    mvc.index = index;
    mvc.picPath = self.picPath;
    NSLog(@"second picpath = %@",mvc.picPath);
    NSMutableArray *modelArray = [NSMutableArray arrayWithArray:self.modelNames];
    [modelArray removeObjectAtIndex:0];
    mvc.glassModels = modelArray;
    [self.navigationController pushViewController:mvc animated:YES];
}



//获得正脸图片
- (void)testForMiddlePic:(NSNotification *)aNotification{
    NSData *data = (NSData *)aNotification.object;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!middleImageView) {
            middleImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 70, WIDTH, WIDTH)];
            [self.view addSubview:middleImageView];
            [self beginAnimation];
        }
        middleImageView.image = [UIImage imageWithData:data];
    });
}

//接收未检测到人脸消息
- (void)testForDetectedFace:(NSNotification *)aNotification{
    //未检测到人脸禁用列表
    multipleBtn.userInteractionEnabled = NO;
    [self stopAnimation];
    self.view.userInteractionEnabled = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        UIAlertController *uac = [UIAlertController alertControllerWithTitle:nil message:@"未采集到人脸，请重新录制" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ac = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
        [uac addAction:ac];
        [self presentViewController:uac animated:YES completion:^{
            
        }];
        
    });
}

- (void)test:(NSNotification *)aNotification{
    self.view.userInteractionEnabled = YES;
    [self stopAnimation];
    if (handle && !self.disposeDemoVideo) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            // [imageView removeFromSuperview];
            [lightView removeFromSuperview];
            [handle changePicturesIfNeed];
            [handle loadPictureWithOrder:YES andPicturePath:self.picPath];
            [handle loadGlassesModel:self.modelNames[0]];
            NSInteger index = [handle middleIndex];
            //NSString *str = [NSString stringWithFormat:@"%ld",index];
            //返回index，正中的图片
            self.block(_vidoPath,_picPath);
            NSArray *faceShapes = @[@"圆脸",@"椭圆",@"三角",@"方脸",@"瓜子"];
            int type = [handle getFaceShape];
            if (type != -1 ) {
                label.text = faceShapes[type];
            }
        });
    }
    if (middleImageView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [middleImageView removeFromSuperview];
            middleImageView = nil;
        });
    }
    
}
#pragma mark pickerview 数据源方法
-(NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (self.modelNames.count > 0)
        return self.modelNames.count;
    return 0;
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    
    return [[self.modelNames[row] lastPathComponent] stringByDeletingPathExtension] ;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component{
    
    return 50;
}

#pragma mark pickerview 代理方法
-(void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    //传入全路径改变眼镜模型
    [handle loadGlassesModel:self.modelNames[row]];
    [handle SetGlassVerticalAngle:verticalAngle];
}

//- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view{
//
//    UIImageView *image = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"eyes.jpg"]];
//    image.frame = CGRectMake(0, 0, 100, 55);
//    return image;
//}
#pragma mark 触摸事件
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

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
        if(touches.count == 1)
        {
            
            if (fabs(moveX)/fabs(moveY)>1) {
                if (!singleH) {
                    singleV = YES;
                    bothH = YES;
                    bothV = YES;
                    mediateScale = YES;
                    if(moveX > 0) {
                        [handle loadPictureWithOrder:YES andPicturePath:self.picPath];
                    } else  if(moveX < 0){
                        [handle loadPictureWithOrder:NO andPicturePath:self.picPath];
                    }
                }
            } else {//改变镜拖的灵敏度
                if (!singleV) {
                    singleH = YES;
                    bothH = YES;
                    bothV = YES;
                    mediateScale = YES;
                    if(moveY > 0){
                        glassHeight = glassHeight +0.04;
                        //glassHeight = glassHeight +0.1;
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
                    [handle SetNosePadPos:glassHeight];
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
                    singleH = YES;
                    singleV = YES;
                    bothH = YES;
                    bothV = YES;
                    if (cc > cc1) {
                        glassModelScale = glassModelScale + 0.05;
                        [handle setGlassModelScale:glassModelScale];
                    }else{
                        glassModelScale = glassModelScale - 0.05;
                        [handle setGlassModelScale:glassModelScale];
                    }
                }
            }
            //****************
            float bmoveX = current1.x - previous1.x;
            float bmoveY = current1.y - previous1.y;
            //        float bmoveX = fabs(current1.x - current2.x)/2 - fabs(previous1.x - previous2.x);
            //        float bmoveY = fabs(current1.y - current2.y)/2 - fabs(previous1.y - previous2.y);
            if (fabs(bmoveX)/fabs(bmoveY)>1) {
                if (!bothH) {
                    bothV = YES;
                    singleH = YES;
                    singleV = YES;
                    mediateScale = YES;
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
                    [handle SetFeatherDistance:featherDistance];
                }
                
            } else {
                if (!bothV) {
                    bothH = YES;
                    singleH = YES;
                    singleV = YES;
                    mediateScale = YES;
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
                    [handle SetGlassVerticalAngle:verticalAngle];
                }
                
            }
        }
        //    NSLog(@"UIViewController moving...");
    }//*****
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    bothH = NO;
    bothV = NO;
    singleV = NO;
    singleH = NO;
    mediateScale = NO;
    count = 0;
    
}
- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}
- (void)viewWillDisappear:(BOOL)animated{
    
    [middleImageView removeFromSuperview];
    middleImageView = nil;
}
@end
