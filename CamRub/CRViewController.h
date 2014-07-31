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

@interface CRViewController : UIViewController <UIActionSheetDelegate, UIDocumentInteractionControllerDelegate, MFMessageComposeViewControllerDelegate> {
    
    CGPoint lastPoint;
    CGFloat brush;
    CGFloat drawSize;
    CGFloat eraseSize;
    CGFloat color;
    CGFloat alpha;
    BOOL mouseSwiped;
    BOOL drawToolSelected; // Otherwise Erase
}

@property (retain) CaptureSessionManager *captureManager;

@end