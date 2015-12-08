//
//  WXYZoomImage.h
//  Pods
//
//  Created by Lome on 15/12/7.
//
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

@interface WXYZoomImage : NSObject
@property (nonatomic, copy) NSString *imageURL; //图链接
@property (nonatomic, assign) CGSize imageSize; //图尺寸
@end
