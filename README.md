# IOSStaticGlassesSample使用说明

[官网](http://www.topplusvision.com)

## 开发环境说明 ##

### 开发环境说明###
Xcode7.0及以上版本


### 支持平台说明 ###
支持iOS7.0及以上版本

## 接入流程 ##
### 依赖库导入 ###

* [基础库](https://github.com/topplus/iOSStaticGlassesSample/tree/master/libs/opencv2.framework)，需添加到iOS项目中。
* [眼镜库](https://github.com/topplus/iOSStaticGlassesSample/tree/master/libs/TGOSGFramework.framework)，需添加到iOS项目中。

### 授权认证 ###

调用TopFaceSDKHandle的setLicense：（NSString *）Client_id和Secret：（NSString *）Clicent_secret; 说明：申请client_id和client_secret后调用此函数获得授权。不调用认证函数无法使用人脸检测功能，正确调用认证函数即可正常使用。


## 接口定义和使用说明 ##

[文档](https://github.com/topplus/iOSStaticGlassesSample/tree/master/doc)

## 联系我们 ##

商务合作sales@topplusvision.com

媒体合作pr@topplusvision.com

技术支持support@topplusvision.com
