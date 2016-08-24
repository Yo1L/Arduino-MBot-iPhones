//
//  BTDiscovery.m
//  Arduino_Servo
//
//  Created by Yoann Le Viavant
//

#import "BTDiscovery.h"


@interface BTDiscovery ()
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *peripheralBLE;		// Connected peripheral
@end

@implementation BTDiscovery

#pragma mark - Lifecycle

+ (instancetype)sharedInstance {
  static BTDiscovery *this = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    this = [[BTDiscovery alloc] init];
  });
  
  return this;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    dispatch_queue_t centralQueue = dispatch_queue_create("com.raywenderlich", DISPATCH_QUEUE_SERIAL);
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:centralQueue options:nil];
    
    self.bleService = nil;
  }
  return self;
}

- (void)startScanning {
    NSLog(@"start scanning");
  //[self.centralManager scanForPeripheralsWithServices:@[RWT_BLE_SERVICE_UUID] options:nil];
  [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}

#pragma mark - Custom Accessors

- (void)setBleService:(BTService *)bleService {
  // Using a setter so the service will be properly started and reset
  if (_bleService) {
    [_bleService reset];
    _bleService = nil;
  }
    
    NSLog(@"setBleService");
  
  _bleService = bleService;
  if (_bleService) {
    [_bleService startDiscoveringServices];
  }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
  // Be sure to retain the peripheral or it will fail during connection.
  
  // Validate peripheral information
  if (!peripheral || !peripheral.name || ([peripheral.name isEqualToString:@""])) {
    return;
  }
    
    NSLog(@"didDiscoverPeripheral %@", peripheral.name);
  
  // If not already connected to a peripheral, then connect to this one
  if (!self.peripheralBLE || (self.peripheralBLE.state == CBPeripheralStateDisconnected)) {
    // Retain the peripheral before trying to connect
    self.peripheralBLE = peripheral;
    
    // Reset service
    self.bleService = nil;
      
      NSLog(@"Oh yeah");
    
    // Connect to peripheral
    [self.centralManager connectPeripheral:peripheral options:nil];
  }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  
  if (!peripheral) {
    return;
  }
    
    NSLog(@"didConnectPeripheral %@", peripheral.name);
  
  // Create new service class
  if (peripheral == self.peripheralBLE) {
    self.bleService = [[BTService alloc] initWithPeripheral:peripheral];
  }
  
  // Stop scanning for new devices
  [self.centralManager stopScan];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  
  if (!peripheral) {
    return;
  }
    
    NSLog(@"didDisconnectPeripheral %@", peripheral.name);
  
  // See if it was our peripheral that disconnected
  if (peripheral == self.peripheralBLE) {
    self.bleService = nil;
    self.peripheralBLE = nil;
  }
    
  // Start scanning for new devices
  [self startScanning];
}

#pragma mark - Private

- (void)clearDevices {
  self.bleService = nil;
  self.peripheralBLE = nil;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
  
  switch (self.centralManager.state) {
    case CBCentralManagerStatePoweredOff:
    {
      [self clearDevices];
      
      break;
    }
      
    case CBCentralManagerStateUnauthorized:
    {
      // Indicate to user that the iOS device does not support BLE.
      break;
    }
      
    case CBCentralManagerStateUnknown:
    {
      // Wait for another event
      break;
    }
      
    case CBCentralManagerStatePoweredOn:
    {
      [self startScanning];
      
      break;
    }
      
    case CBCentralManagerStateResetting:
    {
      [self clearDevices];
      break;
    }
      
    case CBCentralManagerStateUnsupported:
    {
      break;
    }
      
    default:
      break;
  }
  
}

@end
