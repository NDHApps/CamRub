//
//  CRSettingsController.m
//  CamRub
//
//  Created by Nicholas Hall on 8/1/14.
//  Copyright (c) 2014 NDHApps. All rights reserved.
//

#import "CRSettingsController.h"

@interface CRSettingsController ()

@property (nonatomic, weak) IBOutlet UIView *colorPreview;

- (IBAction) hueSliderChanged: (id)sender;
- (IBAction) valueSliderChanged: (id)sender;
- (IBAction) switchChanged: (id)sender;
- (IBAction) dismissView;

@end

@implementation CRSettingsController

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self loadNib];
        hue = -0.1;
        value = -1.0;
        
    }
    return self;
}
- (void) loadNib {
    NSArray * subviewArray = [[NSBundle mainBundle] loadNibNamed:@"CRSettingsView" owner:self options:nil];
    UIView * mainView = [subviewArray objectAtIndex:0];

    [self addSubview:mainView];
}

- (IBAction) hueSliderChanged: (id)sender {
    hue = ((UISlider *)sender).value;
    [self updateColor];
}

- (IBAction) valueSliderChanged: (id)sender {
    value = ((UISlider *)sender).value;
    [self updateColor];
}

- (IBAction) switchChanged: (id)sender {
    drawingMode = ((UISwitch*)sender).on;
}

- (IBAction) dismissView {
    [self removeFromSuperview];
}

- (void) updateColor {
    
    CGFloat h = hue;
    CGFloat s;
    CGFloat b;
    
    if (hue < 0) {
        h = 0.0;
        s = 0.0;
        b = 1.0 - ((value + 1.0) / 2.0);
    } else if (value < 0) {
        s = value + 1.0;
        b = 1.0;
    } else {
        s = 1.0 - value;
    }
    
    _backgroundFillColor = [UIColor colorWithHue:h saturation:s brightness:b alpha:1.0];
    
    [_colorPreview setBackgroundColor:_backgroundFillColor];
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
