//
//  ButtonCollectionView.h
//  ISOCameraLDE-D
//
//  Created by Xcode Developer on 10/20/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ButtonCollectionViewDelegate <NSObject>

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *buttons;
- (UIButton *)buttonWithTag:(NSUInteger)tag;

@end

@interface ButtonCollectionView : UICollectionView <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet id<ButtonCollectionViewDelegate> buttonCollectionViewDelegate;

@end

NS_ASSUME_NONNULL_END
