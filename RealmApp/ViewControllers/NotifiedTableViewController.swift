//
//  NotifiedTableViewController.swift
//  RealmApp
//
//  Created by  Paul on 30.01.2022.


import UIKit
import RealmSwift

class NotifiedTableViewController: UITableViewController {
    
    // MARK: - Private vars
    
    private var notificationTokens = [NotificationToken]()
    private var updatedSections = [Int]() // can just use counter `updatedSections.count`
    
    // MARK: - Public funcs

    func observeChanges<T>(_ results: [Results<T>]) {
        stopObservingChanges()
        for (section, sectionResults) in results.enumerated() {
            let notificationToken = sectionResults.observe { [weak self] (changes) in
                guard let tableView = self?.tableView else { return }
                switch changes {
                case .initial:
                    tableView.reloadSections([section], with: .none)
                case .update(_, let deletions, let insertions, let modifications):
                    if modifications.count == 0 {
                    if self?.updatedSections.count == 0 { tableView.beginUpdates() }
                        tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: section) }),
                                             with: .automatic)
                        tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: section) }),
                                             with: .automatic)
//                        tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: section) }),
//                                             with: .automatic)
                    self?.updatedSections.append(section)
                    if self?.updatedSections.count == results.count {
                        tableView.endUpdates()
                        self?.updatedSections = []
                    }
                    } else {
                        tableView.performBatchUpdates {
                            tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: section) }),
                                                 with: .automatic)
                            tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: section) }),
                                                 with: .automatic)
                            tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: section) }),
                                                 with: .automatic)
                        }
                    }
                case .error(let error):
                    fatalError("\(error)")
                }
            }
            notificationTokens.append(notificationToken)
        }
    }
    
    func stopObservingChanges() {
        notificationTokens.forEach { $0.invalidate() }
    }
    
    deinit {
        stopObservingChanges()
    }

}
