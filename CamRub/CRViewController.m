//
//  CRViewController.m
//  CamRub
//
//  Created by Nicholas Hall on 7/16/14.
//  Copyright (c) 2014 NDHApps. All rights reserved.
//

#import "CRViewController.h"

@interface CRViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *cameraFrame;
@property (nonatomic, weak) IBOutlet UIImageView *savedPixels;
@property (nonatomic, strong) UIImage *pixelMask;

@property (nonatomic, weak) IBOutlet UIView *brushSelectorView;
@property (nonatomic, weak) IBOutlet UIView *brushPreview;
@property (nonatomic, weak) IBOutlet UIView *eraseBrushSelectorView;
@property (nonatomic, weak) IBOutlet UIView *eraseBrushPreview;
@property (nonatomic, weak) IBOutlet UIView *selectorBackground;
@property (nonatomic, weak) IBOutlet UIImageView *drawingStrokes;
@property (nonatomic, weak) IBOutlet UIView *overlayView;
@property (nonatomic, weak) IBOutlet UIButton *clearButton;
@property (nonatomic, weak) IBOutlet UIButton *drawButton;
@property (nonatomic, weak) IBOutlet UIButton *eraseButton;
@property (nonatomic, weak) IBOutlet UIButton *shareButton;
@property (nonatomic, weak) IBOutlet UIImageView *drawIndicator;
@property (nonatomic, weak) IBOutlet UIImageView *eraseIndicator;

- (IBAction) sliderChanged: (id)sender;
- (IBAction) eraseSliderChanged: (id)sender;
- (IBAction) clearImage;
- (IBAction) drawTapped;
- (IBAction) drawPressed;
- (IBAction) eraseTapped;
- (IBAction) erasePressed;
- (IBAction) shareImage;
- (IBAction) dismissBrushSelectors;

@end

@implementation CRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    brush = 30.0;
    eraser = 30.0;
    alpha = 1.0;
    
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

- (IBAction)sliderChanged:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    float val = slider.value * 40.0 + 10;
    brush = val;
    _brushPreview.transform = CGAffineTransformScale(CGAffineTransformIdentity, val/50.0, val/50.0);
}

- (IBAction)eraseSliderChanged:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    float val = slider.value * 40.0 + 10;
    eraser = val;
    _eraseBrushPreview.transform = CGAffineTransformScale(CGAffineTransformIdentity, val/50.0, val/50.0);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    mouseSwiped = NO;
    UITouch *touch = [touches anyObject];
    lastPoint = [touch locationInView:self.drawingStrokes];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    mouseSwiped = YES;
    drawToolSelected = YES;
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self.drawingStrokes];
    
    UIGraphicsBeginImageContextWithOptions(self.drawingStrokes.frame.size, NO, 0.0);
    [self.drawingStrokes.image drawInRect:CGRectMake(0, 0, self.drawingStrokes.frame.size.width, self.drawingStrokes.frame.size.height)];
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), brush );
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.0, 0.0, 0.0, 1.0);
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
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.0, 0.0, 0.0, alpha);
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
    [_captureManager captureStillImage];
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
    CGImageRef maskRef = mask.CGImage;
    CGImageRef CGMask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
	maskRef = CGImageCreateWithMask([capturedImage CGImage], CGMask);
    
    capturedImage = [UIImage imageWithCGImage:maskRef];
    maskRef = CGMask = nil;
    
    UIGraphicsBeginImageContextWithOptions(self.savedPixels.frame.size, NO, 0.0);
    [self.savedPixels.image drawInRect:CGRectMake(0, 0, self.savedPixels.frame.size.width, self.savedPixels.frame.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    [capturedImage drawInRect:CGRectMake(0, 0, self.savedPixels.frame.size.width, self.savedPixels.frame.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    self.savedPixels.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    self.pixelMask = nil;
    self.drawingStrokes.image = nil;
    
}

-(UIImage*) rotate:(UIImage*) src {
    
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
    if(_savedPixels.image) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure you want to clear the canvas?" message:@"All rubbing will be lost." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes",nil];
        alertView.tag = 2;
        [alertView show];
    }
}

- (IBAction) drawTapped {
    drawToolSelected = YES;
    [_drawIndicator setHidden:NO];
    [_eraseIndicator setHidden:YES];
    [self dismissBrushSelectors];
}

- (IBAction) eraseTapped {
    drawToolSelected = NO;
    [_eraseIndicator setHidden:NO];
    [_drawIndicator setHidden:YES];
    [self dismissBrushSelectors];
}

- (IBAction) drawPressed {
    drawToolSelected = YES;
    [_drawIndicator setHidden:NO];
    [_eraseIndicator setHidden:YES];
    [_eraseBrushSelectorView setHidden:YES];
    [_brushSelectorView setHidden:NO];
    [_selectorBackground setHidden:NO];
}

- (IBAction) erasePressed {
    drawToolSelected = NO;
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
        alertView.tag = 4;
        [alertView show];
    }

}

- (void) actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (popup.tag) {
        case 1: {
            switch (buttonIndex) {
                case 0:
//                    [self FBShare];
                    break;
                case 1:
//                    [self TwitterShare];
                    break;
                case 2:
//                    [self InstagramShare];
                    break;
                case 3:
//                    [self MessagesShare];
                    break;
                case 4:
                    UIImageWriteToSavedPhotosAlbum(self.savedPixels.image,self,@selector(image:didFinishSavingWithError:contextInfo:),nil);
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

- (void) animateShare:(SEL)selectorWhenComplete {
    CGRect newFrame = _shareButton.frame;
    newFrame.size.height = newFrame.size.width;
    
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         [_savedPixels setFrame:newFrame];
                         
                     } completion:^(BOOL finished) {
                         [_savedPixels setImage:nil];
                         [_savedPixels setFrame:_drawingStrokes.frame];
                         ((void (*)(id, SEL))[self methodForSelector:selectorWhenComplete])(self, selectorWhenComplete);
                     }];

}

- (void) successAlert {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"Image saved to camera roll." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    alertView.tag = 3;
    [alertView show];
    
}

- (void) image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *) contextInfo {
    if(!error) {
        [self animateShare:@selector(successAlert)];
    }
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case 1:
            if (buttonIndex == 0)
                exit(0);
            break;
        case 2:
            if (buttonIndex == 1)
                self.savedPixels.image = nil;
            break;
        default:
            break;
            
    }
}

@end
