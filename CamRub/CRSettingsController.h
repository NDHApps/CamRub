//
//  CRSettingsController.h
//  CamRub
//
//  Created by Nicholas Hall on 8/1/14.
//  Copyright (c) 2014 NDHApps. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CRSettingsControllerDelegate;

@interface CRSettingsController : UIView {
    CGFloat hue;
    CGFloat value;
    UIColor *color;
}

- (IBAction)handleCloseButton:(id)sender;

@property (nonatomic, weak) id <CRSettingsControllerDelegate> delegate;

@end

@protocol CRSettingsControllerDelegate <NSObject>

- (void)CRSettingsController:(CRSettingsController*)settingController
                 didSetColor:(UIColor*)fillColor
           didSetDrawingMode:(BOOL)drawingMode;

@end