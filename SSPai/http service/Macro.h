//
//  Macro.h
//  SSPai
//
//  Created by AlexYang on 2018/11/22.
//  Copyright © 2018 AlexYang. All rights reserved.
//

#ifndef Macro_h
#define Macro_h

//获得屏幕的宽高
//iphone xs Max 414*896 3x
//iphone xs     375*812 3x
//iphone xr     414*896 2x
//iphone x      375*812 3x
//iphone plus   414*896 3x
//iphone        375*667 2x
#define kScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define kScreenHeight ([UIScreen mainScreen].bounds.size.height)
//iPhoneX / iPhoneXS
#define  isIphoneX_XS     (kScreenWidth == 375.f && kScreenHeight == 812.f ? YES : NO)
//iPhoneXR / iPhoneXSMax
#define  isIphoneXR_XSMax    (kScreenWidth == 414.f && kScreenHeight == 896.f ? YES : NO)
//异性全面屏
#define   isFullScreen    (isIphoneX_XS || isIphoneXR_XSMax)

// Status bar height.
#define  StatusBarHeight     (isFullScreen ? 44.f : 20.f)

// Navigation bar height.
#define  NavigationBarHeight  44.f

// Tabbar height.
#define  TabbarHeight         (isFullScreen ? (49.f+34.f) : 49.f)

// Tabbar safe bottom margin.
#define  TabbarSafeBottomMargin         (isFullScreen ? 34.f : 0.f)

// Status bar & navigation bar height.
#define  StatusBarAndNavigationBarHeight  (isFullScreen ? 88.f : 64.f)


#endif /* Macro_h */
