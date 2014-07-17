//
//  CodeScannerViewController.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 14-1-25.
//  Copyright (c) 2014 Linus Yang. All rights reserved.
//

#import "CodeScannerViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"

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
@property (nonatomic, assign) BOOL isAutoFocus;

@end

@implementation CodeScannerViewController

#pragma mark - Class Methods

+ (void)scanImage:(UIImage *)image completion:(void (^)(BOOL success, NSString *resultText))handler
{
    if (image == nil || handler == nil) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];
        ZXDecodeHints *hints = [ZXDecodeHints hints];
        
        ZXCGImageLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:image.CGImage];
        ZXHybridBinarizer *binarizer = [ZXHybridBinarizer binarizerWithSource:source];
        ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:binarizer];
        
        NSError *error = nil;
        ZXResult *result = [reader decode:bitmap hints:hints error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result) {
                handler(YES, result.text);
            } else {
                handler(NO, nil);
            }
        });
        
        [source release];
    });
}

#pragma mark - View Controller Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /* Portrait Orientation Workaround */
    if ([UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationPortrait) {
        UIViewController *viewController = [[UIViewController alloc] init];
        if ([AppDelegate isLegacySystem]) {
            [self.navigationController presentModalViewController:viewController animated:NO];
            [self.navigationController dismissModalViewControllerAnimated:NO];
        } else {
            viewController.view.backgroundColor = [UIColor blackColor];
            [self.navigationController presentViewController:viewController animated:NO completion:^{
                double delayInSeconds = 0.2;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                });
            }];
        }
        [viewController release];
    }
    
    _capture = [[ZXCapture alloc] init];
    self.capture.rotation = 90.0f;
    self.capture.camera = self.capture.back;
    self.capture.layer.frame = self.view.bounds;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [button setTitle:NSLocalizedString(@"Scan QR Code", nil) forState: UIControlStateNormal];
    [button addTarget:self action:@selector(showUsage) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    self.navigationItem.titleView = button;
    
    if (self.capture.hasTorch) {
        UIBarButtonItem *torchButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Torch", nil)
                                                                        style:UIBarButtonItemStyleBordered
                                                                       target:self
                                                                       action:@selector(toggleTorch)];
        self.navigationItem.rightBarButtonItem = torchButton;
        [torchButton release];
    }
    
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
    _focusSqure.alpha = 0.0f;
    [self.view addSubview:_focusSqure];
    
    self.isAutoFocus = YES;

    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapReset:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self.cameraView addGestureRecognizer:doubleTapGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToFocus:)];
    tapGesture.numberOfTapsRequired = 1;
    [tapGesture requireGestureRecognizerToFail:doubleTapGesture];
    [self.cameraView addGestureRecognizer:tapGesture];
    
    [doubleTapGesture release];
    [tapGesture release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    self.capture.delegate = self;
    [self cameraResetAutoFocus];
#if !TARGET_IPHONE_SIMULATOR
    [self.capture.captureDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
#endif
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.capture.layer.frame = self.view.frame;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    if (self.capture.torch == YES) {
        self.capture.torch = NO;
    }
    self.capture.delegate = nil;
#if !TARGET_IPHONE_SIMULATOR
    [self.capture.captureDevice removeObserver:self forKeyPath:@"adjustingFocus"];
#endif
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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

- (void)showUsage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Camera Usage", nil)
                                                    message:NSLocalizedString(@"Single tap for manual focus.\nDouble tap for auto-focus.\nTap torch button to toggle flashlight.", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

#if !TARGET_IPHONE_SIMULATOR
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"adjustingFocus"] == NO ||
        [[change objectForKey:NSKeyValueChangeNewKey] boolValue]) {
        return;
    }
    if (self.isAutoFocus) {
        [self focusSquareAtPoint:self.view.center];
    }
}
#endif

- (void)focusSquareAtPoint:(CGPoint)point
{
    CGRect focusFrame = CGRectMake(point.x - kFocusSize / 2.0, point.y - kFocusSize / 2.0, kFocusSize, kFocusSize);
    
    self.focusSqure.frame = CGRectMake(0, 0, kFocusBigSize, kFocusBigSize);
    self.focusSqure.center = point;
    self.focusSqure.alpha = 0.0f;
    
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
                         } completion:^(BOOL finished) {}];
    }];
}

- (void)cameraFocusAtPoint:(CGPoint)point
{
#if !TARGET_IPHONE_SIMULATOR
    CGPoint convertedPoint = CGPointZero;
    if (![self.capture.layer respondsToSelector:@selector(captureDevicePointOfInterestForPoint:)]) {
        CGRect layerFrame = self.capture.layer.frame;
        convertedPoint = CGPointMake(point.x / CGRectGetHeight(layerFrame), point.y / CGRectGetWidth(layerFrame));
    } else {
        convertedPoint = [(AVCaptureVideoPreviewLayer *)self.capture.layer captureDevicePointOfInterestForPoint:point];
    }
    AVCaptureDevice *currentDevice = self.capture.captureDevice;
    if ([currentDevice isFocusPointOfInterestSupported] && [currentDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]){
        NSError *error = nil;
        [currentDevice lockForConfiguration:&error];
        if (!error) {
            self.isAutoFocus = NO;
            [currentDevice setFocusPointOfInterest:convertedPoint];
            [currentDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            [currentDevice unlockForConfiguration];
        }
    }
#endif
}

- (void)cameraResetAutoFocus
{
#if !TARGET_IPHONE_SIMULATOR
    AVCaptureDevice *currentDevice = self.capture.captureDevice;
    if ([currentDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
        NSError *error = nil;
        [currentDevice lockForConfiguration:&error];
        if (!error) {
            self.isAutoFocus = YES;
            [currentDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            [currentDevice unlockForConfiguration];
        }
    }
#endif
}

- (void)doubleTapReset:(UITapGestureRecognizer *)doubleTap
{
    [self cameraResetAutoFocus];
}

- (void)tapToFocus:(UITapGestureRecognizer *)singleTap
{
    CGPoint touchPoint = [singleTap locationInView:self.cameraView];
    [self cameraFocusAtPoint:touchPoint];
    [self focusSquareAtPoint:touchPoint];
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
