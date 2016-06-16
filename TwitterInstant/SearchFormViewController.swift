//
//  SearchFormViewController.swift
//  TwitterInstant
//
//  Created by Waratnan Suriyasorn on 6/16/2559 BE.
//
//

import UIKit
import ReactiveCocoa
import Social
import Accounts

typealias NS_Enum = TWState

enum TWState: Int {
	case RWTwitterInstantErrorAccessDenied = 0
	case RWTwitterInstantErrorNoTwitterAccount = 1
	case RWTwitterInstantErrorInvalidResponse = 2
}
struct RWTwitter {
	static let InstantDomain = "TwitterInstant"
}
class SearchFormViewController: UIViewController
{
	@IBOutlet weak var searchText: UITextField!
	var resultsViewController: SearchResultsViewController!

	var accountStore: ACAccountStore!
	var twitterAccountType: ACAccountType!

	override func viewDidLoad() {
		self.accountStore = ACAccountStore()
		self.twitterAccountType = self.accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)

		self.title = "Twitter Instant"
		self.styleTextField(self.searchText)
		self.resultsViewController = self.splitViewController?.viewControllers[1] as! SearchResultsViewController

		self.searchText.rac_textSignal()
			.map {
				[weak weakSelf = self] text in
				let value = text as! String
				let isValid = weakSelf?.isValidSearchText(value)
				return isValid! ? UIColor.whiteColor() : UIColor.yellowColor() }
			.subscribeNext {
				[weak weakSelf = self](color) in
				let colorToSet = color as! UIColor
				weakSelf?.searchText.backgroundColor = colorToSet
		}

		self.requestAccessToTwitterSignal()
			.then { [weak weakSelf = self]() -> RACSignal! in
				return weakSelf?.searchText.rac_textSignal() }
			.filter { [weak weakSelf = self](text) -> Bool in
				return (weakSelf?.isValidSearchText(text as! String))! }
            .flattenMap { [weak weakSelf = self](text) -> RACStream! in
                return weakSelf?.signalForSearchWithText(text as! String) }
            .throttle(0.5)
            .deliverOnMainThread()
			.subscribeNext({ [weak weakSelf = self](data) in
//				print("Acess granted ", data)
                let tweets = (weakSelf?.parseJsonToObject(data as! [String:AnyObject]))!
                weakSelf?.resultsViewController.displayTweet(tweets)
            }) { (err) in
				print("An error occurred: \(err!.description) ")
            }

	}

	func styleTextField(textField: UITextField)
	{
		let textFieldLayer = textField.layer;
		textFieldLayer.borderColor = UIColor.grayColor().CGColor
		textFieldLayer.borderWidth = 2.0
		textFieldLayer.cornerRadius = 0.0
	}

	private func isValidSearchText(text: String) -> Bool {
		return text.characters.count > 2
	}

	private func requestAccessToTwitterSignal() -> RACSignal {
		let accessError = NSError(domain: RWTwitter.InstantDomain, code: NS_Enum.RWTwitterInstantErrorAccessDenied.rawValue, userInfo: nil)

		let racSignal = RACSignal.createSignal { [weak weakSelf = self](subscriber) -> RACDisposable! in
			weakSelf?.accountStore.requestAccessToAccountsWithType(self.twitterAccountType, options: nil, completion: { (granted, NSError) in

				if !granted {
					subscriber.sendError(accessError)
				} else {
					subscriber.sendNext(nil)
					subscriber.sendCompleted()
				}
			})
			return nil
		}

		return racSignal
	}

	private func requestForTwitterSearchWithText(text: String) -> SLRequest {
		let url = NSURL(string: "https://api.twitter.com/1.1/search/tweets.json")
		let param = ["q": text]

		let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: url!, parameters: param)

		return request
	}

	private func signalForSearchWithText(text: String) -> RACSignal {

		let racSignal = RACSignal.createSignal { [weak weakSelf = self](subscriber) -> RACDisposable! in

			let request = weakSelf?.requestForTwitterSearchWithText(text)

			let noAccountError = NSError(domain: RWTwitter.InstantDomain, code: NS_Enum.RWTwitterInstantErrorNoTwitterAccount.rawValue, userInfo: nil)

			let invalidResponseError = NSError(domain: RWTwitter.InstantDomain, code: NS_Enum.RWTwitterInstantErrorInvalidResponse.rawValue, userInfo: nil)

			let twitterAccounts = weakSelf?.accountStore.accountsWithAccountType(weakSelf?.twitterAccountType)

			if twitterAccounts!.count == 0 {
				subscriber.sendError(noAccountError)
			} else {
				request?.account = twitterAccounts?.last as! ACAccount

				request?.performRequestWithHandler { (response, urlResponse, error) in
					if urlResponse.statusCode == 200 {
						do {
							let timelineData = try NSJSONSerialization.JSONObjectWithData(response, options: NSJSONReadingOptions.AllowFragments)
							subscriber.sendNext(timelineData)
							subscriber.sendCompleted()
						} catch let error as NSError {
							subscriber.sendError(error)
						}

					} else {
						subscriber.sendError(invalidResponseError)
					}
				}
			}
			return nil
		}
		return racSignal
	}
    
    private func parseJsonToObject(JSON: [String:AnyObject]) -> [Tweet] {
        var tweets:[Tweet] = []
        if let statueses = JSON["statuses"] as? [[String:AnyObject]] {
            for tweetData in statueses {
                let tweet = Tweet.init(statusObj: tweetData)
                tweets.append(tweet)
            }
        }
        return tweets
    }
}