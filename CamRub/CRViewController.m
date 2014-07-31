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
@property (nonatomic, weak) IBOutlet UIButton *shareButton;

@property (nonatomic) UIImagePickerController *imagePickerController;

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
        [self showCustomImagePicker];
    }

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
    [self.pixelMask drawInRect:CGRectMake(0, 0, self.savedPixels.frame.size.width, self.savedPixels.frame.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    [self.drawingStrokes.image drawInRect:CGRectMake(0, 0, self.drawingStrokes.frame.size.width, self.drawingStrokes.frame.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    self.pixelMask = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.imagePickerController takePicture];
}

- (void)showCustomImagePicker
{
    if (self.cameraFrame.isAnimating)
    {
        [self.cameraFrame stopAnimating];
    }
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.delegate = self;
    imagePickerController.showsCameraControls = NO;
    imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGFloat scaleFactor = 300.0/screenSize.width;
    CGFloat translation = screenSize.height - 284.0 - (200.0/scaleFactor);
    imagePickerController.cameraViewTransform = CGAffineTransformTranslate(CGAffineTransformMakeScale(scaleFactor, 1.0), 0.0, translation);
        /*
         Load the overlay view from the OverlayView nib file. Self is the File's Owner for the nib file, so the overlayView outlet is set to the main view in the nib. Pass that view to the image picker controller to use as its overlay view, and set self's reference to the view to nil.
         */
    [[NSBundle mainBundle] loadNibNamed:@"CRCameraOverlayView" owner:self options:nil];
    self.overlayView.frame = [[UIScreen mainScreen] bounds];
    [self.overlayView setUserInteractionEnabled:YES];
    imagePickerController.cameraOverlayView = self.overlayView;
    self.overlayView = nil;
    self.imagePickerController = imagePickerController;
    
    UIDevice *currentDevice = [UIDevice currentDevice];
    
    while ([currentDevice isGeneratingDeviceOrientationNotifications])
        [currentDevice endGeneratingDeviceOrientationNotifications];
    
    [self.view addSubview:self.imagePickerController.view];
    
    while ([currentDevice isGeneratingDeviceOrientationNotifications])
        [currentDevice endGeneratingDeviceOrientationNotifications];
   
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage * chosenImage = [info objectForKey: UIImagePickerControllerOriginalImage];
    
    CGFloat imageWidth  = chosenImage.size.width;
    CGFloat imageHeight = chosenImage.size.height;
    
    CGRect cropRect = CGRectMake ((imageHeight - imageWidth) / 2.0, 0.0, imageWidth, imageWidth);
    
    // Draw new image in current graphics context
    CGImageRef imageRef = CGImageCreateWithImageInRect ([chosenImage CGImage], cropRect);
    
    // Create new cropped UIImage
    UIImage *croppedImage = [UIImage imageWithCGImage: imageRef scale: imageWidth / 300.0 orientation: UIImageOrientationRight];
    
    UIImage *maskedImage = [self addStrokesToImage:croppedImage];
    
    [_savedPixels setImage:maskedImage];
    
    self.drawingStrokes.image = nil;
    
}

- (UIImage*) addStrokesToImage:(UIImage*)image {
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(300.0,300.0), NO, 0.0 );
    
    CGRect maskRect = CGRectMake(0.0, 0.0, 300.0, 300.0);
    [[UIColor whiteColor] set];
    UIRectFill(CGRectMake(0.0, 0.0, 300.0, 300.0));
    [_pixelMask drawInRect:maskRect];
    
    UIImage* mask = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRef maskRef = mask.CGImage;

    CGImageRef CGMask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
	CGImageRef masked = CGImageCreateWithMask([image CGImage], CGMask);
    
    return [UIImage imageWithCGImage:masked];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
