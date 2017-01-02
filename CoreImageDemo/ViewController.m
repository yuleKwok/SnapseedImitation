//
//  ViewController.m
//  CoreImageDemo
//
//  Created by Gejiaxin on 16/12/25.
//  Copyright © 2016年 VincentJac. All rights reserved.
//

#import "ViewController.h"
#import <CoreImage/CoreImage.h>
#import "MBProgressHUD.h"
#import "SnapseedDropMenu.h"
#import <math.h>
#define FilterCellWidth 120
#define MoveZoom 20


typedef NS_ENUM(NSInteger, SliderType) {
    SaturationSlider = 101,
    BrightnessSlider,
    ContrastSlider
};

typedef NS_ENUM(NSInteger, FilterType) {
    GaussianBlur = 201,
    SepiaTone,
    AffineTransform,
    ModTransition
};

@interface ViewController () <SnapseedDropMenuDelegate>{
    BOOL _change;
    UIActivityIndicatorView * _activityIndicator;
    dispatch_queue_t _serialQueue;
    CIFilter * _colorFilter;
    int filterValue[5];
}
@property (nonatomic, strong) UIImageView * imageView;
@property (nonatomic, strong) CALayer * imgLayer;
@property (nonatomic, strong) UIImage * img;

@property (nonatomic, strong) MBProgressHUD *tipHud;
@property (nonatomic, strong) UIScrollView * tabScrollView;
@property (nonatomic, strong) SnapseedDropMenu * menu;
@property (nonatomic, strong) UILabel * selectFilterNameLab;
@property (nonatomic, copy) NSArray * colorFilterArray;
@property (nonatomic, strong) NSMutableArray<NSNumber *> * colorFilterValueArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initData];
    [self initUI];
    
    
    //添加拖动手势
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) initUI {
    
    self.view.backgroundColor = BACKGROUNDCOLOR;
    //loading tip
    _tipHud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_tipHud];
    // Pic
    self.img = [UIImage imageNamed:@"Duck.jpg"];
    self.imageView = [[UIImageView alloc]initWithImage:self.img];
    self.imageView.width = SCREEN_WIDTH - 30;
    self.imageView.height = SCREEN_HEIGHT / 3 * 2;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.centerX = SCREEN_WIDTH / 2;
    self.imageView.y = SCREEN_HEIGHT / 6;
    [self.view addSubview:self.imageView];
    
    self.imgLayer = [CALayer layer];
    _tabScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 60, SCREEN_WIDTH, 60)];
    [self.view addSubview:_tabScrollView];
    
    //Filter button:
    CGFloat offsetX = 10;
 
    UIButton * gaussianBlurbtn = [self getFilterButton:offsetX  buttonTitle:@"GaussianBlur" buttonType:GaussianBlur];
    [_tabScrollView addSubview:gaussianBlurbtn];
    
    
    offsetX += FilterCellWidth + 10;
    
    UIButton * sepiaTonebtn = [self getFilterButton:offsetX buttonTitle:@"SepiaTone" buttonType:SepiaTone];
    [_tabScrollView addSubview:sepiaTonebtn];
    
    offsetX += FilterCellWidth + 10;
    
    UIButton * affinetransfromBtn = [self getFilterButton:offsetX buttonTitle:@"放大一倍" buttonType:AffineTransform];
    [_tabScrollView addSubview:affinetransfromBtn];
    
    offsetX += FilterCellWidth + 10;
    UIButton * modTransitionBtn = [self getFilterButton:offsetX buttonTitle:@"CIAffineTransform" buttonType:ModTransition];
    [_tabScrollView addSubview:modTransitionBtn];
    
    offsetX += FilterCellWidth + 10;
    
//    //Filter slider
//    CGFloat sliderOffsetY = 380;
//    
//    [self addColorControlSlider:SaturationSlider withOffsetY:sliderOffsetY labName:@"饱和度" withMin:0 andMax:2 andValue:1];
//    sliderOffsetY += 60;
//    
//    [self addColorControlSlider:BrightnessSlider withOffsetY:sliderOffsetY labName:@"亮 度" withMin:-1 andMax:1 andValue:0];
//    sliderOffsetY += 60;
//    
//    [self addColorControlSlider:ContrastSlider withOffsetY:sliderOffsetY labName:@"对比度" withMin:0 andMax:2 andValue:1];
    
    _tabScrollView.contentSize = CGSizeMake(offsetX, 60);
    
    self.selectFilterNameLab = [[UILabel alloc]  initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, NAV_VIEW_HEIGHT + 30)];
    self.selectFilterNameLab.textColor = [UIColor whiteColor];
    self.selectFilterNameLab.backgroundColor = [UIColor clearColor];
    self.selectFilterNameLab.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.selectFilterNameLab];
    
    //Snapseed menu
    self.colorFilterArray = @[@"饱和度",@"亮  度",@"对比度",@"阴  影",@"高  亮"];
    _colorFilterValueArray = [NSMutableArray arrayWithCapacity:_colorFilterArray.count];
    CGPoint point = CGPointMake(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2);
    self.menu = [[SnapseedDropMenu alloc]initWithArray:self.colorFilterArray  viewCenterPoint:point inView:self.view];
    self.menu.dropMenuDelegate = self;
    [self.view addSubview:self.menu];
}




- (void) addColorControlSlider:(SliderType)type withOffsetY:(CGFloat)offsetY labName:(NSString *)name withMin:(CGFloat)min andMax:(CGFloat)max andValue:(CGFloat)value{
 
    UILabel * silderLab = [[UILabel alloc]initWithFrame:CGRectMake(30, offsetY, 70, 20)];
    silderLab.text = name;
    [self.view addSubview:silderLab];
    
    UISlider * silder;
    silder = [[UISlider alloc]initWithFrame:CGRectMake(100, offsetY, 180, 30)];
    silder.continuous = NO;
    silder.minimumValue = min;// 设置最小值
    silder.maximumValue = max;// 设置最大值
    silder.value = value;
    silder.tag = type;
    [silder addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:silder];
}

- (UIButton *) getFilterButton:(CGFloat)offsetX buttonTitle:(NSString *)title buttonType:(FilterType)type{
    UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.layer.borderColor = [UIColor whiteColor].CGColor;
    btn.layer.borderWidth = 1;
    btn.tag = type;
    btn.frame = CGRectMake(offsetX, 5, FilterCellWidth, 50);
    [btn addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}


- (void) initData {
    _change = YES;
    _serialQueue = dispatch_queue_create("com.gcd.concurrentQueue", DISPATCH_QUEUE_SERIAL);
    _colorFilter = [CIFilter filterWithName:@"CIColorControls"];
    [_colorFilter setDefaults];
    _colorFilterValueArray = [NSMutableArray array];
}

#pragma mark SnapseedDropMenu Delegate
- (void)snapseedDropMenu:(SnapseedDropMenu *)sender didSelectCellAtIndex:(NSInteger)index value:(CGFloat)value{
    NSString * colorFilterName = [NSString stringWithFormat:@"%@  %d",[self.colorFilterArray objectAtIndex:index],filterValue[index]];
    self.selectFilterNameLab.text = colorFilterName;
}

- (void)snapseedDropMenu:(SnapseedDropMenu *)sender atIndex:(NSInteger)index valueDidChange:(CGFloat)value {
    if(filterValue[index] > 100){
        filterValue[index] = 100;
    } else if(filterValue[index] < -100) {
        filterValue[index] = -100;
    } else {
        filterValue[index] += value;
    }
    NSString * colorFilterName = [NSString stringWithFormat:@"%@  %d",[self.colorFilterArray objectAtIndex:index],filterValue[index]];
    self.selectFilterNameLab.text = colorFilterName;
}


#pragma mark - Action block

- (void)sliderValueChange:(id)sender {
    UISlider * slider;
    if([sender isKindOfClass:[UISlider class]]) {
        slider = (UISlider *)sender;
    }
    __weak ViewController *weakself = self;
    if(slider.tag == SaturationSlider) {
        dispatch_async(_serialQueue,^{
            UIImage * img = [weakself setStaturation:[NSNumber numberWithFloat:slider.value]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.imageView setImage:img];
                
            });
        });
    } else if(slider.tag == BrightnessSlider){
        dispatch_async(_serialQueue,^{
            UIImage * img = [weakself setBrightness:[NSNumber numberWithFloat:slider.value]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.imageView setImage:img];
                
            });
        });
    } else if(slider.tag == ContrastSlider) {
        dispatch_async(_serialQueue,^{
            UIImage * img = [weakself setContrast:[NSNumber numberWithFloat:slider.value]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.imageView setImage:img];
                
            });
            
        });
    }
    
}

- (void)buttonAction:(UIButton *)sender {
    if(_change) {
        dispatch_async(_serialQueue,^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showLoadingTips];
            });
            UIImage * img = [self setFilter:(FilterType)sender.tag];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.imageView setImage:img];
                [self dismissLoadingTips];
            });
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.imageView setImage:self.img];
        });
    }
    _change = !_change;
}


#pragma mark - Filter

-(void)showAllFilters{
    NSArray *filterNames=[CIFilter filterNamesInCategory:kCICategoryBuiltIn];
    for (NSString *filterName in filterNames) {
        CIFilter *filter=[CIFilter filterWithName:filterName];
        NSLog(@"\rfilter:%@\rattributes:%@",filterName,[filter attributes]);
    }
}

- (UIImage *)setStaturation:(NSNumber *)number {
    if(_colorFilter) {
        [_colorFilter setValue:number forKey:@"inputSaturation"];
        CIImage * inputImage;
        @autoreleasepool {
            NSData *imageData = UIImagePNGRepresentation(self.img);
            inputImage = [CIImage imageWithData:imageData];
            imageData = nil;
        }
        [_colorFilter setValue:inputImage forKey:@"inputImage"];
        return [self useFilter:_colorFilter toCreateImageWiehCIImage:inputImage];
    } else {
        return  nil;
    }
    
}

- (UIImage *)setBrightness:(NSNumber *)number {
    if(_colorFilter) {
        [_colorFilter setValue:number forKey:@"inputBrightness"];
        CIImage * inputImage;
        @autoreleasepool {
            NSData *imageData = UIImagePNGRepresentation(self.img);
            inputImage = [CIImage imageWithData:imageData];
            imageData = nil;
            
        }
        [_colorFilter setValue:inputImage forKey:@"inputImage"];
        return [self useFilter:_colorFilter toCreateImageWiehCIImage:inputImage];
    } else {
        return  nil;
    }
}

- (UIImage *)setContrast:(NSNumber *)number {
    if(_colorFilter) {
        [_colorFilter setValue:number forKey:@"inputContrast"];
        CIImage * inputImage;
        @autoreleasepool {
            NSData *imageData = UIImagePNGRepresentation(self.img);
            inputImage = [CIImage imageWithData:imageData];
            imageData = nil;
        }
        [_colorFilter setValue:inputImage forKey:@"inputImage"];
        return [self useFilter:_colorFilter toCreateImageWiehCIImage:inputImage];
    } else {
        return  nil;
    }
}

//滤镜相关代码

- (UIImage *)setFilter :(FilterType) type{
    UIImage * resImage;
    __weak id weakSelf = self;
    @autoreleasepool {
        
        NSData *imageData = UIImagePNGRepresentation(((ViewController *)weakSelf).img);
        CIImage * inputImage = [CIImage imageWithData:imageData];
        CIFilter * filter;
        switch (type) {
            case GaussianBlur: {
                filter = [CIFilter filterWithName:@"CIGaussianBlur"
                                    keysAndValues:@"inputRadius",@50,
                                                  @"inputImage",inputImage,nil];
            }
                break;
            case SepiaTone: {
                filter = [CIFilter filterWithName:@"CISepiaTone"
                                    keysAndValues:@"inputIntensity",@20,
                                                  @"inputImage", inputImage,nil];
            }
                break;
            case AffineTransform: {
                CGFloat width = self.img.size.width;
                CGAffineTransform trans = CGAffineTransformMake(3, 0, 0, 3, - width,  - width);
                filter = [CIFilter filterWithName:@"CIAffineTransform"
                                    keysAndValues:@"inputImage",inputImage,
                                                  @"inputTransform",[NSValue valueWithCGAffineTransform:trans],nil];
            }
                break;
            case ModTransition: {
                filter = [CIFilter filterWithName: @"CIModTransition"
                                    keysAndValues: @"inputCenter",[CIVector vectorWithX:0.5*self.img.size.width Y:0.5 * self.img.size.height],
                                                   @"inputAngle", @(M_PI*0.1),
                                                   @"inputRadius", @30.0,
                                                   @"inputCompression", @10.0,
                                                   @"inputImage",inputImage,
                                                   nil];
            }
                break;
            default:
                break;
        }
        
        resImage = [self useFilter:filter toCreateImageWiehCIImage:inputImage];
        inputImage = nil;
        imageData = nil;
    }
    return resImage;
}


/*
 * 绘制
 */
- (UIImage * )useFilter:(CIFilter *)filter toCreateImageWiehCIImage:(CIImage*)inputImage {
    CIContext * ciContext = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [ciContext createCGImage:filter.outputImage fromRect:inputImage.extent];
    UIImage * resImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);//释放CGImage对象
    [ciContext clearCaches];
    return resImage;
}


#pragma mark - HUD

- (void)showTextTips:(NSString *)tips {
    [MBProgressHUD hideHUDForView:self.view animated:NO];
    [self.view addSubview:_tipHud];
    [self.view bringSubviewToFront:_tipHud];
    
    _tipHud.mode = MBProgressHUDModeText;
    _tipHud.labelText = tips;
    [_tipHud show:YES];
    [_tipHud hide:YES afterDelay:1];
}

- (void)showLoadingTips {
    [MBProgressHUD hideHUDForView:self.view animated:NO];
    [self.view addSubview:_tipHud];
    [self.view bringSubviewToFront:_tipHud];
    
    _tipHud.labelText = nil;
    _tipHud.mode = MBProgressHUDModeIndeterminate;
    [_tipHud show:YES];
}

- (void)dismissLoadingTips {
    [_tipHud hide:YES];
}
@end
