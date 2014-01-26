//
//  CodeScannerViewController.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 14-1-25.
//  Copyright (c) 2014 Linus Yang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CodeScannerDelegate <NSObject>

- (void)scannerDidGetResult:(NSString *)resultText willDismiss:(BOOL)dismiss;

@end

@interface CodeScannerViewController : UIViewController <ZXCaptureDelegate>

@property (nonatomic, assign) id<CodeScannerDelegate> delegate;

+ (void)scanImage:(UIImage *)image completion:(void (^)(BOOL success, NSString *resultText))handler;

@end

