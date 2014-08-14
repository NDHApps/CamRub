//
//  CRViewController.m
//  CamRub
//
//  Created by Nicholas Hall on 7/16/14.
//  Copyright (c) 2014 NDHApps. All rights reserved.
//

#import "CRViewController.h"
#import <Twitter/Twitter.h>
#import "Reachability.h"
#import <MobileCoreServices/UTCoreTypes.h>

@interface CRViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *cameraFrame;
@property (nonatomic, weak) IBOutlet UIImageView *savedPixels;
@property (nonatomic, strong) UIImage *pixelMask;
@property (nonatomic, strong) UIImage *lastRevision;
@property (nonatomic, weak) IBOutlet UIView *brushSelectorView;
@property (nonatomic, weak) IBOutlet UIView *brushPreview;
@property (nonatomic, weak) IBOutlet UISlider *brushSlider;
@property (nonatomic, weak) IBOutlet UIView *eraseBrushSelectorView;
@property (nonatomic, weak) IBOutlet UIView *eraseBrushPreview;
@property (nonatomic, weak) IBOutlet UISlider *eraseBrushSlider;
@property (nonatomic, weak) IBOutlet UIView *selectorBackground;
@property (nonatomic, weak) IBOutlet UIImageView *drawingStrokes;
@property (nonatomic, weak) IBOutlet UIView *overlayView;
@property (nonatomic, weak) IBOutlet UIView *popupOverlay;
@property (nonatomic, strong) UIView *popup;
@property (nonatomic, weak) IBOutlet UIButton *shareButton;
@property (nonatomic, weak) IBOutlet UIImageView *drawIndicator;
@property (nonatomic, weak) IBOutlet UIImageView *eraseIndicator;
@property (nonatomic, strong) IBOutletCollection(UIButton) NSArray *buttons;
@property (nonatomic, strong) IBOutletCollection(NSLayoutConstraint) NSArray *topButtonConstraints;
@property (nonatomic, strong) IBOutletCollection(NSLayoutConstraint) NSArray *bottomButtonConstraints;
@property (nonatomic, retain) UIDocumentInteractionController *dic;

@end

@implementation CRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    color = 0.0;
    alpha = 1.0;
    drawToolSelected = YES;
    drawingEnabled = YES;
    drawSize = [[NSUserDefaults standardUserDefaults] doubleForKey:@"brushSize"];
    eraseSize = [[NSUserDefaults standardUserDefaults] doubleForKey:@"eraserSize"];
    if (!drawSize)
        drawSize = 30.0;
    if (!eraseSize)
        eraseSize = 30.0;
    drawBehind = [[NSUserDefaults standardUserDefaults] boolForKey:@"drawingMode"];
    alphaEffect = [[NSUserDefaults standardUserDefaults] boolForKey:@"alphaEffect"];
    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"backgroundFillColor"];
    if (colorData)
        backgroundFillColor = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    else
        backgroundFillColor = [UIColor whiteColor];
    self.isFrontCameraSelected = NO;
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CamRub needs a camera!" message:@"Please try CamRub on another camera-enabled device." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        alertView.tag = 1;
        [alertView show];
    }
    else
    {
        [self loadCustomCameraView];
    }

}

- (void) CRHelpController:(CRHelpController *)helpController {
    [self dismissPopup];
}

- (void) CRSettingsController:(CRSettingsController *)settingController didSetColor:(UIColor *)fillColor didSetDrawingMode:(BOOL)drawingMode didSetAlphaEffect:(BOOL)alphaE{
    
    [self dismissPopup];
    drawBehind = drawingMode;
    alphaEffect = alphaE;
    backgroundFillColor = fillColor;
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:backgroundFillColor];
    [[NSUserDefaults standardUserDefaults] setObject:colorData forKey:@"backgroundFillColor"];
    
}

- (CGFloat) trueScreenHeight {
    CGRect screenSize = [[UIScreen mainScreen] bounds];
    return screenSize.size.height - [UIApplication sharedApplication].statusBarFrame.size.height;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL) connected
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    return networkStatus != NotReachable;
}

- (IBAction)undo
{
    [self dismissBrushSelectors];
    if(_savedPixels.image)
        _savedPixels.image = _lastRevision;
}

- (IBAction)flip
{
    [self dismissBrushSelectors];
    [[self captureManager] toggleCamera];
}

- (IBAction) sliderChanged
{
    brush = drawSize = _brushSlider.value;
    _brushPreview.transform = CGAffineTransformScale(CGAffineTransformIdentity, brush/50.0, brush/50.0);
    [[NSUserDefaults standardUserDefaults] setDouble:drawSize forKey:@"brushSize"];
}

- (IBAction) eraseSliderChanged
{
    brush = eraseSize = _eraseBrushSlider.value;
    _eraseBrushPreview.transform = CGAffineTransformScale(CGAffineTransformIdentity, brush/50.0, brush/50.0);
    [[NSUserDefaults standardUserDefaults] setDouble:eraseSize forKey:@"eraserSize"];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(drawingEnabled) {
        [self dismissBrushSelectors];
        mouseSwiped = NO;
        UITouch *touch = [touches anyObject];
        lastPoint = [touch locationInView:self.drawingStrokes];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(drawingEnabled)
    {
        mouseSwiped = YES;
        UITouch *touch = [touches anyObject];
        CGPoint currentPoint = [touch locationInView:self.drawingStrokes];
        UIGraphicsBeginImageContextWithOptions(self.drawingStrokes.frame.size, NO, 0.0);
        [self.drawingStrokes.image drawInRect:CGRectMake(0, 0, self.drawingStrokes.frame.size.width, self.drawingStrokes.frame.size.height)];
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), brush);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), color, color, color, alpha);
        CGContextSetBlendMode(UIGraphicsGetCurrentContext(),kCGBlendModeNormal);
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        self.drawingStrokes.image = UIGraphicsGetImageFromCurrentImageContext();
        self.drawingStrokes.alpha = 0.5;
        UIGraphicsEndImageContext();
        lastPoint = currentPoint;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(drawingEnabled) {
        if(!mouseSwiped) {
            UIGraphicsBeginImageContextWithOptions(self.drawingStrokes.frame.size, NO, 0.0);
            [self.drawingStrokes.image drawInRect:CGRectMake(0, 0, self.drawingStrokes.frame.size.width, self.drawingStrokes.frame.size.height)];
            CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
            CGContextSetLineWidth(UIGraphicsGetCurrentContext(), brush);
            CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), color, color, color, alpha);
            CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
            CGContextStrokePath(UIGraphicsGetCurrentContext());
            CGContextFlush(UIGraphicsGetCurrentContext());
            self.drawingStrokes.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        [self strokesFinished];
    }
    else
        _drawingStrokes.image = nil;
}

- (void) strokesFinished {
    if (_drawingStrokes.image.CGImage && ![self imageIsTransparent:_drawingStrokes.image.CGImage]) {
        UIGraphicsBeginImageContextWithOptions(self.savedPixels.frame.size, NO, 0.0);
        [self.drawingStrokes.image drawInRect:CGRectMake(0, 0, self.drawingStrokes.frame.size.width, self.drawingStrokes.frame.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
        self.pixelMask = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        if (drawToolSelected) {
            if (_captureManager.captureSession.isRunning)
                [_captureManager captureStillImage];
        } else
            [self eraseStrokes];
    }
}

- (void)loadCustomCameraView
{
    if (self.cameraFrame.isAnimating)
    {
        [self.cameraFrame stopAnimating];
    }
    
    [self setCaptureManager:[[CaptureSessionManager alloc] init]];
    
	[[self captureManager] addVideoInput];
	[[self captureManager] addVideoPreviewLayer];
    [[self captureManager] addStillImageOutput];
	CGRect layerRect = [[[self view] layer] bounds];
	[[[self captureManager] previewLayer] setBounds:layerRect];
	[[[self captureManager] previewLayer] setPosition:CGPointMake(CGRectGetMidX(layerRect),
                                                                  CGRectGetMidY(layerRect))];
	[[[self view] layer] addSublayer:[[self captureManager] previewLayer]];
    
    [[NSBundle mainBundle] loadNibNamed:@"CRCameraOverlayView" owner:self options:nil];
    CGRect screenSize = [[UIScreen mainScreen] bounds];
    screenSize.size.height = [self trueScreenHeight];
    self.overlayView.frame = screenSize;
    [self customizeConstraints];
    [self customizeButtons];
    [_brushPreview.layer setCornerRadius: 25.0];
    [_eraseBrushPreview.layer setCornerRadius: 25.0];
    _brushPreview.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.6, 0.6);
    _eraseBrushPreview.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.6, 0.6);
    _brushSlider.value = drawSize;
    _eraseBrushSlider.value = eraseSize;
    [self eraseSliderChanged];
    [self sliderChanged];
    
    [[self view] addSubview:self.overlayView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addStrokesToImage) name:kImageCapturedSuccessfully object:nil];
    
    [[_captureManager captureSession] startRunning];
   
}

- (void) customizeConstraints {
    CGFloat screenHeight = [self trueScreenHeight];
    CGFloat spacing = screenHeight / 4.0 - 110.0;
    for (NSLayoutConstraint *topButtonConstraint in self.topButtonConstraints)
    {
        topButtonConstraint.constant = spacing - 3.0;
    }
    for (NSLayoutConstraint *bottomButtonConstraint in self.bottomButtonConstraints)
    {
        bottomButtonConstraint.constant = spacing;
    }
}

- (void) customizeButtons {
    for (UIButton *buttonToCustomize in self.buttons)
    {
        [buttonToCustomize setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    }
}

- (void) addStrokesToImage {
    
    UIImage *capturedImage = [[self captureManager] stillImage];
    
    CGFloat imageWidth  = capturedImage.size.width;
    CGFloat imageHeight = capturedImage.size.height;
    
    CGRect cropRect = CGRectMake ((imageHeight - imageWidth) / 2.0 + 0.03125 * imageWidth, 0.03125 * imageWidth, 0.9375 * imageWidth, 0.9375 * imageWidth);
    
    // Draw new image in current graphics context
    CGImageRef imageRef = CGImageCreateWithImageInRect ([capturedImage CGImage], cropRect);
    
    // Rotate and crop the image
    NSInteger orientation;
    if (_captureManager.frontCameraInUse)
        orientation = UIImageOrientationLeftMirrored;
    else
        orientation = UIImageOrientationRight;
    
    capturedImage = [self rotate:[UIImage imageWithCGImage: imageRef scale: 0.9375 * imageWidth / 600.0 orientation: orientation]];
    CGImageRelease(imageRef);
    
    // Create alpha mask
    UIImage* mask = [self prepareMask:_pixelMask];
    
    // Mask image
    if (alphaEffect) {
        mask = [self maskImage:capturedImage withMask:mask];
        mask = [self prepareMask:mask];
    }
    capturedImage = [self maskImage:capturedImage withMask:mask];
    
    // Update image
    UIGraphicsBeginImageContextWithOptions(self.savedPixels.frame.size, NO, 0.0);
    if (drawBehind) {
        [capturedImage drawInRect:CGRectMake(0, 0, self.savedPixels.frame.size.width, self.savedPixels.frame.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
        [self.savedPixels.image drawInRect:CGRectMake(0, 0, self.savedPixels.frame.size.width, self.savedPixels.frame.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    } else {
        [self.savedPixels.image drawInRect:CGRectMake(0, 0, self.savedPixels.frame.size.width, self.savedPixels.frame.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
        [capturedImage drawInRect:CGRectMake(0, 0, self.savedPixels.frame.size.width, self.savedPixels.frame.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    }
    self.lastRevision = self.savedPixels.image;
    self.savedPixels.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // Clear temporary images
    self.pixelMask = nil;
    self.drawingStrokes.image = nil;
    
}

- (UIImage*) prepareMask:(UIImage*)maskingImage {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(300.0,300.0), NO, 0.0 );
    CGRect maskRect = CGRectMake(0.0, 0.0, 300.0, 300.0);
    [[UIColor whiteColor] set];
    UIRectFill(CGRectMake(0.0, 0.0, 300.0, 300.0));
    [maskingImage drawInRect:maskRect];
    UIImage* mask = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return mask;
}

- (void) eraseStrokes {
    
    if(_savedPixels.image)
    {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(300.0,300.0), NO, 0.0 );
        CGRect maskRect = CGRectMake(0.0, 0.0, 300.0, 300.0);
        [[UIColor blackColor] set];
        UIRectFill(CGRectMake(0.0, 0.0, 300.0, 300.0));
        [_pixelMask drawInRect:maskRect];
        UIImage* mask = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        self.lastRevision = self.savedPixels.image;
        self.savedPixels.image = [self maskImage:_savedPixels.image withMask:mask];
        
        UIGraphicsBeginImageContextWithOptions(self.savedPixels.frame.size, NO, 0.0);
        [self.savedPixels.image drawInRect:CGRectMake(0, 0, self.savedPixels.frame.size.width, self.savedPixels.frame.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
        self.savedPixels.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    self.pixelMask = nil;
    self.drawingStrokes.image = nil;
    if(_savedPixels.image.CGImage) {
        if ([self imageIsTransparent:_savedPixels.image.CGImage])
            self.savedPixels.image = nil;
    }
}

- (BOOL) imageIsTransparent:(CGImageRef)imgRef {
    size_t w = CGImageGetWidth(imgRef);
    size_t h = CGImageGetHeight(imgRef);
    unsigned char *inImage = malloc(w * h * 4);
    memset(inImage, 0, (h * w * 4));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(inImage, w, h, 8, w * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetShouldAntialias(context, NO);
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), imgRef);
    int byteIndex = 0;
    BOOL imageIsTransparent = YES;
    for(int i = 0; i < (w * h); i++) {
        if (inImage[byteIndex + 3])
            imageIsTransparent = NO;
        if (!imageIsTransparent)
            break;
        byteIndex += 4;
    }
    free(inImage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return imageIsTransparent;
}

- (UIImage*) maskImage:(UIImage*)image withMask:(UIImage*)mask {
    CGImageRef maskRef = mask.CGImage;
    CGImageRef CGMask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                          CGImageGetHeight(maskRef),
                                          CGImageGetBitsPerComponent(maskRef),
                                          CGImageGetBitsPerPixel(maskRef),
                                          CGImageGetBytesPerRow(maskRef),
                                          CGImageGetDataProvider(maskRef), NULL, false);
	maskRef = CGImageCreateWithMask([image CGImage], CGMask);
    CGImageRelease(CGMask);
    UIImage *result = [UIImage imageWithCGImage:maskRef];
    CGImageRelease(maskRef);
    return result;

}

- (UIImage*) rotate:(UIImage*) src {
    
    UIImageOrientation orientation = src.imageOrientation;
    
    UIGraphicsBeginImageContextWithOptions(src.size, NO, 0.0);
    
    CGContextRef context=(UIGraphicsGetCurrentContext());
    
    if (orientation == UIImageOrientationRight) {
        CGContextRotateCTM (context, 90/180*M_PI) ;
    } else if (orientation == UIImageOrientationLeft) {
        CGContextRotateCTM (context, -90/180*M_PI);
    } else if (orientation == UIImageOrientationDown) {
        // NOTHING
    } else if (orientation == UIImageOrientationUp) {
        CGContextRotateCTM (context, 90/180*M_PI);
    }
    
    [src drawAtPoint:CGPointMake(0, 0)];
    UIImage *img=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
    
}

- (IBAction) clearImage {
    [self dismissBrushSelectors];
    drawingEnabled = YES;
    [self.captureManager.captureSession startRunning];
    if(_savedPixels.image) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure you want to clear the canvas?" message:@"All work will be lost." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes",nil];
        alertView.tag = 2;
        [alertView show];
    }
    else
        [self drawTapped];
}

- (IBAction) drawTapped {
    drawToolSelected = YES;
    color = 0.0;
    brush = drawSize;
    [_drawIndicator setHidden:NO];
    [_eraseIndicator setHidden:YES];
    [self dismissBrushSelectors];
}

- (IBAction) eraseTapped {
    drawToolSelected = NO;
    color = 1.0;
    brush = eraseSize;
    [_eraseIndicator setHidden:NO];
    [_drawIndicator setHidden:YES];
    [self dismissBrushSelectors];
}

- (IBAction) drawPressed {
    drawToolSelected = YES;
    color = 0.0;
    brush = drawSize;
    [_drawIndicator setHidden:NO];
    [_eraseIndicator setHidden:YES];
    [_eraseBrushSelectorView setHidden:YES];
    [_brushSelectorView setHidden:NO];
    [_selectorBackground setHidden:NO];
}

- (IBAction) erasePressed {
    drawToolSelected = NO;
    color = 1.0;
    brush = eraseSize;
    [_eraseIndicator setHidden:NO];
    [_drawIndicator setHidden:YES];
    [_brushSelectorView setHidden:YES];
    [_eraseBrushSelectorView setHidden:NO];
    [_selectorBackground setHidden:NO];
}

- (IBAction) dismissBrushSelectors {
    [_brushSelectorView setHidden:YES];
    [_eraseBrushSelectorView setHidden:YES];
    [_selectorBackground setHidden:YES];
}

- (IBAction) shareImage {
    if (_drawingStrokes.image.CGImage)
        _drawingStrokes.image = nil;
    [self dismissBrushSelectors];
    if(_savedPixels.image.CGImage) {
        drawingEnabled = NO;
        [self.captureManager.captureSession stopRunning];
        _drawingStrokes.image = [self renderPreview];
        _drawingStrokes.alpha = 0.5;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
            [UIView animateWithDuration:1.0 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 _drawingStrokes.alpha = 1.0;
                             } completion:^(BOOL finished) {
                                 [self displayActionSheet];
                             }];
        } else {
            [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 _drawingStrokes.alpha = 1.0;
                             } completion:^(BOOL finished) {
                                 [self displayActionSheet];
                             }];
        }
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"There's nothing to share!" message:@"Rub on the camera view to capture portions of the image." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }

}

- (void) displayActionSheet {
    UIActionSheet *sharePopup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
                                 @"Share on Facebook",
                                 @"Share on Twitter",
                                 @"Share on Instagram",
                                 @"Share via Messages",
                                 @"Save to Camera Roll",
                                 nil];
    sharePopup.tag = 1;
    [sharePopup showInView:[UIApplication sharedApplication].keyWindow];
}

- (void) actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (popup.tag) {
        case 1: {
            switch (buttonIndex) {
                case 0:
                    [self SLShareImage:SLServiceTypeFacebook];
                    break;
                case 1:
                    [self SLShareImage:SLServiceTypeTwitter];
                    break;
                case 2:
                    [self instaShare];
                    break;
                case 3:
                    [self messagesShare];
                    break;
                case 4:
                    [self saveImage];
                    break;
                default:
                    [self sharingCancelled];
                    break;
            }
            break;
        }
        default:
            break;
    }
}

- (void) messagesShare {
    
    MFMessageComposeViewController *composer = [[MFMessageComposeViewController alloc] init];
    composer.messageComposeDelegate = self;
    
    // These checks basically make sure it's an MMS capable device with iOS7
    if([MFMessageComposeViewController respondsToSelector:@selector(canSendAttachments)] && [MFMessageComposeViewController canSendAttachments])
    {
        UIImage *imageToShare = [self formatPNG];
        NSData *imgData = UIImagePNGRepresentation(imageToShare);
        [composer addAttachmentData:imgData typeIdentifier:(NSString*)kUTTypeMessage filename:@"image.png"];
        [composer setBody:@"Check out this picture I made using CamRub! NDHApps.com/GetCamRub"];
        [self presentViewController:composer animated:YES completion:nil];
    } else if ([MFMessageComposeViewController respondsToSelector:@selector(canSendText)] && [MFMessageComposeViewController canSendText]){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Image copied to clipboard!" message:@"Select \"Paste\" in the message field to share your work." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        alertView.tag = 4;
        [alertView show];
    } else {
        [self sharingCancelled];
    }

}

- (void) iOS6MessageComposer {
    UIImage *imageToShare = [self formatPNG];
    
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.persistent = NO;
    
    NSMutableDictionary *text = [NSMutableDictionary dictionaryWithCapacity:1];
    [text setValue:@"Check out this picture I made using CamRub! NDHApps.com/GetCamRub" forKey:(NSString *)kUTTypeUTF8PlainText];
    
    NSMutableDictionary *image = [NSMutableDictionary dictionaryWithCapacity:1];
    [image setValue:UIImagePNGRepresentation(imageToShare) forKey:(NSString *)kUTTypePNG];
    
    pasteboard.items = [NSArray arrayWithObjects:image,text, nil];
    
    NSString *phoneToCall = @"sms:";
    NSString *phoneToCallEncoded = [phoneToCall stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSURL *url = [[NSURL alloc] initWithString:phoneToCallEncoded];
    
    [[UIApplication sharedApplication] openURL:url];
    
    [self animateShare:nil];
    
}

- (void) messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    if (result == MessageComposeResultSent) {
        _savedPixels.image = nil;
        [self drawTapped];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    [self sharingCancelled];
    
}

- (void) saveImage {
    UIImageWriteToSavedPhotosAlbum([self formatPNG],self,@selector(image:didFinishSavingWithError:contextInfo:),nil);
}

- (void) SLShareImage:(NSString *const)service {
    SLComposeViewController *shareSheet = [SLComposeViewController
                                           composeViewControllerForServiceType:
                                           service];
    
    NSString *message;
    
    if (service == SLServiceTypeFacebook) {
        message = @"Imaged shared to Facebook.";
        [shareSheet setInitialText:@"Check out this picture I made using CamRub! NDHApps.com/GetCamRub"];
    }
    else if (service == SLServiceTypeTwitter) {
        message = @"Imaged shared to Twitter.";
        [shareSheet setInitialText:@"Check out this picture I made using @CamRubApp! NDHApps.com/GetCamRub"];
    }
    
    [shareSheet addImage:[self formatPNG]];
    
    shareSheet.completionHandler = ^(SLComposeViewControllerResult result) {
        switch(result) {
            case SLComposeViewControllerResultCancelled:
                [self sharingCancelled];
                break;
            case SLComposeViewControllerResultDone:
                if ([self connected])
                    [self animateShare:message];
                else
                    [self sharingCancelled];
                break;
        }
    };
    
    [self presentViewController:shareSheet animated:NO completion:nil];
    
}

- (UIImage*) renderPreview {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(300.0, 300.0), NO, 0.0 );
    CGRect maskRect = CGRectMake(0.0, 0.0, 300.0, 300.0);
    [backgroundFillColor set];
    UIRectFill(CGRectMake(0.0, 0.0, 300.0, 300.0));
    [_savedPixels.image drawInRect:maskRect];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return img;
}

- (UIImage*) formatPNG {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(632.0 ,632.0), NO, 0.0 );
    CGRect maskRect = CGRectMake(16.0, 16.0, 600.0, 600.0);
    [backgroundFillColor set];
    UIRectFill(CGRectMake(0.0, 0.0, 632.0, 632.0));
    [_savedPixels.image drawInRect:maskRect];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return img;
}

- (void) instaShare {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"instagram://"]]) {
    
        // Format for Instagram
        UIImage *instaImage = [self formatPNG];

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"CamRub.igo"];
        [UIImagePNGRepresentation(instaImage) writeToFile:filePath atomically:NO];
        
        NSURL *instaHookFile = [[NSURL alloc] initWithString:[[NSString alloc] initWithFormat:@"file://%@", filePath]];
        
        self.dic = [UIDocumentInteractionController interactionControllerWithURL:instaHookFile];
        self.dic.delegate = self;
        self.dic.annotation = [NSDictionary dictionaryWithObject:@"Check out this picture I made using CamRub! NDHApps.com/GetCamRub"
                                                          forKey:@"InstagramCaption"];
        self.dic.UTI = @"com.instagram.photo";
        
        // OPEN THE HOOK
        CGRect rect = CGRectMake(0.0, 0.0, 0.0, 0.0);
        [self.dic presentOpenInMenuFromRect:rect inView:self.view animated:YES];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Instagram isn't installed!" message:@"Please download the Instagram app to share pictures to Instagram." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        [self sharingCancelled];
    }
    
}

- (UIDocumentInteractionController *) setupControllerWithURL: (NSURL*) fileURL usingDelegate: (id <UIDocumentInteractionControllerDelegate>) interactionDelegate {
    UIDocumentInteractionController *interactionController = [UIDocumentInteractionController interactionControllerWithURL: fileURL];
    interactionController.delegate = interactionDelegate;
    return interactionController;
}

- (void) animateShare:(NSString*)successMessage {
    CGRect newFrame = _shareButton.frame;
    newFrame.size.height = newFrame.size.width;
    _savedPixels.image = nil;
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         [_drawingStrokes setFrame:newFrame];
                         
                     } completion:^(BOOL finished) {
                         [_drawingStrokes setImage:nil];
                         [_drawingStrokes setFrame:_savedPixels.frame];
                         if (successMessage)
                             [self successAlert:successMessage];
                         else {
                             _drawingStrokes.image = nil;
                             [self.captureManager.captureSession startRunning];
                             drawingEnabled = YES;
                             [self drawTapped];
                         }
                     }];

}

- (void) sharingCancelled {
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _drawingStrokes.alpha = 0.0;
                         
                     } completion:^(BOOL finished) {
                         _drawingStrokes.image = nil;
                         drawingEnabled = YES;
                     }];
    [self.captureManager.captureSession startRunning];
}

- (void) successAlert:(NSString*)successMessage {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success!" message:successMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    alertView.tag = 3;
    [alertView show];
}

- (void) image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *) contextInfo {
    if(!error) {
        [self animateShare:@"Image saved to camera roll."];
    } else {
        [self sharingCancelled];
    }
}

-(void) documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller {
    [self sharingCancelled];
}

-(void) documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application {
    _savedPixels.image = nil;
    drawingEnabled = YES;
    [self drawTapped];
}

- (IBAction) help {
        [self showPopup:NO];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case 1:
            if (buttonIndex == 0)
                exit(0);
            break;
        case 2:
            if (buttonIndex == 1) {
                self.savedPixels.image = nil;
                [self drawTapped];
                self.lastRevision = nil;
            }
            break;
        case 3:
            [self.captureManager.captureSession startRunning];
            _drawingStrokes.image = nil;
            drawingEnabled = YES;
            break;
        case 4:
            [self iOS6MessageComposer];
        default:
            break;
            
    }
}

- (IBAction) settings
{
    [self showPopup:YES];
}

- (void) showPopup:(bool) popupType // YES = settings, NO = help
{
    [self dismissBrushSelectors];
    if (_drawingStrokes.image.CGImage)
        _drawingStrokes.image = nil;
    drawingEnabled = NO;
    _popupOverlay.hidden = NO;
    _popupOverlay.alpha = 0.0;
    CGRect frame = _popupOverlay.frame;
    frame.origin.x += (frame.size.width - 310.0) / 2.0;
    frame.origin.y += (frame.size.height - 470.0) / 2.0 + 2.0 + [self trueScreenHeight];
    frame.size = CGSizeMake(310.0, 470.0);
    [_popup removeFromSuperview]; // Make sure previously referenced view is gone
    if (popupType) {
        _popup = [[CRSettingsController alloc] initWithFrame:frame];
        ((CRSettingsController*)_popup).delegate = self;
    } else {
        _popup = [[CRHelpController alloc] initWithFrame:frame];
        ((CRHelpController*)_popup).delegate = self;
    }
    [self.view addSubview:_popup];
    frame.origin.y -= [self trueScreenHeight];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        [UIView animateWithDuration:0.7 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             _popup.frame = frame;
                             _popupOverlay.alpha = 0.7;
                             
                         } completion:^(BOOL finished) {
                             [self.captureManager.captureSession stopRunning];
                         }];
    } else {
        [UIView animateWithDuration:0.7 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             _popup.frame = frame;
                             _popupOverlay.alpha = 0.7;
                             
                         } completion:^(BOOL finished) {
                             [self.captureManager.captureSession stopRunning];
                         }];
    }
}

- (IBAction) dismissPopup {
    CGRect frame = _popup.frame;
    frame.origin.y += [self trueScreenHeight];
    [self.captureManager.captureSession startRunning];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        [UIView animateWithDuration:0.6 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             _popup.frame = frame;
                             _popupOverlay.alpha = 0.0;
                             
                         } completion:^(BOOL finished) {
                             [_popup removeFromSuperview];
                             _popupOverlay.hidden = YES;
                         }];
    } else {
        [UIView animateWithDuration:0.6 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             _popup.frame = frame;
                             _popupOverlay.alpha = 0.0;
                             
                         } completion:^(BOOL finished) {
                             [_popup removeFromSuperview];
                             _popupOverlay.hidden = YES;
                         }];
    }
    drawingEnabled = YES;
}

@end
