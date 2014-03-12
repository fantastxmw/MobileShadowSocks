//
//  CodeGeneratorViewController.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 14-1-25.
//  Copyright (c) 2014 Linus Yang. All rights reserved.
//

#import "CodeGeneratorViewController.h"

#ifdef __IPHONE_6_0
#import <Social/Social.h>
#endif

#ifdef __IPHONE_5_0
#import <Twitter/Twitter.h>
#endif

#define kCodeSize 256.0f

typedef enum {
    ShareActionCopy = 0,
    ShareActionPhoto,
    ShareActionTwitter,
    ShareActionWeibo,
    
    ShareActionCount
} ShareAction;

@interface CodeGeneratorViewController () <UIActionSheetDelegate>

@property (nonatomic, copy) NSString *codeLink;
@property (nonatomic, retain) UIImageView *codeImageView;
@property (nonatomic, assign) BOOL legacyLibrary;

@end

@implementation CodeGeneratorViewController

#pragma mark - View life cycle

- (id)initWithQRCodeLink:(NSString *)link
{
    self = [super init];
    if (self) {
        self.codeLink = link;
        self.legacyLibrary = SYSTEM_VERSION_LESS_THAN(@"6.0");
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (DEVICE_IS_IPAD()) {
        return YES;
    } else {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
}

- (void)dealloc
{
    [_codeLink release];
    _codeLink = nil;
    [_codeImageView release];
    _codeImageView = nil;
    [super dealloc];
}

#pragma mark - Private methods

- (void)showShareMessage:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Share QR Code", nil)
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *) contextInfo;
{
    if (error) {
        [self showShareMessage:NSLocalizedString(@"Failed to save QR code image.", nil)];
    } else {
        [self showShareMessage:NSLocalizedString(@"Image is saved to photo library.", nil)];
    }
}

- (void)generateQRCode
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ZXMultiFormatWriter *writer = [ZXMultiFormatWriter writer];
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
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Share QR Code",nil)
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:
                                  NSLocalizedString(@"Copy Link", nil),
                                  NSLocalizedString(@"Save to Photo Library", nil),
                                  NSLocalizedString(@"Share to Twitter", nil),
                                  NSLocalizedString(@"Share to Weibo", nil),
                                  nil];
    [actionSheet showInView:self.view];
    [actionSheet release];
}

#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    BOOL isTwitterAvailable;
    BOOL isWeiboAvailable;
    
    isTwitterAvailable = NO;
    isWeiboAvailable = NO;
#ifdef __IPHONE_6_0
    if ([SLComposeViewController class]) {
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            isTwitterAvailable = YES;
        }
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeSinaWeibo]) {
            isWeiboAvailable = YES;
        }
    }
#endif
    
#ifdef __IPHONE_5_0
    if (!isTwitterAvailable && self.legacyLibrary) {
        if ([TWTweetComposeViewController class]) {
            if ([TWTweetComposeViewController canSendTweet]) {
                isTwitterAvailable = YES;
            }
        }
    }
#endif
    
    ShareAction action = (ShareAction) buttonIndex;
    switch (action) {
        case ShareActionCopy: {
            UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
            pasteBoard.string = self.codeLink;
            NSString *message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Link is copied to pasteboard", nil), self.codeLink];
            [self showShareMessage:message];
            break;
        }
            
        case ShareActionPhoto: {
            if (self.codeImageView.image) {
                UIImageWriteToSavedPhotosAlbum(self.codeImageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
            }
            break;
        }
            
        case ShareActionTwitter: {
            if (isTwitterAvailable) {
                if (self.legacyLibrary) {
#ifdef __IPHONE_5_0
                    TWTweetComposeViewController *composeViewController = [[TWTweetComposeViewController alloc] init];
                    if (self.codeImageView.image) {
                        [composeViewController addImage:self.codeImageView.image];
                    }
                    [composeViewController setInitialText:NSLocalizedString(@"I've shared a #ShadowSocks profile with QR Code.", nil)];
                    [self presentViewController:composeViewController animated:YES completion:nil];
                    [composeViewController release];
#endif
                } else {
#ifdef __IPHONE_6_0
                    SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
                    if (composeViewController) {
                        if (self.codeImageView.image) {
                            [composeViewController addImage:self.codeImageView.image];
                        }
                        [composeViewController setInitialText:NSLocalizedString(@"I've shared a #ShadowSocks profile with QR Code.", nil)];
                        [self presentViewController:composeViewController animated:YES completion:nil];
                    }
#endif
                }
            } else {
                [self showShareMessage:NSLocalizedString(@"Twitter account is not available.", nil)];
            }
            break;
        }
            
        case ShareActionWeibo: {
            if (isWeiboAvailable) {
#ifdef __IPHONE_6_0
                SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeSinaWeibo];
                if (composeViewController) {
                    if (self.codeImageView.image) {
                        [composeViewController addImage:self.codeImageView.image];
                    }
                    [composeViewController setInitialText:NSLocalizedString(@"I've shared a #ShadowSocks# profile with QR Code.", nil)];
                    [self presentViewController:composeViewController animated:YES completion:nil];
                }
#endif
            } else {
                [self showShareMessage:NSLocalizedString(@"Sina Weibo account is not available.", nil)];
            }
            break;
        }
            
        default:
            break;
    }
}

@end
