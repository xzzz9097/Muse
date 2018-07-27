//
//  ViewController.swift
//  Muse
//
//  Created by Marco Albera on 21/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa
import QuartzCore
import Carbon.HIToolbox
import SpotifyKit

@available(OSX 10.12.2, *)
fileprivate extension NSButton {
    
    static var playerActions: [PlayerAction: Selector] { return
        [.play:             #selector(ViewController.togglePlayPauseButtonClicked(_:)),
         .pause:            #selector(ViewController.togglePlayPauseButtonClicked(_:)),
         .previous:         #selector(ViewController.previousTrackButtonClicked(_:)),
         .next:             #selector(ViewController.nextTrackButtonClicked(_:)),
         .shuffling(false): #selector(WindowController.shuffleButtonClicked(_:)),
         .repeating(false): #selector(WindowController.repeatButtonClicked(_:)),
         .like(false):      #selector(WindowController.likeButtonClicked(_:))]
    }
    
    var playerAction: PlayerAction? {
        set {
            self.tag = newValue?.rawValue ?? -1
            
            if let action = newValue {
                self.action = NSButton.playerActions[action]
                self.setImagePreservingTint(action.smallImage)
            } else {
                self.action = nil
            }
        }
        
        get {
            return PlayerAction(rawValue: self.tag)
        }
    }
}

fileprivate extension NSTabView {
    
    // All the tabs in our tab view
    // with the rawValue representing the index
    enum Tab: Int {
        case playbackControls, playbackOptions
    }
    
    /**
     Returns true when the specified tab is selected
     - parameter tab: the specified tab, listed in the enum
     */
    func isSelected(_ tab: Tab) -> Bool {
        guard let selected = selectedTabViewItem else { return false }
        
        return indexOfTabViewItem(selected) == tab.rawValue
    }
}

fileprivate extension NSLayoutConstraint {
    
    enum SongProgressBarMode: CGFloat {
        case compressed = 2
        case expanded   = 11
    }
    
    var progressBarMode: SongProgressBarMode? {
        set {
            if let mode = newValue { self.constant = mode.rawValue }
        }
        
        get {
            return SongProgressBarMode(rawValue: self.constant)
        }
    }
}

extension NSTextField {
    
    /**
     Sets caret color for current window's field editor
     */
    func setCaretColor(in window: NSWindow?, _ color: NSColor) {
        ( window?.fieldEditor(true, for: self) as? NSTextView )?.insertionPointColor = color
    }
}

extension ImageColors {
    
    func map(_ transform: (NSColor?) -> (NSColor?)) -> ImageColors {
        let colors = [background, primary, secondary, detail].map {
            transform($0)
        }
        
        return ImageColors(background: colors[0],
                           primary:    colors[1],
                           secondary:  colors[2],
                           detail:     colors[3])
    }
    
    var designatedSecondary: NSColor? {
        return secondary.distance(from: primary) >
            detail.distance(from: primary) ? secondary : detail
    }
    
    var highlight: NSColor? {
        if let secondary = designatedSecondary, secondary.distance(from: primary) < 0.02 {
            return secondary.blended(withFraction: 0.5, of: secondary.isDarkColor ? .lightGray : .darkGray)
        }
        
        return designatedSecondary
    }
}

enum MainViewComponent {
    
    case main
    case actionBar
    case results
    case expandedProgressBar
    case tabDots
    case songTitle
    
    var height: CGFloat? {
        switch self {
        case .main:
            return 275
        case .actionBar:
            return 35
        case .results:
            return 180
        default:
            return nil
        }
    }
}

enum MainViewMode {
    
    case compressed
    case partiallyExpanded
    case expanded
    case expandedWithResults
    
    static var defaultMode: MainViewMode {
        return Preference<Bool>(.actionBar).value ? .partiallyExpanded : .compressed
    }
    
    var isHoveredMode: Bool {
        return self == .expanded || self == .expandedWithResults
    }
    
    var components: [MainViewComponent] {
        switch self {
        case .partiallyExpanded:
            return [.main, .actionBar]
        case .expanded:
            return [.main, .actionBar, .expandedProgressBar, .tabDots, .songTitle]
        case .expandedWithResults:
            return [.main, .actionBar, .expandedProgressBar, .tabDots, .songTitle, .results]
        default:
            return [.main]
        }
    }
    
    var height: CGFloat {
        return self.components.reduce(0) { $0 + ($1.height ?? 0) }
    }
    
    func has(_ component: MainViewComponent) -> Bool {
        return self.components.contains(component)
    }
}

@available(OSX 10.12.2, *)
class ViewController: NSViewController, NSTextFieldDelegate {
    
    // MARK: Properties
    
    // The results mode
    enum ResultsMode {
        case trackSearch
        case playlists
    }
    
    // Results mode master switch
    var resultsMode: ResultsMode = .trackSearch
    
    // The search results
    var trackSearchResults: [Song] = []
    
    // The playlists results
    var playlistsResults: [Playlist] = []
    
    // Time of last track search
    var trackSearchStartTime: TimeInterval = 0
    
    // Current artwork image colors
    var colors: ImageColors?
    
    // Action view auto close
    let actionViewTimeout:        TimeInterval = 1       // Timeout in seconds
    var actionViewAutoCloseTimer: Timer        = Timer() // The timer
    
    // Title view auto close
    let titleViewTimeout:         TimeInterval = 2       // Timeout in seconds
    var titleViewAutoCloseTimer:  Timer = Timer()        // The timer
    
    // Preferences
    let shouldPeekControls = true  // Hide/show controls on mouse hover
    let shouldShowArtist   = false // Show artist in title popup view
 
    var shouldShowActionBar: Bool {
        set {
            Preference<Bool>(.actionBar).set(newValue)
            
            if !mainViewMode.isHoveredMode {
                mainViewMode = MainViewMode.defaultMode
            }
        }
        
        get {
            return Preference<Bool>(.actionBar).value
        }
    }
    
    var shouldShowResultsTableView = false {
        didSet {
            showResultsTableView()
        }
    }
    
    // MARK: Helpers
    
    var helper: PlayerHelper {
        guard let window = self.view.window, let windowController = window.windowController as? WindowController else {
            // Default helper
            return PlayersManager.shared.defaultHelper
        }
        
        // Returns helper from WindowController
        // TODO: Move helper outside WC
        return windowController.helper
    }
    
    // A gesture recognizer for single click events
    var searchGestureRecognizer: NSGestureRecognizer {
        let recognizer = NSClickGestureRecognizer()
        
        recognizer.target = self
        recognizer.action = #selector(startSearch)
        
        return recognizer
    }
    
    // MARK: Outlets

    @IBOutlet weak var fullSongArtworkView:   NSImageView!
    @IBOutlet weak var titleLabelView:        NSTextField!
    @IBOutlet weak var albumArtistLabelView:  NSTextField!
    @IBOutlet weak var actionImageView:       NSImageView!
    @IBOutlet weak var actionCheckView:       DrawableView!
    @IBOutlet weak var actionTextField:       NSTextField!
    @IBOutlet weak var titleTextField:        NSTextField!
    @IBOutlet weak var songProgressBar:       NSSlider!
    @IBOutlet weak var likeButton:            NSButton!
    @IBOutlet weak var shuffleButton:         NSButton!
    @IBOutlet weak var repeatButton:          NSButton!
    @IBOutlet weak var actionTabView:         NSTabView!
    @IBOutlet weak var playButton:            NSButton!
    @IBOutlet weak var previousButton:        NSButton!
    @IBOutlet weak var nextButton:            NSButton!
    @IBOutlet weak var songProgressBarHeight: NSLayoutConstraint!
    @IBOutlet weak var nextTabButton:         NSCustomizableButton!
    @IBOutlet weak var previousTabButton:     NSCustomizableButton!
    @IBOutlet weak var resultsTableView:      KeySensitiveTableView?
    
    // MARK: Superviews
    
    var titleAlbumArtistSuperview: NSView!
    var actionSuperview:           NSView!
    var titleSuperview:            NSHoverableView!
    var actionBarSuperview:        NSView!
    var resultsSuperview:          NSView!
    
    var mainView: NSHoverableView? {
        return self.view as? NSHoverableView
    }
    
    var mainViewMode: MainViewMode = MainViewMode.defaultMode {
        didSet {
            updateViewsVisibility()
        }
    }
    
    // MARK: Actions
    
    @IBAction func previousTrackButtonClicked(_ sender: Any) {
        helper.previousTrack()
    }
    
    @IBAction func togglePlayPauseButtonClicked(_ sender: Any) {
        helper.togglePlayPause()
    }
    
    @IBAction func nextTrackButtonClicked(_ sender: Any) {
        helper.nextTrack()
    }
    
    @IBAction func songProgressSliderValueChanged(_ sender: Any) {
        // Track progress slider changes
        if let slider = sender as? NSSlider {
            guard let currentEvent = NSApplication.shared().currentEvent else { return }
            
            if currentEvent.type == .leftMouseDragged {
                // Detected mouse down
                helper.scrub(to: slider.doubleValue, touching: true)
            }
            
            if currentEvent.type == .leftMouseUp {
                // Detected mouse up
                helper.scrub(to: slider.doubleValue, touching: false)
            }
        }
    }
    
    func goToNextActionTab() {
        actionTabView.selectNextTabViewItem(self)
    }
    
    func goToPreviousActionTab() {
        actionTabView.selectPreviousTabViewItem(self)
    }
    
    func goToActionTab(at index: Int) {
        actionTabView.selectTabViewItem(at: index)
    }
    
    // MARK: Key handlers
    
    override func keyDown(with event: NSEvent) {
        // Ensure that no text field is first responder
        // We don't want to intercept keystrokes while text editing
        if let _ = view.window?.firstResponder as? NSTextView { return }
        
        switch KeyCombination(event.modifierFlags, event.keyCode) {
        case KeyCombination(.command, kVK_ANSI_1):
            goToActionTab(at: 0)
        case KeyCombination(.command, kVK_ANSI_2):
            goToActionTab(at: 1)
        case kVK_ANSI_I:
            showTitleView()
        case kVK_ANSI_B:
            shouldShowActionBar = !shouldShowActionBar
        case KeyCombination(.command, kVK_ANSI_F):
            startSearch()
        case KeyCombination(.command, kVK_ANSI_P):
            startPlaylists()
        default: break
        }
    }
    
    /**
     - parameter direction: true for up, false for down
     - return: true if the event has been handled by the ViewController
     */
    @discardableResult
    func handleArrowKeysOrReturn() -> Bool {
        if mainViewMode == .expandedWithResults {
            resultsTableView?.keyDown(with: NSApp.currentEvent!)
            return true
        }
        
        // Pass the event back to WindowController
        return false
    }
    
    /**
     Handles escape key events sent fron WindowController
     - return: true if the event has been handled by the ViewController
     */
    @discardableResult
    func handleEscape() -> Bool {
        if mainViewMode == .expandedWithResults {
            switch resultsMode {
            case .trackSearch:
                endSearch(canceled: true)
            case .playlists:
                endPlaylists()
            }
            
            return true
        }
        
        // Pass the event back to WindowController
        return false
    }
    
    // MARK: UI preparation
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleAlbumArtistSuperview = titleLabelView.superview
        actionSuperview           = actionImageView.superview
        titleSuperview            = titleTextField.superview as? NSHoverableView
        actionBarSuperview        = actionTabView.superview
        resultsSuperview          = resultsTableView?.superview?.superview?.superview
        
        [titleAlbumArtistSuperview,
         actionSuperview,
         titleSuperview,
         actionTabView,
         resultsSuperview].forEach { $0?.wantsLayer = true }
        
        showActionBarView()
        showResultsTableView()
        
        registerObserver()
        
        registerKeyDown()
    }
    
    func registerKeyDown() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            self.keyDown(with: event)
            return event
        }
    }
    
    func registerObserver() {
        PlayerNotification.observe { [weak self] event in
            switch event {
            case .next, .previous:
                self?.showTitleView()
            case .scrub(let touching, _):
                self?.showLastActionView(for: event,
                                              shouldClose: !touching)
                return
            case .shuffling(let shuffling):
                self?.updateShuffleRepeatButtons(shuffling: shuffling)
            case .repeating(let repeating):
                self?.updateShuffleRepeatButtons(repeating: repeating)
            default: break
            }
            
            self?.showLastActionView(for: event)
        }
    }
    
    override func viewWillAppear() {
        setBackgroundAndShadow(for: titleAlbumArtistSuperview)
        
        prepareSongProgressBar()
        prepareFullSongArtworkView()
        prepareLastActionView()
        prepareActionBarButtons()
        prepareTitleView()
        prepareResultsTableView()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func setBackgroundAndShadow(for superview: NSView!) {
        guard let layer = superview.layer else { return }
        
        // Set background color
        layer.backgroundColor = NSColor.controlColor.cgColor
        
        // Set the shadow
        superview.shadow = NSShadow()
        setShadow(for: layer)
    }
    
    func setShadow(for layer: CALayer) {
        // Create shadow
        layer.shadowColor = NSColor.controlShadowColor.cgColor
        layer.shadowRadius = 0.5
        layer.shadowOpacity = 1
    }
    
    func prepareResultsTableView() {
        resultsTableView?.delegate        = self
        resultsTableView?.dataSource      = self
        resultsTableView?.backgroundColor = .clear
        resultsTableView?.doubleAction    = #selector(tableViewDoubleClicked)
        resultsTableView?.returnAction    = tableViewDoubleClicked
    }
    
    func prepareSongProgressBar() {
        guard let cell = self.songProgressBar.cell as? SliderCell else { return }
        
        // Customize slider thumb
        cell.width       = view.frame.width
        cell.knobWidth   = 2.0
        cell.knobMargin  = 0.0
        cell.height      = 11.0
        
        // Remove corner radius
        cell.radius = 0
    }
    
    func prepareFullSongArtworkView() {
        // Set image scaling
        fullSongArtworkView.imageScaling = .scaleAxesIndependently
        
        guard self.shouldPeekControls else { return }
        
        updateViewsVisibility()
        
        // Add callback to show/hide views when hovering (animating)
        mainView?.onMouseHoverStateChange = { [weak self] state in
            guard let strongSelf = self else { return }
            
            switch state {
            case .entered:
                if !strongSelf.mainViewMode.isHoveredMode {
                    strongSelf.mainViewMode = .expanded
                }
            case .exited:
                if strongSelf.mainViewMode == .expandedWithResults {
                    strongSelf.endSearch(canceled: true)
                } else {
                    strongSelf.mainViewMode = MainViewMode.defaultMode
                }
            }
        }
        
        mainView?.onMouseScrollEvent = { [weak self] event in
            guard let direction = event.direction else { return }
            
            switch direction {
            case .left:
                self?.helper.previousTrack()
            case .right:
                self?.helper.nextTrack()
            default:
                break
            }
        }
    }
    
    func updateViewsVisibility() {
        showSongTitle(show: mainViewMode.has(.songTitle))
        
        showActionBarView(show: mainViewMode.has(.actionBar))
        
        showResultsTableView(show: mainViewMode.has(.results))
        
        showExpandedProgressBar(show: mainViewMode.has(.expandedProgressBar))
        
        showTabNavigationButtons(show: mainViewMode.has(.tabDots))
    }
    
    func prepareLastActionView() {
        guard let layer = actionSuperview.layer else { return }
        
        // Set radius
        layer.cornerRadius = 7.5
        layer.masksToBounds = true
        
        // Set shadow
        actionSuperview.shadow = NSShadow()
        setShadow(for: layer)
        
        actionCheckView.shapePath = DrawableViewShapePath.forCheckLineIn(actionCheckView,
                                                                         margin: 8.0)
    }
    
    func prepareActionBarButtons() {
        playButton.playerAction     = .play
        previousButton.playerAction = .previous
        nextButton.playerAction     = .next
        shuffleButton.playerAction  = .shuffling(false)
        repeatButton.playerAction   = .repeating(false)
        likeButton.playerAction     = .like(false)
        
        [likeButton, shuffleButton, repeatButton, playButton, previousButton, nextButton].forEach {
            $0?.imagePosition       = .imageOnly
            $0?.isBordered          = false
            $0?.wantsLayer          = true
            $0?.layer?.cornerRadius = 4.0
        }
        
        [nextTabButton, previousTabButton].forEach {
            guard let button = $0 else { return }
            
            button.circleShaped(scale: 1/5)
            
            // Dim tab buttons when hovered
            button.onMouseHoverStateChange = { state in
                switch state {
                case .entered:
                    button.animator().alphaValue = 0.5
                case .exited:
                    button.animator().alphaValue = 1.0
                }
            }
        }
        
        nextTabButton.action     = #selector(goToNextActionTab)
        previousTabButton.action = #selector(goToPreviousActionTab)
    }
    
    func prepareTitleView() {
        guard let layer = titleSuperview.layer else { return }
        
        // Set radius
        layer.cornerRadius = 7.5
        layer.masksToBounds = true
        
        titleSuperview.onMouseHoverStateChange = { [weak self] state in
            guard let strongSelf = self else { return }
            
            if state == .exited, strongSelf.mainViewMode == .expandedWithResults {
                strongSelf.endSearch(canceled: true)
            }
            
            guard strongSelf.mainViewMode != .expandedWithResults else { return }
            
            strongSelf.titleTextField.stringValue = state == .exited ?
                strongSelf.titleLabelView.stringValue : strongSelf.albumArtistLabelView.stringValue
        }
        
        titleTextField.addGestureRecognizer(searchGestureRecognizer)
        
        titleTextField.focusRingType = .none
        titleTextField.delegate      = self
    }
    
    // MARK: UI activation
    
    func showTitleView(shouldClose: Bool = true) {
        // Invalidate existing timers
        // This prevents calls form precedent ones
        titleViewAutoCloseTimer.invalidate()
        
        // Show the view
        titleSuperview.animator().isHidden = false
        
        // This keeps time info visible while sliding
        guard shouldClose, mainViewMode != .expanded else { return }
        
        // Restart the autoclose timer
        launchTitleViewAutoCloseTimer()
    }
    
    func launchTitleViewAutoCloseTimer() {
        titleViewAutoCloseTimer = Timer.scheduledTimer(withTimeInterval: titleViewTimeout,
                                                       repeats: false)
        { [weak self] timer in
            guard let strongSelf = self, !strongSelf.mainViewMode.isHoveredMode else { return }
            
            // Hide the view and invalidate the timer
            strongSelf.titleSuperview.animator().isHidden = true
            timer.invalidate()
        }
    }
    
    func showLastActionView(for action:  PlayerAction,
                            shouldClose: Bool = true) {
        // Invalidate existing timers
        // This prevents calls from precedent ones
        actionViewAutoCloseTimer.invalidate()
        
        // Only show last action view when the corresponding control is not visible
        switch action {
        case .play, .pause, .next, .previous:
            if actionTabView.isSelected(.playbackControls) { return }
        case .shuffling, .repeating, .like:
            if actionTabView.isSelected(.playbackOptions) { return }
        case .scrub:
            if let mode = songProgressBarHeight.progressBarMode, mode == .expanded { return }
        }
        
        if let image = action.image {
            actionImageView.setImagePreservingTint(image)
        }
        
        switch action {
        case .shuffling, .repeating, .like:
            var shouldCheck = false
            
            // Determine if we should draw a check on the action view
            // to highlight off state for the action
            switch action {
            case .shuffling(let shuffling): shouldCheck = !shuffling
            case .repeating(let repeating): shouldCheck = !repeating
            case .like(let liked):          shouldCheck = !liked
            default: break
            }
            
            // Send the request to the view
            actionCheckView.shouldDrawShape = shouldCheck
        case .scrub(_, let time):
            // Hide image view if scrubbing
            actionImageView.isHidden = true
            
            // Set the string value formatted as MM:SS
            actionTextField.stringValue = time.secondsToMMSSString
        default:
            break
        }
        
        // Show image view if not scrubbing
        if case .scrub = action { } else { actionImageView.isHidden = false }
        
        // Show the view
        actionSuperview.animator().isHidden = false
        
        // This keeps time info visible while sliding
        guard shouldClose else { return }
        
        // Restart the autoclose timer
        actionViewAutoCloseTimer = Timer.scheduledTimer(withTimeInterval: actionViewTimeout,
                                                        repeats: false) { timer in
            // Hide the view and invalidate the timer
            self.actionSuperview.animator().isHidden = true
            self.actionTextField.stringValue = ""
            timer.invalidate()
        }
    }
    
    func showActionBarView(show: Bool? = nil) {
        let show = show ?? shouldShowActionBar
        
        view.toggleSubviewVisibilityAndResize(subviewHeight: MainViewComponent.actionBar.height!,
                                              windowHeight: MainViewMode.compressed.height,
                                              otherViewsHeight: [MainViewComponent.results.height!],
                                              visible: show)
        
        // Setup action bar buttons and colors
        if shouldShowActionBar {
            colorActionBar(background: titleSuperview.layer?.backgroundColor,
                           highlight: (songProgressBar.cell as! SliderCell).highlightColor)
        }
    }
    
    func showResultsTableView(show: Bool? = nil) {
        let show = show != nil ? show! : shouldShowResultsTableView
        
        view.toggleSubviewVisibilityAndResize(subviewHeight: MainViewComponent.results.height!,
                                              windowHeight: MainViewMode.expanded.height,
                                              otherViewsHeight: [MainViewComponent.actionBar.height!],
                                              visible: show)
        
        if shouldShowResultsTableView {
            prepareResultsTableView()
        }
    }
    
    func showExpandedProgressBar(show: Bool) {
        songProgressBarHeight.animator().progressBarMode = show ? .expanded : .compressed
    }
    
    func showTabNavigationButtons(show: Bool) {
        [nextTabButton, previousTabButton].forEach { $0?.isHidden = !show }
    }
    
    func showSongTitle(show: Bool) {
        if show {
            // Stop title view auto close timer
            titleViewAutoCloseTimer.invalidate()
            
            // Show title view
            showTitleView(shouldClose: false)
        } else {
            // Hide title view after 500ms
            DispatchQueue.main.run(after: 500) { [weak self] in
                guard let strongSelf = self, !strongSelf.mainViewMode.isHoveredMode else { return }
                
                strongSelf.titleSuperview.animator().isHidden = !show
            }
        }
    }
    
    // MARK: UI refresh
    
    func updateButtons() {
        playButton.playerAction = helper.isPlaying ? .pause : .play
    }
    
    func updateShuffleRepeatButtons(shuffling: Bool? = nil, repeating: Bool? = nil) {
        [shuffleButton, repeatButton].enumerated().forEach {
            let enabled         = $0.offset == 0 ?    shuffling : repeating
            let alpha: CGFloat? = enabled != nil ? enabled! ? 1 : 0.25 : nil
            
            if let alpha = alpha {
                $0.element?.layer?.backgroundColor = $0.element?.layer?.backgroundColor?
                    .copy(alpha: alpha)
            }
        }
    }
    
    func updateLikeButton(liked: Bool) {
        likeButton.layer?.backgroundColor = likeButton.layer?.backgroundColor?.copy(alpha: liked ? 1 : 0.25)
    }
    
    func updateFullSongArtworkView(with object: Any?) {
        // Update the artwork view with an image URL
        if let url = object as? URL {
            fullSongArtworkView.loadImage(from: url, fallback: .defaultBg, callback: { _ in })
        // Or an NSImage
        } else if let image = object as? NSImage {
            fullSongArtworkView.image = image
        }
        
        // If the image is not square we cut it instead of stretching it
        // We also crop the margin a bit to cut blank corners
        if let image = fullSongArtworkView.image {
            fullSongArtworkView.image = image.resized(
                to: NSMakeSize(fullSongArtworkView.frame.width,
                               fullSongArtworkView.frame.height),
                marginCrop: 1.0
            )
        }
    }
    
    func colorButtonImages(with color: NSColor) {
        // Update button images with new color
        [playButton, previousButton, nextButton, likeButton, shuffleButton, repeatButton].forEach {
            $0?.tintedImage = $0?.image?.tint(with: color)
        }
    }
    
    func colorViews(with imageColors: ImageColors) {
        // Blend all colors with 50% of lightGray to avoid too contrasty views
        colors = imageColors.map { $0?.blended(withFraction: 0.5, of: .lightGray) }
        
        // guard let colors = colors else { return }
        
        guard   let backgroundColor = colors?.background,
                let primaryColor    = colors?.primary,
                let secondaryColor  = colors?.designatedSecondary,
                let highlightColor  = colors?.highlight else { return }
        
        // Set the superviews background color and animate it
        [ titleAlbumArtistSuperview, actionSuperview, titleSuperview, actionTabView, resultsSuperview ].forEach {
            $0?.layer?.animateChange(to: backgroundColor.cgColor,
                                     for: CALayer.kBackgroundColorPath)
        }
        
        // Set the text colors
        [ titleLabelView, actionTextField, titleTextField ].forEach {
            $0?.textColor = primaryColor
        }
        albumArtistLabelView.textColor = secondaryColor
        
        // Set caret color
        titleTextField.setCaretColor(in: self.view.window, primaryColor)
        
        // And on the progress bar
        if let barCell = songProgressBar.cell as? SliderCell {
            barCell.backgroundColor = primaryColor
            barCell.highlightColor  = highlightColor
            barCell.knobColor       = backgroundColor
        }
        
        // Set the color on the playback buttons
        updateButtons()
        colorButtonImages(with: primaryColor)
        
        colorActionBar(highlight: highlightColor)
        
        // Update table view with new colors
        resultsTableView?.reloadData(keepingSelection: true)
        
        // Color last action view items
        colorLastActionView(imageColor: primaryColor, checkColor: highlightColor)
    }
    
    func colorLastActionView(imageColor: NSColor, checkColor: NSColor) {
        // Color action image too
        // We have to give a fallback image to ensure action image gets tinted at first start
        // Because it is not given a default value otherwise
        actionImageView.tintedImage = (actionImageView.image ?? PlayerAction.play.image!).tint(with: imageColor)
        
        // Also reset the color of the action check
        actionCheckView.shapeColor = checkColor
    }
    
    func colorActionBar(background: CGColor? = nil,
                        highlight: NSColor? = nil) {
        if let backgroundColor = background {
            actionTabView.layer?.backgroundColor = backgroundColor
        }
        
        if let highlightColor = highlight {
            [likeButton, shuffleButton, repeatButton].forEach {
                var alpha: CGFloat = 0.25
                
                // Check current alpha value before setting a new one
                if  let currentAlpha = $0?.layer?.backgroundColor?.alpha {
                    alpha = currentAlpha
                }
                
                $0?.layer?.backgroundColor = highlightColor.cgColor.copy(alpha: alpha)
            }
            
            [playButton, previousButton, nextButton, nextTabButton, previousTabButton].forEach {
                $0?.layer?.backgroundColor = highlightColor.cgColor
            }
        }
    }
    
    func updateTitleAlbumArtistView(for song: Song) {
        titleLabelView.stringValue = song.name
        
        // ALso update title on popup view
        titleTextField.stringValue = shouldShowArtist ?
                                     "\(song.name) - \(song.artist)" :
                                     song.name
        
        albumArtistLabelView.stringValue = "\(song.artist)"
    }
    
    func updateSongProgressSlider(with position: Double) {
        // Update always on progress bar
        songProgressBar.doubleValue = position
    }
    
    // MARK: NSTextFieldDelegate
    
    override func controlTextDidChange(_ obj: Notification) {
        if let field = obj.object as? NSTextField {
            search(field.stringValue)
        }
    }
    
    /**
     Intercept NSTextField key events. We use this to forward some to tableView.
     */
    func control(_ control: NSControl,
                 textView: NSTextView,
                 doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(moveUp(_:)), #selector(moveDown(_:)), #selector(insertNewline(_:)):
            // Forward ⏎, ⬆ and ⬇ to tableView
            handleArrowKeysOrReturn()
            return true
        case #selector(cancelOperation(_:)):
            // End editing on escape key press
            handleEscape()
            return true
        default:
            return false
        }
    }
    
    var windowController: WindowController? {
        return view.window?.windowController as? WindowController
    }
    
}

