//
//  CodeGeneratorViewController.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 14-1-25.
//  Copyright (c) 2014 Linus Yang. All rights reserved.
//

#import "CodeGeneratorViewController.h"

#define kCodeSize 256.0f

@interface CodeGeneratorViewController ()

@property (nonatomic, retain) NSString *codeLink;
@property (nonatomic, retain) UIImageView *codeImageView;

@end

@implementation CodeGeneratorViewController

- (id)initWithQRCodeLink:(NSString *)link
{
    self = [super init];
    if (self) {
        self.codeLink = link;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _codeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kCodeSize, kCodeSize)];
    _codeImageView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin |
                                       UIViewAutoresizingFlexibleBottomMargin |
                                       UIViewAutoresizingFlexibleLeftMargin |
                                       UIViewAutoresizingFlexibleRightMargin);
    _codeImageView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_codeImageView];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.title = NSLocalizedString(@"Share QR Code", nil);
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Share", nil)
                                                                    style:UIBarButtonItemStyleBordered
                                                                   target:self
                                                                   action:@selector(shareCodeImage)];
    self.navigationItem.rightBarButtonItem = shareButton;
    [shareButton release];
    
    [self generateQRCode];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.codeImageView.center = self.view.center;
}

- (void)dealloc
{
    [_codeLink release];
    _codeLink = nil;
    [_codeImageView release];
    _codeImageView = nil;
    [super dealloc];
}

- (void)generateQRCode
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ZXMultiFormatWriter *writer = [[ZXMultiFormatWriter alloc] init];
        ZXBitMatrix *result = [writer encode:self.codeLink format:kBarcodeFormatQRCode width:kCodeSize height:kCodeSize error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result) {
                self.codeImageView.image = [UIImage imageWithCGImage:[ZXImage imageWithMatrix:result].cgimage];
            } else {
                self.codeImageView.image = nil;
            }
        });
    });
}

- (void)shareCodeImage
{
    
}

@end
