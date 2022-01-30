//
//  TaskListsViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import UIKit
import RealmSwift

class TaskListViewController: UITableViewController {
    
    @IBOutlet weak var sortBySegmentedControl: UISegmentedControl!

    var taskLists: Results<TaskList>!
    
    private var notificationToken: NotificationToken?

    private var sortProperties: [PartialKeyPath<TaskList>] = [\.date, \.name]
    private var sortAscending = true
    private var sortBy: PartialKeyPath<TaskList> {
        sortProperties[sortBySegmentedControl.selectedSegmentIndex]
    }
    private var currentTasksPredicate = NSPredicate(format: "%K = %@", argumentArray: ["isComplete", false])
    private var sortDirectionButtonItem: UIBarButtonItem!
    //private var searchBar = UISearchBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        taskLists = StorageManager.shared.realm.objects(TaskList.self).sorted(byKeyPaths: [(sortBy, sortAscending)])
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        
        sortDirectionButtonItem = UIBarButtonItem(
            title: "↑",
            style: .plain,
            target: self,
            action: #selector(sortButtonPressed)
        )
        
        navigationItem.rightBarButtonItems = [editButtonItem, addButton]
        navigationItem.leftBarButtonItem = sortDirectionButtonItem
        
        DataManager.shared.createTempDataV2() { /* Nothing to do in completion. Updates are done via notification. */}
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskLists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let taskList = taskLists[indexPath.row]
        content.text = taskList.name
        let currentTasksCount = taskList.tasks.filter(currentTasksPredicate).count
        content.secondaryText = currentTasksCount == 0 ? "✓" : "\(currentTasksCount)"
        cell.contentConfiguration = content
        return cell
    }
    
    // MARK: - Table View Data Source
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let taskList = taskLists[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.delete(taskList)
            //tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, isDone in
            self.showAlert(with: taskList) {
                // self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        
        let doneAction = UIContextualAction(style: .normal, title: "Done") { _, _, isDone in
            StorageManager.shared.done(taskList)
            // tableView.reloadRows(at: [indexPath], with: .automatic)
            isDone(true)
        }
        
        editAction.backgroundColor = .orange
        doneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        guard let tasksVC = segue.destination as? TasksViewController else { return }
        let taskList = taskLists[indexPath.row]
        tasksVC.taskList = taskList
    }

    @IBAction func sortingList(_ sender: UISegmentedControl) {
        resortTaskLists()
    }
    
    @objc private func addButtonPressed() {
        showAlert()
    }
    
    @objc private func sortButtonPressed() {
        sortAscending.toggle()
        resortTaskLists()
    }
    
    private func resortTaskLists() {
        sortDirectionButtonItem.title = sortAscending ? "↑" : "↓"
        taskLists = taskLists.sorted(byKeyPaths: [(sortBy, sortAscending)])
        tableView.reloadSections([0], with: .middle)
    }
    
    
    
    private func observeChanges() {
        notificationToken = taskLists.observe { [weak self] (changes) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                tableView.performBatchUpdates({
                    // It's important to be sure to always update a table in this order:
                    // deletions, insertions, then updates. Otherwise, you could be unintentionally
                    // updating at the wrong index!
                    tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0) }),
                        with: .automatic)
                    tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                        with: .automatic)
                    tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                        with: .automatic)
                })
            case .error(let error):
                fatalError("\(error)")
            }
        }
    }
}

extension TaskListViewController {
    
    private func showAlert(with taskList: TaskList? = nil, completion: (() -> Void)? = nil) {
        let title = taskList != nil ? "Edit List" : "New List"
        let alert = UIAlertController.createAlert(withTitle: title, andMessage: "Please set title for new task list")
        
        alert.action(with: taskList) { newValue in
            if let taskList = taskList, let completion = completion {
                StorageManager.shared.edit(taskList, newValue: newValue)
                completion()
            } else {
                self.save(taskList: newValue)
            }
        }
        
        present(alert, animated: true)
    }
    
    private func save(taskList: String) {
        let taskList = TaskList(value: [taskList])
        StorageManager.shared.add(taskList)
        
        let rowIndex = IndexPath(row: taskLists.index(of: taskList) ?? 0, section: 0)
        tableView.insertRows(at: [rowIndex], with: .automatic)
    }
}
