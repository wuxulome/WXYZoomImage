//
//  WXYZoomImage.h
//  Pods
//
//  Created by Lome on 15/12/7.
//
//

#import <Foundation/Foundation.h>

@interface WXYZoomImage : NSObject
@property (nonatomic, copy) NSString *imageURL; //图片链接
@property (nonatomic, strong) UIImage *image;   //当需要直接打开图片时使用此字段
@end
