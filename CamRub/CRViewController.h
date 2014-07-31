//
//  CRViewController.h
//  CamRub
//
//  Created by Nicholas Hall on 7/16/14.
//  Copyright (c) 2014 NDHApps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CaptureSessionManager.h"

@interface CRViewController : UIViewController {
    
    CGPoint lastPoint;
    CGFloat brush;
    CGFloat alpha;
    BOOL mouseSwiped;
}

@property (retain) CaptureSessionManager *captureManager;
@property (nonatomic, retain) UILabel *scanningLabel;

@end