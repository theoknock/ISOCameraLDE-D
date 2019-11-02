//
//  ButtonCollectionView.m
//  ISOCameraLDE-D
//
//  Created by Xcode Developer on 10/20/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ButtonCollectionView.h"
#import "ButtonCollectionViewCell.h"

static NSString * const reuseIdentifier = @"ButtonCollectionViewCell";

@implementation ButtonCollectionView

@synthesize buttonCollectionViewDelegate = _buttonCollectionViewDelegate;

- (id<ButtonCollectionViewDelegate>)buttonCollectionViewDelegate
{
    return self->_buttonCollectionViewDelegate;
}

- (void)setButtonCollectionViewDelegate:(id<ButtonCollectionViewDelegate>)buttonCollectionViewDelegate
{
    self->_buttonCollectionViewDelegate = buttonCollectionViewDelegate;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self registerClass:[ButtonCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    self.dataSource = self;
    self.delegate = self;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize buttonCellSize = CGSizeMake(CGRectGetWidth(self.bounds) / [self numberOfItemsInSection:0], CGRectGetHeight(self.frame));
    return buttonCellSize;
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSLog(@"Button count: %lu", self.buttonCollectionViewDelegate.buttons.count);
    return self.buttonCollectionViewDelegate.buttons.count;
}

- (ButtonCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ButtonCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
   
    UIButton *button = [self.buttonCollectionViewDelegate buttonWithTag:(indexPath.item + 2)];
    [button setFrame:cell.contentView.frame];
    [cell.contentView addSubview:button];
    
//    [cell.contentView.layer setBorderColor:[UIColor whiteColor].CGColor];
    [cell.contentView setBackgroundColor:[UIColor blackColor]];
//    [cell.contentView.layer setBorderWidth:0.25];

    return cell;
}

@end
