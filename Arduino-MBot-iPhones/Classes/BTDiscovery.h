//
//  BTDiscovery.h
//  Arduino_Servo
//
//  Created by Yoann Le Viavant
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BTService.h"


@interface BTDiscovery : NSObject <CBCentralManagerDelegate>

+ (instancetype)sharedInstance;

@property (strong, nonatomic) BTService *bleService;

@end
