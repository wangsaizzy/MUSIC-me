//
//  PlayerVC.m
//  音乐
//
//  Created by qingyun on 15/8/22.
//  Copyright (c) 2015年 hnqingyun. All rights reserved.
//

#import "PlayerVC.h"
#import <AVFoundation/AVFoundation.h>
#import "commen.h"

@interface PlayerVC () <UIScrollViewDelegate,UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *songName;
@property (weak, nonatomic) IBOutlet UIScrollView *scroll;
@property (weak, nonatomic) IBOutlet UITableView *LRCView;
@property (weak, nonatomic) IBOutlet UIImageView *songImage;
@property (weak, nonatomic) IBOutlet UIPageControl *page;
@property (weak, nonatomic) IBOutlet UILabel *songTime;
@property (weak, nonatomic) IBOutlet UILabel *songTiming;
@property (weak, nonatomic) IBOutlet UISlider *songProgress;
@property (weak, nonatomic) IBOutlet UIButton *play;
@property (weak, nonatomic) IBOutlet UIButton *next;
@property (weak, nonatomic) IBOutlet UIButton *back;
@property (weak, nonatomic) IBOutlet UISlider *volume;
@property (weak, nonatomic) IBOutlet UIButton *singlePlay;
@property (weak, nonatomic) IBOutlet UITableView *songListTVC;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSMutableArray *songListArrray;
@property (nonatomic) int songNum;
@property (nonatomic, strong) NSMutableArray *LRCarray;
@property (nonatomic, strong) NSMutableDictionary *LRCDictionary;
@property (nonatomic) NSUInteger LRCLineNum;
@property (nonatomic) BOOL isSingle;
@property (nonatomic) BOOL isPlaying;
@end

@implementation PlayerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initDataZoom];
    [self initPlayer];
    [self initUI];
    [self initLRC];
    [self setupTimer];
}

//从Plist文件中取出歌曲名称数组
- (NSMutableArray *)songListArrray
{
    if (_songListArrray == nil) {
        NSURL *songURL = [[NSBundle mainBundle] URLForResource:@"Song" withExtension:@"plist"];
        _songListArrray = [NSMutableArray arrayWithContentsOfURL:songURL];
    }
    return _songListArrray;
}

- (void)initDataZoom
{
    self.LRCarray = [[NSMutableArray alloc] initWithCapacity:20];;
    self.LRCDictionary = [[NSMutableDictionary alloc] initWithCapacity:20];
}

//初始化播放器
- (void)initPlayer
{
    self.songNum = 0;
    self.isSingle = NO;
    self.isPlaying = NO;
    NSURL *songURL = [[NSBundle mainBundle] URLForResource:self.songListArrray[self.songNum] withExtension:@"mp3"];
    NSError *error;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:songURL error:&error];
    [self.player prepareToPlay];
}

//初始化UI
- (void)initUI
{
    self.songName.text = self.songListArrray[self.songNum];
    self.songImage.image = [UIImage imageNamed:self.songListArrray[self.songNum]];
    
    [self.songProgress setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [self.songProgress setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateHighlighted];
    
    self.volume.minimumValue = 0;
    self.volume.maximumValue = 1.0;
    self.volume.value = 1;
    self.player.volume = self.volume.value;
    
    self.scroll.contentSize = CGSizeMake(kScreenW * 2, kScreenH);
    self.scroll.bounces = NO;
    
    self.LRCView.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1];
    
    self.songListTVC.tag = 1;
    self.songListTVC.hidden = YES;
    self.songListTVC.backgroundColor = [UIColor grayColor];
}

//初始化歌词
- (void)initLRC
{
    NSString *LRCPath = [[NSBundle mainBundle] pathForResource:self.songListArrray[self.songNum] ofType:@"lrc"];
    NSString *contentStr = [NSString stringWithContentsOfFile:LRCPath encoding:NSUTF8StringEncoding error:nil];
        NSLog(@"contentStr = %@",contentStr);
    NSArray *array = [contentStr componentsSeparatedByString:@"\n"];
    for (int i = 0; i < array.count; i++) {
        NSString *linStr = [array objectAtIndex:i];
        NSArray *lineArray = [linStr componentsSeparatedByString:@"]"];
        if ([lineArray[0] length] > 8) {
            NSString *str1 = [linStr substringWithRange:NSMakeRange(3, 1)];
            NSString *str2 = [linStr substringWithRange:NSMakeRange(6, 1)];
            if ([str1 isEqualToString:@":"] && [str2 isEqualToString:@"."]) {
                NSString *lrcStr = [lineArray objectAtIndex:1];
                NSString *timeStr = [[lineArray objectAtIndex:0] substringWithRange:NSMakeRange(1, 5)];//分割区间求歌词时间
                //把时间 和 歌词 加入词典
                [self.LRCDictionary setObject:lrcStr forKey:timeStr];
                [self.LRCarray addObject:timeStr];//timeArray的count就是行数
                NSLog(@"得到歌词的count数值 = %ld",self.LRCarray.count);
            }
        }
    }

}

//设置定时监控
- (void)setupTimer
{
    [NSTimer scheduledTimerWithTimeInterval:0.1f
                                     target:self
                                   selector:@selector(timingUpdate)
                                   userInfo:nil
                                    repeats:YES];

}

//动态更新歌曲时间，播放进度
- (void)timingUpdate
{
    if ((int)self.player.currentTime % 60 < 10) {
        self.songTime.text = [NSString stringWithFormat:@"%d:0%d",(int)self.player.currentTime / 60, (int)self.player.currentTime % 60];
    } else {
        self.songTime.text = [NSString stringWithFormat:@"%d:%d",(int)self.player.currentTime / 60, (int)self.player.currentTime % 60];
    }
    //
    if ((int)self.player.duration % 60 < 10) {
        self.songTiming.text = [NSString stringWithFormat:@"%d:0%d",(int)self.player.duration / 60, (int)self.player.duration % 60];
    } else {
        self.songTiming.text = [NSString stringWithFormat:@"%d:%d",(int)self.player.duration / 60, (int)self.player.duration % 60];
    }
    self.songProgress.value = self.player.currentTime / self.player.duration;
    
    
    //如果播放完，调用自动播放下一首
    if (self.songProgress.value > 0.999) {
        [self setupSinglePlay];
    }
    
    [self showLRC:self.player.currentTime];//调用歌词函数

    NSLog(@"%f",self.player.volume);
}

//更新播放器
- (void)updatePlayer
{
    NSURL *songURL = [[NSBundle mainBundle] URLForResource:self.songListArrray[self.songNum] withExtension:@"mp3"];
    NSError *error;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:songURL error:&error];
    [self.player prepareToPlay];
}

//更新UI
- (void)updateUI
{
    self.songName.text = self.songListArrray[self.songNum];
    self.songImage.image = [UIImage imageNamed:self.songListArrray[self.songNum]];
}

//更新播放按钮UI
- (void)updatePlayBtnUI
{
    if (self.isPlaying) {
        [self.play setImage:[UIImage imageNamed:@"pausebutton"] forState:UIControlStateNormal];
        [self.play setImage:[UIImage imageNamed:@"pausebutton"] forState:UIControlStateHighlighted];
    } else {
        [self.play setImage:[UIImage imageNamed:@"playbutton"] forState:UIControlStateHighlighted];
        [self.play setImage:[UIImage imageNamed:@"playbutton"] forState:UIControlStateNormal];
    }
}

//是否单曲循环
- (void)setupSinglePlay
{
    if (self.isSingle == YES) {
        self.isPlaying = YES;
        [self updatePlayBtnUI];
        [self updatePlayer];
        [self updateLRC];
        [self updateUI];
        [self.player play];
    } else {
        if (self.songNum == self.songListArrray.count) {
            self.songNum = -1;
        }
        self.songNum++;
        [self updatePlayBtnUI];
        [self updatePlayer];
        [self updateUI];
        [self updateLRC];
        [self.player play];
    }
}

//显示歌词
- (void)showLRC:(NSUInteger)number
{
    NSLog(@"cout的数值 = %ld",self.LRCarray.count);
   for (int i = 0; i < self.LRCarray.count; i++) {
        
        NSArray *array = [self.LRCarray[i] componentsSeparatedByString:@":"];//把时间转换成秒
        NSUInteger currentTime = [array[0] intValue] * 60 + [array[1] intValue];
        if (i == self.LRCarray.count - 1) {
            //求最后一句歌词的时间点
            NSArray *array1 = [self.LRCarray[self.LRCarray.count - 1] componentsSeparatedByString:@":"];
            NSUInteger currentTime1 = [array1[0] intValue] * 60 + [array1[1] intValue];
            if (number > currentTime1) {
                [self updateLrcTableView:i];
                break;
            }
        } else {
            //求出第一句的时间点，在第一句显示前的时间内一直加载第一句
            NSArray *array2 = [self.LRCarray[0] componentsSeparatedByString:@":"];
            NSUInteger currentTime2 = [array2[0] intValue] * 60 + [array2[1] intValue];
            if (number < currentTime2) {
                [self updateLrcTableView:0];
                //                NSLog(@"马上到第一句");
                break;
            }
            //求出下一步的歌词时间点，然后计算区间
            NSArray *array3 = [self.LRCarray[i+1] componentsSeparatedByString:@":"];
            NSUInteger currentTime3 = [array3[0] intValue] * 60 + [array3[1] intValue];
            if (number >= currentTime && number <= currentTime3) {
                [self updateLrcTableView:i];
                break;
            }
            
        }
    }

}

//更新歌词显示TableView
- (void)updateLrcTableView:(NSUInteger)line
{
//    NSLog(@"lrc = %@", [self.LRCDictionary objectForKey:[self.LRCarray objectAtIndex:line]]);
    //重新载入 歌词列表lrcTabView
    self.LRCLineNum = line;
    [self.LRCView reloadData];
    //使被选中的行移到中间
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:line inSection:0];
    [self.LRCView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
//    NSLog(@"%lu",(unsigned long)line);

}

- (void)updateLRC
{
    self.LRCarray = [[NSMutableArray alloc] initWithCapacity:20];
    self.LRCDictionary = [[NSMutableDictionary alloc] initWithCapacity:20];
    [self initLRC];
}

- (IBAction)play:(UIButton *)sender {
    if (self.isPlaying) {
        self.isPlaying = NO;
        [self updatePlayBtnUI];
        [self.player pause];
    } else {
        self.isPlaying = YES;
        [self updatePlayBtnUI];
        [self.player play];
    }
}

- (IBAction)next:(UIButton *)sender {
    if (self.songNum == self.songListArrray.count) {
        self.songNum = 0;
        self.isPlaying = YES;
        [self updatePlayBtnUI];
        [self updatePlayer];
        [self updateUI];
        [self updateLRC];
        [self.player play];
    } else {
        self.songNum++;
        self.isPlaying = YES;
        [self updatePlayBtnUI];
        [self updatePlayer];
        [self updateUI];
        [self updateLRC];
        [self.player play];
    }
}

- (IBAction)back:(UIButton *)sender {
    if (self.songNum == 0) {
        self.songNum = (int)self.songListArrray.count;
        self.isPlaying = YES;
        [self updatePlayBtnUI];
        [self updatePlayer];
        [self updateLRC];
        [self updateUI];
        [self.player play];
    } else {
        self.songNum--;
        self.isPlaying = YES;
        [self updatePlayBtnUI];
        [self updatePlayer];
        [self updateLRC];
        [self updateUI];
        [self.player play];
    }
}

- (IBAction)progress:(UISlider *)sender {
    self.player.currentTime = sender.value * self.player.duration;
}

- (IBAction)volume:(UISlider *)sender {
    self.player.volume = sender.value;
}

- (IBAction)singlePlay:(UIButton *)sender {
    if (self.isSingle) {
        self.isSingle = NO;
        [sender setImage:[UIImage imageNamed:@"repeat"] forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:@"repeat"] forState:UIControlStateHighlighted];
    } else {
        self.isSingle = YES;
        [sender setImage:[UIImage imageNamed:@"repeatH"] forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:@"repeatH"] forState:UIControlStateHighlighted];
    }
}

- (IBAction)list:(UIButton *)sender {
    if (self.songListTVC.hidden == YES) {
        self.songListTVC.hidden = NO;
    } else {
        self.songListTVC.hidden = YES;
    }
}

#pragma mark - LRC table view datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView.tag == 1) {
        return self.songListArrray.count;
    } else {
        return [self.LRCarray count];
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 1) {
        UITableViewCell *scell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
        if (scell == nil) {
            scell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        }
        tableView.rowHeight = 30;
        scell.textLabel.text = self.songListArrray[indexPath.row];
        scell.textLabel.font = [UIFont systemFontOfSize:15];
        scell.backgroundColor = [UIColor grayColor];
        scell.textLabel.textColor = [UIColor whiteColor];
        return scell;
    }
    static NSString *cellIdentifier = @"LRCCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;//该表格选中后没有颜色
    cell.backgroundColor = [UIColor clearColor];
    if (indexPath.row == self.LRCLineNum) {
        cell.textLabel.text = self.LRCDictionary[self.LRCarray[indexPath.row]];
        cell.textLabel.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0];
        cell.textLabel.font = [UIFont systemFontOfSize:15];
    } else {
        
        
        cell.textLabel.text = self.LRCDictionary[self.LRCarray[indexPath.row]];
        cell.textLabel.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        cell.textLabel.font = [UIFont systemFontOfSize:13];
    }
    cell.textLabel.backgroundColor = [UIColor clearColor];
    //        cell.textLabel.textColor = [UIColor blackColor];
    
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    //        [cell.contentView addSubview:lable];//往列表视图里加 label视图，然后自行布局
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == 1) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        self.songNum = (int)indexPath.row;
        self.isPlaying = YES;
        [self updatePlayBtnUI];
        [self updatePlayer];
        [self updateLRC];
        [self updateUI];
        [self.player play];
        self.songListTVC.hidden = YES;
    }

}

#pragma mark - Scroll delegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSUInteger index = scrollView.contentOffset.x / kScreenW;
    self.page.currentPage = index;
}

@end
