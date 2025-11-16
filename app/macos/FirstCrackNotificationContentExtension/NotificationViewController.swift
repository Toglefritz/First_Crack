//
//  NotificationViewController.swift
//  FirstCrackNotificationContentExtension
//
//  Created by Scott Hatfield on 11/16/25.
//

import Cocoa
import UserNotifications
import UserNotificationsUI

class NotificationViewController: NSViewController, UNNotificationContentExtension {

    @IBOutlet var label: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        self.label.stringValue = notification.request.content.body
    }

}
