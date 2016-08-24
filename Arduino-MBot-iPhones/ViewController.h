//
//  ViewController.h
//  Arduino-MBot-iPhones
//
//  Created by Yoann on 24/08/16.
//  Copyright © 2016 Yoann Le Viavant. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <AVFoundation/AVFoundation.h>

#define kMCServiceType @"ylt-streaming"

@interface ViewController : UIViewController <MCSessionDelegate, MCBrowserViewControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imgBluetoothStatus;
@property (weak, nonatomic) IBOutlet UISlider *positionSlider;
@property (weak, nonatomic) IBOutlet UISwitch *runSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *advertiserSwitch;
@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;
@property (strong, nonatomic) MCPeerID *mcPeerID;
@property (strong, nonatomic) MCSession *mcSession;
@property (nonatomic, strong) MCBrowserViewController *mcBrowser;
@property (nonatomic, strong) MCAdvertiserAssistant *mcAdvertiser;


- (void)toggleCamera:(Boolean)on;
- (IBAction)positionSliderChanged:(UISlider *)sender;
- (IBAction)runSwitchChanged:(UISwitch *)sender;
- (IBAction)directionChanged:(id)sender;
- (IBAction)directionStop:(id)sender;
- (IBAction)toggleMCAdvertiser:(id)sender;
@end

