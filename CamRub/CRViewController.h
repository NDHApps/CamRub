//
//  CRViewController.h
//  CamRub
//
//  Created by Nicholas Hall on 7/16/14.
//  Copyright (c) 2014 NDHApps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CaptureSessionManager.h"
#import <MessageUI/MFMessageComposeViewController.h>
#import "CRSettingsController.h"

@interface CRViewController : UIViewController <UIActionSheetDelegate, UIDocumentInteractionControllerDelegate, MFMessageComposeViewControllerDelegate, CRSettingsControllerDelegate> {
    
    CGPoint lastPoint;
    CGFloat brush;
    CGFloat drawSize;
    CGFloat eraseSize;
    CGFloat color;
    CGFloat alpha;
    UIColor *backgroundFillColor;
    
    BOOL mouseSwiped;
    BOOL drawToolSelected; // Otherwise Erase
    BOOL drawInFront;
}

@property (retain) CaptureSessionManager *captureManager;
@property BOOL isFrontCameraSelected;

@end