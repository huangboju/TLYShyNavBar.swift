//
//  Copyright © 2016年 xiAo_Ju. All rights reserved.
//

extension UIScrollView {
    func tly_setInsets(contentInsets: UIEdgeInsets) {
        if dragging && !decelerating && contentInset.top != contentInset.top {
            let offsetDelta = contentInsets.top - contentInset.top
            bounds.origin.y -= offsetDelta
        }
        
        contentInset = contentInsets
        scrollIndicatorInsets = contentInsets
    }
}

extension NSObject {
    class func tly_swizzleClassMethod(originalSelector: Selector, with replacementSelector: Selector) {
        let originalMethod = class_getClassMethod(self, originalSelector)
        let replacementMethod = class_getClassMethod(self, replacementSelector)
        method_exchangeImplementations(replacementMethod, originalMethod)
    }
    
    class func tly_swizzleInstanceMethod(originalSelector: Selector, with replacementSelector: Selector) {
        let originalMethod = class_getClassMethod(self, originalSelector)
        let replacementMethod = class_getInstanceMethod(self, replacementSelector)
        method_exchangeImplementations(replacementMethod, originalMethod)
    }
}

extension UIViewController {
    var tly_topLayoutGuide: UILayoutSupport {
        if parentViewController is UINavigationController && parentViewController != nil {
           return parentViewController!.tly_topLayoutGuide
        } else {
            return topLayoutGuide
        }
    }
    
    var tly_bottomLayoutGuide: UILayoutSupport {
        if parentViewController is UINavigationController && parentViewController != nil {
            return parentViewController!.tly_bottomLayoutGuide
        } else {
            return bottomLayoutGuide
        }
    }
}
