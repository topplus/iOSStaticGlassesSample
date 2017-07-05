//
//  customViewController.h
//  testCamera
//
//  Created by Jeavil on 16/8/25.
//  Copyright © 2016年 L. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^videoBlock)(NSString *,NSString *);

@interface customViewController : UIViewController

@property (nonatomic, strong)NSString *videoPath;

@property (nonatomic, copy)videoBlock testBlock;

@end
