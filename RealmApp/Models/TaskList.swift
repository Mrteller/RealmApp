//
//  TaskList.swift
//  RealmApp
//
//  Created by Alexey Efimov on 08.10.2021.
//  Copyright © 2021 Alexey Efimov. All rights reserved.
//

import RealmSwift

class TaskList: Object, Identifiable {
    @Persisted var name = ""
    @Persisted var date = Date()
    @Persisted var tasks = List<Task>()
    //@Persisted var id = UUID() this crashes on deletion
//    @Persisted var id = UUID().hashValue
//    
//    override var hash: Int {
//        id
//    }
    //@Persisted(primaryKey: true) var id: ObjectId // ObjectId crashes on deletion with diffable datasource
    @Persisted(primaryKey: true) var id = UUID()
}

class Task: Object, Identifiable {
    @Persisted var name = ""
    @Persisted var note = ""
    @Persisted var date = Date()
    @Persisted var isComplete = false
    //@Persisted(originProperty: "tasks") var taskList: LinkingObjects<TaskList>
    // EmbeddedObject with primary key crashes
    // @Persisted(primaryKey: true) var id: ObjectId
    @Persisted(primaryKey: true) var id = UUID()
}
