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
@property (nonatomic, weak) IBOutlet UISwitch *drawingMode;
@property (nonatomic, weak) IBOutlet UISwitch *alphaEffect;
@property (nonatomic, weak) IBOutlet UISlider *hueSlider;
@property (nonatomic, weak) IBOutlet UISlider *valueSlider;

- (IBAction) hueSliderChanged: (id)sender;
- (IBAction) valueSliderChanged: (id)sender;

@end

@implementation CRSettingsController

- (id)initWithFrame:(CGRect)frame {
    
    self = [self loadNibWithFrame:frame];
    
    if (self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults synchronize];
        self.drawingMode.on = [defaults boolForKey:@"drawingMode"];
        self.alphaEffect.on = [defaults boolForKey:@"alphaEffect"];
        self.hueSlider.value = hue = [defaults doubleForKey:@"hue"] - 0.1;
        self.valueSlider.value = value = [defaults doubleForKey:@"value"] - 1.0;
        [self updateColor];
    }
    
    return self;
}

- (CRSettingsController*) loadNibWithFrame:(CGRect)frame {
    NSArray * subviewArray = [[NSBundle mainBundle] loadNibNamed:@"CRSettingsView" owner:self options:nil];
    CRSettingsController* view = [subviewArray objectAtIndex:0];
    view.frame = frame;
    return view;
}

- (IBAction) hueSliderChanged: (id)sender {
    hue = ((UISlider *)sender).value;
    [self updateColor];
}

- (IBAction) valueSliderChanged: (id)sender {
    value = ((UISlider *)sender).value;
    [self updateColor];
}

- (IBAction) handleCloseButton:(id)sender {

    id<CRSettingsControllerDelegate> strongDelegate = self.delegate;
    
    if ([strongDelegate respondsToSelector:@selector(CRSettingsController:didSetColor:didSetDrawingMode:didSetAlphaEffect:)])
        [strongDelegate CRSettingsController:self didSetColor:color didSetDrawingMode:_drawingMode.on didSetAlphaEffect:_alphaEffect.on];
    
    // Save settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:(hue+0.1) forKey:@"hue"];
    [defaults setDouble:(value+1.0) forKey:@"value"];
    [defaults setBool:_drawingMode.on forKey:@"drawingMode"];
    [defaults setBool:_alphaEffect.on forKey:@"alphaEffect"];
    [defaults synchronize];    
}

- (void) updateColor {
    
    CGFloat h = hue;
    CGFloat s;
    CGFloat b;
    
    if (hue < 0) {
        h = s = 0.0;
        b = 1.0 - ((value + 1.0) / 2.0);
    } else if (value < 0) {
        s = value + 1.0;
        b = 1.0;
    } else {
        s = 1.0;
        b = 1.0 - value;
    }
    
    color = [UIColor colorWithHue:h saturation:s brightness:b alpha:1.0];
    
    [_colorPreview setBackgroundColor:color];
    
}


- (IBAction) resetSettings {
    hue = -0.1;
    value = -1.0;
    _drawingMode.on = NO;
    _alphaEffect.on = NO;
    
    // Reset settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:0.0 forKey:@"hue"];
    [defaults setDouble:0.0 forKey:@"value"];
    [defaults setBool:NO forKey:@"drawingMode"];
    [defaults setBool:NO forKey:@"alphaEffect"];
    [defaults synchronize];
    
    [self.drawingMode setOn: _drawingMode.on animated:YES];
    [self.alphaEffect setOn: _alphaEffect.on animated:YES];
    [self.hueSlider setValue: hue animated:YES];
    [self.valueSlider setValue: value animated:YES];
    [self updateColor];

    
}


@end
