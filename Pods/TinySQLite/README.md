[![CI Status](http://img.shields.io/travis/Øyvind Grimnes/TinySQLite.svg?style=flat)](https://travis-ci.org/Øyvind Grimnes/TinySQLite)
[![Version](https://img.shields.io/cocoapods/v/TinySQLite.svg?style=flat)](http://cocoapods.org/pods/TinySQLite)
[![License](https://img.shields.io/cocoapods/l/TinySQLite.svg?style=flat)](http://cocoapods.org/pods/TinySQLite)
[![Platform](https://img.shields.io/cocoapods/p/TinySQLite.svg?style=flat)](http://cocoapods.org/pods/TinySQLite)

![alt text] (http://i.imgur.com/KvtukKk.png "Logo")

A lightweight SQLite wrapper written in Swift

###Features
- [x] Lightweight
- [x] Object oriented
- [x] Automatic parameter binding
- [x] Named parameter binding
- [x] Thread safe
- [x] Supports all native Swift types

####Valid datatypes
- [x] String
- [x] Character
- [x] Bool
- [x] All integer types (signed and unsigned)
- [x] Float
- [x] Double
- [x] NSString
- [x] NSData
- [x] NSDate (represented as UNIX timestamps)
- [x] NSNumber

## Usage
### Creating the database object
Provide the path to an existing or new database
```Swift
let databaseQueue = DatabaseQueue(path: path)
```
### Creating queries
All valid SQLite queries are accepted by TinySQLite

To use automatic binding, replace the values in the statement by '?', and provide the values in an array

```Swift
let query = "INSERT INTO YourTable (column, otherColumn) VALUES (?, ?)"
let values = [1, "A value"]
```

To use automatic named binding, replace the values in the statement by ':\<name>', and provide the values in a dictionary

```Swift
let query = "INSERT INTO YourTable (column, otherColumn) VALUES (:column, :otherColumn)"
let values = ["column": 1, "otherColumn": "A value"]
```

### Executing updates
Execute an update in the database
```Swift
try databaseQueue.database { (database) in
    try database.executeUpdate(query, values: values)
    try database.executeUpdate(query, namedValues: values)
}
```


### Executing queries
Execute a query to the database.
```Swift
try databaseQueue.database { (database) in
    for row in try database.executeQuery(query) {
        row.integerForColumn(2) // Returns an integer from the second column in the row
        row.dateForColumn("deadline") // Returns a date from the column called 'deadline'
        row.dictionary // Returns a dictionary representing the row
    }
}
```

### Transactions
To improve performance, and prevent partial updates when executing multiple queries, you can use `DatabaseQueue`'s `transaction` method.
If an error is thrown in the block, all changes are rolled back. 
```Swift
try databaseQueue.transaction { (database) in
    try database.executeUpdate(query)
    try database.executeUpdate(query)
    try database.executeUpdate(query)
}
```

## Installation

TinySQLite is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "TinySQLite"
```

## Author

Øyvind Grimnes, oyvindkg@yahoo.com

## License

TinySQLite is available under the MIT license. See the LICENSE file for more info.
