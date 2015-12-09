//
//  WXYZoomImageScrollView.h
//  WXYZoomImage
//
//  Created by 吴旭 on 12/07/2015.
//  Copyright (c) 2015 吴旭. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WXYZoomImage;

@protocol WXYZoomImageScrollViewDelegate <NSObject>

- (void)tapImageViewTappedWithObject:(id)sender;

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

@interface WXYZoomImageScrollView : UIScrollView
@property (nonatomic, weak) id<WXYZoomImageScrollViewDelegate> zDelegate;
@property (nonatomic, assign) NSUInteger index;                     //Default is 0
@property (nonatomic, assign, getter=canSaveImage) BOOL saveImage;  //Default is Yes

- (void)setStartFrame:(CGRect)rect image:(WXYZoomImage *)image placeholderImage:(UIImage *)placeholderImage;
- (void)showWithAnimation:(BOOL)show;

- (void)rechangeInitRdct;

@end
