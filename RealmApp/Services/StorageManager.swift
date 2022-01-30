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
    
    // MARK: - Generic
    
    func add<S: Sequence>(_ objects: S) where S.Iterator.Element: Object {
        try! realm.write {
            realm.add(objects)
        }
    }
        
    func add<T: Object>(_ item: T) {
        write {
            realm.add(item)
        }
    }
    
    func delete<T: ObjectBase>(_ item: T) {
        write {
            // Now child objects are deleted automatically
            //realm.delete(taskList.tasks)
            realm.delete(item)
        }
    }
    
    func edit<T: ObjectBase>(_ item: T, keyedValues: [String : Any]) {
        write {
            item.setValuesForKeys(keyedValues)
        }
    }

    // MARK: - Specific: Task List
    
    func done(_ taskList: TaskList) {
        write {
            taskList.tasks.setValue(true, forKey: "isComplete")
        }
    }

    // MARK: - Specific: Tasks
    func add(_ task: Task, to taskList: TaskList) {
        write {
            taskList.tasks.append(task)
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
