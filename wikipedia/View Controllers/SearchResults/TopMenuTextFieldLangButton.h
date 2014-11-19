//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface SearchLangSwitcherButton : UIView

-(void)showGlyph: (NSString *)glyphChar
      glyphColor: (UIColor *)glyphColor
       glyphSize: (CGFloat)glyphSize
          domain: (NSString *)domain
     domainColor: (UIColor *)domainColor
      domainSize: (CGFloat)domainSize;

@end
