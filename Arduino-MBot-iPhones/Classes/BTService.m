//
//  BTService.m
//  Arduino_Servo
//
//  Created by Yoann Le Viavant
//

#import "BTService.h"


@interface BTService()
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) CBCharacteristic *writeCharacteristic;
@property (strong, nonatomic) CBCharacteristic *readCharacteristic;
@property (strong, nonatomic) NSArray *characteristicList;
@end

@implementation BTService

#pragma mark - Lifecycle

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral {
  self = [super init];
  if (self) {
    self.peripheral = peripheral;
    [self.peripheral setDelegate:self];
  }
  return self;
}

- (void)dealloc {
  [self reset];
}

- (void)startDiscoveringServices {
  self.characteristicList = @[kTransDataCharateristicUUID, kTransDataDualCharateristicUUID, kNofityDataCharateristicUUID, kNofityDataDualCharateristicUUID];
  [self.peripheral discoverServices:nil];
}

- (void)reset {
  
  if (self.peripheral) {
    self.peripheral = nil;
  }
  
  // Deallocating therefore send notification
  [self sendBTServiceNotificationWithIsBluetoothConnected:NO];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
  NSArray *services = nil;
  
  if (peripheral != self.peripheral) {
    NSLog(@"Wrong Peripheral.\n");
    return ;
  }
  
  if (error != nil) {
    NSLog(@"Error %@\n", error);
    return ;
  }
  
  services = [peripheral services];
  if (!services || ![services count]) {
    NSLog(@"No Services");
    return ;
  }
    
  
  for (CBService *service in services) {
    NSLog(@"Service: %@", service.UUID.UUIDString);
    [peripheral discoverCharacteristics:self.characteristicList forService:service];
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
  NSArray     *characteristics    = [service characteristics];
  
  if (peripheral != self.peripheral) {
    //NSLog(@"Wrong Peripheral.\n");
    return ;
  }
  
  if (error != nil) {
    //NSLog(@"Error %@\n", error);
    return ;
  }
    
  if( ![characteristics count]) {
    NSLog(@"No characteristics");
    return;
  }
  
  NSLog(@"didDiscoverCharacteristicsForService");
  
  for (CBCharacteristic *characteristic in characteristics) {
    NSLog(@"characteristic: %@", characteristic.UUID.UUIDString);
    
    if ([[characteristic UUID] isEqual:kTransDataDualCharateristicUUID] || [[characteristic UUID] isEqual:kTransDataCharateristicUUID]) {
      self.writeCharacteristic = characteristic;
    }
    else if ([[characteristic UUID] isEqual:kNofityDataCharateristicUUID] || [[characteristic UUID] isEqual:kNofityDataDualCharateristicUUID]) {
      [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
      self.readCharacteristic = characteristic;
    }
  }
  
  if( self.writeCharacteristic && self.readCharacteristic ) {
    [self sendBTServiceNotificationWithIsBluetoothConnected:YES];
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  if( error ) {
    NSLog(@"Error %@", error);
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
  [self read:characteristic.value];
}

#pragma mark - Private

- (void)write:(NSData *)data {
  if( !self.writeCharacteristic ) {
    NSLog(@"No write characteristic");
    return;
  }
  
  NSLog(@"Sending data with char: %@", self.writeCharacteristic.UUID.UUIDString);
  
  [self.peripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

- (void)read:(NSData *)data {
  if( !data.length ) {
    return;
  }
  
  NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  NSLog(@"BT Return %@", str);
}

- (BOOL)isDual {
  return self.writeCharacteristic && [self.writeCharacteristic isEqual:kTransDataDualCharateristicUUID];
}

- (void)sendBTServiceNotificationWithIsBluetoothConnected:(BOOL)isBluetoothConnected {
  NSDictionary *connectionDetails = @{@"isConnected": @(isBluetoothConnected)};
  [[NSNotificationCenter defaultCenter] postNotificationName:RWT_BLE_SERVICE_CHANGED_STATUS_NOTIFICATION object:self userInfo:connectionDetails];
}

@end
