//
//  NotifiedTableViewController.swift
//  RealmApp
//
//  Created by  Paul on 30.01.2022.


import UIKit
import RealmSwift
import SwiftUI

class NotifiedTableViewController<O: Object>: UITableViewController{
    //typealias O = Object
    
    // MARK: - Private vars
    
    var diffableDataSource: StringConvertibleSectionTableViewDiffibleDataSource<String, O>!
    private var notificationToken: NotificationToken?
    var results: Results<O>?
    var sectionsBy: PartialKeyPath<O>?
    
    // MARK: - Public funcs

    func observeChanges(_ results: Results<O>) {
        notificationToken = results.observe { [weak self] (changes) in
            switch changes {
            case .initial, .update:
                self?.generateAndApplySnapshot(results)
            case .error(let error):
                fatalError("\(error)")
            }
        }
    }
    
    func stopObservingChanges() {
        notificationToken?.invalidate()
    }
    
    deinit {
        stopObservingChanges()
    }

    private func generateAndApplySnapshot(_ results: Results<O>) {
        var snapshot = NSDiffableDataSourceSnapshot<String, O>()
        if let sectionsBy = sectionsBy {
            let sections = results.distinct(by: [sectionsBy])
            print("sections: \(sections)")
        }
//        fetchedResultsController.sections?.forEach {
            snapshot.appendSections(["Section"])
        snapshot.appendItems(Array(results), toSection: "Section")
//        }
        diffableDataSource.apply(snapshot, animatingDifferences: true)
    }
    
}

class StringConvertibleSectionTableViewDiffibleDataSource<UserSection: Hashable, User: Hashable>: UITableViewDiffableDataSource<UserSection, User> where UserSection: CustomStringConvertible {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionIdentifier(for: section)?.description
    }
}
