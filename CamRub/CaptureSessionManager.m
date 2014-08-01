#import "CaptureSessionManager.h"
#import <ImageIO/ImageIO.h>

@implementation CaptureSessionManager

- (id)init {
	if ((self = [super init])) {
        self.frontCameraInUse = NO;
		[self setCaptureSession:[[AVCaptureSession alloc] init]];
	}
	return self;
}

- (void)addVideoPreviewLayer {
	[self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:[self captureSession]]];
	[[self previewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
  
}

- (void)addVideoInput {
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *device in devices) {
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack)
                backCamera = device;
        }
    }
    
    NSError *error = nil;
    
    AVCaptureDeviceInput *backFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
    if (!error) {
        if ([[self captureSession] canAddInput:backFacingCameraDeviceInput]) {
            [[self captureSession] addInput:backFacingCameraDeviceInput];
            self.frontCameraInUse = NO;
        }
    }
}

- (void)addStillImageOutput
{
    [self setStillImageOutput:[[AVCaptureStillImageOutput alloc] init]];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    [[self stillImageOutput] setOutputSettings:outputSettings];
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in [[self stillImageOutput] connections]) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    
    [[self captureSession] addOutput:[self stillImageOutput]];
}

- (void)captureStillImage
{
	AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in [[self stillImageOutput] connections]) {
		for (AVCaptureInputPort *port in [connection inputPorts]) {
			if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) {
            break;
        }
	}
    
	[[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:videoConnection
                                                         completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
                                                             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                                                             UIImage *image = [[UIImage alloc] initWithData:imageData];
                                                             [self setStillImage:image];
                                                             [[NSNotificationCenter defaultCenter] postNotificationName:kImageCapturedSuccessfully object:nil];
                                                         }];
}

-(void)toggleCamera {
    
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *device in devices) {
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack)
                backCamera = device;
            else
                frontCamera = device;
        }
    }
    
    NSError *error = nil;
    
    if(!_frontCameraInUse) {
        if (frontCamera) {
            [[self captureSession] removeInput:[[self captureSession].inputs objectAtIndex:0]];
            AVCaptureDeviceInput *frontFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
            if (!error) {
                if ([[self captureSession] canAddInput:frontFacingCameraDeviceInput]) {
                    [[self captureSession] addInput:frontFacingCameraDeviceInput];
                    self.frontCameraInUse = YES;
                }
            }
        }
    } else {
        [[self captureSession] removeInput:[[self captureSession].inputs objectAtIndex:0]];
        AVCaptureDeviceInput *backFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        if (!error) {
            if ([[self captureSession] canAddInput:backFacingCameraDeviceInput]) {
                [[self captureSession] addInput:backFacingCameraDeviceInput];
                self.frontCameraInUse = NO;
            }
        }
    }
    
}
@end
