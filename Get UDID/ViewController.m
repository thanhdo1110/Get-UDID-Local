//
//  ViewController.m
//  Get UDID
//
//  Created by Đỗ Trung Thành on 2/9/25.
//

#import "ViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import <ifaddrs.h>

static void AcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

@interface ViewController ()

@property (nonatomic, assign) CFSocketRef serverSocket;
@property (nonatomic, assign) BOOL isServerRunning;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UITextView *deviceInfoTextView;
@property (nonatomic, strong) UIButton *getUDIDButton;
@property (nonatomic, strong) UIButton *startServerButton;
@property (nonatomic, strong) UIButton *stopServerButton;
@property (nonatomic, strong) UIButton *testServerButton;
@property (nonatomic, strong) NSString *serverIPAddress;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTask;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.isServerRunning = NO;
    self.backgroundTask = UIBackgroundTaskInvalid;
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(appDidEnterBackground:) 
                                                 name:UIApplicationDidEnterBackgroundNotification 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(appWillEnterForeground:) 
                                                 name:UIApplicationWillEnterForegroundNotification 
                                               object:nil];
    
    [self setupUI];
    
    self.serverIPAddress = [self getDeviceIPAddress];
}

- (NSString *)getDeviceIPAddress {
    return @"127.0.0.1";
}

- (void)appDidEnterBackground:(NSNotification *)notification {
    if (self.isServerRunning) {
        [self startBackgroundTask];
    }
}

- (void)appWillEnterForeground:(NSNotification *)notification {
    [self endBackgroundTask];
}

- (void)startBackgroundTask {
    if (self.backgroundTask != UIBackgroundTaskInvalid) {
        return;
    }
    
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"HTTPServerBackgroundTask" expirationHandler:^{
        [self endBackgroundTask];
    }];
    
    if (self.backgroundTask != UIBackgroundTaskInvalid) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.isServerRunning) {
                self.statusLabel.text = [NSString stringWithFormat:@"HTTP Server: Running on %@ (Background Mode)", self.serverIPAddress];
                self.statusLabel.textColor = [UIColor systemOrangeColor];
            }
        });
    }
}

- (void)endBackgroundTask {
    if (self.backgroundTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.isServerRunning) {
                self.statusLabel.text = [NSString stringWithFormat:@"HTTP Server: Running on %@:1110", self.serverIPAddress];
                self.statusLabel.textColor = [UIColor systemGreenColor];
            }
        });
    }
}

- (void)setupUI {
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, self.view.frame.size.width - 40, 30)];
    self.statusLabel.text = @"HTTP Server Status: Stopped";
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.textColor = [UIColor redColor];
    [self.view addSubview:self.statusLabel];
    
    self.startServerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.startServerButton.frame = CGRectMake(20, 150, 120, 40);
    [self.startServerButton setTitle:@"Start Server" forState:UIControlStateNormal];
    [self.startServerButton addTarget:self action:@selector(startServerPressed) forControlEvents:UIControlEventTouchUpInside];
    self.startServerButton.backgroundColor = [UIColor systemGreenColor];
    self.startServerButton.tintColor = [UIColor whiteColor];
    self.startServerButton.layer.cornerRadius = 8;
    [self.view addSubview:self.startServerButton];
    
    self.stopServerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.stopServerButton.frame = CGRectMake(160, 150, 120, 40);
    [self.stopServerButton setTitle:@"Stop Server" forState:UIControlStateNormal];
    [self.stopServerButton addTarget:self action:@selector(stopServerPressed) forControlEvents:UIControlEventTouchUpInside];
    self.stopServerButton.backgroundColor = [UIColor systemRedColor];
    self.stopServerButton.tintColor = [UIColor whiteColor];
    self.stopServerButton.layer.cornerRadius = 8;
    self.stopServerButton.enabled = NO;
    [self.view addSubview:self.stopServerButton];
    
    self.testServerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.testServerButton.frame = CGRectMake(300, 150, 80, 40);
    [self.testServerButton setTitle:@"Test" forState:UIControlStateNormal];
    [self.testServerButton addTarget:self action:@selector(testServerPressed) forControlEvents:UIControlEventTouchUpInside];
    self.testServerButton.backgroundColor = [UIColor systemOrangeColor];
    self.testServerButton.tintColor = [UIColor whiteColor];
    self.testServerButton.layer.cornerRadius = 8;
    self.testServerButton.enabled = NO;
    [self.view addSubview:self.testServerButton];
    
    self.getUDIDButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.getUDIDButton.frame = CGRectMake(20, 210, self.view.frame.size.width - 40, 40);
    [self.getUDIDButton setTitle:@"Install Profile to Get UDID" forState:UIControlStateNormal];
    [self.getUDIDButton addTarget:self action:@selector(getUDIDPressed) forControlEvents:UIControlEventTouchUpInside];
    self.getUDIDButton.backgroundColor = [UIColor systemBlueColor];
    self.getUDIDButton.tintColor = [UIColor whiteColor];
    self.getUDIDButton.layer.cornerRadius = 8;
    [self.view addSubview:self.getUDIDButton];
    
    self.deviceInfoTextView = [[UITextView alloc] initWithFrame:CGRectMake(20, 270, self.view.frame.size.width - 40, 300)];
    self.deviceInfoTextView.text = @"Device information will appear here after installing the profile...";
    self.deviceInfoTextView.backgroundColor = [UIColor systemGray6Color];
    self.deviceInfoTextView.layer.cornerRadius = 8;
    self.deviceInfoTextView.editable = NO;
    self.deviceInfoTextView.font = [UIFont fontWithName:@"Menlo" size:12];
    [self.view addSubview:self.deviceInfoTextView];
}

- (void)startServerPressed {
    [self startHTTPServer];
}

- (void)stopServerPressed {
    [self stopHTTPServer];
}

- (void)testServerPressed {
    [self performServerTest:^(BOOL success) {
        NSString *message = success ? @"Server is working correctly!" : @"Server test failed. Check console for details.";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Server Test" 
                                                                       message:message 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)getUDIDPressed {
    if (!self.isServerRunning) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Server Not Running" 
                                                                       message:@"Please start the HTTP server first." 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    [self performServerTest:^(BOOL serverWorking) {
        if (serverWorking) {
            [self openMobileConfigProfile];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Server Issue" 
                                                                           message:@"Server is not responding properly. Please restart the server." 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)performServerTest:(void(^)(BOOL success))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *testRequest = [NSString stringWithFormat:@"POST /udid HTTP/1.1\r\nHost: %@:1110\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: 26\r\n\r\n<plist><dict></dict></plist>", self.serverIPAddress];
        
        int testSocket = socket(AF_INET, SOCK_STREAM, 0);
        if (testSocket < 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
            return;
        }
        
        struct sockaddr_in serverAddr;
        memset(&serverAddr, 0, sizeof(serverAddr));
        serverAddr.sin_family = AF_INET;
        serverAddr.sin_port = htons(1110);
        serverAddr.sin_addr.s_addr = inet_addr([self.serverIPAddress UTF8String]);
        
        struct timeval timeout;
        timeout.tv_sec = 5;
        timeout.tv_usec = 0;
        setsockopt(testSocket, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout, sizeof(timeout));
        setsockopt(testSocket, SOL_SOCKET, SO_SNDTIMEO, (char *)&timeout, sizeof(timeout));
        
        int connectResult = connect(testSocket, (struct sockaddr *)&serverAddr, sizeof(serverAddr));
        if (connectResult != 0) {
            close(testSocket);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
            return;
        }
        
        const char *requestData = [testRequest UTF8String];
        ssize_t bytesSent = send(testSocket, requestData, strlen(requestData), 0);
        if (bytesSent <= 0) {
            close(testSocket);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
            return;
        }
        
        char responseBuffer[1024];
        ssize_t bytesReceived = recv(testSocket, responseBuffer, sizeof(responseBuffer) - 1, 0);
        close(testSocket);
        
        if (bytesReceived > 0) {
            responseBuffer[bytesReceived] = '\0';
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
        }
    });
}

- (void)startHTTPServer {
    if (self.isServerRunning) {
        return;
    }
    
    CFSocketContext socketContext = {0, (__bridge void *)self, NULL, NULL, NULL};
    
    self.serverSocket = CFSocketCreate(kCFAllocatorDefault, 
                                       PF_INET, 
                                       SOCK_STREAM, 
                                       IPPROTO_TCP, 
                                       kCFSocketAcceptCallBack, 
                                       (CFSocketCallBack)&AcceptCallBack, 
                                       &socketContext);
    
    if (self.serverSocket == NULL) {
        [self showServerError:@"Failed to create server socket"];
        return;
    }
    
    int reuse = 1;
    setsockopt(CFSocketGetNative(self.serverSocket), SOL_SOCKET, SO_REUSEADDR, (void *)&reuse, sizeof(int));
    
    int noSigPipe = 1;
    setsockopt(CFSocketGetNative(self.serverSocket), SOL_SOCKET, SO_NOSIGPIPE, (void *)&noSigPipe, sizeof(int));
    
    struct sockaddr_in addr4;
    memset(&addr4, 0, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(1110);
    
    if (self.serverIPAddress && ![self.serverIPAddress isEqualToString:@"127.0.0.1"]) {
        addr4.sin_addr.s_addr = inet_addr([self.serverIPAddress UTF8String]);
    } else {
        addr4.sin_addr.s_addr = htonl(INADDR_ANY);
    }
    
    CFDataRef address = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&addr4, sizeof(addr4));
    
    CFSocketError bindResult = CFSocketSetAddress(self.serverSocket, address);
    CFRelease(address);
    
    if (bindResult != kCFSocketSuccess) {
        CFRelease(self.serverSocket);
        self.serverSocket = NULL;
        [self showServerError:@"Failed to bind to port 1110"];
        return;
    }
    
    CFRunLoopSourceRef socketsource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, self.serverSocket, 0);
    if (socketsource == NULL) {
        CFRelease(self.serverSocket);
        self.serverSocket = NULL;
        [self showServerError:@"Failed to create run loop source"];
        return;
    }
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), socketsource, kCFRunLoopDefaultMode);
    CFRelease(socketsource);
    
    [self testServerConnection];
    
    self.isServerRunning = YES;
    self.statusLabel.text = [NSString stringWithFormat:@"HTTP Server: Running on %@:1110", self.serverIPAddress];
    self.statusLabel.textColor = [UIColor systemGreenColor];
    self.startServerButton.enabled = NO;
    self.stopServerButton.enabled = YES;
    self.testServerButton.enabled = YES;
}

- (void)testServerConnection {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.statusLabel.text = [NSString stringWithFormat:@"HTTP Server: Running and verified on %@:1110", self.serverIPAddress];
    });
}

- (void)showServerError:(NSString *)errorMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = @"HTTP Server Status: Failed to start";
        self.statusLabel.textColor = [UIColor systemRedColor];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Server Error" 
                                                                       message:errorMessage 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)stopHTTPServer {
    if (!self.isServerRunning) {
        return;
    }
    
    if (self.serverSocket) {
        CFSocketInvalidate(self.serverSocket);
        CFRelease(self.serverSocket);
        self.serverSocket = NULL;
    }
    
    self.isServerRunning = NO;
    self.statusLabel.text = @"HTTP Server Status: Stopped";
    self.statusLabel.textColor = [UIColor redColor];
    self.startServerButton.enabled = YES;
    self.stopServerButton.enabled = NO;
    self.testServerButton.enabled = NO;
}

- (void)openMobileConfigProfile {
    if (!self.isServerRunning) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Server Not Running" 
                                                                       message:@"Please start the HTTP server first." 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    [self openMobileConfigInSafari];
}

- (void)openMobileConfigInSafari {
    NSString *urlString = [NSString stringWithFormat:@"http://%@:1110/GetUDID-signed.mobileconfig", self.serverIPAddress];
    NSURL *profileURL = [NSURL URLWithString:urlString];
    
    if ([[UIApplication sharedApplication] canOpenURL:profileURL]) {
        [[UIApplication sharedApplication] openURL:profileURL options:@{} completionHandler:^(BOOL success) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Profile Loading" 
                                                                                   message:@"The configuration profile is being loaded in Safari. Please follow the iOS prompts to install it. The app will automatically receive device information after installation." 
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" 
                                                                                   message:@"Failed to open Safari. Please try again." 
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];
                });
            }
        }];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" 
                                                                       message:@"Cannot open Safari to load the profile. Please check your device settings." 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)handleURLSchemeCallback:(NSURL *)url {
    NSString *urlString = url.absoluteString;
    
    if ([urlString containsString:@"profile-installed"] || [urlString containsString:@"profile-completed"]) {
        if (self.presentedViewController) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Profile Completed" 
                                                                           message:@"Device information has been successfully collected and displayed below." 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
}

- (void)handleHTTPRequest:(NSData *)requestData fromSocket:(CFSocketNativeHandle)socket {
    NSString *requestString = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
    
    if (!requestString) {
        [self handleBinaryHTTPRequest:requestData fromSocket:socket];
        return;
    }
    
    NSArray *lines = [requestString componentsSeparatedByString:@"\n"];
    if (lines.count == 0) {
        [self sendErrorResponse:socket];
        return;
    }
    
    NSString *requestLine = lines[0];
    requestLine = [requestLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *requestComponents = [requestLine componentsSeparatedByString:@" "];
    
    if (requestComponents.count < 3) {
        [self sendErrorResponse:socket];
        return;
    }
    
    NSString *method = requestComponents[0];
    NSString *path = requestComponents[1];
    
    if ([path isEqualToString:@"/GetUDID-signed.mobileconfig"] && [method isEqualToString:@"GET"]) {
        [self serveMobileConfigFile:socket];
        return;
    }
    else if ([method isEqualToString:@"POST"]) {
        if ([path isEqualToString:@"/udid"] || [path hasPrefix:@"/udid"]) {
            [self handleCallbackRequest:requestString fromSocket:socket];
            return;
        } else {
            [self sendErrorResponse:socket];
            return;
        }
    }
    else {
        [self sendErrorResponse:socket];
    }
}

- (void)handleBinaryHTTPRequest:(NSData *)requestData fromSocket:(CFSocketNativeHandle)socket {
    const char *bytes = (const char *)requestData.bytes;
    NSUInteger dataLength = requestData.length;
    
    NSUInteger headerLength = 0;
    BOOL foundSeparator = NO;
    
    for (NSUInteger i = 0; i < dataLength - 3; i++) {
        if (bytes[i] == '\r' && bytes[i+1] == '\n' && bytes[i+2] == '\r' && bytes[i+3] == '\n') {
            headerLength = i + 4;
            foundSeparator = YES;
            break;
        } else if (i < dataLength - 1 && bytes[i] == '\n' && bytes[i+1] == '\n') {
            headerLength = i + 2;
            foundSeparator = YES;
            break;
        }
    }
    
    if (!foundSeparator) {
        [self sendErrorResponse:socket];
        return;
    }
    
    NSData *headerData = [NSData dataWithBytes:bytes length:headerLength];
    NSString *headerString = [[NSString alloc] initWithData:headerData encoding:NSUTF8StringEncoding];
    
    if (!headerString) {
        [self sendErrorResponse:socket];
        return;
    }
    
    NSArray *headerLines = [headerString componentsSeparatedByString:@"\n"];
    if (headerLines.count == 0) {
        [self sendErrorResponse:socket];
        return;
    }
    
    NSString *requestLine = [[headerLines[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] copy];
    NSArray *requestComponents = [requestLine componentsSeparatedByString:@" "];
    
    if (requestComponents.count < 3) {
        [self sendErrorResponse:socket];
        return;
    }
    
    NSString *method = requestComponents[0];
    NSString *path = requestComponents[1];
    
    if ([method isEqualToString:@"POST"] && ([path isEqualToString:@"/udid"] || [path hasPrefix:@"/udid"])) {
        NSData *bodyData = [NSData dataWithBytes:bytes + headerLength length:dataLength - headerLength];
        
        NSString *bodyString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
        if (!bodyString) {
            bodyString = [self extractTextFromBinaryData:bodyData];
        }
        
        if (bodyString && bodyString.length > 0) {
            [self parseDeviceInfo:bodyString];
        }
        [self sendSuccessResponse:socket];
    } else {
        [self sendErrorResponse:socket];
    }
}

- (NSString *)extractTextFromBinaryData:(NSData *)binaryData {
    const char *bytes = (const char *)binaryData.bytes;
    NSUInteger length = binaryData.length;
    
    NSMutableString *extractedText = [NSMutableString string];
    BOOL inTextRegion = NO;
    
    for (NSUInteger i = 0; i < length; i++) {
        char c = bytes[i];
        
        if (!inTextRegion && i < length - 5) {
            if (strncmp(&bytes[i], "<?xml", 5) == 0 || strncmp(&bytes[i], "<plist", 6) == 0) {
                inTextRegion = YES;
            }
        }
        
        if (inTextRegion) {
            if ((c >= 32 && c <= 126) || c == '\n' || c == '\r' || c == '\t') {
                [extractedText appendFormat:@"%c", c];
            }
            
            if (i >= 7 && strncmp(&bytes[i-7], "</plist>", 8) == 0) {
                break;
            }
        }
    }
    
    if (extractedText.length > 0) {
        return extractedText;
    }
    
    return nil;
}

- (void)serveMobileConfigFile:(CFSocketNativeHandle)socket {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"GetUDID-signed" ofType:@"mobileconfig"];
    if (!filePath) {
        [self sendErrorResponse:socket];
        return;
    }
    
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    if (!fileData) {
        [self sendErrorResponse:socket];
        return;
    }
    
    NSString *headers = [NSString stringWithFormat:@"HTTP/1.1 200 OK\r\nContent-Type: application/x-apple-aspen-config\r\nContent-Disposition: attachment; filename=\"GetUDID-signed.mobileconfig\"\r\nContent-Length: %lu\r\n\r\n", 
                        (unsigned long)[fileData length]];
    
    NSData *headerData = [headers dataUsingEncoding:NSUTF8StringEncoding];
    
    send(socket, [headerData bytes], [headerData length], 0);
    send(socket, [fileData bytes], [fileData length], 0);
    close(socket);
}

- (void)handleCallbackRequest:(NSString *)requestString fromSocket:(CFSocketNativeHandle)socket {
    NSRange bodyRange = [requestString rangeOfString:@"\r\n\r\n"];
    if (bodyRange.location == NSNotFound) {
        bodyRange = [requestString rangeOfString:@"\n\n"];
    }
    
    if (bodyRange.location != NSNotFound) {
        NSString *body = [requestString substringFromIndex:bodyRange.location + bodyRange.length];
        if (body.length > 0) {
            [self parseDeviceInfo:body];
        }
    }
    [self sendSuccessResponse:socket];
}

- (void)parseDeviceInfo:(NSString *)requestBody {
    NSString *xmlContent = [self extractXMLFromPKCS7Data:requestBody];
    if (!xmlContent || xmlContent.length == 0) return;
    
    NSData *xmlData = [xmlContent dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *plistDict = [NSPropertyListSerialization propertyListWithData:xmlData 
                                                                        options:NSPropertyListImmutable 
                                                                         format:nil 
                                                                          error:&error];
    
    if (error || !plistDict) return;
    
    NSString *receivedChallenge = plistDict[@"CHALLENGE"];
    if (!receivedChallenge || ![receivedChallenge isEqualToString:@"GetUDIDChallenge2025"]) return;
    
    self.deviceUDID = plistDict[@"UDID"] ?: @"Not Available";
    self.deviceSerial = plistDict[@"SERIAL"] ?: @"Not Available";
    self.deviceIMEI = plistDict[@"IMEI"] ?: @"Not Available";
    self.deviceVersion = plistDict[@"VERSION"] ?: @"Not Available";
    self.deviceProduct = plistDict[@"PRODUCT"] ?: @"Not Available";
    self.deviceName = plistDict[@"DEVICE_NAME"];
    if (!self.deviceName || [self.deviceName isEqualToString:@""]) {
        self.deviceName = [[UIDevice currentDevice] name];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateDeviceInfoDisplay];
    });
}

- (NSString *)extractXMLFromPKCS7Data:(NSString *)pkcs7Data {
    NSRange beginRange = [pkcs7Data rangeOfString:@"<?xml"];
    if (beginRange.location == NSNotFound) {
        beginRange = [pkcs7Data rangeOfString:@"<plist"];
    }
    if (beginRange.location == NSNotFound) {
        beginRange = [pkcs7Data rangeOfString:@"<dict>"];
    }
    
    NSRange endRange = [pkcs7Data rangeOfString:@"</plist>"];
    if (beginRange.location == NSNotFound || endRange.location == NSNotFound) {
        return nil;
    }
    
    NSUInteger startPos = beginRange.location;
    NSUInteger endPos = endRange.location + endRange.length;
    
    if (endPos > pkcs7Data.length || startPos >= endPos) {
        return nil;
    }
    
    return [pkcs7Data substringWithRange:NSMakeRange(startPos, endPos - startPos)];
}

- (void)updateDeviceInfoDisplay {
    NSMutableString *infoText = [NSMutableString string];
    [infoText appendFormat:@"Device Information:\n\n"];
    [infoText appendFormat:@"UDID: %@\n", self.deviceUDID];
    [infoText appendFormat:@"IMEI: %@\n", self.deviceIMEI];
    [infoText appendFormat:@"Product: %@\n", self.deviceProduct];
    [infoText appendFormat:@"iOS Version: %@\n", self.deviceVersion];
    [infoText appendFormat:@"Serial Number: %@\n\n", self.deviceSerial];
    [infoText appendFormat:@"Extraction completed at: %@", [NSDate date]];
    
    self.deviceInfoTextView.text = infoText;
}

- (void)sendSuccessResponse:(CFSocketNativeHandle)socket {
    NSString *redirectHTML = @"\
    <!DOCTYPE html>\n\
    <html>\n\
    <head>\n\
        <meta charset='UTF-8'>\n\
        <title>Device Information Received</title>\n\
        <style>\n\
            body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; text-align: center; padding: 40px; background: #f5f5f7; }\n\
            .container { background: white; border-radius: 12px; padding: 30px; max-width: 400px; margin: 0 auto; }\n\
            .success { color: #34c759; font-size: 48px; margin-bottom: 20px; }\n\
        </style>\n\
    </head>\n\
    <body>\n\
        <div class='container'>\n\
            <div class='success'>&#9989;</div>\n\
            <h1>Success!</h1>\n\
            <p>Device information has been successfully collected. You will be redirected back to the app shortly.</p>\n\
            <p><strong>Redirecting in <span id='countdown'>3</span> seconds...</strong></p>\n\
        </div>\n\
        <script>\n\
            let count = 3;\n\
            const countdown = document.getElementById('countdown');\n\
            const timer = setInterval(() => {\n\
                count--;\n\
                countdown.textContent = count;\n\
                if (count <= 0) {\n\
                    clearInterval(timer);\n\
                    window.location.href = 'getudid://profile-completed';\n\
                }\n\
            }, 1000);\n\
        </script>\n\
    </body>\n\
    </html>";
    
    NSString *response = [NSString stringWithFormat:@"HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=UTF-8\r\nContent-Length: %lu\r\n\r\n%@", 
                         (unsigned long)[redirectHTML lengthOfBytesUsingEncoding:NSUTF8StringEncoding], redirectHTML];
    
    NSData *responseData = [response dataUsingEncoding:NSUTF8StringEncoding];
    send(socket, [responseData bytes], [responseData length], 0);
    close(socket);
}

- (void)sendErrorResponse:(CFSocketNativeHandle)socket {
    NSString *errorHTML = @"\
    <!DOCTYPE html>\n\
    <html>\n\
    <head>\n\
        <meta charset='UTF-8'>\n\
        <title>Request Error</title>\n\
        <style>\n\
            body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; text-align: center; padding: 40px; background: #f5f5f7; }\n\
            .container { background: white; border-radius: 12px; padding: 30px; max-width: 400px; margin: 0 auto; }\n\
            .error { color: #ff3b30; font-size: 48px; margin-bottom: 20px; }\n\
        </style>\n\
    </head>\n\
    <body>\n\
        <div class='container'>\n\
            <div class='error'>&#9888;</div>\n\
            <h1>Request Error</h1>\n\
            <p>The server could not process this request. Please check the logs for more details.</p>\n\
        </div>\n\
    </body>\n\
    </html>";
    
    NSString *response = [NSString stringWithFormat:@"HTTP/1.1 400 Bad Request\r\nContent-Type: text/html; charset=UTF-8\r\nContent-Length: %lu\r\n\r\n%@", 
                         (unsigned long)[errorHTML lengthOfBytesUsingEncoding:NSUTF8StringEncoding], errorHTML];
    
    NSData *responseData = [response dataUsingEncoding:NSUTF8StringEncoding];
    send(socket, [responseData bytes], [responseData length], 0);
    close(socket);
}

- (void)dealloc {
    [self stopHTTPServer];
    [self endBackgroundTask];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

static void AcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    ViewController *viewController = (__bridge ViewController *)info;
    
    if (type == kCFSocketAcceptCallBack) {
        CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            struct timeval timeout;
            timeout.tv_sec = 10;
            timeout.tv_usec = 0;
            setsockopt(nativeSocketHandle, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout, sizeof(timeout));
            
            NSMutableData *completeRequestData = [NSMutableData data];
            char buffer[4096];
            BOOL headersComplete = NO;
            NSInteger expectedContentLength = 0;
            NSInteger headerLength = 0;
            
            while (YES) {
                ssize_t bytesRead = recv(nativeSocketHandle, buffer, sizeof(buffer), 0);
                
                if (bytesRead <= 0) {
                    break;
                }
                
                [completeRequestData appendBytes:buffer length:bytesRead];
                
                if (!headersComplete) {
                    NSString *currentData = [[NSString alloc] initWithData:completeRequestData encoding:NSUTF8StringEncoding];
                    NSRange headerEndRange = [currentData rangeOfString:@"\r\n\r\n"];
                    if (headerEndRange.location == NSNotFound) {
                        headerEndRange = [currentData rangeOfString:@"\n\n"];
                    }
                    
                    if (headerEndRange.location != NSNotFound) {
                        headersComplete = YES;
                        headerLength = headerEndRange.location + headerEndRange.length;
                        
                        NSString *headers = [currentData substringToIndex:headerEndRange.location];
                        NSArray *headerLines = [headers componentsSeparatedByString:@"\n"];
                        for (NSString *line in headerLines) {
                            NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            if ([trimmedLine hasPrefix:@"Content-Length:"]) {
                                NSString *lengthString = [[trimmedLine substringFromIndex:15] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                expectedContentLength = [lengthString integerValue];
                                break;
                            }
                        }
                    }
                }
                
                if (headersComplete) {
                    NSInteger currentBodyLength = completeRequestData.length - headerLength;
                    
                    if (currentBodyLength >= expectedContentLength) {
                        break;
                    }
                }
                
                if (completeRequestData.length > 50000) {
                    break;
                }
            }
            
            if (completeRequestData.length > 0) {
                [viewController handleHTTPRequest:completeRequestData fromSocket:nativeSocketHandle];
            } else {
                close(nativeSocketHandle);
            }
        });
    }
}
