//
//  WXYZoomImageManager.m
//  WXYZoomImage
//
//  Created by 吴旭 on 12/07/2015.
//  Copyright (c) 2015 吴旭. All rights reserved.
//

#import "WXYZoomImageManager.h"
#import "WXYZoomImageScrollView.h"
#import <Reachability/Reachability.h>

@interface WXYZoomImageManager()<UIScrollViewDelegate, WXYZoomImageScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *showScrollView;
@property (nonatomic, assign) NSUInteger showIndex;
@property (nonatomic, copy) NSArray<UIView *> *views;
@property (nonatomic, copy) NSArray<WXYZoomImage *> *images;
@property (nonatomic, copy) NSMutableArray<WXYZoomImageScrollView *> *zoomScrollViews;
@property (nonatomic, copy) void(^willDismissBlock)(void);
@end

@implementation WXYZoomImageManager

#pragma mark - init

- (instancetype)init
{
    return [self initWithFrame:[UIScreen mainScreen].bounds];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.windowLevel = UIWindowLevelAlert;
        
        _views = [NSArray array];
        _images = [NSArray array];
        _zoomScrollViews = [NSMutableArray array];
        _showIndex = 0;
        _saveImage = YES;
        
        _showScrollView = [[UIScrollView alloc] initWithFrame:frame];
        _showScrollView.pagingEnabled = YES;
        _showScrollView.delegate = self;
        [self addSubview:self.showScrollView];
    }
    return self;
}

- (void)dealloc
{
    self.showScrollView.delegate = nil;
}

#pragma mark - public

- (void)setViews:(NSArray<UIView *> *)views images:(NSArray<WXYZoomImage *> *)images showIndex:(NSUInteger)showIndex
{
    if (showIndex < views.count) {
        _views = views;
        _images = images;
        _showIndex = showIndex;
        
        CGSize contentSize = self.showScrollView.contentSize;
        contentSize.width = CGRectGetWidth(self.frame) * views.count;
        self.showScrollView.contentSize = contentSize;
    }
}

- (void)starZoomInAnimation
{
    for (UIView *view in self.showScrollView.subviews) {
        [view removeFromSuperview];
    }
    
    [self.zoomScrollViews removeAllObjects];
    
    CGPoint contentOffset = self.showScrollView.contentOffset;
    contentOffset.x = self.showIndex * CGRectGetWidth(self.frame);
    self.showScrollView.contentOffset = contentOffset;
    
    for (int i = 0; i < self.views.count; i++) {
        UIView *view = self.views[i];
        WXYZoomImage *image = self.images[i];
        
        CGRect convertRect = [[view superview] convertRect:view.frame toView:view.window];
        
        WXYZoomImageScrollView *imgScrollView = [[WXYZoomImageScrollView alloc] initWithFrame:(CGRect){i*CGRectGetWidth(self.showScrollView.bounds), 0, self.showScrollView.bounds.size}];
        imgScrollView.index = i;
        imgScrollView.zDelegate = self;
        imgScrollView.saveImage = self.canSaveImage;
        [imgScrollView setStartFrame:convertRect image:image placeholderImage:[self placeholderImageWithIndex:i]];
        [self.showScrollView addSubview:imgScrollView];
        [self.zoomScrollViews addObject:imgScrollView];
        
        if (i == self.showIndex) {
            [imgScrollView showWithAnimation:YES loadImage:YES];
            
            [UIView animateWithDuration:0.2f animations:^{
                self.backgroundColor = [UIColor blackColor];
            } completion:^(BOOL finished) {
                
            }];
            continue;
        }
        
        if ([[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] != NotReachable) {
            if ((self.showIndex-1 > -1 && i == self.showIndex-1) ||
                (self.showIndex+1 < self.views.count && i == self.showIndex+1)) {
                [imgScrollView showWithAnimation:NO loadImage:YES];
            } else {
               [imgScrollView showWithAnimation:NO loadImage:NO];
            }
        } else {
            [imgScrollView showWithAnimation:NO loadImage:NO];
        }
    }
    
    [self makeKeyAndVisible];
}

- (void)setWillDismissBlock:(void(^)(void))block
{
    _willDismissBlock = [block copy];
}

- (UIView *)currentView
{
    if ([self currentIndex] < self.views.count) {
        return self.views[[self currentIndex]];
    } else {
        NSLog(@"index exceed view count");
        return nil;
    }
}

- (NSUInteger)currentIndex
{
    if (self.showScrollView.contentOffset.x < 0) {
        return 0;
    }
    
    if (self.showScrollView.contentOffset.x > CGRectGetWidth(self.frame) * (self.views.count-1)) {
        return self.views.count - 1;
    }
    
    return self.showScrollView.contentOffset.x / CGRectGetWidth(self.showScrollView.bounds);
}

#pragma mark - placeholder Image

- (UIImage *)placeholderImageWithIndex:(NSUInteger)index
{
    UIView *view = self.views[index];
    
    if ([view isKindOfClass:[UIImageView class]]) {
        UIImageView *v = (UIImageView *)view;
        return v.image ? :self.placeholderImage;
    }
    
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *v = (UIButton *)view;
        return v.imageView.image ? :self.placeholderImage;
    }
    
    return self.placeholderImage;
}

#pragma mark - WXYZoomImageScrollViewDelegate

- (void)tapImageViewTappedWithObject:(id)sender
{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2f animations:^{
        weakSelf.backgroundColor = [UIColor clearColor];
    }];
    
    if (self.willDismissBlock) {
        self.willDismissBlock();
    }
    
    WXYZoomImageScrollView *tmpImgView = sender;
    
    [UIView animateWithDuration:0.3f animations:^{
        [tmpImgView rechangeInitRdct];
    } completion:^(BOOL finished) {
        weakSelf.hidden = YES;
    }];
}

- (void)saveImageSuccess:(NSUInteger)index
{
    if ([self.mDelegate respondsToSelector:@selector(saveImageSuccess:)]) {
        [self.mDelegate saveImageSuccess:index];
    }
}

- (void)saveImageFailedWithError:(NSError *)error
{
    if ([self.mDelegate respondsToSelector:@selector(saveImageFailedWithError:)]) {
        [self.mDelegate saveImageFailedWithError:error];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    CGPoint nowPoint = self.showScrollView.contentOffset;
    NSUInteger cIndex = [self currentIndex];
    NSUInteger tvCount = self.views.count;
    
    if (nowPoint.x < 0 && cIndex == 0) {
        if ([self.mDelegate respondsToSelector:@selector(scrollToBorder:)]) {
            [self.mDelegate scrollToBorder:WXYZoomImageLeft];
        }
    } else if (nowPoint.x > CGRectGetWidth(self.frame) * (tvCount-1) && cIndex == tvCount-1) {
        if ([self.mDelegate respondsToSelector:@selector(scrollToBorder:)]) {
            [self.mDelegate scrollToBorder:WXYZoomImageRight];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] != NotReachable) {
        if ([self currentIndex]-1 > -1) {
            WXYZoomImageScrollView *imgScrollView = [self.zoomScrollViews objectAtIndex:[self currentIndex]-1];
            if (!imgScrollView.loadImageSuccess) {
                [imgScrollView loadImageAndModifySize];
            }
        }
        
        if ([self currentIndex]+1 < self.views.count) {
            WXYZoomImageScrollView *imgScrollView = [self.zoomScrollViews objectAtIndex:[self currentIndex]+1];
            if (!imgScrollView.loadImageSuccess) {
                [imgScrollView loadImageAndModifySize];
            }
        }
    } else {
        WXYZoomImageScrollView *imgScrollView = [self.zoomScrollViews objectAtIndex:[self currentIndex]];
        if (!imgScrollView.loadImageSuccess) {
            [imgScrollView loadImageAndModifySize];
        }
    }
    
    if ([self.mDelegate respondsToSelector:@selector(didScrollToView:index:)]) {
        [self.mDelegate didScrollToView:[self currentView] index:[self currentIndex]];
    }
}

@end
