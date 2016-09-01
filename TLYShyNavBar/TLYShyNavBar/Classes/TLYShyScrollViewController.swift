//
//  Copyright © 2016年 xiAo_Ju. All rights reserved.
//

class TLYShyScrollViewController: TLYShyChild {
    var scrollView: UIScrollView?
    var refreshControl: UIRefreshControl?
    var parent: TLYShyViewController?
    
    func updateLayoutIfNeeded() -> CGFloat {
        if let scrollView = scrollView {
            if scrollView.contentSize.height < CGFloat(FLT_EPSILON) && scrollView.isKindOfClass(UITableView.self) || scrollView.isKindOfClass(UICollectionView.self)  {
                return 0
            }
            
            let parentMaxY = parent?.maxYRelativeToView(scrollView.superview)
            let normalizedY = parentMaxY! - scrollView.frame.minY
            var insets = UIEdgeInsets(top: scrollView.contentInset.top, left: 0, bottom: scrollView.contentInset.bottom, right: 0)
            insets.top = normalizedY
            if normalizedY > CGFloat(-FLT_EPSILON) && UIEdgeInsetsEqualToEdgeInsets(insets, scrollView.contentInset) {
                let delta = insets.top - scrollView.contentInset.top
                if let  refreshControl = refreshControl {
                    if refreshControl.hidden {
                        scrollView.tly_setInsets(insets)
                    }
                } else {
                    scrollView.tly_setInsets(insets)
                }
                return delta
            }
            
            if normalizedY < -CGFloat(FLT_EPSILON) {
                var rect = scrollView.frame
                rect  = UIEdgeInsetsInsetRect(rect, insets)
                scrollView.frame = rect
                return updateLayoutIfNeeded()
            }
        }
        
        return 0
    }
    
    func offsetCenterBy(deltaPoint: CGPoint) {
        updateLayoutIfNeeded()
    }
}
