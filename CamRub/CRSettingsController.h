//
//  CRSettingsController.h
//  CamRub
//
//  Created by Nicholas Hall on 8/1/14.
//  Copyright (c) 2014 NDHApps. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CRSettingsController;

@protocol CRSettingsControllerDelegate <NSObject>

<#methods#>

@end

@interface CRSettingsController : UIView {
    BOOL drawingMode;
    CGFloat hue;
    CGFloat value;
}

@property (nonatomic, strong) UIColor *backgroundFillColor;

@property (assign) id <CRSettingsControllerDelegate> delegate;

@end
