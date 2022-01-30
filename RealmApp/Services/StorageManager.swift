//
//  StorageManager.swift
//  RealmApp
//
//  Created by Alexey Efimov on 08.10.2021.
//  Copyright © 2021 Alexey Efimov. All rights reserved.
//

import RealmSwift

class StorageManager {
    static let shared = StorageManager()
    
    let realm = try! Realm()
    
    private init() {}
    
    // MARK: - Task List
    func add(_ taskLists: [TaskList]) {
        try! realm.write {
            realm.add(taskLists)
        }
    }
    
    func add(_ taskList: TaskList) {
        write {
            realm.add(taskList)
        }
    }
    
    func delete(_ taskList: TaskList) {
        write {
            //realm.delete(taskList.tasks)
            realm.delete(taskList)
        }
    }
    
//    func delete<T: ObjectBase>(_ item: T) {
//        write {
//            //realm.delete(taskList.tasks)
//            realm.delete(item)
//        }
//    }
    
    
    func edit(_ taskList: TaskList, newValue: String) {
        write {
            taskList.name = newValue
        }
    }

    func done(_ taskList: TaskList) {
        write {
            taskList.tasks.setValue(true, forKey: "isComplete")
        }
    }

    // MARK: - Tasks
    func add(_ task: Task, to taskList: TaskList) {
        write {
            taskList.tasks.append(task)
        }
    }
    
    func delete(_ task: Task) {
        write {
            realm.delete(task)
        }
    }
    
    func edit(_ task: Task, keyedValues: [String : Any]) {
        write {
            task.setValuesForKeys(keyedValues)
        }
    }

    func done(_ task: Task) {
        write {
            task.isComplete.toggle()
        }
    }
    
    private func write(completion: () -> Void) {
        do {
            try realm.write {
                completion()
            }
        } catch {
            print(error)
        }
    }
}


extension Results {
    
    public func sorted<S: Sequence>(byKeyPaths sortKeyPaths: S) -> Results<Element>
    where S.Iterator.Element == PartialKeyPath<Element>, Element: ObjectBase {
        sorted(by: sortKeyPaths.map { SortDescriptor(keyPath: $0) })
    }
    
    public func sorted<S: Sequence>(byKeyPaths sortKeyPaths: S) -> Results<Element>
    where S.Iterator.Element == (keyPath: PartialKeyPath<Element>, ascending: Bool), Element: ObjectBase {
        sorted(by: sortKeyPaths.map { SortDescriptor(keyPath: $0.keyPath, ascending: $0.ascending) })
    }
    
}
