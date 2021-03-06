//
//  ViewController.m
//  ESCCameraH264Demo
//
//  Created by xiang on 2018/6/20.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "ESCSaveToH264FileTool.h"

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong, nonatomic) IBOutlet UIButton *recordToH264Button;

@property(nonatomic,strong)AVCaptureSession* captureSession;

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;

@property(nonatomic,assign)BOOL isRecording;

@property(nonatomic,strong)dispatch_queue_t videoDataOutputQueue;

@property(nonatomic,strong)ESCSaveToH264FileTool* h264Tool;

@property(nonatomic,strong)NSDateFormatter* dateFormatter;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initCapureSession];

}

- (IBAction)didClickRecordToH264Button:(id)sender {
    if (self.isRecording) {
        [self.recordToH264Button setTitle:@"start record video to H264" forState:UIControlStateNormal];
        [self.captureSession stopRunning];
        [self.h264Tool stopRecord];
        NSLog(@"结束");
    }else {
        [self.recordToH264Button setTitle:@"stop record video to H264" forState:UIControlStateNormal];
        [self.captureSession startRunning];
        
        self.h264Tool = [[ESCSaveToH264FileTool alloc] init];
        NSString *filePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
        filePath = [NSString stringWithFormat:@"%@/%@.h264",filePath,[self.dateFormatter stringFromDate:[NSDate date]]];
        self.h264Tool.filePath = filePath;
        [self.h264Tool startRecordWithWidth:1280 height:720 frameRate:25];
        NSLog(@"开始");
    }
    self.isRecording = !self.isRecording;
}

-(void)initCapureSession{
    //创建AVCaptureDevice的视频设备对象
    AVCaptureDevice* videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError* error;
    //创建视频输入端对象
    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (error) {
        NSLog(@"创建输入端失败,%@",error);
        return;
    }
    
    //创建功能会话对象
    self.captureSession = [[AVCaptureSession alloc] init];
    //设置会话输出的视频分辨率
    [self.captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    
    //添加输入端
    if (![self.captureSession canAddInput:input]) {
        NSLog(@"输入端添加失败");
        return;
    }
    [self.captureSession addInput:input];
    
    //显示摄像头捕捉到的数据
    AVCaptureVideoPreviewLayer* layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    layer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 100);
    [self.view.layer addSublayer:layer];
    
    //创建输出端
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    //会话对象添加输出端
    if ([self.captureSession canAddOutput:videoDataOutput]) {
        [self.captureSession addOutput:videoDataOutput];
        self.videoDataOutput = videoDataOutput;
        //创建输出调用的队列
        dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("videoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        self.videoDataOutputQueue = videoDataOutputQueue;
        //设置代理和调用的队列
        [self.videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
        //设置延时丢帧
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
    }
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"did get %@",output);
    [self.h264Tool addFrame:sampleBuffer];
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection NS_AVAILABLE(10_7, 6_0) {
    NSLog(@"did drop %@",output);
}

#pragma mark - getter
- (NSDateFormatter *)dateFormatter {
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyy_MM_dd_HH_mm_ss";
    }
    return _dateFormatter;
}
@end
