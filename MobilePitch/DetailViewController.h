//
//  DetailViewController.h
//  MobilePitch
//
//  Created by Nathan Wallace on 10/23/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

