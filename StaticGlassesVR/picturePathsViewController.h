//
//  picturePathsViewController.h
//  TGOSGTest
//
//  Created by Jeavil on 16/1/7.
//  Copyright © 2016年 topplusvision. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^TopBlock)(NSString *,NSString *);
typedef void(^demoBlock)(NSString *);
@interface picturePathsViewController : UIViewController
/** 添加序列图路径 */
@property (nonatomic, strong)NSString *vidoPath;
@property (nonatomic, strong)NSString *picPath;
@property (nonatomic, copy)TopBlock block;
@property (nonatomic, copy)demoBlock deblock;
@property (nonatomic, assign)BOOL disposeDemoVideo;
@end
