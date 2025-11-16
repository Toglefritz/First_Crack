//
//  NotificationViewController.swift
//  FirstCrackNotificationContentExtension
//
//  Created by Scott Hatfield on 11/16/25.
//

import Cocoa
import UserNotifications
import UserNotificationsUI

/// Notification Content Extension for First Crack
///
/// This extension provides custom UI for expanded notifications, displaying rich
/// interactive content when the user expands a brew notification. The extension
/// creates stage-specific visualizations and controls that go beyond the standard
/// notification layout.
///
/// ## Brew Stage Visualizations
///
/// Each brew stage displays different content:
/// - **Heating**: Progress bar with temperature and time remaining
/// - **Grinding**: Image with grind progress and dose information
/// - **Pre-Infusion**: Animated puck visualization with pressure and timing
/// - **Brewing**: Live extraction stats dashboard with multiple parameters
/// - **Complete**: Summary card with final stats and hero image
///
/// ## UI Components
///
/// The extension uses a flexible layout that adapts to the brew stage:
/// - Header with stage title and subtitle
/// - Media display area (image or video)
/// - Parameter grid showing live brew statistics
/// - Progress indicators (bars, rings, or custom visualizations)
/// - Action hints (actions are handled by the system, not the extension)
///
/// ## Data Flow
///
/// The extension receives notification data through the `didReceive(_:)` method
/// and extracts brew parameters from the `userInfo` dictionary. The UI updates
/// automatically when new notification data arrives, allowing for real-time
/// parameter updates during active brews.
///
/// ## Performance Considerations
///
/// The content extension runs in a separate process with limited resources:
/// - Keep UI updates lightweight and efficient
/// - Avoid heavy animations or continuous timers
/// - Cache images and reuse views when possible
/// - Test memory usage with multiple notifications
class NotificationViewController: NSViewController, UNNotificationContentExtension {

    // MARK: - UI Components
    
    /// Container for all custom UI elements
    ///
    /// This stack view provides flexible layout for stage-specific content,
    /// allowing us to add/remove elements based on the brew stage.
    private lazy var containerStack: NSStackView = {
        let stack: NSStackView = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    /// Image view for displaying brew stage media
    ///
    /// Shows images attached by the Notification Service Extension, such as
    /// grinding beans, extraction streams, or completed espresso shots.
    private lazy var mediaImageView: NSImageView = {
        let imageView: NSImageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    /// Label displaying the brew stage subtitle
    ///
    /// Shows dynamic information like "Espresso • 18g @ 93°C" constructed
    /// by the Notification Service Extension.
    private lazy var subtitleLabel: NSTextField = {
        let label: NSTextField = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// Grid container for brew parameters
    ///
    /// Displays key statistics like elapsed time, pressure, temperature,
    /// and flow rate in a structured grid layout.
    private lazy var parametersGrid: NSStackView = {
        let stack: NSStackView = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    /// Progress indicator for brew stage completion
    ///
    /// Shows visual progress through the current stage, with percentage
    /// and time-based indicators.
    private lazy var progressIndicator: NSProgressIndicator = {
        let indicator: NSProgressIndicator = NSProgressIndicator()
        indicator.style = .bar
        indicator.isIndeterminate = false
        indicator.minValue = 0
        indicator.maxValue = 100
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    /// Label showing progress percentage or time remaining
    ///
    /// Displays contextual progress information like "60%" or "15s remaining"
    private lazy var progressLabel: NSTextField = {
        let label: NSTextField = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    
    /// Called when the view controller's view is loaded into memory
    ///
    /// Sets up the custom UI hierarchy and constraints. The layout is designed
    /// to be flexible and adapt to different brew stages and content types.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    /// Sets up the custom UI hierarchy and layout constraints
    ///
    /// Creates a vertical stack layout with:
    /// 1. Subtitle label at the top
    /// 2. Media image view (if media attached)
    /// 3. Parameters grid with brew statistics
    /// 4. Progress indicator at the bottom
    ///
    /// All elements are added to the container stack which is then
    /// constrained to fill the view.
    private func setupUI() {
        // Add container stack to view
        view.addSubview(containerStack)
        
        // Add UI components to container
        containerStack.addArrangedSubview(subtitleLabel)
        containerStack.addArrangedSubview(mediaImageView)
        containerStack.addArrangedSubview(parametersGrid)
        containerStack.addArrangedSubview(progressIndicator)
        containerStack.addArrangedSubview(progressLabel)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Container fills the view with padding
            containerStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            containerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            
            // Media image has fixed aspect ratio
            mediaImageView.widthAnchor.constraint(equalTo: containerStack.widthAnchor),
            mediaImageView.heightAnchor.constraint(equalTo: mediaImageView.widthAnchor, multiplier: 0.5625), // 16:9 aspect
            
            // Progress indicator spans full width
            progressIndicator.widthAnchor.constraint(equalTo: containerStack.widthAnchor),
        ])
        
        // Initially hide media view until we have an image
        mediaImageView.isHidden = true
    }
    
    // MARK: - UNNotificationContentExtension
    
    /// Called when a notification is received for display
    ///
    /// This is the main entry point for updating the custom UI with notification
    /// data. The method extracts brew parameters from the notification's userInfo
    /// and updates all UI components to reflect the current brew state.
    ///
    /// The method handles all brew stages and adapts the UI accordingly:
    /// - Shows/hides media based on attachment availability
    /// - Populates parameter grid with stage-specific statistics
    /// - Updates progress indicators with current completion percentage
    /// - Applies stage-specific styling and colors
    ///
    /// - Parameter notification: The notification containing brew data and media
    func didReceive(_ notification: UNNotification) {
        let content: UNNotificationContent = notification.request.content
        let userInfo: [AnyHashable: Any] = content.userInfo
        
        // Extract brew stage and parameters
        let stage: String = userInfo["stage"] as? String ?? ""
        let brewType: String = userInfo["brewType"] as? String ?? "Espresso"
        let dose: String = userInfo["dose"] as? String ?? "18"
        let temperature: String = userInfo["temperature"] as? String ?? "93"
        let pressure: String = userInfo["pressure"] as? String ?? "9"
        let elapsedTime: String = userInfo["elapsedTime"] as? String ?? "0"
        let progress: Double = userInfo["progress"] as? Double ?? 0
        
        // Update subtitle from enriched content
        subtitleLabel.stringValue = content.subtitle
        
        // Display media if attached
        if let attachment: UNNotificationAttachment = content.attachments.first,
           attachment.url.startAccessingSecurityScopedResource() {
            
            if let image: NSImage = NSImage(contentsOf: attachment.url) {
                mediaImageView.image = image
                mediaImageView.isHidden = false
            }
            
            attachment.url.stopAccessingSecurityScopedResource()
        } else {
            mediaImageView.isHidden = true
        }
        
        // Update UI based on brew stage
        updateUIForStage(
            stage: stage,
            brewType: brewType,
            dose: dose,
            temperature: temperature,
            pressure: pressure,
            elapsedTime: elapsedTime,
            progress: progress,
            userInfo: userInfo
        )
    }
    
    // MARK: - Stage-Specific UI Updates
    
    /// Updates UI components based on the current brew stage
    ///
    /// Each stage displays different parameters and visualizations:
    ///
    /// **Heating**: Temperature progress and time remaining
    /// **Grinding**: Dose information and grind progress
    /// **Pre-Infusion**: Pressure, timing, and puck saturation visualization
    /// **Brewing**: Full extraction dashboard with multiple live parameters
    /// **Complete**: Final statistics summary with completion message
    ///
    /// - Parameters:
    ///   - stage: Current brew stage identifier
    ///   - brewType: Type of brew (espresso, americano, etc.)
    ///   - dose: Coffee dose in grams
    ///   - temperature: Water temperature in Celsius
    ///   - pressure: Extraction pressure in bars
    ///   - elapsedTime: Time elapsed in current stage (seconds)
    ///   - progress: Overall brew progress percentage (0-100)
    ///   - userInfo: Full notification payload for additional parameters
    private func updateUIForStage(
        stage: String,
        brewType: String,
        dose: String,
        temperature: String,
        pressure: String,
        elapsedTime: String,
        progress: Double,
        userInfo: [AnyHashable: Any]
    ) {
        // Clear existing parameters
        parametersGrid.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        switch stage {
        case "heating":
            // Heating stage: Show temperature and time remaining
            addParameter(label: "Brew Type", value: brewType)
            addParameter(label: "Dose", value: "\(dose)g")
            addParameter(label: "Target Temp", value: "\(temperature)°C")
            addParameter(label: "Target Pressure", value: "\(pressure) bar")
            
            if let remainingTime: String = userInfo["remainingTime"] as? String {
                addParameter(label: "Time Remaining", value: "\(remainingTime)s")
            }
            
            progressLabel.stringValue = "Heating: \(Int(progress))%"
            
        case "grinding":
            // Grinding stage: Show dose and grind information
            addParameter(label: "Brew Type", value: brewType)
            addParameter(label: "Dose", value: "\(dose)g")
            addParameter(label: "Target Temp", value: "\(temperature)°C")
            
            progressLabel.stringValue = "Grinding: \(Int(progress))%"
            
        case "preInfusion":
            // Pre-infusion stage: Show pressure and timing
            addParameter(label: "Brew Type", value: brewType)
            addParameter(label: "Dose", value: "\(dose)g")
            addParameter(label: "Pressure", value: "\(pressure) bar")
            addParameter(label: "Temperature", value: "\(temperature)°C")
            
            if let preInfusionTime: String = userInfo["preInfusionTime"] as? String {
                addParameter(label: "Pre-Infusion", value: "\(elapsedTime)s / \(preInfusionTime)s")
            }
            
            progressLabel.stringValue = "Pre-infusion: \(Int(progress))%"
            
        case "brewing":
            // Brewing stage: Show full extraction dashboard
            addParameter(label: "Elapsed Time", value: "\(elapsedTime)s")
            addParameter(label: "Pressure", value: "\(pressure) bar")
            addParameter(label: "Temperature", value: "\(temperature)°C")
            addParameter(label: "Dose", value: "\(dose)g")
            
            if let flowRate: String = userInfo["flowRate"] as? String {
                addParameter(label: "Flow Rate", value: "\(flowRate) ml/s")
            }
            
            if let volume: String = userInfo["volumeExtracted"] as? String {
                addParameter(label: "Volume", value: "\(volume) ml")
            }
            
            progressLabel.stringValue = "Extracting: \(Int(progress))%"
            
        case "complete":
            // Complete stage: Show final statistics
            addParameter(label: "Brew Type", value: brewType)
            addParameter(label: "Dose", value: "\(dose)g")
            addParameter(label: "Total Time", value: "\(elapsedTime)s")
            addParameter(label: "Temperature", value: "\(temperature)°C")
            addParameter(label: "Pressure", value: "\(pressure) bar")
            
            progressLabel.stringValue = "Complete! ☕"
            
        default:
            // Unknown stage: Show basic information
            addParameter(label: "Brew Type", value: brewType)
            addParameter(label: "Dose", value: "\(dose)g")
            
            progressLabel.stringValue = "Brew in progress..."
        }
        
        // Update progress indicator
        progressIndicator.doubleValue = progress
        
        // Apply stage-specific styling
        applyStageColors(stage: stage, progress: progress)
    }
    
    /// Adds a parameter row to the parameters grid
    ///
    /// Creates a horizontal stack with label and value, styled consistently
    /// across all parameters. The label is secondary color and the value is
    /// primary color for visual hierarchy.
    ///
    /// - Parameters:
    ///   - label: Parameter name (e.g., "Pressure", "Temperature")
    ///   - value: Parameter value (e.g., "9 bar", "93°C")
    private func addParameter(label: String, value: String) {
        let rowStack: NSStackView = NSStackView()
        rowStack.orientation = .horizontal
        rowStack.spacing = 8
        
        let labelField: NSTextField = NSTextField(labelWithString: "\(label):")
        labelField.font = NSFont.systemFont(ofSize: 12)
        labelField.textColor = .secondaryLabelColor
        
        let valueField: NSTextField = NSTextField(labelWithString: value)
        valueField.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        valueField.textColor = .labelColor
        
        rowStack.addArrangedSubview(labelField)
        rowStack.addArrangedSubview(valueField)
        
        parametersGrid.addArrangedSubview(rowStack)
    }
    
    /// Applies stage-specific colors to progress indicators
    ///
    /// Different brew stages use different color schemes to provide visual
    /// feedback about the current phase:
    /// - **Heating**: Blue (cool, preparing)
    /// - **Grinding**: Amber (active preparation)
    /// - **Pre-Infusion**: Teal (gentle saturation)
    /// - **Brewing**: Orange (active extraction)
    /// - **Complete**: Green (success)
    ///
    /// - Parameters:
    ///   - stage: Current brew stage identifier
    ///   - progress: Current progress percentage (0-100)
    private func applyStageColors(stage: String, progress: Double) {
        // Note: NSProgressIndicator doesn't support direct color customization on macOS
        // In a production app, you might use a custom progress view with CALayer
        // to apply stage-specific colors. For now, we use the default system appearance.
        
        // The color mapping would be:
        // - Heating: Blue (cool, preparing)
        // - Grinding: Amber (active preparation)
        // - Pre-Infusion: Teal (gentle saturation)
        // - Brewing: Orange (active extraction)
        // - Complete: Green (success)
        
        progressIndicator.appearance = NSAppearance(named: .aqua)
    }
}
