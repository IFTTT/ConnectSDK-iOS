//
//  HomeViewController.m
//  SDK Example ObjC
//
//  Created by Jon Chmura on 8/31/18.
//  Copyright © 2018 IFTTT. All rights reserved.
//

#import <IFTTT_SDK/IFTTT_SDK.h>

#import "HomeViewController.h"
#import "AppletViewController.h"

@interface HomeViewController ()

@property (nonatomic, nullable) NSArray<IFTTTApplet*>* applets;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self refresh];
}

- (void)refresh {
    [IFTTTApplet getApplets:^(IFTTTAppletResponse * _Nonnull response) {
        self.applets = response.applets;
        [self.tableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.applets count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IFTTTApplet *applet = [self.applets objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"applet-cell" forIndexPath:indexPath];
    cell.textLabel.text = applet.name;
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"applet-detail"]) {
        NSIndexPath *path = [self.tableView indexPathForSelectedRow];
        if (path != nil) {
            AppletViewController *controller = segue.destinationViewController;
            [controller setApplet: [self.applets objectAtIndex: path.row]];
        }
    }
}

@end
