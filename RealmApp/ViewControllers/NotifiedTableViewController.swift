//
//  NotifiedTableViewController.swift
//  RealmApp
//
//  Created by  Paul on 30.01.2022.


import UIKit
import RealmSwift

class NotifiedTableViewController: UITableViewController {
    
    private var notificationToken: NotificationToken?

    func observeChanges<T>(_ results: Results<T>) {
        notificationToken = results.observe { [weak self] (changes) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                tableView.performBatchUpdates {
                    tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0) }),
                        with: .automatic)
                    tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                        with: .automatic)
                    tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                        with: .automatic)
                }
            case .error(let error):
                fatalError("\(error)")
            }
        }
    }
    
    deinit {
        notificationToken?.invalidate()
    }

}
