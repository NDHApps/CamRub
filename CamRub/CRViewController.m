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
@property (nonatomic, weak) IBOutlet UIImageView *drawingStrokes;
@property (nonatomic, weak) IBOutlet UIView *overlayView;
@property (nonatomic, weak) IBOutlet UIButton *clearButton;
@property (nonatomic, weak) IBOutlet UIButton *drawButton;
@property (nonatomic, weak) IBOutlet UIButton *eraseButton;
@property (nonatomic, weak) IBOutlet UIButton *share;

- (void) IBAction clearImage;

@end

@implementation CRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    brush = 25.0;
    alpha = 1.0;
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CamRub needs a camera!" message:@"Please try CamRub on another camera-enabled device." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    mouseSwiped = NO;
    UITouch *touch = [touches anyObject];
    lastPoint = [touch locationInView:self.drawingStrokes];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    mouseSwiped = YES;
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self.drawingStrokes];
    
    UIGraphicsBeginImageContext(self.drawingStrokes.frame.size);
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
        UIGraphicsBeginImageContext(self.drawingStrokes.frame.size);
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
    
    UIGraphicsBeginImageContext(self.savedPixels.frame.size);
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
    [self.overlayView setUserInteractionEnabled:YES];
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
    
    // Create new cropped UIImage
    UIImage *croppedImage = [self rotate:[UIImage imageWithCGImage: imageRef scale: 0.9375 * imageWidth / 600.0 orientation: UIImageOrientationRight]];
    
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
	CGImageRef masked = CGImageCreateWithMask([croppedImage CGImage], CGMask);
    
    UIImage *maskedImage = [UIImage imageWithCGImage:masked];
    
    UIGraphicsBeginImageContext(self.savedPixels.frame.size);
    [self.savedPixels.image drawInRect:CGRectMake(0, 0, self.savedPixels.frame.size.width, self.savedPixels.frame.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    [maskedImage drawInRect:CGRectMake(0, 0, self.savedPixels.frame.size.width, self.savedPixels.frame.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    self.savedPixels.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    self.pixelMask = nil;
    self.drawingStrokes.image = nil;
    
}

-(UIImage*) rotate:(UIImage*) src {
    
    UIImageOrientation orientation = src.imageOrientation;
    
    UIGraphicsBeginImageContext(src.size);
    
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

@end
