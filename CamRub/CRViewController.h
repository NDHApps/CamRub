//
//  CRViewController.h
//  CamRub
//
//  Created by Nicholas Hall on 7/16/14.
//  Copyright (c) 2014 NDHApps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CaptureSessionManager.h"

@interface CRViewController : UIViewController <UIActionSheetDelegate> {
    
    CGPoint lastPoint;
    CGFloat brush;
    CGFloat eraser;
    CGFloat alpha;
    BOOL mouseSwiped;
    BOOL drawToolSelected; // Otherwise Erase
}

@property (retain) CaptureSessionManager *captureManager;
@property (nonatomic, retain) UILabel *scanningLabel;

@end