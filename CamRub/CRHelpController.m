//
//  CRHelpController.m
//  CamRub
//
//  Created by Nicholas Hall on 8/5/14.
//  Copyright (c) 2014 NDHApps. All rights reserved.
//

#import "CRHelpController.h"

@implementation CRHelpController

- (id)initWithFrame:(CGRect)frame
{
    self = [self loadNibWithFrame:frame];
    
    if (self) {
        // Initialization code
    }
    
    return self;
}

- (CRHelpController*) loadNibWithFrame:(CGRect)frame {
    NSArray * subviewArray = [[NSBundle mainBundle] loadNibNamed:@"CRHelpView" owner:self options:nil];
    CRHelpController* view = [subviewArray objectAtIndex:0];
    view.frame = frame;
    return view;
}

- (IBAction) handleCloseButton:(id)sender {
    id<CRHelpControllerDelegate> strongDelegate = self.delegate;
    
    if ([strongDelegate respondsToSelector:@selector(CRHelpController:)])
        [strongDelegate CRHelpController:self];
    
}

- (IBAction) emailButtonPressed {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:NDHApps@gmail.com"]];
}

- (IBAction) webButtonPressed {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://NDHApps.com"]];
}

- (IBAction) facebookButtonPressed {
    if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"fb://profile/262158193993200"]])
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.facebook.com/CamRub"]];
}

- (IBAction) twitterButtonPressed {
    if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=CamRubApp"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/CamRubApp"]];
}

@end
