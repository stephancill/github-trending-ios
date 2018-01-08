//
//  TrendingTableViewController.swift
//  Github Trending
//
//  Created by Stephan Cilliers on 2018/01/07.
//  Copyright © 2018 Stephan. All rights reserved.
//

import UIKit
import SafariServices

struct Repo: Codable {
	var title: String
	var url: String
	var stars: String
	var description: String
	var language: String
}

class TrendingTableViewController: UITableViewController {
	
	var repos: [Repo] = [] {
		didSet {
			UserDefaults.standard.setValue(try? PropertyListEncoder().encode(repos), forKey: "repos")
			UserDefaults.standard.setValue(Date(), forKey: "lastUpdate")
			self.tableView.reloadData()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.navigationController?.navigationBar.prefersLargeTitles = true
		self.navigationItem.largeTitleDisplayMode = .always
		self.title = "Trending"
		
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
		tableView.refreshControl = {
			let refreshControl = UIRefreshControl()
			refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
			return refreshControl
		}()
		
		if let _ = self.extensionContext { } else {
			refresh()
		}
	}
	
	func getTrending(language: String="", callback: @escaping ([Repo]?, Error?) -> ()) {
		// Locally hosted API
		let endpoint = "https://github-trending.herokuapp.com/trending"
		// HTTP Request
		URLSession.shared.dataTask(with: URL(string: endpoint)!) { (data, response, error) in
			if let error = error {
				callback(nil, error)
				return
			}
			let statusCode = (response as! HTTPURLResponse).statusCode
			// Check for problems with response
			if statusCode == 200 && error == nil {
				// Response Data -> JSON String
				if let jsonString = String.init(data: data!, encoding: String.Encoding.utf8) {
					// JSON String -> JSON
					if let json = jsonString.data(using: .utf8) {
						// JSON -> MarketSummaryResponse
						let repos = try? JSONDecoder().decode([Repo].self, from: json)
						// Return data (success)
						callback(repos, error)
					}
				}
			} else {
				// Return data (failure)
				callback(nil, error)
			}
		}.resume()
	}
	
	@objc func refresh() {
		getTrending(callback: { (repos, error) in
			DispatchQueue.main.async {
				self.tableView.refreshControl?.endRefreshing()
				if let repos = repos {
					// Update successful
					self.repos = repos
					print("Hello")
				} else {
					// Update failed
					print("Error: \(String(describing: error))")
					return
				}
			}
		})
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		tableView.reloadData()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	// MARK: - Table view data source
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 40
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.repos.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		let repo = self.repos[indexPath.row]
		
		cell.subviews.forEach { (subview) in
			subview.removeFromSuperview()
		}
		// Configure the cell...
		let titleLabel = { () -> UILabel in
			let label = UILabel(frame: CGRect(x: 10, y: 2, width: 0, height: 18))
			label.text = "\(repo.title)"
			label.font = UIFont(name: "Helvetica", size: 16)
			label.frame.size = CGSize(width: min(label.intrinsicContentSize.width, cell.frame.width/2) , height: label.frame.height)
			return label
		}()
		cell.addSubview(titleLabel)
		
		let starsLabel = { () -> UILabel in
			let label = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 15))
			label.text = "\(repo.language) • \(repo.stars) ★"
			label.textAlignment = .right
			label.font = UIFont(name: "Helvetica", size: 12)
			label.frame.size = CGSize(width: 120 , height: label.frame.height)
			label.frame.origin = CGPoint(x: cell.frame.width - 130, y: 5)
			return label
		}()
		cell.addSubview(starsLabel)
		
		let descriptionLabel = { () -> UILabel in
			let label = UILabel(frame: CGRect(x: 10, y: titleLabel.frame.maxY + 3, width: cell.frame.width - 20, height: 14))
			label.text = "\(repo.description)"
			label.font = UIFont(name: "Helvetica", size: 12)
			return label
		}()
		cell.addSubview(descriptionLabel)
		
		return cell
	}
	
	func openURL(_ url: URL) {
		let safari = SFSafariViewController(url: url)
		self.navigationController?.navigationBar.isHidden = true
		self.present(safari, animated: true) {
			self.navigationController?.navigationBar.isHidden = false
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let url = URL(string: self.repos[indexPath.row].url)!
		openURL(url)
	}

}

