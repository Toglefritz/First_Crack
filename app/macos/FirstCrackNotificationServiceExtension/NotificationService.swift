//
//  NotificationService.swift
//  FirstCrackNotificationServiceExtension
//
//  Created by Scott Hatfield on 11/16/25.
//

import UserNotifications

/// Notification Service Extension for First Crack
///
/// This extension intercepts Firebase Cloud Messaging (FCM) notifications before they are
/// displayed to the user, allowing us to enrich the notification content with:
/// - Dynamic subtitles constructed from brew parameters
/// - Downloaded and attached media (images/videos)
/// - Enhanced body text with timing and status information
/// - Appropriate notification categories for stage-specific actions
///
/// The extension has a 30-second execution time limit, so all operations must complete
/// quickly or provide fallback content. Media downloads are performed asynchronously
/// with timeout handling to ensure timely delivery.
///
/// ## Brew Stage Processing
///
/// Each brew stage receives different enrichment:
/// - **Heating**: Subtitle with brew parameters (type, dose, temperature)
/// - **Grinding**: Subtitle with dose + image attachment
/// - **Pre-Infusion**: Subtitle with pressure + timing information
/// - **Brewing**: Subtitle with elapsed time + extraction image
/// - **Complete**: Subtitle with final time + completion image
///
/// ## FCM Payload Structure
///
/// The extension expects FCM messages with the following structure:
/// ```
/// {
///   "stage": "brewing",
///   "brewType": "espresso",
///   "dose": "18",
///   "temperature": "93",
///   "pressure": "9",
///   "elapsedTime": "19",
///   "imageUrl": "https://cdn.example.com/brewing.png",
///   "deepLink": "firstcrack://brew/123/live"
/// }
/// ```
class NotificationService: UNNotificationServiceExtension {

    /// Completion handler provided by the system to deliver modified content
    ///
    /// This handler must be called within 30 seconds or the system will display
    /// the original notification content without modifications.
    var contentHandler: ((UNNotificationContent) -> Void)?
    
    /// Mutable copy of the notification content being enriched
    ///
    /// This is the working copy that we modify with enhanced text, media attachments,
    /// and category assignments before delivering to the user.
    var bestAttemptContent: UNMutableNotificationContent?
    
    /// Maximum time allowed for media downloads in seconds
    ///
    /// Set conservatively to ensure we have time to complete processing and deliver
    /// the notification before the 30-second system timeout.
    private let mediaDownloadTimeout: TimeInterval = 10.0

    /// Called when a notification arrives with mutable-content flag set
    ///
    /// This is the main entry point for notification enrichment. The method:
    /// 1. Extracts brew parameters from the FCM payload
    /// 2. Constructs dynamic subtitle based on brew stage
    /// 3. Downloads and attaches media if URL provided
    /// 4. Sets appropriate notification category for actions
    /// 5. Delivers enriched content via completion handler
    ///
    /// - Parameters:
    ///   - request: The notification request containing FCM payload data
    ///   - contentHandler: Completion handler to deliver modified content
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }
        
        // Extract brew parameters from FCM userInfo payload
        let userInfo: [AnyHashable: Any] = request.content.userInfo
        let stage: String = userInfo["stage"] as? String ?? ""
        
        // Enrich notification based on brew stage
        enrichNotificationContent(bestAttemptContent, stage: stage, userInfo: userInfo)
        
        // Download and attach media if URL provided
        if let imageUrlString: String = userInfo["imageUrl"] as? String,
           let imageUrl: URL = URL(string: imageUrlString) {
            downloadAndAttachMedia(imageUrl, to: bestAttemptContent) { success in
                if !success {
                    // Log failure but still deliver notification with text enrichment
                    NSLog("First Crack NSE: Failed to download media from \(imageUrlString)")
                }
                
                // Deliver enriched content (with or without media)
                contentHandler(bestAttemptContent)
            }
        } else {
            // No media to download, deliver text-enriched content immediately
            contentHandler(bestAttemptContent)
        }
    }
    
    /// Called when the 30-second execution time limit is about to expire
    ///
    /// This is our last chance to deliver modified content. We deliver whatever
    /// enrichment we've completed so far, even if media download is incomplete.
    /// If we don't call the content handler here, the system will display the
    /// original unmodified notification.
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler,
           let bestAttemptContent = bestAttemptContent {
            NSLog("First Crack NSE: Time limit expiring, delivering best attempt content")
            contentHandler(bestAttemptContent)
        }
    }
    
    // MARK: - Content Enrichment
    
    /// Enriches notification content based on brew stage and parameters
    ///
    /// This method constructs dynamic subtitles and enhances body text using
    /// brew parameters from the FCM payload. Each stage has a specific format:
    ///
    /// - **Heating**: "Espresso • 18g @ 93°C"
    /// - **Grinding**: "Espresso • 18g dose"
    /// - **Pre-Infusion**: "Espresso • 18g @ 2 bar"
    /// - **Brewing**: "Espresso • 19s elapsed"
    /// - **Complete**: "Completed in 28s"
    ///
    /// The method also assigns the appropriate notification category for each stage,
    /// which determines what action buttons are available to the user.
    ///
    /// - Parameters:
    ///   - content: The mutable notification content to enrich
    ///   - stage: The current brew stage identifier
    ///   - userInfo: Dictionary containing brew parameters from FCM
    private func enrichNotificationContent(
        _ content: UNMutableNotificationContent,
        stage: String,
        userInfo: [AnyHashable: Any]
    ) {
        // Extract common brew parameters with sensible defaults
        let brewType: String = userInfo["brewType"] as? String ?? "Espresso"
        let dose: String = userInfo["dose"] as? String ?? "18"
        let temperature: String = userInfo["temperature"] as? String ?? "93"
        let pressure: String = userInfo["pressure"] as? String ?? "9"
        let elapsedTime: String = userInfo["elapsedTime"] as? String ?? "0"
        
        // Construct subtitle and set category based on brew stage
        switch stage {
        case "heating":
            // Heating stage: Show brew type, dose, and target temperature
            // Example: "Espresso • 18g @ 93°C"
            content.subtitle = "\(brewType) • \(dose)g @ \(temperature)°C"
            content.categoryIdentifier = "BREW_HEATING"
            
            // Optionally enhance body with time remaining if provided
            if let remainingTime: String = userInfo["remainingTime"] as? String {
                content.body += "\nAbout \(remainingTime) seconds remaining."
            }
            
        case "grinding":
            // Grinding stage: Show brew type and dose being ground
            // Example: "Espresso • 18g dose"
            content.subtitle = "\(brewType) • \(dose)g dose"
            content.categoryIdentifier = "BREW_GRINDING"
            
        case "preInfusion":
            // Pre-infusion stage: Show brew type, dose, and current pressure
            // Example: "Espresso • 18g @ 2 bar"
            content.subtitle = "\(brewType) • \(dose)g @ \(pressure) bar"
            content.categoryIdentifier = "BREW_PREINFUSION"
            
            // Add timing information if available
            if let preInfusionTime: String = userInfo["preInfusionTime"] as? String,
               !elapsedTime.isEmpty {
                content.body += "\nPre-infusion: \(elapsedTime) / \(preInfusionTime) seconds."
            }
            
        case "brewing":
            // Brewing/extraction stage: Show brew type and elapsed time
            // Example: "Espresso • 19s elapsed"
            content.subtitle = "\(brewType) • \(elapsedTime)s elapsed"
            content.categoryIdentifier = "BREW_EXTRACTION"
            
            // Add flow rate if available
            if let flowRate: String = userInfo["flowRate"] as? String {
                content.body += "\nFlow rate: \(flowRate) ml/s"
            }
            
        case "complete":
            // Complete stage: Show final brew time
            // Example: "Completed in 28s"
            content.subtitle = "Completed in \(elapsedTime)s"
            content.categoryIdentifier = "BREW_COMPLETE"
            
        default:
            // Unknown stage: Use generic subtitle
            content.subtitle = brewType
            NSLog("First Crack NSE: Unknown brew stage '\(stage)'")
        }
        
        // Store brew ID and deep link for action handling
        if let brewId: String = userInfo["brewId"] as? String {
            content.userInfo["brewId"] = brewId
        }
        
        if let deepLink: String = userInfo["deepLink"] as? String {
            content.userInfo["deepLink"] = deepLink
        }
    }
    
    // MARK: - Media Download
    
    /// Downloads media from URL and attaches it to the notification
    ///
    /// This method performs an asynchronous download of the image or video from
    /// the provided URL and creates a UNNotificationAttachment. The download has
    /// a timeout to ensure we don't exceed the 30-second extension limit.
    ///
    /// ## Download Process
    ///
    /// 1. Create URLSession with timeout configuration
    /// 2. Download media to temporary file location
    /// 3. Validate downloaded file exists and has content
    /// 4. Create UNNotificationAttachment from file
    /// 5. Attach to notification content
    /// 6. Clean up temporary files on completion
    ///
    /// ## Error Handling
    ///
    /// If download fails for any reason (network error, timeout, invalid file),
    /// the method returns false but does not prevent notification delivery.
    /// The notification will be displayed with text enrichment only.
    ///
    /// - Parameters:
    ///   - url: URL of the media file to download
    ///   - content: Notification content to attach media to
    ///   - completion: Callback with success/failure result
    private func downloadAndAttachMedia(
        _ url: URL,
        to content: UNMutableNotificationContent,
        completion: @escaping (Bool) -> Void
    ) {
        // Configure URLSession with timeout
        let sessionConfig: URLSessionConfiguration = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = mediaDownloadTimeout
        sessionConfig.timeoutIntervalForResource = mediaDownloadTimeout
        
        let session: URLSession = URLSession(configuration: sessionConfig)
        
        // Start download task
        let downloadTask: URLSessionDownloadTask = session.downloadTask(with: url) { [weak self] tempUrl, response, error in
            guard let self = self else {
                completion(false)
                return
            }
            
            // Check for download errors
            if let error = error {
                NSLog("First Crack NSE: Media download error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Validate temporary file location
            guard let tempUrl = tempUrl else {
                NSLog("First Crack NSE: No temporary file URL returned")
                completion(false)
                return
            }
            
            // Determine file extension from URL or response
            let fileExtension: String = self.getFileExtension(from: url, response: response)
            
            // Create permanent file URL in temporary directory
            let fileManager: FileManager = FileManager.default
            let tempDirectory: URL = fileManager.temporaryDirectory
            let fileName: String = UUID().uuidString + "." + fileExtension
            let permanentUrl: URL = tempDirectory.appendingPathComponent(fileName)
            
            do {
                // Move downloaded file to permanent location
                try fileManager.moveItem(at: tempUrl, to: permanentUrl)
                
                // Create notification attachment
                let attachment: UNNotificationAttachment = try UNNotificationAttachment(
                    identifier: "media",
                    url: permanentUrl,
                    options: nil
                )
                
                // Attach to notification content
                content.attachments = [attachment]
                
                NSLog("First Crack NSE: Successfully attached media from \(url.absoluteString)")
                completion(true)
                
            } catch {
                NSLog("First Crack NSE: Failed to create attachment: \(error.localizedDescription)")
                completion(false)
            }
        }
        
        downloadTask.resume()
    }
    
    /// Determines file extension from URL or HTTP response
    ///
    /// Attempts to extract file extension from:
    /// 1. URL path extension
    /// 2. HTTP Content-Type header
    /// 3. Falls back to "png" as default
    ///
    /// - Parameters:
    ///   - url: The media URL
    ///   - response: Optional HTTP response with Content-Type header
    /// - Returns: File extension without leading dot (e.g., "png", "jpg", "mp4")
    private func getFileExtension(from url: URL, response: URLResponse?) -> String {
        // Try to get extension from URL path
        let pathExtension: String = url.pathExtension.lowercased()
        if !pathExtension.isEmpty {
            return pathExtension
        }
        
        // Try to get extension from Content-Type header
        if let httpResponse = response as? HTTPURLResponse,
           let contentType: String = httpResponse.allHeaderFields["Content-Type"] as? String {
            
            if contentType.contains("image/jpeg") || contentType.contains("image/jpg") {
                return "jpg"
            } else if contentType.contains("image/png") {
                return "png"
            } else if contentType.contains("image/gif") {
                return "gif"
            } else if contentType.contains("video/mp4") {
                return "mp4"
            } else if contentType.contains("video/quicktime") {
                return "mov"
            }
        }
        
        // Default to PNG if unable to determine
        return "png"
    }
}
