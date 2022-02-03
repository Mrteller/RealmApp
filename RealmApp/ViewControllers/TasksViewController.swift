//
//  TasksViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import UIKit
import RealmSwift

class TasksViewController: NotifiedTableViewController<Task> {
    
    // MARK: - Public vars
    
    var taskList: TaskList!
    private var tasks: Results<Task>!
    
    // MARK: - Private vars
    
    private let taskCategoryNames = ["Current", "Completed"]

    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = taskList.name
        customSections = [false: "Current", true : "Complete"]
        sectionsBy = \.isComplete
        diffableDataSource = StringConvertibleSectionTableViewDiffibleDataSource<AnyHashable, OID<Task>>(tableView: tableView) { (tableView, indexPath, taskOID) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "TasksCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            let task = taskOID.object
            content.text = task.name
            content.secondaryText = task.hashValue.description
            cell.contentConfiguration = content
            return cell
        }
        tasks = taskList.tasks.sorted(by: ["isComplete", "name"])
        observeChanges(tasks)
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        navigationItem.rightBarButtonItems = [addButton, editButtonItem]
    }
    
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let task = diffableDataSource?.itemIdentifier(for: indexPath)?.object else { return UISwipeActionsConfiguration(actions: [])}
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.delete(task)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self]_, _, isDone in
            self?.showAlert(with: task)
            isDone(true)
        }
        // FIXME: Kext with section indexing. Use cycled `nextIndex` instead.
        let doneAction = UIContextualAction(style: .normal, title:  taskCategoryNames[indexPath.section == 0 ? 1 : 0]) { _, _, isDone in
            StorageManager.shared.done(task)
            isDone(true)
        }
        
        editAction.backgroundColor = .orange
        doneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
    }
    
    // MARK: - Private funcs
    
    @objc private func addButtonPressed() {
        showAlert()
    }

}

// MARK: - Extensions

extension TasksViewController {
    private func showAlert(with task: Task? = nil) {
        let title = task != nil ? "Edit Task" : "New Task"
        
        let alert = UIAlertController.createAlert(withTitle: title, andMessage: "What do you want to do?")
        
        alert.action(with: task) { [unowned self] name, note in
            if let task = task {
                StorageManager.shared.edit(task, keyedValues: ["name": name, "note": note])
            } else {
                let task = Task(value: [name, note])
                StorageManager.shared.add(task, to: self.taskList)
            }
        }
        
        present(alert, animated: true)
    }
    
}
