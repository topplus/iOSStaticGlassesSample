//
//  staicGlassesController.m
//  three_topplusvisionDemo
//
//  Created by Jeavil on 16/1/18.
//  Copyright © 2016年 topplusvision. All rights reserved.
//

#import "ViewController.h"
#import <TGOSGFramework/TGOSGFramework.h>
#import "SVProgressHUD/SVProgressHUD.h"
#import "picturePathsViewController.h"
#import "customViewController.h"
#import "multipleViewController.h"
#define WIDTH  [UIScreen mainScreen].bounds.size.width
#define HEIGHT  [UIScreen mainScreen].bounds.size.height
#define MEDIA_TYPE_MOIVE  [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary].lastObject
#define DOCUMENT_PATH   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject
#define FILE_PATH @"/Users/jeavil/Desktop/pics"
#define Heard_HEIGHT self.navigationController.navigationBar.bounds.size.height
#define SEQMAP_PATH [NSString stringWithFormat:@"%@%@res",DOCUMENT_PATH,@"/"]
@interface ViewController ()<UIPickerViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITableViewDataSource,UITableViewDelegate>{
    
    NSString *videoPath;
    NSString *picPath;//全局序列图路径
    
    picturePathsViewController *picsViewController;
    UITableView *TopTable;
    
    
}
@property (nonatomic, strong) UIButton *moreBtn;
@property (nonatomic, strong)NSMutableArray *picPaths;
@property (nonatomic, strong)NSMutableArray *middleIndexs;
@end
@implementation ViewController
static int pathFlag = 12;
- (NSMutableArray *)picPaths{
    
    if (!_picPaths) {
        _picPaths = [NSMutableArray array];
        NSUserDefaults *ndb = [NSUserDefaults standardUserDefaults];
        _picPaths = [NSMutableArray array];
        NSArray *array = [ndb arrayForKey:@"picPaths"];
        [_picPaths addObjectsFromArray:array];
        
    }
    
    return  _picPaths;
}
- (NSMutableArray *)middleIndexs{
    
    if (!_middleIndexs) {
        _middleIndexs = [NSMutableArray array];
        NSUserDefaults *ndb = [NSUserDefaults standardUserDefaults];
        _middleIndexs = [NSMutableArray array];
        NSArray *array = [ndb arrayForKey:@"middleIndexs"];
        [_middleIndexs addObjectsFromArray:array];
    }
    return _middleIndexs;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                
                                [UIColor blackColor],
                                
                                NSForegroundColorAttributeName, nil];
    
    [self.navigationController.navigationBar setTitleTextAttributes:attributes];
    
    self.navigationController.navigationBar.tintColor = [UIColor blackColor]; //定义导航栏颜色
   
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    picPath = [NSString stringWithFormat:@"%@%d%@",SEQMAP_PATH,pathFlag,@"/"];
    [self creatTable];
    [self creatBtn];
}

//初始化tableview
- (void)creatTable{
    [self tableViewLoadData];
    if (TopTable == nil) {
        TopTable = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT - 100 - Heard_HEIGHT) style:UITableViewStylePlain];
        TopTable.dataSource = self;
        TopTable.delegate = self;
        TopTable.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self.view addSubview:TopTable];
    }
}

- (void)tableViewLoadData{
    
    NSString *firstPath = [[NSBundle mainBundle]pathForResource:@"modelgirl" ofType:@"bundle"];
    [self.picPaths insertObject:firstPath atIndex:0];
    
    NSString *firstMiddle = @"7";
    [self.middleIndexs insertObject:firstMiddle atIndex:0];
    [TopTable reloadData];
    
    NSUserDefaults *udb = [NSUserDefaults standardUserDefaults];
    [udb setObject:firstPath forKey:@"modelgirl"];
}

- (void)creatBtn{
    
    //录制
    UIButton *recodBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [recodBtn setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    [recodBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    recodBtn.frame = CGRectMake(WIDTH / 5 * 2, HEIGHT - WIDTH / 5, WIDTH / 5, WIDTH / 5);
    [recodBtn addTarget:self action:@selector(startRecod:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:recodBtn];
    
    //show multiple
    //    UIButton *multiple = [UIButton buttonWithType:UIButtonTypeCustom];
    //    [multiple setTitle:@"组合图" forState:UIControlStateNormal];
    //    [multiple setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    //    multiple.frame = CGRectMake(0, Heard_HEIGHT / 8, Heard_HEIGHT * 2, Heard_HEIGHT / 4 * 3);
    //    [multiple addTarget:self action:@selector(showMultiple:) forControlEvents:UIControlEventTouchUpInside];
    //    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:multiple];
    //
    
}
//开始录制
- (void)startRecod:(UIButton *)sender{

    //录制的时候可以保存;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        NSString *movieName = [NSString stringWithFormat:@"%@.mov",[self uuidString]];
        
        NSString *moviePath = [NSTemporaryDirectory() stringByAppendingString:movieName];
        customViewController *customVC  = [[customViewController alloc]init];
        customVC.videoPath =moviePath;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:customVC animated:YES completion:^{
                //
            }];
        });
        
        customVC.testBlock = ^(NSString *video_Path, NSString *pic_Path){
    
            NSString *saveToDocument_picPath = [pic_Path stringByReplacingOccurrencesOfString:DOCUMENT_PATH withString:@""];
            picturePathsViewController *pc = [[picturePathsViewController alloc]init];
            
            #if USE_MODELVIDEO == 1
                        NSString *str = [[NSBundle mainBundle]pathForResource:@"model" ofType:@"MOV"];
                        video_Path = str;
            #endif
            
            pc.vidoPath = video_Path;
            pc.picPath = pic_Path;
            
            pc.block = ^(NSString *video_pt,NSString *pic_pt){
                NSUserDefaults *ndb = [NSUserDefaults standardUserDefaults];
                NSString *saveToDocument_Path = [pic_pt stringByReplacingOccurrencesOfString:DOCUMENT_PATH withString:@""];
                [self.picPaths addObject:saveToDocument_Path];
                NSMutableArray *arr = [NSMutableArray arrayWithArray:self.picPaths];
                [arr removeObjectAtIndex:0];
                [ndb setObject:arr forKey:@"picPaths"];
                pathFlag++;
                
                [TopTable reloadData];
            };

            NSLog(@"总：%lu",(unsigned long)self.picPaths.count);
            [self.navigationController pushViewController:pc animated:YES];
           
        };
    }
    else
    {
        NSLog(@"Not Support");
    }
    
}

//不保存点击后切换回table

//保存不切换回table


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)video:(NSString *)videoFileName didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
//    if (error) {
//        NSLog(@"保存视频过程中发生错误，错误信息:%@",error.localizedDescription);
//    }else{
//        NSLog(@"视频保存成功.");
//        videoPath = videoFileName;
//        //ocean------
//        if(videoPath)
//        {
//#if USE_MODELVIDEO == 1
//            NSString *str = [[NSBundle mainBundle]pathForResource:@"model" ofType:@"MOV"];
//            videoPath = str;
//#endif
//            
//            //[SVProgressHUD showWithStatus:@"加载中，请稍后。。。"];
//            picturePathsViewController *pc = [[picturePathsViewController alloc]init];
//            pc.vidoPath = videoPath;
//            pc.picPath = picPath;
//            [self.navigationController pushViewController:pc animated:YES];
//        }
//    }
//}


#pragma mark 　TopTable的回调
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return YES;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > 0) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            NSFileManager *manager = [NSFileManager defaultManager];
            NSError *error = nil;
            [manager removeItemAtPath:self.picPaths[indexPath.row] error:&error];
            [self.picPaths removeObjectAtIndex:indexPath.row];

            NSUserDefaults *ndb = [NSUserDefaults standardUserDefaults];
            //上传的数组中需要删除演示序列图
            NSMutableArray *tempPicPaths = [[NSMutableArray alloc]init];
            [tempPicPaths addObjectsFromArray:self.picPaths];
            [tempPicPaths removeObjectAtIndex:0];
            
            [ndb setObject:tempPicPaths forKey:@"picPaths"];
            NSArray *indexPaths = @[indexPath]; // 构建 索引处的行数 的数组
            // 删除 索引的方法 后面是动画样式
            [TopTable deleteRowsAtIndexPaths:indexPaths withRowAnimation:(UITableViewRowAnimationLeft)];
            
        }
        else if (editingStyle == UITableViewCellEditingStyleInsert) {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 150;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.picPaths.count > 0) return self.picPaths.count;
    return 0;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CELL"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CELL"];
    }else{
        
        NSArray *subviews = [[NSArray alloc] initWithArray:cell.contentView.subviews];
        for (UIView *subview in subviews) {
            [subview removeFromSuperview];
        }
    }
    
    if (self.picPaths.count > 0) {
        NSString *path= nil;
        if (indexPath.row == 0) {
            path = [NSString stringWithFormat:@"%@/7.jpg",self.picPaths[indexPath.row]];
        }else{
            path = [NSString stringWithFormat:@"%@/%@/%@",DOCUMENT_PATH,self.picPaths[indexPath.row],@"front.jpg"];
        }
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        NSLog(@"image=%@\nimage_path=%@",image,path);
        if (image) {
            UIImageView *imagView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, WIDTH, 150)];
            imagView.contentMode = UIViewContentModeScaleAspectFill;
            imagView.clipsToBounds = YES;
            imagView.image = image;
            [cell.contentView addSubview:imagView];
        }
        
    }
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
   
    picturePathsViewController *pc = [[picturePathsViewController alloc]init];
    pc.vidoPath = nil;
    if (indexPath.row == 0) {
       pc.picPath = self.picPaths[indexPath.row];
    }else{
    pc.picPath = [NSString stringWithFormat:@"%@/%@",DOCUMENT_PATH,self.picPaths[indexPath.row]];
    }
    NSLog(@"路径%@",pc.picPath);
    [self.navigationController pushViewController:pc animated:YES];
    
}
- (void)viewWillAppear:(BOOL)animated{

     [TopTable reloadData];
}

- (NSString *)uuidString
{
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
    CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
    NSString *uuid = [NSString stringWithString:(__bridge NSString *)uuid_string_ref];
    CFRelease(uuid_ref);
    CFRelease(uuid_string_ref);
    return [uuid lowercaseString];
}
@end
