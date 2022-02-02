//
//  TasksViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import UIKit
import RealmSwift

class TasksViewController: UITableViewController {
    
    // MARK: - Public vars
    
    var taskList: TaskList!
    
    // MARK: - Private vars
    
    private let taskCategoryNames = ["Current", "Completed"]
    private var currentTasks: Results<Task>!
    private var completedTasks: Results<Task>!
    private var tasksByCategory: [Results<Task>] {
        [currentTasks, completedTasks]
    }
    private var isCompletePredicate = NSPredicate(format: "%K = %@", argumentArray: ["isComplete", true])
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = taskList.name
        currentTasks = taskList.tasks.filter(!isCompletePredicate)
        completedTasks = taskList.tasks.filter(isCompletePredicate)
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        navigationItem.rightBarButtonItems = [addButton, editButtonItem]
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        taskCategoryNames.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tasksByCategory[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        taskCategoryNames[section].uppercased()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TasksCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let task = tasksByCategory[indexPath.section][indexPath.row]
        content.text = task.name
        content.secondaryText = task.note
        cell.contentConfiguration = content
        return cell
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let task = tasksByCategory[indexPath.section][indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.delete(task)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self]_, _, isDone in
            self?.showAlert(with: task)
            isDone(true)
        }
        // FIXME: Kext with section indexing. Use cycled `nextIndex` instead.
        let doneAction = UIContextualAction(style: .normal, title:  taskCategoryNames[indexPath.section == 0 ? 1 : 0]) { _, _, isDone in
            StorageManager.shared.done(task)
            guard let indexPathOfChangedTask = self.indexPath(of: task) else {
                tableView.reloadData()
                return
            }
            tableView.moveRow(at: indexPath, to: indexPathOfChangedTask)
            isDone(true)
        }
        
        editAction.backgroundColor = .orange
        doneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
    }
    
    // MARK: - Private funcs
    
    private func indexPath(of task: Task) -> IndexPath? {
        for (section, tasks) in tasksByCategory.enumerated() {
            if let row = tasks.index(of: task) {
                return IndexPath(row: row, section: section)
            }
        }
        return nil
    }
    
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
                guard let indexPathOfChangedTask = self.indexPath(of: task) else {
                    tableView.reloadData()
                    return
                }
                tableView.reloadRows(at: [indexPathOfChangedTask], with: .automatic)
            } else {
                let task = Task(value: [name, note])
                StorageManager.shared.add(task, to: self.taskList)
                guard let indexPathOfChangedTask = self.indexPath(of: task) else {
                    tableView.reloadData()
                    return
                }
                tableView.insertRows(at: [indexPathOfChangedTask], with: .automatic)
            }
        }
        
        present(alert, animated: true)
    }
    
}
