//
//  multipleViewController.h
//  three_topplusvisionDemo
//
//  Created by Jeavil on 16/1/27.
//  Copyright © 2016年 topplusvision. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface multipleViewController : UIViewController
@property (nonatomic,strong)NSString *picPath;
@property (nonatomic, strong)NSArray *glassModels;
@property (nonatomic, assign)NSInteger index;
@property (nonatomic, strong)NSDictionary *picValues;
@end
