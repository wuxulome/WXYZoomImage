//
//  WXYZoomImageScrollView.m
//  WXYZoomImage
//
//  Created by 吴旭 on 12/07/2015.
//  Copyright (c) 2015 吴旭. All rights reserved.
//

#import "WXYZoomImageScrollView.h"
#import "WXYZoomImage.h"
#import "UIImageView+WebCache.h"

static NSString * const title = @"保存失败";
static NSString * const message = @"建议开启图片访问权限（设置>隐私>照片）";

@interface WXYZoomImageScrollView()<UIScrollViewDelegate, UIActionSheetDelegate>
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UIActivityIndicatorView *progressView;

@property (nonatomic, assign) CGRect startRect;//缩放前大小
@property (nonatomic, strong) WXYZoomImage *zoomImage;
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
        
        _imgView = [[UIImageView alloc] init];
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

- (void)showWithAnimation:(BOOL)show
{
    NSString *cacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:[NSURL URLWithString:self.zoomImage.imageURL]];
    UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:cacheKey];
    if (image) {
        //判断首先缩放的值
        CGFloat scaleX = CGRectGetWidth(self.frame)/image.size.width;
        CGFloat scaleY = CGRectGetHeight(self.frame)/ image.size.height;
        CGRect rect;
        
        //倍数小的，先到边缘
        if (scaleX > scaleY) {
            //Y方向先到边缘
            CGFloat imgViewWidth = image.size.width * scaleY;
            rect = CGRectMake(CGRectGetWidth(self.frame)/2-imgViewWidth/2, 0, imgViewWidth, CGRectGetHeight(self.frame));
        } else {
            //X先到边缘
            CGFloat imgViewHeight = image.size.height * scaleX;
            rect = CGRectMake(0, CGRectGetHeight(self.frame)/2-imgViewHeight/2, CGRectGetWidth(self.frame), imgViewHeight);
        }
        
        self.imgView.image = image;
        if (show) {
            [UIView animateWithDuration:0.3f animations:^{
                self.imgView.frame = rect;
            }];
        } else {
            self.imgView.frame = rect;
        }
    } else {
        //判断首先缩放的值
        CGFloat scaleX = CGRectGetWidth(self.frame)/CGRectGetWidth(self.imgView.frame);
        CGFloat scaleY = CGRectGetHeight(self.frame)/ CGRectGetHeight(self.imgView.frame);
        CGRect rect;
        
        //倍数小的，先到边缘
        if (scaleX > scaleY) {
            //Y方向先到边缘
            CGFloat imgViewWidth = CGRectGetWidth(self.imgView.frame)*scaleY;
            rect = CGRectMake(CGRectGetWidth(self.frame)/2-imgViewWidth/2, 0, imgViewWidth, CGRectGetHeight(self.frame));
        } else {
            //X先到边缘
            CGFloat imgViewHeight = CGRectGetHeight(self.imgView.frame)*scaleX;
            rect = CGRectMake(0, CGRectGetHeight(self.frame)/2-imgViewHeight/2, CGRectGetWidth(self.frame), imgViewHeight);
        }
        
        if (show) {
            [UIView animateWithDuration:0.3f animations:^{
                self.imgView.frame = rect;
            } completion:^(BOOL finished) {
                [self getImageAndModifySize];
            }];
        } else {
            self.imgView.frame = rect;
            [self getImageAndModifySize];
        }
    }
}

- (void)rechangeInitRdct
{
    self.zoomScale = 1.0;
    self.imgView.frame = self.startRect;
}

#pragma mark - get image

- (void)getImageAndModifySize
{
    if(self.zoomImage) {
        //设置图片
        __weak typeof(self) weakSelf = self;
        [self.imgView sd_setImageWithURL:[NSURL URLWithString:self.zoomImage.imageURL]
                        placeholderImage:self.imgView.image
                                 options:0
                                progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                    weakSelf.progressView.hidden = NO;
                                    [weakSelf.progressView startAnimating];
                                }
                               completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                   __strong typeof(weakSelf) strongSelf = weakSelf;
                                   
                                   [strongSelf.progressView stopAnimating];
                                   if (!error && image) {
                                       //判断首先缩放的值
                                       CGFloat scaleX = CGRectGetWidth(strongSelf.frame)/image.size.width;
                                       CGFloat scaleY = CGRectGetHeight(strongSelf.frame)/image.size.height;
                                       
                                       //倍数小的，先到边缘
                                       if (scaleX > scaleY) {
                                           //Y方向先到边缘
                                           CGFloat imgViewWidth = image.size.width*scaleY;
                                           strongSelf.imgView.frame = (CGRect){CGRectGetWidth(strongSelf.frame)/2-imgViewWidth/2,0,imgViewWidth,CGRectGetHeight(strongSelf.frame)};
                                       } else {
                                           //X先到边缘
                                           CGFloat imgViewHeight = image.size.height*scaleX;
                                           strongSelf.imgView.frame = (CGRect){0,CGRectGetHeight(strongSelf.frame)/2-imgViewHeight/2,CGRectGetWidth(strongSelf.frame),imgViewHeight};
                                       }
                                       strongSelf.imgView.image = image;
                                   } else {
                                       
                                   }
                               }];
    }
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
            if (error.code == -3310) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
                [alert show];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"保存失败" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
                [alert show];
            }
        }
    }
}

@end
