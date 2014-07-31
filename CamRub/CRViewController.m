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
@property (nonatomic, weak) IBOutlet UIView *eraseBrushSelectorView;
@property (nonatomic, weak) IBOutlet UIView *eraseBrushPreview;
@property (nonatomic, weak) IBOutlet UIView *selectorBackground;
@property (nonatomic, weak) IBOutlet UIImageView *drawingStrokes;
@property (nonatomic, weak) IBOutlet UIView *overlayView;
@property (nonatomic, weak) IBOutlet UIButton *shareButton;
@property (nonatomic, weak) IBOutlet UIImageView *drawIndicator;
@property (nonatomic, weak) IBOutlet UIImageView *eraseIndicator;
@property (nonatomic, retain) UIDocumentInteractionController *dic;

- (IBAction) sliderChanged: (id)sender;
- (IBAction) eraseSliderChanged: (id)sender;
- (IBAction) clearImage;
- (IBAction) drawTapped;
- (IBAction) drawPressed;
- (IBAction) eraseTapped;
- (IBAction) erasePressed;
- (IBAction) shareImage;
- (IBAction) dismissBrushSelectors;
- (IBAction) undo;

@end

@implementation CRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    brush = drawSize = eraseSize = 30.0;
    color = 0.0;
    alpha = 1.0;
    drawToolSelected = YES;
    
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
    if(_savedPixels.image)
        _savedPixels.image = _lastRevision;
}

- (IBAction)sliderChanged:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    float val = slider.value * 40.0 + 10;
    brush = drawSize = val;
    _brushPreview.transform = CGAffineTransformScale(CGAffineTransformIdentity, val/50.0, val/50.0);
}

- (IBAction)eraseSliderChanged:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    float val = slider.value * 40.0 + 10;
    brush = eraseSize = val;
    _eraseBrushPreview.transform = CGAffineTransformScale(CGAffineTransformIdentity, val/50.0, val/50.0);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self dismissBrushSelectors];
    mouseSwiped = NO;
    UITouch *touch = [touches anyObject];
    lastPoint = [touch locationInView:self.drawingStrokes];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    mouseSwiped = YES;
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self.drawingStrokes];
    
    UIGraphicsBeginImageContextWithOptions(self.drawingStrokes.frame.size, NO, 0.0);
    [self.drawingStrokes.image drawInRect:CGRectMake(0, 0, self.drawingStrokes.frame.size.width, self.drawingStrokes.frame.size.height)];
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), brush );
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), color, color, color, alpha);
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(),kCGBlendModeNormal);
    
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    self.drawingStrokes.image = UIGraphicsGetImageFromCurrentImageContext();
    [self.drawingStrokes setAlpha:0.5];
    UIGraphicsEndImageContext();
    
    lastPoint = currentPoint;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
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
    
    UIGraphicsBeginImageContextWithOptions(self.savedPixels.frame.size, NO, 0.0);
    [self.drawingStrokes.image drawInRect:CGRectMake(0, 0, self.drawingStrokes.frame.size.width, self.drawingStrokes.frame.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    self.pixelMask = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (drawToolSelected)
        [_captureManager captureStillImage];
    else
        [self eraseStrokes];
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
    self.overlayView.frame = [[UIScreen mainScreen] bounds];
    [_brushPreview.layer setCornerRadius: 25.0];
    [_eraseBrushPreview.layer setCornerRadius: 25.0];
    _brushPreview.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.6, 0.6);
    _eraseBrushPreview.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.6, 0.6);
    [[self view] addSubview:self.overlayView];
    self.overlayView = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addStrokesToImage) name:kImageCapturedSuccessfully object:nil];
    
    [[_captureManager captureSession] startRunning];
   
}

- (void) addStrokesToImage {
    
    UIImage *capturedImage = [[self captureManager] stillImage];
    
    CGFloat imageWidth  = capturedImage.size.width;
    CGFloat imageHeight = capturedImage.size.height;
    
    CGRect cropRect = CGRectMake ((imageHeight - imageWidth) / 2.0 + 0.03125 * imageWidth, 0.03125 * imageWidth, 0.9375 * imageWidth, 0.9375 * imageWidth);
    
    // Draw new image in current graphics context
    CGImageRef imageRef = CGImageCreateWithImageInRect ([capturedImage CGImage], cropRect);
    
    // Rotate and crop the image
    capturedImage = [self rotate:[UIImage imageWithCGImage: imageRef scale: 0.9375 * imageWidth / 600.0 orientation: UIImageOrientationRight]];
    
    // Create alpha mask
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(300.0,300.0), NO, 0.0 );
    CGRect maskRect = CGRectMake(0.0, 0.0, 300.0, 300.0);
    [[UIColor whiteColor] set];
    UIRectFill(CGRectMake(0.0, 0.0, 300.0, 300.0));
    [_pixelMask drawInRect:maskRect];
    UIImage* mask = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Mask image
    capturedImage = [self maskImage:capturedImage withMask:mask];
    
    // Update image
    UIGraphicsBeginImageContextWithOptions(self.savedPixels.frame.size, NO, 0.0);
    [self.savedPixels.image drawInRect:CGRectMake(0, 0, self.savedPixels.frame.size.width, self.savedPixels.frame.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    [capturedImage drawInRect:CGRectMake(0, 0, self.savedPixels.frame.size.width, self.savedPixels.frame.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    self.lastRevision = self.savedPixels.image;
    self.savedPixels.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // Clear temporary images
    self.pixelMask = nil;
    self.drawingStrokes.image = nil;
    
}

- (void) eraseStrokes {
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
    
    _pixelMask = nil;
    self.drawingStrokes.image = nil;

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
    
    return [UIImage imageWithCGImage:maskRef];

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
    if(_savedPixels.image) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure you want to clear the canvas?" message:@"All rubbing will be lost." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes",nil];
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
    [self dismissBrushSelectors];
    if(_savedPixels.image) {
        UIActionSheet *sharePopup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
                                @"Share on Facebook",
                                @"Share on Twitter",
                                @"Share on Instagram",
                                @"Share via Messages",
                                @"Save to Camera Roll",
                                nil];
        sharePopup.tag = 1;
        [sharePopup showInView:[UIApplication sharedApplication].keyWindow];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"There's nothing to share!" message:@"Rub on the camera view to capture portions of the image." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        alertView.tag = 3;
        [alertView show];
    }

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
        NSData *imgData = UIImagePNGRepresentation(_savedPixels.image);
        [composer addAttachmentData:imgData typeIdentifier:(NSString*)kUTTypeMessage filename:@"image.png"];
        [composer setBody:@"Check out the rub I made using Cam Rub!"];
    }
    
    [self animateShare:nil];
    
    [self presentViewController:composer animated:YES completion:nil];
}

- (void) messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) saveImage {
    UIImageWriteToSavedPhotosAlbum(self.savedPixels.image,self,@selector(image:didFinishSavingWithError:contextInfo:),nil);
}

- (void) SLShareImage:(NSString *const)service {
    SLComposeViewController *shareSheet = [SLComposeViewController
                                           composeViewControllerForServiceType:
                                           service];
    
    NSString *message;
    
    if (service == SLServiceTypeFacebook) {
        message = @"Imaged shared to Facebook.";
        [shareSheet setInitialText:@"Check out the rub I made using Cam Rub!"];
    }
    else if (service == SLServiceTypeTwitter) {
        message = @"Imaged shared to Twitter.";
        [shareSheet setInitialText:@"Check out the rub I made using @CamRubApp!"];
    }
    
    if (![shareSheet addImage:_savedPixels.image]) {
        NSLog(@"Unable to add the image!");
    }
    
    shareSheet.completionHandler = ^(SLComposeViewControllerResult result) {
        switch(result) {
            case SLComposeViewControllerResultCancelled:
                break;
            case SLComposeViewControllerResultDone:
                if ([self connected])
                    [self animateShare:message];
                break;
        }
    };
    
    [self presentViewController:shareSheet animated:NO completion:nil];
    
}

- (UIImage*) formatPNG {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(624.0 ,624.0), NO, 0.0 );
    CGRect maskRect = CGRectMake(12.0, 12.0, 600.0, 600.0);
    [[UIColor whiteColor] set];
    UIRectFill(CGRectMake(0.0, 0.0, 624.0, 624.0));
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
        self.dic.annotation = [NSDictionary dictionaryWithObject:@"Check out the rub I made using Cam Rub!"
                                                          forKey:@"InstagramCaption"];
        self.dic.UTI = @"com.instagram.photo";
        
        // OPEN THE HOOK
        CGRect rect = CGRectMake(0.0, 0.0, 0.0, 0.0);
        [self.dic presentOpenInMenuFromRect:rect inView:self.view animated:YES];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Instagram isn't installed!" message:@"Please download the Instagram app to share rubs to Instagram." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
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
    
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         [_savedPixels setFrame:newFrame];
                         
                     } completion:^(BOOL finished) {
                         [_savedPixels setImage:nil];
                         [_savedPixels setFrame:_drawingStrokes.frame];
                         if (successMessage)
                             [self successAlert:successMessage];
                     }];

}

- (void) successAlert:(NSString*)successMessage {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success!" message:successMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    alertView.tag = 4;
    [alertView show];
}

- (void) image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *) contextInfo {
    if(!error) {
        [self animateShare:@"Image saved to camera roll."];
    }
}

-(void) documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application {
    self.savedPixels.image = nil;
    [self drawTapped];
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
        default:
            break;
            
    }
}

@end
