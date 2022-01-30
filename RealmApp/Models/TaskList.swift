//
//  TaskList.swift
//  RealmApp
//
//  Created by Alexey Efimov on 08.10.2021.
//  Copyright © 2021 Alexey Efimov. All rights reserved.
//

import RealmSwift

class TaskList: Object {
    @Persisted var name = ""
    @Persisted var date = Date()
    @Persisted var tasks = List<Task>()
    @Persisted(primaryKey: true) var id: ObjectId // For future use
}

class Task: EmbeddedObject {
    @Persisted var name = ""
    @Persisted var note = ""
    @Persisted var date = Date()
    @Persisted var isComplete = false
    @Persisted(originProperty: "tasks") var taskList: LinkingObjects<TaskList>
    // EmbeddedObject with primary key crashes
    // @Persisted(primaryKey: true) var id: ObjectId
}
