//
//  CodeScannerViewController.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 14-1-25.
//  Copyright (c) 2014 Linus Yang. All rights reserved.
//

#import "CodeScannerViewController.h"
#import <QuartzCore/QuartzCore.h>

#define kFocusBigSize 80.0f
#define kFocusSize 60.0f

@interface CameraFocusSquare : UIView

@property (nonatomic, retain) UIColor *animateColor;

@end

@implementation CameraFocusSquare

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIColor *borderColor = [UIColor orangeColor];
        [self setBackgroundColor:[UIColor clearColor]];
        [self.layer setBorderWidth:1.0];
        [self.layer setBorderColor:borderColor.CGColor];
        self.animateColor = [self lighterColorForColor:borderColor];
    }
    return self;
}

- (void)dealloc
{
    [_animateColor release];
    _animateColor = nil;
    [super dealloc];
}

- (UIColor *)lighterColorForColor:(UIColor *)color
{
    CGFloat r, g, b, a;
    if ([color getRed:&r green:&g blue:&b alpha:&a]) {
        return [UIColor colorWithRed:MIN(r + 0.3, 1.0)
                               green:MIN(g + 0.3, 1.0)
                                blue:MIN(b + 0.3, 1.0)
                               alpha:a];
    }
    return nil;
}

- (void)animate
{
    CABasicAnimation* selectionAnimation = [CABasicAnimation animationWithKeyPath:@"borderColor"];
    selectionAnimation.toValue = (id) self.animateColor.CGColor;
    selectionAnimation.repeatCount = 6;
    [self.layer addAnimation:selectionAnimation forKey:@"selectionAnimation"];
}

@end

@interface CodeScannerViewController ()

@property (nonatomic, retain) ZXCapture* capture;
@property (nonatomic, retain) UIView *cameraView;
@property (nonatomic, retain) CameraFocusSquare *focusSqure;

@end

@implementation CodeScannerViewController

#pragma mark - View Controller Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /* Portrait Orientation Workaround */
    if ([UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationPortrait) {
        UIViewController *viewController = [[UIViewController alloc] init];
        if (SYSTEM_VERSION_LESS_THAN(@"5.0")) {
            [self.navigationController presentModalViewController:viewController animated:NO];
            [self.navigationController dismissModalViewControllerAnimated:NO];
        } else {
            viewController.view.backgroundColor = [UIColor blackColor];
            [self.navigationController presentViewController:viewController animated:NO completion:^{
                [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
            }];
        }
        [viewController release];
    }
    
    _capture = [[ZXCapture alloc] init];
    self.capture.rotation = 90.0f;
    self.capture.camera = self.capture.back;
    self.capture.layer.frame = self.view.bounds;
    
    self.title = NSLocalizedString(@"Scan QR Code", nil);
    UIBarButtonItem *torchButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Torch", nil)
                                                                    style:UIBarButtonItemStyleBordered
                                                                   target:self
                                                                   action:@selector(toggleTorch)];
    self.navigationItem.rightBarButtonItem = torchButton;
    [torchButton release];
    
    _cameraView = [[UIView alloc] initWithFrame:self.view.bounds];
    _cameraView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin |
                                    UIViewAutoresizingFlexibleBottomMargin |
                                    UIViewAutoresizingFlexibleLeftMargin |
                                    UIViewAutoresizingFlexibleRightMargin |
                                    UIViewAutoresizingFlexibleWidth |
                                    UIViewAutoresizingFlexibleHeight);
    _cameraView.backgroundColor = [UIColor blackColor];
    [_cameraView.layer addSublayer:self.capture.layer];
    [self.view addSubview:_cameraView];
    
    _focusSqure = [[CameraFocusSquare alloc] initWithFrame:CGRectMake(0, 0, kFocusSize, kFocusSize)];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToFocus:)];
    [self.cameraView addGestureRecognizer:tapGesture];
    [tapGesture release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    self.capture.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.capture.torch == YES) {
        [self toggleTorch];
    }
    self.capture.delegate = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortrait);
}

#ifdef __IPHONE_6_0
- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
#endif

- (void)dealloc
{
    [_capture release];
    _capture = nil;
    [_cameraView release];
    _cameraView = nil;
    [_focusSqure release];
    _focusSqure = nil;
    [super dealloc];
}

#pragma mark - Private Methods

- (void)toggleTorch
{
    if (self.capture.hasTorch) {
        self.capture.torch = !self.capture.torch;
    }
}

- (void)tapToFocus:(UITapGestureRecognizer *)singleTap
{
    
    CGPoint touchPoint = [singleTap locationInView:self.cameraView];
    CGRect focusFrame = CGRectMake(touchPoint.x - kFocusSize / 2.0, touchPoint.y - kFocusSize / 2.0, kFocusSize, kFocusSize);
    
    self.focusSqure.frame = CGRectMake(0, 0, kFocusBigSize, kFocusBigSize);
    self.focusSqure.center = touchPoint;
    self.focusSqure.alpha = 0.0f;
    
    [self.view addSubview:self.focusSqure];
    [self.focusSqure animate];
    [self.focusSqure setNeedsDisplay];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.focusSqure.alpha = 1.0f;
        self.focusSqure.frame = focusFrame;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3
                              delay:0.9
                            options:UIViewAnimationCurveEaseInOut
                         animations:^{
                             self.focusSqure.alpha = 0.0f;
                         } completion:^(BOOL finished) {
                             [self.focusSqure removeFromSuperview];
                         }];
    }];
    
#if !TARGET_IPHONE_SIMULATOR
    CGPoint convertedPoint = [(AVCaptureVideoPreviewLayer *)self.capture.layer captureDevicePointOfInterestForPoint:touchPoint];
    AVCaptureDevice *currentDevice = self.capture.captureDevice;
    
    if ([currentDevice isFocusPointOfInterestSupported] && [currentDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]){
        NSError *error = nil;
        [currentDevice lockForConfiguration:&error];
        if (!error) {
            [currentDevice setFocusPointOfInterest:convertedPoint];
            [currentDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            [currentDevice unlockForConfiguration];
        }
    }
#endif
}


#pragma mark - ZXCaptureDelegate Methods

- (void)captureResult:(ZXCapture *)capture result:(ZXResult *)result
{
    if (result) {
        // We got a result. Call fallback delegate.
        if (self.delegate && [self.delegate respondsToSelector:@selector(scannerDidGetResult:willDismiss:)]) {
            [self.delegate scannerDidGetResult:result.text willDismiss:YES];
        }
    }
}

- (void)captureSize:(ZXCapture *)capture width:(NSNumber *)width height:(NSNumber *)height
{
    // Do nothing
}

@end
