//
//  SearchResultsViewController.swift
//  TwitterInstant
//
//  Created by Waratnan Suriyasorn on 6/16/2559 BE.
//
//

import UIKit
import ReactiveCocoa

class SearchResultsViewController: UITableViewController
{
    var tweets:[Tweet] = []
    
    func displayTweet(tweets:[Tweet]) {
        self.tweets = tweets
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! TableViewCell
        
        let tweet = tweets[indexPath.row]
        
        cell.twitterStatusText.text = tweet.status
        cell.twitterUsernameText.text = tweet.username
        
        let url = NSURL(string:tweet.profileImageUrl)!
        
        self.signalForLoadingImage(url).subscribeNext { (imageReturn) in
            let image = imageReturn as! UIImage
            cell.twitterAvatarView.image = image
        }
        
        return cell
    }
    
    private func signalForLoadingImage(imageUrl:NSURL) -> RACSignal{
        
        let scheduler = RACScheduler(priority: RACSchedulerPriorityBackground)
        
        return RACSignal.createSignal { (subscriber) -> RACDisposable! in
            let data = NSData(contentsOfURL: imageUrl)
            let image = UIImage(data: data!)
            subscriber.sendNext(image)
            subscriber.sendCompleted()
            return nil
        }.subscribeOn(scheduler)
    }
}