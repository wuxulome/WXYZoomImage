//
//  WXYZoomImageManager.h
//  WXYZoomImage
//
//  Created by 吴旭 on 12/07/2015.
//  Copyright (c) 2015 吴旭. All rights reserved.
//

typedef NS_ENUM(NSUInteger, WXYZoomImageDirection) {
    WXYZoomImageNone,
    WXYZoomImageLeft,
    WXYZoomImageRight,
    WXYZoomImageUp,
    WXYZoomImageDown
};

#import <UIKit/UIKit.h>

@class WXYZoomImage;

@protocol WXYZoomImageManagerDelegate <NSObject>

/*!
 *  @brief  滑动到边界时触发此回调，目前只会返回左右
 *
 *  @param direction 边界方向
 */
- (void)scrollToBorder:(WXYZoomImageDirection)direction;

/*!
 *  @brief  已滑动到某一视图
 *
 *  @param view  已滑动到的视图
 *  @param index 已滑动到的视图索引
 */
- (void)didScrollToView:(UIView *)view index:(NSUInteger)index;

/*!
 *  @brief  图片保存成功的回调
 */
- (void)saveImageSuccess:(NSUInteger)index;

/*!
 *  @brief  图片保存失败的回调
 *
 *  @param error 错误原因
 */
- (void)saveImageFailedWithError:(NSError *)error;

@end

@interface WXYZoomImageManager : UIWindow
@property (nonatomic, weak) id<WXYZoomImageManagerDelegate> mDelegate;
@property (nonatomic, assign, getter=canSaveImage) BOOL saveImage;  //Default is Yes
@property (nonatomic, strong) UIImage *placeholderImage;  //Default is

/**
 *  初始化
 */
- (instancetype)initWithFrame:(CGRect)frame;

/*!
 *  @brief  设置图片和当前index
 *
 *  @param imageViews   含有UIView对象的数组
 *  @param images       含有WXYZoomImage对象的数组
 *  @param currentIndex 当前点击图片在数组中的位置
 */
- (void)setViews:(NSArray<UIView *> *)views images:(NSArray<WXYZoomImage *> *)images showIndex:(NSUInteger)showIndex;

/**
 *  启动放大动画
 *
 *  @param window 放大前主window
 */
- (void)starZoomInAnimation;

/**
 *  图片浏览窗口关闭时执行block
 */
- (void)setWillDismissBlock:(void(^)(void))block;

/*!
 *  @brief  获取当前所在view
 *
 *  @return view
 */
- (UIView *)currentView;

/*!
 *  @brief  获取当前所在索引
 *
 *  @return 索引值
 */
- (NSUInteger)currentIndex;

@end
