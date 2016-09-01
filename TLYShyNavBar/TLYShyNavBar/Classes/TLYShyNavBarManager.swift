//
//  Copyright © 2016年 xiAo_Ju. All rights reserved.
//

protocol TLYShyNavBarManagerDelegate {
    func shyNavBarManagerDidBecomeFullyContracted(shyNavBarManager: TLYShyNavBarManager)
    func shyNavBarManagerDidFinishContracting(shyNavBarManager: TLYShyNavBarManager)
    func shyNavBarManagerDidFinishExpanding(shyNavBarManager: TLYShyNavBarManager)
}

typealias KVOContext = UInt8
var kTLYShyNavBarManagerKVOContext = KVOContext()

class TLYShyNavBarManager: NSObject {
    var viewController: UIViewController? {
        didSet {
            if let viewController = viewController {
                if viewController.isKindOfClass(UITableViewController.self) || viewController.view.isKindOfClass(UITableViewController.self) {
                    print("*** WARNING: Please consider using a UIViewController with a UITableView as a subview ***")
                }
                let navbar = viewController.navigationController?.navigationBar
                assert(navbar != nil, "Please make sure the viewController is already attached to a navigation controller.")
                viewController.extendedLayoutIncludesOpaqueBars = true
                extensionViewContainer.removeFromSuperview()
                viewController.view.addSubview(extensionViewContainer)
                navBarController.view = navbar
                layoutViews()
            }
        }
    }
    var scrollView: UIScrollView? {
        didSet {
            scrollView?.removeObserver(self, forKeyPath: "contentSize", context: &kTLYShyNavBarManagerKVOContext)
            scrollView?.delegate
            if let delegate = delegateProxy as? UIScrollViewDelegate {
//                scrollView?.delegate = delegateProxy?.originalDelegate
            }
            
            scrollViewController.scrollView = scrollView
            
            if let index = scrollView?.subviews.indexOf({
                $0.isKindOfClass(UIRefreshControl.self)
            }) {
                scrollViewController.refreshControl = scrollView?.subviews[index.bigEndian] as? UIRefreshControl
            }
            
            if (delegateProxy as? UIScrollViewDelegate) == nil {
                
            }
            
            cleanup()
            layoutViews()
            scrollView?.addObserver(self, forKeyPath: "contentSize", options: .New, context: &kTLYShyNavBarManagerKVOContext)
        }
    }
    var extensionView: UIView? {
        willSet {
            if newValue != extensionView {
                var bounds = newValue?.frame
                bounds?.origin = .zero
                
                newValue?.frame = bounds!
                
                extensionViewContainer.frame = bounds!
                extensionViewContainer.addSubview(newValue!)
                extensionViewContainer.userInteractionEnabled = newValue!.userInteractionEnabled
                let wasDisabled = disable
                disable = true
                layoutViews()
                disable = wasDisabled
            }
        }
    }
    var extensionViewBounds: CGRect {
        return extensionViewContainer.bounds
    }
    var stickyNavigationBar: Bool {
        set {
            navBarController.sticky = newValue
        }
        
        get {
            return navBarController.sticky
        }
    }
    var stickyExtensionView: Bool {
        set {
            extensionController.sticky = newValue
        }
        
        get {
            return extensionController.sticky
        }
    }
    var expansionResistance: CGFloat = 200
    var contractionResistance: CGFloat = 0
    var fadeBehavior = TLYShyNavBarFade.Subviews
    var disable: Bool = false {
        didSet {
            if disable == oldValue {
                return
            }
            
            if !disable {
                previousYOffset = scrollView!.contentOffset.y
            }
        }
    }
    var delegate: TLYShyNavBarManagerDelegate?
    
    private let statusBarController = TLYShyStatusBarController()
    private let navBarController = TLYShyViewController()
    private let extensionController = TLYShyViewController()
    private var scrollViewController = TLYShyScrollViewController()
    private var delegateProxy: TLYDelegateProxy?
    private let extensionViewContainer = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 0))
    private var previousYOffset: CGFloat = .NaN
    private var resistanceConsumed: CGFloat?
    private var contracting = false
    private var previousContractionState = true
    private var isViewControllerVisible: Bool {
        return viewController!.isViewLoaded() && viewController?.view.window != nil
    }
    
    override init() {
        super.init()
        extensionViewContainer.backgroundColor = UIColor.clearColor()
        extensionViewContainer.autoresizingMask = [.FlexibleWidth, .FlexibleBottomMargin]
        
        extensionController.view = extensionViewContainer
        
        navBarController.parent = statusBarController
        navBarController.child = extensionController
        navBarController.subShyController = extensionController
        extensionController.parent = navBarController
        extensionController.child = scrollViewController
        scrollViewController.parent = extensionController
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationDidChangeStatusBarFrame), name: UIApplicationDidChangeStatusBarFrameNotification, object: nil)
        
    }
    
    deinit {
        if scrollView?.delegate === delegateProxy {
//            scrollView?.delegate = delegateProxy?.originalDelegate
        }
        NSNotificationCenter.defaultCenter().removeObserver(self)
        scrollView?.removeObserver(self, forKeyPath: "contentSize", context: &kTLYShyNavBarManagerKVOContext)
    }
    
    func _shouldHandleScrolling() -> Bool {
        if disable {
            return false
        }
        
        return isViewControllerVisible && _scrollViewIsSuffecientlyLong()
    }
    
    func _scrollViewIsSuffecientlyLong() -> Bool {
        let scrollFrame =  UIEdgeInsetsInsetRect(scrollView!.bounds, scrollView!.contentInset)
        let scrollableAmount = scrollView!.contentSize.height - scrollFrame.height
        return scrollableAmount > extensionController.calculateTotalHeightRecursively()
    }
    
    func _handleScrolling() {
        if !_shouldHandleScrolling() {
            return
        }
        
        if !isnan(previousYOffset) {
            
            var deltaY = previousYOffset - scrollView!.contentOffset.y
            
            let start = -scrollView!.contentInset.top
            if previousYOffset < start {
                deltaY = min(0, deltaY - (previousYOffset - start))
            }
            
            let end = floor(scrollView!.contentSize.height - scrollView!.bounds.height + scrollView!.contentInset.bottom - 0.5)
            if previousYOffset > end && deltaY > 0 {
                deltaY = max(0, deltaY - previousYOffset + end)
            }
            
            if fabs(deltaY) > CGFloat(FLT_EPSILON) {
                contracting = deltaY < 0
            }
            
            if contracting != previousContractionState {
                previousContractionState = contracting
                resistanceConsumed = 0
            }
            
            if contracting {
                let availableResistance = contractionResistance - resistanceConsumed!
                resistanceConsumed = min(contractionResistance, resistanceConsumed! - deltaY)
                
                deltaY = min(0, availableResistance + deltaY)
            } else if scrollView?.contentOffset.y > 0 {
                let availableResistance = expansionResistance - resistanceConsumed!
                resistanceConsumed = min(expansionResistance, resistanceConsumed! + deltaY)
                
                deltaY = max(0, deltaY - availableResistance)
            }
            
            navBarController.fadeBehavior = fadeBehavior
            
            let maxNavY = navBarController.view?.frame.maxX
            let maxExtensionY = extensionViewContainer.frame.maxY
            var visibleTop: CGFloat?
            if extensionViewContainer.hidden {
                visibleTop = maxNavY
            } else {
                visibleTop = max(maxNavY!, maxExtensionY)
            }
            if visibleTop == statusBarController.calculateTotalHeightRecursively() {
                //TODO:
            }
            
            navBarController.updateYOffset(deltaY)
        }
        
        previousYOffset = scrollView!.contentOffset.y
    }
    
    func _handleScrollingEnded() {
        if !isViewControllerVisible {
            return
        }
        
        let completion = { [weak self] in
            if self != nil {
//                if self!.contracting {
//                    if self!.delegate {
//                        <#code#>
//                    }
//                }
            }
        }
        
        resistanceConsumed = 0
        navBarController.snap(contracting, completion: completion)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &kTLYShyNavBarManagerKVOContext {
            if isViewControllerVisible && _scrollViewIsSuffecientlyLong() {
               navBarController.expand()
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    func applicationDidBecomeActive() {
        navBarController.expand()
    }
    
    func applicationDidChangeStatusBarFrame() {
        navBarController.expand()
    }
    
    func layoutViews() {
        if fabs(scrollViewController.updateLayoutIfNeeded()) > CGFloat(FLT_EPSILON) {
            navBarController.expand()
            extensionViewContainer.superview?.bringSubviewToFront(extensionViewContainer)
        }
    }
    
    func prepareForDisplay() {
        cleanup()
    }
    
    func cleanup() {
        navBarController.expand()
        previousYOffset = .NaN
    }
}

extension TLYShyNavBarManager: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        _handleScrolling()
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            _handleScrollingEnded()
        }
    }
    
    func scrollViewDidScrollToTop(scrollView: UIScrollView) {
        self.scrollView?.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
        self.scrollView?.flashScrollIndicators()
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        _handleScrollingEnded()
    }
}

var shyNavBarManagerKey = "shyNavBarManagerKey"

extension UIViewController {
    var shyNavBarManager: TLYShyNavBarManager? {
        set {
            setShyNavBarManager(newValue, viewController: self)
        }
        
        get {
            var shyNavBarManager = objc_getAssociatedObject(self, &shyNavBarManagerKey) as? TLYShyNavBarManager
            if shyNavBarManager == nil {
                shyNavBarManager = TLYShyNavBarManager()
                self.shyNavBarManager = shyNavBarManager
            }
            return shyNavBarManager
        }
    }
    
    public class func loaad() {
        var onceToken: dispatch_once_t = 0
        dispatch_once(&onceToken) { 
            tly_swizzleInstanceMethod(#selector(viewWillAppear), with: #selector(tly_swizzledViewWillAppear))
            tly_swizzleInstanceMethod(#selector(viewWillLayoutSubviews), with: #selector(tly_swizzledViewDidLayoutSubviews))
            tly_swizzleInstanceMethod(#selector(viewWillDisappear), with: #selector(tly_swizzledViewWillDisappear))
        }
    }
    
    //MARK: - Swizzled View Life Cycle
    func tly_swizzledViewWillAppear(animated: Bool) {
        _internalShyNavBarManager()?.prepareForDisplay()
        tly_swizzledViewWillAppear(animated)
    }
    
    func tly_swizzledViewDidLayoutSubviews() {
        _internalShyNavBarManager()?.layoutViews()
        tly_swizzledViewDidLayoutSubviews()
    }
    
    func tly_swizzledViewWillDisappear(animated: Bool) {
        _internalShyNavBarManager()?.cleanup()
        tly_swizzledViewWillDisappear(animated)
    }
    
    func isShyNavBarManagerPresent() -> Bool {
        return _internalShyNavBarManager() != nil
    }
    
    func setShyNavBarManager(shyNavBarManager: TLYShyNavBarManager?, viewController: UIViewController) {
        shyNavBarManager?.viewController = viewController
        objc_setAssociatedObject(self, &shyNavBarManagerKey, shyNavBarManager, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func _internalShyNavBarManager() -> TLYShyNavBarManager? {
        return objc_getAssociatedObject(self, &shyNavBarManagerKey) as? TLYShyNavBarManager
    }
}







