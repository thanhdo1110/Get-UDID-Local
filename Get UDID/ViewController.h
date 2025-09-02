//
//  ViewController.h
//  Get UDID
//
//  Created by Đỗ Trung Thành on 2/9/25.
//

#import <UIKit/UIKit.h>
#import <CFNetwork/CFNetwork.h>
#import <Foundation/Foundation.h>

@interface ViewController : UIViewController

@property (nonatomic, strong) NSString *deviceUDID;
@property (nonatomic, strong) NSString *deviceSerial;
@property (nonatomic, strong) NSString *deviceIMEI;
@property (nonatomic, strong) NSString *deviceVersion;
@property (nonatomic, strong) NSString *deviceProduct;
@property (nonatomic, strong) NSString *deviceName;

- (void)startHTTPServer;
- (void)stopHTTPServer;
- (void)openMobileConfigProfile;
- (void)testServerConnection;
- (void)showServerError:(NSString *)errorMessage;
- (void)performServerTest:(void(^)(BOOL success))completion;
- (void)handleURLSchemeCallback:(NSURL *)url;

@end

