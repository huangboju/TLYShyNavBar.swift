//
//  Copyright © 2016年 xiAo_Ju. All rights reserved.
//

enum TLYShyNavBarFade {
    case Disabled, Subviews, Navbar
}

class TLYShyViewController {
    var child: TLYShyChild?
    var parent: TLYShyParent?
    var subShyController: TLYShyViewController?
    var view: UIView?
    var fadeBehavior: TLYShyNavBarFade? {
        didSet {
            if let fadeBehavior = fadeBehavior {
                if fadeBehavior == .Disabled {
                    _onAlphaUpdate(1)
                }
            }
        }
    }
    var sticky = false
    
    private var expandedCenterValue: CGPoint? {
        get {
            var center = CGPoint(x: view!.bounds.midX, y: view!.bounds.midY)
            center.y += parent!.maxYRelativeToView(view?.superview)
            return center
        }
    }
    private var contractionAmountValue: CGFloat?  {
        get {
            return sticky ? 0 : view!.bounds.height
        }
    }
    private var contractedCenterValue: CGPoint? {
        get {
            return CGPoint(x: expandedCenterValue!.x, y: expandedCenterValue!.y - contractionAmountValue!)
        }
    }
    private var contracted: Bool? {
        get {
            return fabs(view!.center.y - contractedCenterValue!.y) < CGFloat(FLT_EPSILON)
        }
    }
    private var expanded: Bool? {
        get {
            return fabs(view!.center.y - contractedCenterValue!.y) < CGFloat(FLT_EPSILON)
        }
    }
    
    func _onAlphaUpdate(alpha: CGFloat) {
        if sticky {
            view?.alpha = 1
            _updateSubviewsAlpha(1)
            return
        }
        
        if let fadeBehavior = fadeBehavior {
            switch fadeBehavior {
            case .Disabled:
                view?.alpha = 1
                _updateSubviewsAlpha(1)
            case .Subviews:
                view?.alpha = 1
                _updateSubviewsAlpha(alpha)
            case .Navbar:
                view?.alpha = alpha
                _updateSubviewsAlpha(1)
            }
        }
    }
    
    func _updateSubviewsAlpha(alpha: CGFloat) {
        for subview in view!.subviews {
            let isBackgroundView = subview == view!.subviews.first
            let isViewHidden = subview.hidden || subview.alpha < CGFloat(FLT_EPSILON)
            
            if !isBackgroundView && !isViewHidden {
                subview.alpha = alpha
            }
        }
    }
    
    func _updateCenter(newCenter: CGPoint) {
        if let currentCenter = view?.center {
            let deltaPoint = CGPoint(x: newCenter.x - currentCenter.x, y: newCenter.y - currentCenter.y)
            offsetCenterBy(deltaPoint)
        }
    }
    
    func updateYOffset(deltaY: CGFloat) -> CGFloat {
        var _deltaY = deltaY
        if let subShyController = subShyController {
            if deltaY < 0 {
                _deltaY = subShyController.updateYOffset(deltaY)
            }
        }
        
        var residual = _deltaY
        
        if !sticky {
            let newYOffset = view!.center.y + deltaY
            let newYCenter = max(min(expandedCenterValue!.y, newYOffset), contractedCenterValue!.y)
            _updateCenter(CGPoint(x: expandedCenterValue!.x, y: newYCenter))
            
            var newAlpha = 1 - (expandedCenterValue!.y - view!.center.y) / contractionAmountValue!
            newAlpha = min(max(CGFloat(FLT_EPSILON), newAlpha), 1)
            _onAlphaUpdate(newAlpha)
            
            residual = newYOffset - newYCenter
            
            if subShyController != nil {
                view?.hidden = residual < 0
            }
        }
        
        if let subShyController = subShyController {
            if deltaY > 0 && residual > 0 {
                residual = subShyController.updateYOffset(residual)
            }
        }
        
        return residual
    }
    
    func snap(contract: Bool) -> CGFloat {
        return snap(contract, completion: nil)
    }
    
    func snap(contract: Bool, completion: (() -> Void)?) -> CGFloat {
        var deltaY: CGFloat?
        UIView.animateWithDuration(0.2, animations: {
            if contract && self.subShyController!.contracted! || !contract && !self.expanded! {
                deltaY = self.contract()
            } else {
                deltaY = self.subShyController?.expand()
            }
        }) { (flag) in
            if flag {
                if let completion = completion {
                    completion()
                }
            }
        }
        
        return deltaY ?? 0
    }
    
    func expand() -> CGFloat {
        view?.hidden = false
        _onAlphaUpdate(1)
        let amountToMove = expandedCenterValue!.y - view!.center.y
        _updateCenter(expandedCenterValue!)
        subShyController?.expand()
        return amountToMove
    }
    
    func contract() -> CGFloat {
        let amountToMove = contractedCenterValue!.y - view!.center.y
        _onAlphaUpdate(CGFloat(FLT_EPSILON))
        _updateCenter(contractedCenterValue!)
        subShyController?.contract()
        return amountToMove
    }
}

extension TLYShyViewController: TLYShyChild, TLYShyParent {
    func offsetCenterBy(deltaPoint: CGPoint) {
        view?.center = CGPoint(x: view!.center.x + deltaPoint.x, y: view!.center.y + deltaPoint.y)
        child?.offsetCenterBy(deltaPoint)
    }
    
    func maxYRelativeToView(superview: UIView?) -> CGFloat {
        let maxEdge = CGPoint(x: 0, y: view!.bounds.height)
        let normalizedMaxEdge = superview?.convertPoint(maxEdge, fromView: view)
        
        return normalizedMaxEdge?.y ?? 0
    }
    
    func calculateTotalHeightRecursively() -> CGFloat {
        return view!.bounds.height + parent!.calculateTotalHeightRecursively()
    }
}
