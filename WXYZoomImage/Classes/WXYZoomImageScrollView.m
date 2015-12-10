//
//  WXYZoomImageScrollView.m
//  WXYZoomImage
//
//  Created by 吴旭 on 12/07/2015.
//  Copyright (c) 2015 吴旭. All rights reserved.
//

#import "WXYZoomImageScrollView.h"
#import "WXYZoomImage.h"
#import <YYWebImage/YYWebImage.h>

@interface WXYZoomImageScrollView()<UIScrollViewDelegate, UIActionSheetDelegate>
@property (nonatomic, strong) YYAnimatedImageView *imgView;
@property (nonatomic, strong) UIActivityIndicatorView *progressView;
@property (nonatomic, assign) CGRect startRect;//缩放前大小
@property (nonatomic, strong) WXYZoomImage *zoomImage;
@property (nonatomic, assign) BOOL loadImageSuccess;
@end

@implementation WXYZoomImageScrollView

#pragma mark - init

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.backgroundColor = [UIColor clearColor];
        self.delegate = self;
        self.minimumZoomScale = 1.0f;
        self.maximumZoomScale = 2.0f;
        
        _index = 0;
        _saveImage = YES;
        _zoomImage = [[WXYZoomImage alloc] init];
        _loadImageSuccess = NO;
        
        _imgView = [[YYAnimatedImageView alloc] init];
        _imgView.clipsToBounds = YES;
        _imgView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.imgView];
        
        self.progressView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.progressView.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
        self.progressView.hidesWhenStopped = YES;
        self.progressView.hidden = YES;
        [self addSubview:self.progressView];
        
        //添加长按事件
        UILongPressGestureRecognizer *longPressGr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressToDo:)];
        longPressGr.minimumPressDuration = 1.0;
        [self addGestureRecognizer:longPressGr];
        
        // 单击事件
        UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [self addGestureRecognizer:singleTapGesture];
        
        // 双击事件
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTapGesture.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTapGesture];
        
        [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
    }
    return self;
}

- (void)dealloc
{
    self.zDelegate = nil;
    self.delegate = nil;
}

#pragma mark - public

- (void)setStartFrame:(CGRect)rect image:(WXYZoomImage *)image placeholderImage:(UIImage *)placeholderImage
{
    self.imgView.frame = rect;
    self.imgView.image = placeholderImage;
    self.startRect = rect;
    self.zoomImage = image;
}

- (void)showWithAnimation:(BOOL)show loadImage:(BOOL)load
{
    if (self.zoomImage.image) {
        self.loadImageSuccess = YES;
        CGRect rect = [self zoomSize:self.zoomImage.image.size];
        self.imgView.image = self.zoomImage.image;
        if (show) {
            [UIView animateWithDuration:0.3f animations:^{
                self.imgView.frame = rect;
            }];
        } else {
            self.imgView.frame = rect;
        }
    } else if ([[YYImageCache sharedCache] containsImageForKey:self.zoomImage.imageURL]) {
        self.loadImageSuccess = YES;
        UIImage *image = [[YYImageCache sharedCache] getImageForKey:self.zoomImage.imageURL];
        CGRect rect = [self zoomSize:image.size];
        self.imgView.image = image;
        if (show) {
            [UIView animateWithDuration:0.3f animations:^{
                self.imgView.frame = rect;
            }];
        } else {
            self.imgView.frame = rect;
        }
    } else {
        CGRect rect = [self zoomSize:(CGSize){CGRectGetWidth(self.imgView.frame), CGRectGetHeight(self.imgView.frame)}];
        if (show) {
            [UIView animateWithDuration:0.3f animations:^{
                self.imgView.frame = rect;
            } completion:^(BOOL finished) {
                if (load) {
                    [self loadImageAndModifySize];
                }
            }];
        } else {
            self.imgView.frame = rect;
            if (load) {
                [self loadImageAndModifySize];
            }
        }
    }
}

- (void)rechangeInitRdct
{
    self.zoomScale = 1.0;
    self.imgView.frame = self.startRect;
}

#pragma mark - get image

- (void)loadImageAndModifySize
{
    if(self.zoomImage) {
        __weak typeof(self) weakSelf = self;
        [self.imgView yy_setImageWithURL:[NSURL URLWithString:self.zoomImage.imageURL]
                             placeholder:self.imgView.image
                                 options:YYWebImageOptionUseNSURLCache
                                progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                    __strong typeof(weakSelf) strongSelf = weakSelf;
                                    strongSelf.progressView.hidden = NO;
                                    [strongSelf.progressView startAnimating];
                                }
                               transform:nil
                              completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
                                  __strong typeof(weakSelf) strongSelf = weakSelf;
                                  [strongSelf.progressView stopAnimating];
                                  if (!error && image) {
                                      strongSelf.imgView.frame = [strongSelf zoomSize:image.size];
                                      strongSelf.imgView.image = image;
                                      strongSelf.loadImageSuccess = YES;
                                  } else {
                                      
                                  }
                              }];
    }
}

#pragma mark - zoom size

- (CGRect)zoomSize:(CGSize)size
{
    //判断首先缩放的值
    CGFloat scaleX = CGRectGetWidth(self.frame) / size.width;
    CGFloat scaleY = CGRectGetHeight(self.frame) / size.height;
    CGRect rect;
    
    //倍数小的，先到边缘
    if (scaleX > scaleY) {
        //Y方向先到边缘
        CGFloat width = size.width * scaleY;
        rect = CGRectMake(CGRectGetWidth(self.frame)/2 - width/2, 0, width, CGRectGetHeight(self.frame));
    } else {
        //X先到边缘
        CGFloat height = size.height * scaleX;
        rect = CGRectMake(0, CGRectGetHeight(self.frame)/2 - height/2, CGRectGetWidth(self.frame), height);
    }
    
    return rect;
}

#pragma mark - scroll delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imgView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    
    CGSize boundsSize = scrollView.bounds.size;
    CGRect imgFrame = self.imgView.frame;
    CGSize contentSize = scrollView.contentSize;
    
    CGPoint centerPoint = CGPointMake(contentSize.width/2, contentSize.height/2);
    
    // center horizontally
    if (imgFrame.size.width <= boundsSize.width) {
        centerPoint.x = boundsSize.width/2;
    }
    
    // center vertically
    if (imgFrame.size.height <= boundsSize.height) {
        centerPoint.y = boundsSize.height/2;
    }
    
    self.imgView.center = centerPoint;
}

#pragma mark - GestureRecognizer

- (void)singleTap:(UIGestureRecognizer *)gesture
{
    if ([self.zDelegate respondsToSelector:@selector(tapImageViewTappedWithObject:)]) {
        [self.zDelegate tapImageViewTappedWithObject:self];
    }
}

- (void)doubleTap:(UIGestureRecognizer *)gesture
{
    if (self.zoomScale < self.maximumZoomScale) {
        [self setZoomScale:self.maximumZoomScale  animated:YES];
    } else {
        [self setZoomScale:self.minimumZoomScale  animated:YES];
    }
}

#pragma mark - download image

- (void)longPressToDo:(UILongPressGestureRecognizer *)sender
{
    //UILongPressGestureRecognizer存在执行两次的问题，需要这样判断
    if(self.canSaveImage && sender.state == UIGestureRecognizerStateBegan) {
        UIActionSheet *choiceSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"取消"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"保存到相册", nil];
        [choiceSheet showInView:self];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        UIImageWriteToSavedPhotosAlbum(self.imgView.image,self,@selector(image:didFinishSavingWithError:contextInfo:),nil);
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (!error) {
        if ([self.zDelegate respondsToSelector:@selector(saveImageSuccess:)]) {
            [self.zDelegate saveImageSuccess:self.index];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"保存成功" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
            [alert show];
        }
    } else {
        if ([self.zDelegate respondsToSelector:@selector(saveImageFailedWithError:)]) {
            [self.zDelegate saveImageFailedWithError:error];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"保存失败" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
            [alert show];
        }
    }
}

@end
