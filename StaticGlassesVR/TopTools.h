//
//  TopTools.h
//  TGOSGTest
//
//  Created by Jeavil on 16/1/4.
//  Copyright © 2016年 topplusvision. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class SDKHandle;
@interface TopTools : NSObject
+ (SDKHandle *)handle;
+(UIImage*)getSubImage:(UIImage *)image mCGRect:(CGRect)mCGRect centerBool:(BOOL)centerBool;
/**获取uuid*/
+ (NSString *)uuidString;
+ (UIColor*) colorWithHex:(NSInteger)hexValue alpha:(CGFloat)alphaValue;
/**镜像*/
+ (UIImage*)rotateImageUpMirrored:(UIImage*)img;
@end
