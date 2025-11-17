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
    /// - Parses brew stage from notification userInfo
    /// - Routes to appropriate UI update method based on stage
    /// - Shows/hides media based on attachment availability
    /// - Populates parameter grid with stage-specific statistics
    /// - Updates progress indicators with current completion percentage
    /// - Applies stage-specific styling and colors
    /// - Handles missing or invalid stage data gracefully
    ///
    /// **Error Handling:**
    /// - Missing stage data defaults to empty string (triggers default UI)
    /// - Invalid stage identifiers are handled by default case
    /// - Missing parameters use sensible defaults
    /// - Media loading failures are caught and logged
    ///
    /// - Parameter notification: The notification containing brew data and media
    func didReceive(_ notification: UNNotification) {
        let content: UNNotificationContent = notification.request.content
        let userInfo: [AnyHashable: Any] = content.userInfo
        
        // Parse brew stage from notification userInfo
        // If stage is missing or invalid, default to empty string which triggers default UI
        let stage: String = userInfo["stage"] as? String ?? ""
        
        // Validate stage data - log warning if stage is missing
        if stage.isEmpty {
            NSLog("Warning: Notification received without stage identifier. Using default UI.")
        }
        
        // Extract brew parameters with sensible defaults
        let brewType: String = userInfo["brewType"] as? String ?? "Espresso"
        let dose: String = userInfo["dose"] as? String ?? "18"
        let temperature: String = userInfo["temperature"] as? String ?? "93"
        let pressure: String = userInfo["pressure"] as? String ?? "9"
        let elapsedTime: String = userInfo["elapsedTime"] as? String ?? "0"
        let progress: Double = userInfo["progress"] as? Double ?? 0
        
        // Update subtitle from enriched content
        subtitleLabel.stringValue = content.subtitle
        
        // Display media if attached
        // Handle media loading errors gracefully to prevent extension crashes
        if let attachment: UNNotificationAttachment = content.attachments.first,
           attachment.url.startAccessingSecurityScopedResource() {
            
            if let image: NSImage = NSImage(contentsOf: attachment.url) {
                mediaImageView.image = image
                mediaImageView.isHidden = false
            } else {
                NSLog("Warning: Failed to create NSImage from attachment URL")
                mediaImageView.isHidden = true
            }
            
            attachment.url.stopAccessingSecurityScopedResource()
        } else {
            mediaImageView.isHidden = true
        }
        
        // Route to appropriate UI update method based on stage
        // The updateUIForStage method handles invalid stages with a default case
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
    /// Routes to the appropriate stage-specific UI update method based on the
    /// brew stage identifier. This method acts as a dispatcher, delegating to
    /// specialized methods that handle the unique visualization requirements
    /// for each brew stage.
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
        // Clear existing parameters before updating
        parametersGrid.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Route to stage-specific UI update method
        switch stage {
        case "heating":
            displayHeatingUI(
                brewType: brewType,
                dose: dose,
                temperature: temperature,
                pressure: pressure,
                progress: progress,
                userInfo: userInfo
            )
            
        case "grinding":
            displayGrindingUI(
                brewType: brewType,
                dose: dose,
                temperature: temperature,
                progress: progress,
                userInfo: userInfo
            )
            
        case "preInfusion":
            displayPreInfusionUI(
                brewType: brewType,
                dose: dose,
                temperature: temperature,
                pressure: pressure,
                elapsedTime: elapsedTime,
                progress: progress,
                userInfo: userInfo
            )
            
        case "brewing":
            displayBrewingUI(
                dose: dose,
                temperature: temperature,
                pressure: pressure,
                elapsedTime: elapsedTime,
                progress: progress,
                userInfo: userInfo
            )
            
        case "complete":
            displayCompleteUI(
                brewType: brewType,
                dose: dose,
                temperature: temperature,
                pressure: pressure,
                elapsedTime: elapsedTime,
                progress: progress,
                userInfo: userInfo
            )
            
        default:
            // Unknown stage: Show basic information
            displayDefaultUI(brewType: brewType, dose: dose)
        }
        
        // Update progress indicator
        progressIndicator.doubleValue = progress
        
        // Apply stage-specific styling
        applyStageColors(stage: stage, progress: progress)
    }
    
    /// Displays UI for the heating stage
    ///
    /// Shows a progress indicator with temperature and time remaining information.
    /// The heating stage is the initial preparation phase where the machine brings
    /// water to the target temperature before grinding begins.
    ///
    /// **UI Elements:**
    /// - Brew type and dose information
    /// - Target temperature and pressure settings
    /// - Time remaining until heating completes
    /// - Progress bar showing heating completion percentage
    ///
    /// - Parameters:
    ///   - brewType: Type of brew being prepared
    ///   - dose: Coffee dose in grams
    ///   - temperature: Target water temperature in Celsius
    ///   - pressure: Target extraction pressure in bars
    ///   - progress: Heating progress percentage (0-100)
    ///   - userInfo: Additional notification data
    private func displayHeatingUI(
        brewType: String,
        dose: String,
        temperature: String,
        pressure: String,
        progress: Double,
        userInfo: [AnyHashable: Any]
    ) {
        // Display brew parameters
        addParameter(label: "Brew Type", value: brewType)
        addParameter(label: "Dose", value: "\(dose)g")
        addParameter(label: "Target Temp", value: "\(temperature)°C")
        addParameter(label: "Target Pressure", value: "\(pressure) bar")
        
        // Show time remaining if available
        if let remainingTime: String = userInfo["remainingTime"] as? String {
            addParameter(label: "Time Remaining", value: "\(remainingTime)s")
        }
        
        // Update progress label
        progressLabel.stringValue = "Heating: \(Int(progress))%"
    }
    
    /// Displays UI for the grinding stage
    ///
    /// Shows the grinding progress with an image (if attached) and dose information.
    /// The grinding stage involves grinding the coffee beans to the specified dose
    /// while the machine maintains the target temperature.
    ///
    /// **UI Elements:**
    /// - Grinding image showing beans or grinder in action
    /// - Brew type and dose information
    /// - Target temperature for upcoming extraction
    /// - Progress bar showing grinding completion percentage
    ///
    /// - Parameters:
    ///   - brewType: Type of brew being prepared
    ///   - dose: Coffee dose in grams
    ///   - temperature: Target water temperature in Celsius
    ///   - progress: Grinding progress percentage (0-100)
    ///   - userInfo: Additional notification data
    private func displayGrindingUI(
        brewType: String,
        dose: String,
        temperature: String,
        progress: Double,
        userInfo: [AnyHashable: Any]
    ) {
        // Display brew parameters
        addParameter(label: "Brew Type", value: brewType)
        addParameter(label: "Dose", value: "\(dose)g")
        addParameter(label: "Target Temp", value: "\(temperature)°C")
        
        // Show grind size if available
        if let grindSize: String = userInfo["grindSize"] as? String {
            addParameter(label: "Grind Size", value: grindSize)
        }
        
        // Update progress label
        progressLabel.stringValue = "Grinding: \(Int(progress))%"
    }
    
    /// Displays UI for the pre-infusion stage
    ///
    /// Shows a puck visualization with pressure and timing information. Pre-infusion
    /// is the gentle saturation phase where low-pressure water evenly wets the coffee
    /// puck before full extraction begins.
    ///
    /// **UI Elements:**
    /// - Circular puck visualization showing saturation progress
    /// - Current pressure and temperature readings
    /// - Pre-infusion timer showing elapsed/total time
    /// - Brew parameters (type, dose)
    ///
    /// - Parameters:
    ///   - brewType: Type of brew being prepared
    ///   - dose: Coffee dose in grams
    ///   - temperature: Current water temperature in Celsius
    ///   - pressure: Current extraction pressure in bars
    ///   - elapsedTime: Time elapsed in pre-infusion (seconds)
    ///   - progress: Pre-infusion progress percentage (0-100)
    ///   - userInfo: Additional notification data
    private func displayPreInfusionUI(
        brewType: String,
        dose: String,
        temperature: String,
        pressure: String,
        elapsedTime: String,
        progress: Double,
        userInfo: [AnyHashable: Any]
    ) {
        // Display brew parameters
        addParameter(label: "Brew Type", value: brewType)
        addParameter(label: "Dose", value: "\(dose)g")
        addParameter(label: "Pressure", value: "\(pressure) bar")
        addParameter(label: "Temperature", value: "\(temperature)°C")
        
        // Show pre-infusion timing
        if let preInfusionTime: String = userInfo["preInfusionTime"] as? String {
            addParameter(label: "Pre-Infusion", value: "\(elapsedTime)s / \(preInfusionTime)s")
        } else {
            addParameter(label: "Elapsed Time", value: "\(elapsedTime)s")
        }
        
        // Update progress label
        progressLabel.stringValue = "Pre-infusion: \(Int(progress))%"
    }
    
    /// Displays UI for the brewing/extraction stage
    ///
    /// Shows a comprehensive stats grid with live extraction parameters. This is
    /// the main extraction phase where pressurized water flows through the coffee
    /// puck to extract the espresso.
    ///
    /// **UI Elements:**
    /// - Live extraction image or video
    /// - Stats grid with 6 key parameters:
    ///   - Elapsed time
    ///   - Current pressure
    ///   - Current temperature
    ///   - Coffee dose
    ///   - Flow rate (ml/s)
    ///   - Volume extracted (ml)
    /// - Progress bar showing extraction completion
    ///
    /// - Parameters:
    ///   - dose: Coffee dose in grams
    ///   - temperature: Current water temperature in Celsius
    ///   - pressure: Current extraction pressure in bars
    ///   - elapsedTime: Time elapsed in extraction (seconds)
    ///   - progress: Extraction progress percentage (0-100)
    ///   - userInfo: Additional notification data
    private func displayBrewingUI(
        dose: String,
        temperature: String,
        pressure: String,
        elapsedTime: String,
        progress: Double,
        userInfo: [AnyHashable: Any]
    ) {
        // Display live extraction parameters in priority order
        addParameter(label: "Elapsed Time", value: "\(elapsedTime)s")
        addParameter(label: "Pressure", value: "\(pressure) bar")
        addParameter(label: "Temperature", value: "\(temperature)°C")
        addParameter(label: "Dose", value: "\(dose)g")
        
        // Show flow rate if available
        if let flowRate: String = userInfo["flowRate"] as? String {
            addParameter(label: "Flow Rate", value: "\(flowRate) ml/s")
        }
        
        // Show volume extracted if available
        if let volume: String = userInfo["volumeExtracted"] as? String {
            addParameter(label: "Volume", value: "\(volume) ml")
        }
        
        // Update progress label
        progressLabel.stringValue = "Extracting: \(Int(progress))%"
    }
    
    /// Displays UI for the brew complete stage
    ///
    /// Shows a hero image of the finished espresso with a summary card containing
    /// final statistics. This is the completion phase where the brew is finished
    /// and ready to enjoy.
    ///
    /// **UI Elements:**
    /// - Hero image of completed espresso shot
    /// - Summary card with final statistics:
    ///   - Brew type
    ///   - Coffee dose
    ///   - Total brew time
    ///   - Final temperature
    ///   - Final pressure
    ///   - Total volume (if available)
    /// - Completion message with coffee emoji
    ///
    /// - Parameters:
    ///   - brewType: Type of brew that was prepared
    ///   - dose: Coffee dose in grams
    ///   - temperature: Final water temperature in Celsius
    ///   - pressure: Final extraction pressure in bars
    ///   - elapsedTime: Total brew time (seconds)
    ///   - progress: Should be 100 for completed brews
    ///   - userInfo: Additional notification data
    private func displayCompleteUI(
        brewType: String,
        dose: String,
        temperature: String,
        pressure: String,
        elapsedTime: String,
        progress: Double,
        userInfo: [AnyHashable: Any]
    ) {
        // Display final brew statistics
        addParameter(label: "Brew Type", value: brewType)
        addParameter(label: "Dose", value: "\(dose)g")
        addParameter(label: "Total Time", value: "\(elapsedTime)s")
        addParameter(label: "Temperature", value: "\(temperature)°C")
        addParameter(label: "Pressure", value: "\(pressure) bar")
        
        // Show final volume if available
        if let volume: String = userInfo["volumeExtracted"] as? String {
            addParameter(label: "Final Volume", value: "\(volume) ml")
        }
        
        // Show brew quality rating if available
        if let quality: String = userInfo["quality"] as? String {
            addParameter(label: "Quality", value: quality)
        }
        
        // Update progress label with completion message
        progressLabel.stringValue = "Complete! ☕"
    }
    
    /// Displays default UI for unknown or invalid brew stages
    ///
    /// Provides a fallback display when the brew stage is not recognized or
    /// when stage data is missing. Shows basic brew information to ensure
    /// the notification is still useful even with incomplete data.
    ///
    /// - Parameters:
    ///   - brewType: Type of brew being prepared
    ///   - dose: Coffee dose in grams
    private func displayDefaultUI(brewType: String, dose: String) {
        // Display minimal brew information
        addParameter(label: "Brew Type", value: brewType)
        addParameter(label: "Dose", value: "\(dose)g")
        
        // Update progress label with generic message
        progressLabel.stringValue = "Brew in progress..."
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
