import Foundation

infix operator &&
infix operator ||
prefix operator !

func &&(left: NSPredicate, right: NSPredicate) -> NSPredicate {
    return NSCompoundPredicate(andPredicateWithSubpredicates: [left, right])
}

func ||(left: NSPredicate, right: NSPredicate) -> NSPredicate {
    return NSCompoundPredicate(orPredicateWithSubpredicates: [left, right])
}

prefix func !(arg: NSPredicate) -> NSPredicate {
    return NSCompoundPredicate(notPredicateWithSubpredicate: arg)
}
