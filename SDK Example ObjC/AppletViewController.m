//
//  ViewController.m
//  SDK Example ObjC
//
//  Created by Jon Chmura on 8/31/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

#import "AppletViewController.h"
#import <IFTTT_SDK/IFTTT_SDK.h>

@interface AppletViewController ()

@property (strong, nonatomic) IFTTTApplet *applet;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end

@implementation AppletViewController

- (void)setApplet:(IFTTTApplet *)applet {
    _applet = applet;
    if (self.isViewLoaded) {
        [self configureWithApplet:applet];
    }
}

- (void)configureWithApplet:(IFTTTApplet *)applet {
    self.titleLabel.text = applet.name;
    self.descriptionLabel.text = applet.appletDescription;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.applet != nil) {
        [self configureWithApplet:self.applet];
    }
}

@end
