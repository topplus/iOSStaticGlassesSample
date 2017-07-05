# AndroidStaticGlassesSample使用说明

[官网](http://www.topplusvision.com)

## 开发环境说明 ##

### 开发环境说明###
Xcode7.0及以上版本


### 支持平台说明 ###
支持iOS7.0及以上版本

## 接入流程 ##
### 依赖库导入 ###

* 基础库:https://github.com/topplus/iOSStaticGlassesSample/tree/master/libs/opencv2.framework，需添加到iOS项目中。
* 眼镜库: https://github.com/topplus/iOSStaticGlassesSample/tree/master/libs/TGOSGFramework.framework，需添加到iOS项目中。

### 授权认证 ###

调用topplus.com.commonutils.Library.init(getApplicationContext(), " client_id", " client_secret",false);
说明：申请 client_id 和 client_secret 后调用此函数获得授权。可通过商务合作邮箱sales@topplusvision.com获得client_id 和 client_secret


## 接口定义和使用说明 ##

[文档](https://github.com/topplus/iOSStaticGlassesSample/tree/master/doc)

## 联系我们 ##

商务合作sales@topplusvision.com

媒体合作pr@topplusvision.com

技术支持support@topplusvision.com
