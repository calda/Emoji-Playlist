//
//  ViewController.swift
//  Emoji Playlist
//
//  Created by DFA Film 9: K-9 on 4/14/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import UIKit
import iAd

let SHOW_HELP_POPUP = "SHOW_HELP_POPUP"

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ADBannerViewDelegate {
    
    var emojis : [String] = []
    var savedCells : [Int] = []
    
    let about : [(emoji: String, text: String)] = [
        ("🌐", "1️⃣ open emoji keyboard"),
        ("👇🏻", "2️⃣ type emoji"),
        ("📲", "3️⃣ save to camera roll"),
        ("🎧", "4️⃣ set as playlist icon"),
        ("🙏🏻", "5️⃣ nice!")
    ]
    
    @IBOutlet weak var hiddenField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    let startColor = UIColor(hue: 0.0, saturation: 0.5, brightness: 0.7, alpha: 1.0).CGColor
    let endColor = UIColor(hue: 0.5, saturation: 0.5, brightness: 0.7, alpha: 1.0).CGColor
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hiddenField.becomeFirstResponder()
        self.view.layer.backgroundColor = startColor
        //animateBackground()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardChanged:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardChanged:", name: UIKeyboardDidChangeFrameNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showHelpPopup", name: SHOW_HELP_POPUP, object: nil)
    }
    
    var keyboardHidden = false
    
    func keyboardChanged(notification: NSNotification) {
        let info = notification.userInfo!
        let value: AnyObject = info[UIKeyboardFrameEndUserInfoKey]!
        
        
        let rawFrame = value.CGRectValue()
        let keyboardFrame = view.convertRect(rawFrame, fromView: nil)
        self.keyboardHeight = keyboardFrame.height
        
        if !adBanner.bannerLoaded {
            //ad is not on screen
            keyboardHidden = false
            return
        }
        
        updateContentInset()
        adPosition.constant = keyboardHeight
        
        if keyboardHidden {
            UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: { self.view.layoutIfNeeded() }, completion: nil)
        } else {
            self.view.layoutIfNeeded()
        }
        
        keyboardHidden = false
        
    }
    
    func updateContentInset() {
        let contentInset = self.keyboardHeight + (adPosition.constant > 0 ? 50 : 0)
        tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, contentInset, 0.0)
    }
    
    func animateBackground() {
        UIView.animateWithDuration(15, animations: {
                self.view.layer.backgroundColor = self.startColor
            }, completion: { _ in
                UIView.animateWithDuration(15, animations: {
                    self.view.layer.backgroundColor = self.endColor
                }, completion: { _ in
                    self.animateBackground()
                })
        })
    }
    
    func showHelpPopup() {
        let popup = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("help") as! UIViewController
        
        let nav = LightNavigation(rootViewController: popup)
        nav.navigationBar.translucent = false
        popup.view.frame = CGRectMake(0, 0, -44, self.view.bounds.size.height)
        
        let closeButton = UIBarButtonItem(title: "got it", style: UIBarButtonItemStyle.Plain, target: self, action: "closeHelpPopup")
        closeButton.tintColor = UIColor.whiteColor()
        popup.navigationItem.rightBarButtonItem = closeButton
        
        popup.navigationController?.navigationBar.barTintColor = UIColor(hue: 0.0, saturation: 0.5, brightness: 0.7, alpha: 1.0)
        let font = UIFont(name: "HelveticaNeue-Light", size: 25.0)!
        popup.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : font, NSForegroundColorAttributeName : UIColor.whiteColor()]
        
        nav.modalPresentationStyle = UIModalPresentationStyle.Popover
        nav.modalPresentationCapturesStatusBarAppearance = true
        self.presentViewController(nav, animated: true, completion: nil)
        self.keyboardHidden(true)
    }
    
    func closeHelpPopup() {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.adPosition.constant = -55
        self.view.layoutIfNeeded()
        keyboardHidden = true
        self.hiddenField.becomeFirstResponder()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidAppear(animated: Bool) {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    //pragma MARK: - emoji inputs and table
    
    @IBAction func hiddenInputReceived(sender: UITextField, forEvent event: UIEvent) {
        var emoji = sender.text.substringFromIndex(sender.text.endIndex.predecessor()) as NSString
        
        if emoji.length == 0 { return }
        
        if emoji.length > 1 {
            let char2 = emoji.characterAtIndex(1)
            if char2 >= 57339 && char2 <= 57343
            { //is skin tone marker
                emoji = sender.text.substringFromIndex(sender.text.endIndex.predecessor().predecessor()) as NSString
            }
            
            if emoji.length % 4 == 0 && emoji.length > 4 { //flags stick together for some reason?
                emoji = emoji.substringFromIndex(emoji.length - 4)
            }
        }
        
        emojis.insert(emoji as String, atIndex: 0)
        tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Right)
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: true)
        
        sender.text = ""
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("emojiCell") as! EmojiCell
        
        if indexPath.item >= emojis.count {
            let aboutText = about[indexPath.item - emojis.count]
            cell.decorateCell(emoji: aboutText.emoji, text: aboutText.text, isLast: aboutText.text.hasSuffix("nice!"))
        }
        
        else {
            cell.decorateCell(emojis[indexPath.item])
        }
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emojis.count + about.count
    }
    
    //pragma MAR: - ad delegate
    
    @IBOutlet weak var adBanner: ADBannerView!
    @IBOutlet weak var adPosition: NSLayoutConstraint!
    var keyboardHeight : CGFloat = 0
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        
        //do not show ad if 4S (aspect != 9:16) (9/16 = 0.5625)
        let aspect = self.view.frame.width / self.view.frame.height
        if aspect > 0.6 || aspect < 0.5 {
            println("iPhone 4S")
            adBanner.hidden = true
            return
        }
        
        if adPosition.constant != keyboardHeight {
            adPosition.constant = keyboardHeight
            UIView.animateWithDuration(1.0, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
                    self.view.layoutIfNeeded()
                }, completion: { success in
                    self.updateContentInset()
            })
        }
        
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        adPosition.constant = -50
        UIView.animateWithDuration(1.0, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: { self.view.layoutIfNeeded() }, completion: { success in
                self.updateContentInset()
        })
    }
    
    func keyboardHidden(hidden: Bool) {
        adPosition.constant = (hidden ? -50 : keyboardHeight)
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: { self.view.layoutIfNeeded() }, completion: nil)
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        self.keyboardHidden(true)
        return true
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        self.adPosition.constant = -55
        self.view.layoutIfNeeded()
        self.hiddenField.becomeFirstResponder()
    }

}