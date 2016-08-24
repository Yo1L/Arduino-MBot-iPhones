//
//  BTService.h
//  Arduino_Servo
//
//  Created by Yoann Le Viavant
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

/* Services & Characteristics UUIDs */
#define kConnectedServiceUUID     [CBUUID UUIDWithString:@"FFF0"]
#define kConnectedDualServiceUUID [CBUUID UUIDWithString:@"FFE1"]
//================== TransmitMoudel =====================
// TransmitMoudel Receive Data Service UUID
#define kTransDataServiceUUID                    [CBUUID UUIDWithString:@"FFF0"]
#define kTransDataDualServiceUUID                [CBUUID UUIDWithString:@"FFE1"]
#define kDualResetServiceUUID           [CBUUID UUIDWithString:@"FFE4"]
// TransmitMoudel characteristics UUID
#define kTransDataCharateristicUUID         [CBUUID UUIDWithString:@"FFF1"]
#define kTransDataDualCharateristicUUID     [CBUUID UUIDWithString:@"FFE3"]
#define kNofityDataCharateristicUUID        [CBUUID UUIDWithString:@"FFF4"]
#define kNofityDataDualCharateristicUUID        [CBUUID UUIDWithString:@"FFE2"]

#define kDualResetCharateristicUUID         @"FFE5"
#define RWT_BLE_SERVICE_UUID		[CBUUID UUIDWithString:@"B8E06067-62AD-41BA-9231-206AE80AB550"]
#define RWT_POSITION_CHAR_UUID		[CBUUID UUIDWithString:@"BF45E40A-DE2A-4BC8-BBA0-E5D6065F1B4B"]

/* Notifications */
static NSString* const RWT_BLE_SERVICE_CHANGED_STATUS_NOTIFICATION = @"kBLEServiceChangedStatusNotification";


/* BTService */
@interface BTService : NSObject <CBPeripheralDelegate>

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral;
- (void)reset;
- (void)startDiscoveringServices;

- (void)write:(NSData *)data;
- (void)read:(NSData *)data;

@end
