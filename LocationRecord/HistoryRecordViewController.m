//
//  HistoryRecordViewController.m
//  LocationRecord
//
//  Created by Daniel on 2017/1/9.
//  Copyright © 2017年 Daniel. All rights reserved.
//

#import "HistoryRecordViewController.h"
#import "Record+CoreDataClass.h"
#import "HistoryRecordTableViewCell.h"

@interface HistoryRecordViewController ()<UITableViewDelegate,UITableViewDataSource> {
    CoreDataManager * dataManager;
    TimeMethod * timeMethod;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property MKMapView *mainMapView;
@end

@implementation HistoryRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    timeMethod = [TimeMethod new];
    CoreDataAction * coreDataAction = [CoreDataAction new];
    dataManager = [coreDataAction coreDataManagerSetting];
    //set table view background
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    //self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    UIImage * backgroundImage = [UIImage imageNamed:@"tableViewImage"];
    UIImageView * imageView = [[UIImageView alloc] initWithImage:backgroundImage];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    self.tableView.backgroundView = imageView;
}

- (void)viewWillAppear:(BOOL)animated {
    [_tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return dataManager.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    HistoryRecordTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    Record * eventItem = (Record*)[dataManager getByIndex:indexPath.row];
    cell.titleLabel.text = eventItem.title;
    NSDate * date = [timeMethod dateFormatWithDate:eventItem.endTime];
    cell.dateLabel.text = [NSString stringWithFormat:@"%@",date];
    cell.infoBtn.tag = indexPath.row;
    [cell.infoBtn addTarget:self action:@selector(showInfoWithBtn:) forControlEvents:UIControlEventTouchUpInside];
    [cell setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.8]];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSManagedObject *item = [dataManager getByIndex:indexPath.row];
        [dataManager deleteItem:item];
        [dataManager saveContextWithCompletion:^(BOOL success) {
            //對tableView做新增刪除的動作記得先update tableView
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView reloadData];
        }];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Record * item = (Record*)[dataManager getByIndex:indexPath.row];
    NSArray * locations = item.locations;
    if (locations.count >= 2) {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"backToMainPage" object:self userInfo:@{@"locations":locations,@"getByIndex":[NSNumber numberWithInteger:indexPath.row]}];
    }
    [self.viewDeckController openSide:IIViewDeckSideNone animated:YES];
}

- (void) showInfoWithBtn:(UIButton*)sender {
    
    Record * eventItem = (Record*)[dataManager getByIndex:sender.tag];
    NSString * startTime = [NSString stringWithFormat:@"%@",[timeMethod dateFormatWithDate: eventItem.startTime]];
    NSString * endTime = [NSString stringWithFormat:@"%@",[timeMethod dateFormatWithDate: eventItem.endTime]];
    double meter = eventItem.totalMile;
    double km = meter / 1000;
    //    eventItem.startTime eventItem.title
    NSString * message = [NSString stringWithFormat:@"備註：%@\n起始時間：%@\n結束時間：%@\n時程：%0.0f sec\n距離：%.03f km",eventItem.descripe,startTime,endTime,eventItem.spanTime,km];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:eventItem.title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    
    UIAlertAction *edit = [UIAlertAction actionWithTitle:@"Edit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UIAlertController* alertEdit = [UIAlertController alertControllerWithTitle:@"編輯" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [alertEdit addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"事件標題";
            textField.text = eventItem.title;
        }];
        
        [alertEdit addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"備註";
            textField.text = eventItem.descripe;
        }];
        
        UIAlertAction * editSend = [UIAlertAction actionWithTitle:@"Send" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSMutableDictionary  * eventDictionary = [NSMutableDictionary new];
            eventDictionary[@"startTime"] = eventItem.startTime;
            eventDictionary[@"id"] = [NSNumber numberWithInt:eventItem.id];
            eventDictionary[@"title"] = alertEdit.textFields.firstObject.text;
            eventDictionary[@"descripe"] = alertEdit.textFields.lastObject.text;
            eventDictionary[@"endTime"] = eventItem.endTime;
            eventDictionary[@"locations"] = eventItem.locations;
            eventDictionary[@"totalMile"] = [NSNumber numberWithDouble:eventItem.totalMile];
            eventDictionary[@"spanTime"] = [NSNumber numberWithInt:eventItem.spanTime];
            CoreDataAction * coreDataAction = [CoreDataAction new];
            [coreDataAction editWithDefault:eventItem dataDictionary:eventDictionary completion:^(bool success, NSManagedObject *result) {
                if (success) {
                    [dataManager saveContextWithCompletion:nil];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadData];
                    });
                }
            }];
        }];
        
        UIAlertAction * editCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
        
        [alertEdit addAction:editCancel];
        [alertEdit addAction:editSend];
        [self presentViewController:alertEdit animated:true completion:nil];
    }];
    
    [alert addAction:edit];
    [alert addAction:ok];
    [self presentViewController:alert animated:true completion:nil];
}

- (IBAction)backBtn:(UIBarButtonItem *)sender {
    [self.viewDeckController openSide:IIViewDeckSideNone animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
