#pragma mark Defines

#import "WMF_Colors.h"

#define CHROME_MENUS_HEIGHT_TABLET 66.0
#define CHROME_MENUS_HEIGHT_PHONE 46.0

#define CHROME_MENUS_HEIGHT ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? CHROME_MENUS_HEIGHT_TABLET : CHROME_MENUS_HEIGHT_PHONE)

// Use this and UIView+ConstraintsScale to make scale for iPads.
// Make layouts work for phone first, then apply multiplier to scalar values
// and use UIView+ConstraintsScale methods to make layout also work with iPads.
#define MENUS_SCALE_MULTIPLIER (CHROME_MENUS_HEIGHT / CHROME_MENUS_HEIGHT_PHONE)


#define SEARCH_THUMBNAIL_WIDTH (48 * 3)
#define SEARCH_MAX_RESULTS 24

#define SEARCH_TEXT_FIELD_FONT [UIFont systemFontOfSize:(14.0 * MENUS_SCALE_MULTIPLIER)]
#define SEARCH_TEXT_FIELD_HIGHLIGHTED_COLOR [UIColor blackColor]

#define SEARCH_FIELD_PLACEHOLDER_TEXT_COLOR [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0]

#define SEARCH_BUTTON_BACKGROUND_COLOR [UIColor grayColor]

#define HIDE_KEYBOARD_ON_SCROLL_THRESHOLD 55.0f

#define THUMBNAIL_MINIMUM_SIZE_TO_CACHE CGSizeMake(35, 35)

#define EDIT_SUMMARY_DOCK_DISTANCE_FROM_BOTTOM 68.0f

#define MENU_TOP_GLYPH_FONT_SIZE (34.0 * MENUS_SCALE_MULTIPLIER)

#define MENU_TOP_FONT_SIZE_CANCEL (17.0 * MENUS_SCALE_MULTIPLIER)
#define MENU_TOP_FONT_SIZE_NEXT (14.0 * MENUS_SCALE_MULTIPLIER)
#define MENU_TOP_FONT_SIZE_SAVE (14.0 * MENUS_SCALE_MULTIPLIER)
#define MENU_TOP_FONT_SIZE_DONE (14.0 * MENUS_SCALE_MULTIPLIER)
#define MENU_TOP_FONT_SIZE_CHECK (25.0 * MENUS_SCALE_MULTIPLIER)

#define MENU_BOTTOM_GLYPH_FONT_SIZE (34.0 * MENUS_SCALE_MULTIPLIER)

#define CHROME_COLOR [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0]

#define ALERT_FONT_SIZE (12.0 * MENUS_SCALE_MULTIPLIER)
#define ALERT_BACKGROUND_COLOR [UIColor grayColor]
#define ALERT_TEXT_COLOR [UIColor whiteColor]
#define ALERT_PADDING UIEdgeInsetsMake(2.0, 10.0, 2.0, 10.0)

#define CHROME_OUTLINE_COLOR ALERT_BACKGROUND_COLOR
#define CHROME_OUTLINE_WIDTH (1.0f / [UIScreen mainScreen].scale)

// Reminder: For caching reasons, don't do "(scale * 320)" here.
#define LEAD_IMAGE_WIDTH (([UIScreen mainScreen].scale > 1) ? 640 : 320)
