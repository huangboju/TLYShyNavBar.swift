//
//  Copyright © 2016年 xiAo_Ju. All rights reserved.
//

protocol TLYShyParent {
    func maxYRelativeToView(superview: UIView?) -> CGFloat
    func calculateTotalHeightRecursively() -> CGFloat
}
