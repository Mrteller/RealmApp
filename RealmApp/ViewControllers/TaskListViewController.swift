import UIKit
import RealmSwift

class TaskListViewController: NotifiedTableViewController<TaskList>, UISearchBarDelegate {
    
    // MARK: - @IBOutlets
    
    @IBOutlet weak var sortBySegmentedControl: UISegmentedControl!

    // MARK: - Public vars
    
    var taskLists: Results<TaskList>!

    // MARK: - Private vars
    
    private var sortProperties: [PartialKeyPath<TaskList>] = [\.date, \.name]
    private var sortAscending = true
    private var sortBy: PartialKeyPath<TaskList> {
        sortProperties[sortBySegmentedControl.selectedSegmentIndex]
    }
    private var currentTasksPredicate = NSPredicate(format: "%K = %@", argumentArray: ["isComplete", false])
    private var sortDirectionButtonItem: UIBarButtonItem!
    private var searchBar = UISearchBar()
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        taskLists = StorageManager.shared.realm.objects(TaskList.self).sorted(byKeyPaths: [(sortBy, sortAscending)])
        
        diffableDataSource = StringConvertibleSectionTableViewDiffibleDataSource<String, TaskList>(tableView: tableView) { (tableView, indexPath, commit) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            let taskList = self.taskLists[indexPath.row]
            content.text = taskList.name
            let currentTasksCount = taskList.tasks.filter(self.currentTasksPredicate).count
            content.secondaryText = currentTasksCount == 0 ? "✓" : "\(currentTasksCount)"
            cell.contentConfiguration = content
            return cell
        }
        observeChanges(taskLists)
        setupNavBar()
        DataManager.shared.createTempDataV2() { /* Nothing to do in completion. Updates are done via notification. */}
    }
    
    // MARK: - Table view data source
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        taskLists.count
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListCell", for: indexPath)
//        var content = cell.defaultContentConfiguration()
//        let taskList = taskLists[indexPath.row]
//        content.text = taskList.name
//        let currentTasksCount = taskList.tasks.filter(currentTasksPredicate).count
//        content.secondaryText = currentTasksCount == 0 ? "✓" : "\(currentTasksCount)"
//        cell.contentConfiguration = content
//        return cell
//    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let taskList = taskLists[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.delete(taskList)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, isDone in
            self?.showAlert(with: taskList)
            isDone(true)
        }
        
        let doneAction = UIContextualAction(style: .normal, title: "Done") { _, _, isDone in
            StorageManager.shared.done(taskList)
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

    // MARK: - @IBActions
    
    @IBAction func sortingList(_ sender: UISegmentedControl) {
        resortTaskLists()
    }
    
    // MARK: - Public funcs
    
    func searchBar(_ searchBar: UISearchBar, textDidChange textSearched: String) {
        if !textSearched.isEmpty {
            let predicate = NSPredicate(format:"name CONTAINS[c] %@ OR ANY tasks.name CONTAINS[c] %@", textSearched, textSearched)
            taskLists = StorageManager.shared.realm.objects(TaskList.self).filter(predicate).sorted(byKeyPaths: [(sortBy, sortAscending)])
        } else {
            taskLists = StorageManager.shared.realm.objects(TaskList.self).sorted(byKeyPaths: [(sortBy, sortAscending)])
        }
        tableView.reloadData()
    }
    
    // MARK: - Private funcs
    
    private func setupNavBar() {
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
        
        searchBar.delegate = self
        searchBar.placeholder = "Search..."
        searchBar.autocapitalizationType = .none
        
        navigationItem.titleView = searchBar
        navigationItem.rightBarButtonItems = [editButtonItem, addButton]
        navigationItem.leftBarButtonItem = sortDirectionButtonItem
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
    
}

    // MARK: - Extensions

extension TaskListViewController {
    
    private func showAlert(with taskList: TaskList? = nil) {
        let title = taskList != nil ? "Edit List" : "New List"
        let alert = UIAlertController.createAlert(withTitle: title, andMessage: "Please set title for new task list")
        
        alert.action(with: taskList) { newName in
            if let taskList = taskList {
                StorageManager.shared.edit(taskList, keyedValues: ["name" : newName])
            } else {
                let taskList = TaskList(value: [newName])
                StorageManager.shared.add(taskList)
            }
        }
        
        present(alert, animated: true)
    }
    
}


