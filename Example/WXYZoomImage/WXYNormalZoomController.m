//
//  WXYNormalZoomController.m
//  WXYZoomImage
//
//  Created by Lome on 15/12/8.
//  Copyright © 2015年 吴旭. All rights reserved.
//

#import "WXYNormalZoomController.h"
#import "WXYZoomImageManager.h"
#import "WXYZoomImage.h"

@interface WXYNormalZoomController ()<WXYZoomImageManagerDelegate>
@property (nonatomic, strong) WXYZoomImageManager *manager;
@property (nonatomic, strong) NSMutableArray<UIView *> *views;
@property (nonatomic, strong) NSMutableArray<WXYZoomImage *> *images;
@end

@implementation WXYNormalZoomController

#pragma mark - life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIImageView *imageView;
    _views = [NSMutableArray array];
    _images = [NSMutableArray array];
    
    for (int i = 0; i < 3; i++) {
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(100, 100+120*i, 100, 100)];
        imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", i]];
        imageView.contentMode = UIViewContentModeScaleToFill;
        imageView.clipsToBounds = YES;
        imageView.userInteractionEnabled = YES;
        [self.view addSubview:imageView];
        
        UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [imageView addGestureRecognizer:singleTapGesture];
        
        [self.views addObject:imageView];
        
        WXYZoomImage *image = [[WXYZoomImage alloc] init];
        image.imageURL = @[@"http://h.hiphotos.baidu.com/baike/c0%3Dbaike150%2C5%2C5%2C150%2C50/sign=1fc42a91be3eb13550cabfe9c777c3b6/a5c27d1ed21b0ef4841b9e27dfc451da80cb3ed3.jpg",
                           @"http://img5.duitang.com/uploads/item/201301/22/20130122185342_zG2GV.jpeg",
                           @"http://img4.duitang.com/uploads/item/201309/13/20130913202122_NaL8B.jpeg"][i];
        [self.images addObject:image];
    }
    
    _manager = [[WXYZoomImageManager alloc] initWithFrame:self.view.bounds];
    _manager.mDelegate = self;
}

#pragma mark - UIGestureRecognizer

- (void)singleTap:(UIGestureRecognizer *)gesture
{
    CGPoint currentPoint = [gesture locationInView:self.view];
    for (int i = 0; i < 3; i++) {
        if (CGRectContainsPoint(CGRectMake(100, 100+120*i, 100, 100), currentPoint) ) {
            [self.manager setViews:[NSArray arrayWithArray:self.views] images:[NSArray arrayWithArray:self.images] showIndex:i];
            [self.manager starZoomInAnimation];
            
            [self.manager setWillDismissBlock:^{
                //Dismiss
            }];
        }
    }
}

#pragma mark - WXYZoomImageManagerDelegate

- (void)didScrollToView:(UIView *)view index:(NSUInteger)index
{
    NSLog(@"%@", @(index));
}

- (void)scrollToBorder:(WXYZoomImageDirection)direction
{
    NSLog(@"%@", @(direction));
}

- (void)saveImageSuccess:(NSUInteger)index
{
    
}

- (void)saveImageFailedWithError:(NSError *)error
{
    
}

@end
