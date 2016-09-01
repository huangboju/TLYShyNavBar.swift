//
//  Copyright © 2016年 xiAo_Ju. All rights reserved.
//

func AACStatusBarHeight(viewController: UIViewController?) -> CGFloat {
    guard let viewController = viewController else {
        return 0
    }
    
    if UIApplication.sharedApplication().statusBarHidden {
        return 0
    }
    
    let statusBarSize = UIApplication.sharedApplication().statusBarFrame.size
    let statusBarHeight = min(statusBarSize.width, statusBarSize.height)
    let view = viewController.view
    let frame = view.superview?.convertRect(view.frame, toView: view.window)
    if frame!.origin.y < statusBarHeight {
        return 0
    }
    
    return statusBarHeight
}

class TLYShyStatusBarController {
    var viewController: UIViewController?
    
    func _statusBarHeight() -> CGFloat {
        var statusBarHeight = AACStatusBarHeight(viewController)
        if statusBarHeight > 20 {
            statusBarHeight -= 20
        }
        
        return statusBarHeight
    }
}

extension TLYShyStatusBarController: TLYShyParent {
    func maxYRelativeToView(superview: UIView?) -> CGFloat {
        return _statusBarHeight()
    }
    
    func calculateTotalHeightRecursively() -> CGFloat {
        return _statusBarHeight()
    }
}
