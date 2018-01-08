//
//  TodayViewController.swift
//  Github Trending Widget
//
//  Created by Stephan Cilliers on 2018/01/07.
//  Copyright © 2018 Stephan. All rights reserved.
//

import UIKit
import NotificationCenter


//struct Repo: Codable {
//	var title: String
//	var url: String
//	var stars: String
//	var description: String
//	var language: String
//}

@objc(TodayViewController)

class TodayViewController: TrendingTableViewController {
	
	override func loadView() {
		view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height:200))
		tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height:200))
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
	}
	
    override func viewDidLoad() {
		self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
		self.preferredContentSize = (self.extensionContext?.widgetMaximumSize(for: .expanded))!
		
		let placeholderLabel = { () -> UILabel in
			let label = UILabel()
			label.text = "Placeholder"
			label.center = CGPoint(x: self.view.frame.maxX/2, y: self.view.frame.maxY/2)
			return label
		}()
		view.addSubview(placeholderLabel)
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let url = URL(string: "githubtrending://:\(self.repos[indexPath.row].url)")!
		self.extensionContext?.open(url, completionHandler: nil)
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension TodayViewController: NCWidgetProviding {
	func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
		self.preferredContentSize = maxSize
		if activeDisplayMode == .compact {
			self.preferredContentSize = maxSize
		} else if activeDisplayMode == .expanded {
			self.preferredContentSize = CGSize(width: 320, height: 200)
		}
	}
	
	func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
		// Perform any setup necessary in order to update the view.
		
		// If an error is encountered, use NCUpdateResult.Failed
		// If there's no update required, use NCUpdateResult.NoData
		// If there's an update, use NCUpdateResult.NewData
		
		if let lastUpdate = UserDefaults.standard.value(forKey: "lastUpdate") as? Date {
			let now = Date()
			print("\(now) \(lastUpdate.addingTimeInterval(3600))")
			if now < lastUpdate.addingTimeInterval(3600) {
				print("Not fetching new data \(now) \(lastUpdate.addingTimeInterval(3600))")
				if let data = UserDefaults.standard.value(forKey:"repos") as? Data {
					if let repos = try? PropertyListDecoder().decode([Repo].self, from: data) {
						if repos.count > self.repos.count {
							self.repos = repos
						}
					}
				}
				completionHandler(NCUpdateResult.noData)
				return
			}
		}
		getTrending(callback: { (repos, error) in
			DispatchQueue.main.async {
				if let repos = repos {
					// Update successful
					self.repos = repos
					completionHandler(NCUpdateResult.newData)
				} else {
					// Update failed
					print("Error: \(String(describing: error))")
					completionHandler(NCUpdateResult.failed)
					return
				}
			}
		})
	}
}
