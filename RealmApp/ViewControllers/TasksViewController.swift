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
    
    var taskList: TaskList!
    
    private let taskCategoryNames = ["Current", "Completed"]
    private var currentTasks: Results<Task>!
    private var completedTasks: Results<Task>!
    private var tasksByCategory: [Results<Task>] {
        [currentTasks, completedTasks]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = taskList.name
        currentTasks = taskList.tasks.filter("isComplete = false")
        completedTasks = taskList.tasks.filter("isComplete = true")
        //observeChanges(currentTasks)
        
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
    
    @objc private func addButtonPressed() {
        showAlert()
    }
    
    // MARK: - Table View Delegate
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let task = tasksByCategory[indexPath.section][indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.delete(task)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, isDone in
            self.showAlert(with: task) {
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        
        let doneAction = UIContextualAction(style: .normal, title: "Done") { _, _, isDone in
            StorageManager.shared.done(task)
            guard let indexPathOfChangedTask = self.indexPath(of: task) else {
                tableView.reloadData()
                return
            }
            tableView.performBatchUpdates {
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.insertRows(at: [indexPathOfChangedTask], with: .automatic)
            }
            isDone(true)
        }
        
        editAction.backgroundColor = .orange
        doneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
    }
    
    private func indexPath(of task: Task) -> IndexPath? {
        for (section, tasks) in tasksByCategory.enumerated() {
            if let row = tasks.index(of: task) {
                return IndexPath(row: row, section: section)
            }
        }
        return nil
    }

}

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
                //self.saveTask(withName: newValue, andNote: note)
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
    
//    private func saveTask(withName name: String, andNote note: String) {
//        let task = Task(value: [name, note])
//        StorageManager.shared.add(task, to: taskList)
//
//        let rowIndex = IndexPath(row: currentTasks.index(of: task) ?? 0, section: 0)
//        tableView.insertRows(at: [rowIndex], with: .automatic)
//    }
}
