import UIKit

class ViewController: UIViewController {

    enum CardState {
        case expanded
        case collapsed
    }
    
    private var cardViewController: CardViewController!
    private var visualEffectView: UIVisualEffectView!
    
    private let cardExpandedHeight: CGFloat = 600
    private let cardCollapsedHeight: CGFloat = 84
    
    private var cardState: CardState = .collapsed
    private var inverseCardState: CardState {
        cardState != .collapsed ? .collapsed : .expanded
    }
    
    private var runningAnimations = [UIViewPropertyAnimator]()
    private var animationProgressWhenInterrupted: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCard()
    }
    
    func setupCard() {
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = view.frame
        view.addSubview(visualEffectView)
        
        cardViewController = CardViewController(nibName: "CardViewController", bundle: nil)
        add(child: cardViewController)
        
        cardViewController.view.frame = CGRect(x: 0, y: view.frame.height - cardCollapsedHeight, width: view.frame.width, height: cardExpandedHeight)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleCardTap(recognizer:)))
        cardViewController.handleView.addGestureRecognizer(tapGestureRecognizer)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleCardPan(recognizer:)))
        cardViewController.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc
    func handleCardTap(recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            animateTransitionIfNeeded(state: inverseCardState, duration: 0.5)
        }
    }
    
    @objc
    func handleCardPan(recognizer: UIPanGestureRecognizer) {
        switch(recognizer.state) {
        case .began:
            startInteractiveTransition(state: inverseCardState, duration: 0.5)
        case .changed:
            let translation = recognizer.translation(in: cardViewController.handleView)
            var fractionComplete = translation.y / cardExpandedHeight
            fractionComplete = cardState == .expanded ? fractionComplete : -fractionComplete
            updateInteractionTransition(fractionCompleted: fractionComplete)
        case .ended:
            continueInteractiveTransition()
        default:
            break
        }
    }
    
    func animateTransitionIfNeeded(state: CardState, duration: TimeInterval) {
        guard runningAnimations.isEmpty else { return }
        
        let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
            switch state {
            case .expanded:
                self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardExpandedHeight
            default:
                self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardCollapsedHeight
            }
        }
        
        frameAnimator.addCompletion { _ in
            self.cardState = self.inverseCardState
            self.runningAnimations.removeAll()
        }
        
        runningAnimations.append(frameAnimator)
        
        let blurAnimation = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
            switch state {
            case .expanded:
                self.visualEffectView.effect = UIBlurEffect(style: .dark)
            default:
                self.visualEffectView.effect = nil
            }
        }
        runningAnimations.append(blurAnimation)

        frameAnimator.startAnimation()
        blurAnimation.startAnimation()
    }
    
    private func startInteractiveTransition(state: CardState, duration: TimeInterval) {
        animateTransitionIfNeeded(state: state, duration: duration)
        
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    private func updateInteractionTransition(fractionCompleted: CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    private func continueInteractiveTransition() {
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
}
