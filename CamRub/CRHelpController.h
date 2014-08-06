//
//  CRHelpController.h
//  CamRub
//
//  Created by Nicholas Hall on 8/5/14.
//  Copyright (c) 2014 NDHApps. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CRHelpControllerDelegate;

@interface CRHelpController : UIView

@property (nonatomic, weak) id <CRHelpControllerDelegate> delegate;

@end

@protocol CRHelpControllerDelegate <NSObject>

- (void)CRHelpController:(CRHelpController*)helpController;

@end