//
//  NotifiedTableViewController.swift
//  RealmApp
//
//  Created by  Paul on 30.01.2022.


import UIKit
import RealmSwift

class NotifiedTableViewController<O: Object>: UITableViewController {
    
    // MARK: - Private vars
    
    var diffableDataSource: UITableViewDiffableDataSource<AnyHashable, O>?
    private var notificationToken: NotificationToken?
    //var results: Results<O>?
    var sectionsBy: PartialKeyPath<O>?
    var sortSectionsAscending = true
    var customSections = [AnyHashable : AnyHashable]()
    
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
        //guard var snapshot = diffableDataSource?.snapshot() else { return }
        var snapshot = NSDiffableDataSourceSnapshot<AnyHashable, O>()
        if let sectionsBy = sectionsBy {
            if customSections.isEmpty {
                //let sections = results.distinct(by: [sectionsBy])
                var sections = Array(Set(results.compactMap { $0[keyPath: sectionsBy] as? AnyHashable }))
                //let deletedSections = Array(Set(snapshot.sectionIdentifiers).subtracting(sections))
//                snapshot.deleteSections(deletedSections)
//                sectionsToAdd = sections -
                // TODO: Think about replacing with sort closure here
                if sortSectionsAscending {
                    sections = sections.sorted(by: { $0.description > $1.description })
                } else {
                    sections = sections.sorted(by: { $0.description < $1.description })
                }
                for section in sections {
                    print("section: \(section)")
                    snapshot.appendSections([section])
//                    let predicate = NSPredicate(format: "%K == %@", argumentArray: ["name", section])
//                    print(predicate)
//                    let items = Array(results.filter(predicate))
//                    snapshot.appendItems(items)
                    print(snapshot.itemIdentifiers)
                    snapshot.appendItems(Array(results.filter( { ($0[keyPath: sectionsBy] as! AnyHashable) == section })), toSection: section)
                }
            } else {
                for customSection in customSections {
                    snapshot.appendSections([customSection.value])
                    snapshot.appendItems(Array(results.filter( { $0[keyPath: sectionsBy] as! AnyHashable == customSection.key })), toSection: customSection.value)
                }
            }
            
        } else {
            snapshot.appendSections([0])
            snapshot.appendItems(Array(results), toSection: 0)
        }
        UIView.animate(withDuration: 3) { [weak self] in
            self?.diffableDataSource?.apply(snapshot, animatingDifferences: true)
        }
    }
    
}

