//
//  SDKHandle.h
//  TGOSGTest
//
//  Copyright © 2015年 topplusvision. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>


@interface SDKHandle : GLKView

@property (nonatomic, assign, readwrite)CGRect screenFrame;

/**使用录制好的视频,picturePath（序列图路径）进入函数后会在尾部添加“/”*/
- (void) useVideoWithVideoPath:(NSString *)path andPicturePath:(NSString *)picturePath;

/**根据序列图路径加载图片order 值为YES时升序,order值为NO时降序*/
- (void) loadPictureWithOrder:(BOOL)order andPicturePath:(NSString *)picturePath;

/**引擎初始化*/
- (BOOL) Engine_Init;

/**设置等效焦距*/
- (void) SetFocuswithFocus: (float)fFocusLen;

/**设置鼻托在鼻梁上的位置，参数范围是0-1，设置为0鼻托在最顶部，设置为1鼻托在最底部，推荐初始值设置为0.2*/
- (void)SetNosePadPos:(float) glassHeight;

/**设置眼镜的俯仰角度，参数范围是0-1，设置为0为向下转15度，设置为1是向上转15度*/
- (void) SetGlassVerticalAngle:(float) verticalAngle;

/**设置镜腿虚化的程度，参数范围是0-1，设置为0是显示部分镜腿，设置为1是显示全部镜腿*/
- (void) SetFeatherDistance:(float) featherDistance;

/**从本地加载眼镜模型*/
-(void)loadGlassesModel: (NSString*)filePath;

/**从网络加载眼镜模型*/
- (void)loadGlassesModelWithFlag:(NSString *)modelFlag;

/** 加载其他序列图需要调用的方法 */
- (void)changePicturesIfNeed;

/**返回正中图片在序列图路径下的文件名称*/
- (NSString *)middlePath;

- (NSInteger)middleIndex;
/**调整眼镜大小，参数范围是0-1，设置为0时最小，设置为1时最大，推荐初始值设置为0.5*/
- (void)setGlassModelScale:(float) glassModelScale;

/**获得美颜效果
 type:
 1   美白
 2   磨皮
 value:
 0 ~ 1
 */
- (void)enhancePics:(int)type andValue:(float)value;

/**隐藏正在显示的眼镜模型*/
- (void)hideGlassModel:(BOOL)isVisible;

/**获取脸型分类
 -1     没有人脸存在
 0     圆脸
 1     椭圆脸
 2     方脸
 3     梨形脸
 4     瓜子脸
 */
- (int)getFaceShape;

/**保存眼镜姿态数据：文件路径 序列图路径／MAA.prop*/
- (void)saveAdjustedAttitude;

/**是否镜像序列图*/
- (void)setImageMirroredStatus:(BOOL)Mirrored;

/**设置用户id和secret*/
- (void)setLicense:(NSString *)Client_id andSecret:(NSString *)Clicent_secret;

/**
 *  @brief 保存日志，参数为空默认保存至 NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject/topglasses.log
 * 
 *  filePath： 保存日志的路径
 */
- (void)saveLogToFile:(NSString *)filePath;

/**设置所有眼镜为统一大小*/
- (void)SetNormalizedScale:(BOOL)isNormal;

/**返回当前的渲染图片*/
- (UIImage *)snapshotImage;
@end
