//
//  multipleViewController.m
//  three_topplusvisionDemo
//
//  Created by Jeavil on 16/1/27.
//  Copyright © 2016年 topplusvision. All rights reserved.
//
#define WIDTH  [UIScreen mainScreen].bounds.size.width
#define HEIGHT  [UIScreen mainScreen].bounds.size.height
#define Heard_HEIGHT (self.navigationController.navigationBar.bounds.size.height + self.navigationController.navigationBar.bounds.origin.y)
#import "multipleViewController.h"
#import <TGOSGFramework/TGOSGFramework.h>
#import "TopTools.h"
@interface multipleViewController ()<UITableViewDataSource,UITableViewDelegate,UIScrollViewDelegate,UIGestureRecognizerDelegate>{
    UIImage *img;//正面图像
    
    //tableview
    UITableView *multipleTable;
    SDKHandle *handle;
    SDKHandle *handle1;
    SDKHandle *handle2;
    SDKHandle *handle3;
    
    //pan手势中上一个点
    CGPoint lastPoint;
    UIPanGestureRecognizer *pan;
    
    
    NSInteger lastModel;
    NSInteger currentModel;
    
    NSInteger lastModel1;
    NSInteger currentModel1;
    
    NSInteger lastModel2;
    NSInteger currentModel2;
    
    NSInteger lastModel3;
    NSInteger currentModel3;
    
    dispatch_queue_t topQueue;
    BOOL isHidden;
    float currentOffset; //列表当前的偏移
    BOOL isVisiable;
    BOOL isScroll;//tableview是否在滚动
    BOOL firstScroll;//解决默认调用 scrollDidend
}

@end

@implementation multipleViewController

-  (void)viewDidLoad {
    [super viewDidLoad];
    isVisiable = NO;
    isScroll = NO;
    firstScroll = YES;
    //    [self creatBtn];
    self.view.backgroundColor = [UIColor grayColor];
    topQueue = dispatch_queue_create("topThread", DISPATCH_QUEUE_SERIAL);
    handle = [TopTools handle];
   dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [handle changePicturesIfNeed];
        [handle loadPictureWithOrder:YES andPicturePath:self.picPath];
        [handle loadGlassesModel:self.glassModels[0]];
    });
    handle1 = [TopTools handle];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [handle1 changePicturesIfNeed];
        [handle1 loadPictureWithOrder:YES andPicturePath:self.picPath];
        [handle1 loadGlassesModel:self.glassModels[1]];
    });
    handle2 = [TopTools handle];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [handle2 changePicturesIfNeed];
        [handle2 loadPictureWithOrder:YES andPicturePath:self.picPath];
        [handle2 loadGlassesModel:self.glassModels[2]];
    });
    //4个handle
    handle3 = [TopTools handle];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [handle3 changePicturesIfNeed];
        [handle3 loadPictureWithOrder:YES andPicturePath:self.picPath];
        [handle3 loadGlassesModel:self.glassModels[3]];
    });
    //  [self getImage];
    
    [self loadData];
    [self creatTable];
}
//隐身按钮
- (void)creatBtn{
    
    UIButton *hiddenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    hiddenBtn.backgroundColor = [UIColor yellowColor];
    hiddenBtn.frame = CGRectMake(0, 0, 70, 70);
    [hiddenBtn addTarget:self action:@selector(hiddenClick:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:hiddenBtn];
}
- (void)hiddenClick:(UIButton *)sender{
    
    if (!sender.selected) {
        [handle hideGlassModel:YES];
        [handle1 hideGlassModel:YES];
        [handle2 hideGlassModel:YES];
        NSLog(@"*********************yes");
        sender.selected = YES;
    }else{
        [handle hideGlassModel:NO];
        [handle1 hideGlassModel:NO];
        [handle2 hideGlassModel:NO];
        NSLog(@"********************no");
        sender.selected = NO;
    }
}
//得到正脸图像
- (void)getImage{
    NSString *suffix = nil;
    if (self.index >= 0) {
        suffix = [NSString stringWithFormat:@"/%ld.jpg",(long)self.index];
    }
    //NSString *target = [videoPath stringByAppendingString:@"0.jpg"];
    NSString *target = [self.picPath stringByAppendingString:suffix];
    img = [UIImage imageWithContentsOfFile:target];
}
//初始化multipleTable
- (void)creatTable{
    multipleTable = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT) style:UITableViewStylePlain];
    multipleTable.delegate = self;
    multipleTable.dataSource = self;
    [self.view addSubview:multipleTable];
    [multipleTable reloadData];
    multipleTable.multipleTouchEnabled = YES;
    pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panClick:)];
    pan.delegate = self;
    [multipleTable addGestureRecognizer:pan];
}
- (void)loadData{
    lastModel = 0;
    lastModel1 = 1;
    lastModel2 = 0;
    lastModel3 = 0;
}

- (void)hiddenGlasses{
    [handle hideGlassModel:YES];
    [handle1 hideGlassModel:YES];
    [handle2 hideGlassModel:YES];
    isHidden = YES;
}
//
- (void)panClick:(UIPanGestureRecognizer *)press{
    if (firstScroll) {
        isScroll = NO;
        firstScroll = NO;
    }
    NSLog(@"pan");
    if (press.state == UIGestureRecognizerStateBegan) {
        lastPoint = [press translationInView:multipleTable];
    }
    
    if (press.state == UIGestureRecognizerStateChanged) {
        NSLog(@"pan isscroll=%d",isScroll);
        if (!isScroll) {
            
            CGPoint current = [press translationInView:multipleTable];
            NSLog(@"L C=%f,Last=%f",current.x,lastPoint.x);
            //if (ABS(current.x - lastPoint.x) > ABS(current.y - lastPoint.y)) {

            if ((current.x - lastPoint.x) > 8) {
                multipleTable.scrollEnabled = NO;
                NSLog(@"1");
                [handle loadPictureWithOrder:YES andPicturePath:self.picPath];
                [handle1 loadPictureWithOrder:YES andPicturePath:self.picPath];
                [handle2 loadPictureWithOrder:YES andPicturePath:self.picPath];
                [handle3 loadPictureWithOrder:YES andPicturePath:self.picPath];
                lastPoint.x = current.x ;
            }else if((current.x - lastPoint.x) < -8){
                multipleTable.scrollEnabled = NO;
                NSLog(@"2");
                [handle loadPictureWithOrder:NO andPicturePath:self.picPath];
                [handle1 loadPictureWithOrder:NO andPicturePath:self.picPath];
                [handle2 loadPictureWithOrder:NO andPicturePath:self.picPath];
                [handle3 loadPictureWithOrder:NO andPicturePath:self.picPath];
                lastPoint.x = current.x ;
            }
        }
        // }
    }
    if (press.state == UIGestureRecognizerStateEnded) {//pan手势结束  恢复list滚动
        
        multipleTable.scrollEnabled = YES;
    }
}
#pragma mark 屏幕点击
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    currentOffset = multipleTable.contentOffset.y;
}
#pragma  mark tableview的回调方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.glassModels.count > 0) return self.glassModels.count;
    return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return HEIGHT/3;
}
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, WIDTH, 20)];
    view.backgroundColor = [UIColor grayColor];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSLog(@"tableview == %f",tableView.contentOffset.y);
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CELL"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CELL"];
    }else{
        
        NSArray *subviews = [[NSArray alloc] initWithArray:cell.contentView.subviews];
        for (UIView *subview in subviews) {
            [subview removeFromSuperview];
        }
        
    }
    if ((indexPath.row % 4) == 0) {
        currentModel = indexPath.row;
        if (currentModel == lastModel) {
            //如果当前index与上次相同则显示
            dispatch_async(topQueue, ^{
                [handle hideGlassModel:YES];
            });
        }else if (isVisiable){
            dispatch_async(topQueue, ^{
                [handle hideGlassModel:NO];
            });
        }
        UIImageView *imageV = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT/2)];
        imageV.clipsToBounds = YES;
        [imageV addSubview:handle];
        imageV.userInteractionEnabled = YES;
        cell.tag = 200;
        [cell.contentView addSubview:imageV];
    }
    if ((indexPath.row % 4) == 1) {
        currentModel1 = indexPath.row;
        if (currentModel1 == lastModel1) {
            //如果当前index与上次相同则显示
            dispatch_async(topQueue, ^{
                [handle1 hideGlassModel:YES];
            });
        }else if(isVisiable){
            dispatch_async(topQueue, ^{
                [handle1 hideGlassModel:NO];
            });
        }
        UIImageView *imageV = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT/2)];
        imageV.clipsToBounds = YES;
        [imageV addSubview:handle1];
        imageV.userInteractionEnabled = YES;
        cell.tag = 201;
        [cell.contentView addSubview:imageV];
    }
    if ((indexPath.row % 4) == 2) {
        currentModel2 = indexPath.row;
        UIImageView *imageV = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT/2)];
        imageV.clipsToBounds = YES;
        [imageV addSubview:handle2];
        imageV.userInteractionEnabled = YES;
        cell.tag = 202;
        [cell.contentView addSubview:imageV];
        if (currentModel2 == lastModel2) {
            dispatch_async(topQueue, ^{
                [handle2 hideGlassModel:YES];
            });
        }else if (isVisiable){
            dispatch_async(topQueue, ^{
                [handle2 hideGlassModel:NO];
            });
        }
    }
    //
    if ((indexPath.row % 4) == 3) {
        isVisiable = YES;
        currentModel3 = indexPath.row;
        UIImageView *imageV = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT/2)];
        imageV.clipsToBounds = YES;
        [imageV addSubview:handle3];
        imageV.userInteractionEnabled = YES;
        cell.tag = 202;
        [cell.contentView addSubview:imageV];
        
        if (currentModel3 == lastModel3) {
            dispatch_async(topQueue, ^{
                [handle3 hideGlassModel:YES];
            });
        }else if (isVisiable){
            dispatch_async(topQueue, ^{
                [handle3 hideGlassModel:NO];
            });
        }
    }
    cell.selectionStyle =UITableViewCellSelectionStyleNone;
    return cell;
}


#pragma mark scrollview delegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    isScroll = NO;
    if (!decelerate) {
        if (currentModel != lastModel) {
            dispatch_async(topQueue, ^{
                [handle loadGlassesModel:self.glassModels[currentModel]];
                [handle hideGlassModel:YES];
            });
            lastModel = currentModel;
            
        }
        if (currentModel1 != lastModel1) {
            dispatch_async(topQueue, ^{
                [handle1 loadGlassesModel:self.glassModels[currentModel1]];
                [handle1 hideGlassModel:YES];
            });
            lastModel1 = currentModel1;
        }
        if (currentModel2 != lastModel2) {
            dispatch_async(topQueue, ^{
                [handle2 loadGlassesModel:self.glassModels[currentModel2]];
                [handle2 hideGlassModel:YES];
            });
            lastModel2 = currentModel2;
        }
        //
        if (currentModel3 != lastModel3) {
            dispatch_async(topQueue, ^{
                [handle3 loadGlassesModel:self.glassModels[currentModel3]];
                [handle3 hideGlassModel:YES];
            });
            lastModel3 = currentModel3;
        }

    }
    
}


//
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    isScroll = NO;
    NSLog(@"2didENDdecelerating");
    if (currentModel != lastModel) {
        dispatch_async(topQueue, ^{
            [handle loadGlassesModel:self.glassModels[currentModel]];
            [handle hideGlassModel:YES];
        });
        lastModel = currentModel;
        
    }
    if (currentModel1 != lastModel1) {
        dispatch_async(topQueue, ^{
            [handle1 loadGlassesModel:self.glassModels[currentModel1]];
            [handle1 hideGlassModel:YES];
        });
        lastModel1 = currentModel1;
    }
    if (currentModel2 != lastModel2) {
        dispatch_async(topQueue, ^{
            [handle2 loadGlassesModel:self.glassModels[currentModel2]];
            [handle2 hideGlassModel:YES];
        });
        lastModel2 = currentModel2;
    }
    if (currentModel3 != lastModel3) {
        dispatch_async(topQueue, ^{
            [handle3 loadGlassesModel:self.glassModels[currentModel3]];
            [handle3 hideGlassModel:YES];
        });
        lastModel3 = currentModel3;
    }
    
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    isScroll = YES;
    NSLog(@"didScroll");
    
}
#pragma mark gestureRecognizer
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
//{
//    // 输出点击的view的类名
//    NSLog(@"%@", NSStringFromClass([touch.view class]));
//    // 若为UITableViewCellContentView（即点击了tableViewCell），则不截获Touch事件
//    if ([NSStringFromClass([touch.view class]) isEqualToString:@"GraphicsWindowIOSGLView"] || [NSStringFromClass([touch.view class]) isEqualToString:@"GLKView"]) {
//        return YES;
//    }
//    return  NO;
//}
#pragma mark gestureRecognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // 输出点击的view的类名
    NSLog(@"点击的view%@", NSStringFromClass([touch.view class]));
    
    // 若为UITableViewCellContentView（即点击了tableViewCell），则不截获Touch事件
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }
    return  YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer.view isKindOfClass:[UITableView class]]) {
        NSLog(@"L_who%@,other=%@", NSStringFromClass([gestureRecognizer.view class]),NSStringFromClass([otherGestureRecognizer.view class]));
        return YES;
    }
    return NO;
}


@end
