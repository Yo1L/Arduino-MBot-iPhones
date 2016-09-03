//
//  ViewController.m
//  Arduino-MBot-iPhones
//
//  Created by Yoann on 24/08/16.
//  Copyright © 2016 Yoann Le Viavant. All rights reserved.
//

//
//  MainViewController.m
//  Arduino_Servo
//
//  Created by Yoann Le Viavant
//

#import "ViewController.h"
#import "BTDiscovery.h"
#import "BTService.h"

@interface ViewController ()
@property (strong, nonatomic) AVCaptureSession *captureSession;
@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Set thumb image on slider
  [self.positionSlider setThumbImage:[UIImage imageNamed:@"Bar"] forState:UIControlStateNormal];
  
  // Watch Bluetooth connection
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionChanged:) name:YLT_BLE_SERVICE_CHANGED_STATUS_NOTIFICATION object:nil];
  // Watch Read returns from Bluetooth
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothRead:) name:YLT_BLE_SERVICE_READ_STATUS_NOTIFICATION object:nil];
  
  // Start the Bluetooth discovery process
  [BTDiscovery sharedInstance];
  
  // init MCSession
  self.mcPeerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
  self.mcSession = [[MCSession alloc] initWithPeer:self.mcPeerID];
  self.mcSession.delegate = self;
  
  self.mcAdvertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:kMCServiceType discoveryInfo:nil session:self.mcSession];
  [self.mcAdvertiser start];
  
  [self toggleCamera:YES];
}

- (void)toggleCamera:(Boolean)on {
  if( !self.captureSession ) {
    // Create the AVCaptureSession
    self.captureSession = [[AVCaptureSession alloc] init];
    
    [self.captureSession setSessionPreset:AVCaptureSessionPresetHigh];
    
    // Create video device input
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (videoDevice) {
      NSError *error = nil;
      AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
      if( !videoDeviceInput ) {
        NSLog(@"Error %@", error);
        return;
      }
      
      [self.captureSession addInput:videoDeviceInput];
      
      // Create output
      AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
      
      dispatch_queue_t queue = dispatch_queue_create("com.idbrothers.frames", DISPATCH_QUEUE_SERIAL);
      [output setSampleBufferDelegate:self queue:queue];
      [output setAlwaysDiscardsLateVideoFrames:YES];
      
      [self.captureSession addOutput:output];
    } else {
      UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"No video device" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      [alert show];
    }
  }
  
  if( on == NO ) {
    [UIApplication sharedApplication].idleTimerDisabled = NO; // reenable sleeping mode
    [self.captureSession stopRunning];
  }
  else {
    [UIApplication sharedApplication].idleTimerDisabled = YES; // avoid sleeping mode
    [self.captureSession startRunning];
  }
}

- (UIImage*) cgImageBackedImageWithCIImage:(CIImage*) ciImage {
  CIContext *context = [CIContext contextWithOptions:nil];
  CGImageRef ref = [context createCGImage:ciImage fromRect:ciImage.extent];
  UIImage* image = [UIImage imageWithCGImage:ref scale:[UIScreen mainScreen].scale orientation:UIImageOrientationRight];
  CGImageRelease(ref);
  
  return image;
}

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  if (self.mcSession.connectedPeers.count) {
    NSNumber* timestamp = @(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)));
    
    CVImageBufferRef cvImage = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:cvImage];
    UIImage* cgBackedImage = [self cgImageBackedImageWithCIImage:ciImage];
    
    NSData *imageData = UIImageJPEGRepresentation(cgBackedImage, 0.2);
    
    // maybe not always the correct input?  just using this to send current FPS...
    AVCaptureInputPort* inputPort = connection.inputPorts[0];
    AVCaptureDeviceInput* deviceInput = (AVCaptureDeviceInput*) inputPort.input;
    CMTime frameDuration = deviceInput.device.activeVideoMaxFrameDuration;
    NSDictionary* dict = @{
                           @"image": imageData,
                           @"timestamp" : timestamp,
                           @"framesPerSecond": @(frameDuration.timescale)
                           };
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    
    
    [self.mcSession sendData:data toPeers:self.mcSession.connectedPeers withMode:MCSessionSendDataReliable error:nil];
  }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:YLT_BLE_SERVICE_CHANGED_STATUS_NOTIFICATION object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:YLT_BLE_SERVICE_READ_STATUS_NOTIFICATION object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [self toggleCamera:NO];
  [self.mcSession disconnect];
}

#pragma mark - IBActions

- (IBAction)positionSliderChanged:(UISlider *)sender {
  // Since the slider value range is from 0 to 180, it can be sent directly to the Arduino board
  [self sendPosition:(uint8_t)sender.value];
}

- (IBAction)runSwitchChanged:(UISwitch *)sender {
  //NSString *command = [NSString stringWithFormat:@"run:%d", self.runSwitch.on == YES ? 1 : 0];
  [self sendRun:self.runSwitch.on];
}

- (IBAction)directionChanged:(id)sender {
  [self sendDirection:[sender tag]];
}

- (IBAction)directionStop:(id)sender {
  [self sendDirection:0];
}

- (IBAction)toggleMCAdvertiser:(id)sender {
  [self toggleCamera:self.advertiserSwitch.on];
  
  if( self.advertiserSwitch.on ) {
    [self.mcAdvertiser start];
  }
  else {
    [self.mcAdvertiser stop];
    
    // MCBrowser
    MCBrowserViewController *browserVC = [[MCBrowserViewController alloc] initWithServiceType:kMCServiceType session:self.mcSession];
    browserVC.delegate = self;
    [self presentViewController:browserVC animated:YES completion:nil];
  }
}

#pragma mark - MultiPeer delegates

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
  [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
  [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
  if( state == MCSessionStateConnected ) {
    NSLog(@"peer %@ connected", [peerID displayName]);
  }
  else if( state == MCSessionStateNotConnected ) {
    NSLog(@"peer %@ not connected", [peerID displayName]);
  }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
  static Float64 lastTimestamp = 0;
  NSDictionary* dict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
  
  // the timestamp of this frame
  NSNumber* timestamp = dict[@"timestamp"];
  if( lastTimestamp > timestamp.floatValue ) {
    // discard older frame
    return;
  }
  
  lastTimestamp = timestamp.floatValue;
  
  // the actual image data (as JPG)
  dispatch_async(dispatch_get_main_queue(), ^{
    self.bgImageView.image = [UIImage imageWithData:dict[@"image"]];
    [self.bgImageView setNeedsDisplay];
  });
  
  // the current FPS
  //NSNumber* framesPerSecond = dict[@"framesPerSecond"];
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
}

#pragma mark - Private

- (void)connectionChanged:(NSNotification *)notification {
  // Connection status changed. Indicate on GUI.
  BOOL isConnected = [(NSNumber *) (notification.userInfo)[@"isConnected"] boolValue];
  NSLog(@"connected %@", isConnected == YES ? @"YES" : @"NO");
  
  dispatch_async(dispatch_get_main_queue(), ^{
    // Set image based on connection status
    self.imgBluetoothStatus.image = isConnected ? [UIImage imageNamed:@"Bluetooth_Connected"]: [UIImage imageNamed:@"Bluetooth_Disconnected"];
    
    if (isConnected) {
      // Send current slider position
      [self sendDirection:0];
      [self sendPosition:(uint8_t)self.positionSlider.value];
      [self sendRun:self.runSwitch.on];
    }
  });
}

- (void)bluetoothRead:(NSNotification *)notification {
  Byte data[2];
  [(NSData *)notification.userInfo[@"data"] getBytes:data length:2];
  
  
  NSLog(@"bluetoothRead Return %u %u", data[0], data[1]);
}

#pragma mark - Arduino bluetooth commands

- (void)sendRun:(Boolean)status {
  Byte command[2] = { 0x80 | 0x1, status == YES ? 1 : 0 };
  [self sendCommand:command];
}

- (void)sendPosition:(uint8_t)position {
  Byte command[2] = { 0x80 | 0x2, position };
  [self sendCommand:command];
}

- (void)sendDirection:(uint8_t)direction {
  Byte command[2] = { 0x80 | 0x4, direction };
  [self sendCommand:command];
}

- (void)sendCommand:(Byte *)command {
  if( [BTDiscovery sharedInstance].bleService ) {
    NSLog(@"sendCommand: %d with value: %d", command[0], command[1]);
    [[BTDiscovery sharedInstance].bleService write:[NSData dataWithBytes:command length:2]];
  }
}
@end
