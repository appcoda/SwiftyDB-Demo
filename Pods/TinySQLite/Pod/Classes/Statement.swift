//
//  Statement.swift
//  TinySQLite
//
//  Created by Øyvind Grimnes on 25/12/15.
//

import sqlite3

public enum SQLiteDatatype: String {
    case Text       = "TEXT"
    case Integer    = "INTEGER"
    case Real       = "REAL"
    case Blob       = "BLOB"
    case Numeric    = "NUMERIC"
    case Null       = "NULL"
}

public class Statement {
    private var handle: COpaquePointer
    var query: String
    
    var isBusy: Bool {
        return NSNumber(int: sqlite3_stmt_busy(handle)).boolValue
    }
    
    lazy var indexToNameMapping: [Int32: String] = {
        var mapping: [Int32: String] = [:]
        
        for index in 0..<sqlite3_column_count(self.handle) {
            let name =  NSString(UTF8String: sqlite3_column_name(self.handle, index)) as! String
            mapping[index] = name
        }
        
        return mapping
    }()
    
    lazy var nameToIndexMapping: [String: Int32] = {
        var mapping: [String: Int32] = [:]
        
        for index in 0..<sqlite3_column_count(self.handle) {
            let name =  NSString(UTF8String: sqlite3_column_name(self.handle, index)) as! String
            mapping[name] = index
        }
        
        return mapping
    }()
    
    
    public init(_ query: String, handle: COpaquePointer = nil) {
        self.query = query
        self.handle = handle
    }
    
    /** Next row in results */
    public func step() throws -> Bool {
        let result = sqlite3_step(handle)
        
        try SQLiteResultHandler.verifyResultCode(result, forHandle: handle)
        
        if result == SQLITE_DONE {
            return false
        }
        
        return true
    }
    
    /** Clear memory */
    public func finalize() throws {
        try SQLiteResultHandler.verifyResultCode(sqlite3_finalize(handle), forHandle: handle)
    }
    
    /** ID of the last row inserted */
    public func lastInsertRowId() -> Int? {
        let id = Int(sqlite3_last_insert_rowid(handle))
        return id > 0 ? id : nil
    }
    
// MARK: - Execute query
    
    /**
    Execute a write-only update with an array of variables to bind to placeholders in the prepared query
    
    - parameter value:  array of values that will be bound to parameters in the prepared query
    
    - returns:          `self`
    */
    public func executeUpdate(values: SQLiteValues = []) throws -> Statement {
        try execute(values)
        try step()
        return self
    }
    
    /**
    Execute a write-only update with a dictionary of variables to bind to placeholders in the prepared query
     
    - parameter namedValue: dictionary of values that will be bound to parameters in the prepared query
     
    - returns:              `self`
    */
    public func executeUpdate(namedValues: NamedSQLiteValues) throws -> Statement {
        try execute(namedValues)
        try step()
        return self
    }
    
    /**
    Execute a query with a dictionary of variables to bind to placeholders in the prepared query
    Finalize the statement when you are done by calling `finalize()`
     
    - parameter namedValue: dictionary of values that will be bound to parameters in the prepared query
     
    - returns:              `self`
    */
    public func execute(namedValues: NamedSQLiteValues) throws -> Statement {
        try bind(namedValues)
        return self
    }
    
    /**
    Execute a query with an array of variables to bind to placeholders in the prepared query
    Finalize the statement when you are done by calling `finalize()`
     
    - parameter value:  array of values that will be bound to parameters in the prepared query
     
    - returns:          `self`
    */
    public func execute(values: SQLiteValues = []) throws -> Statement {
        try bind(values)
        return self
    }
    
// MARK: - Internal methods
    
    internal func reset() throws {
        try SQLiteResultHandler.verifyResultCode(sqlite3_reset(handle), forHandle: handle)
    }
    
    internal func clearBindings() throws {
        try SQLiteResultHandler.verifyResultCode(sqlite3_clear_bindings(handle), forHandle: handle)
    }
    
    internal func prepareForDatabase(databaseHandle: COpaquePointer) throws {
        try SQLiteResultHandler.verifyResultCode(sqlite3_prepare_v2(databaseHandle, query, -1, &handle, nil), forHandle: handle)
    }
    
    internal func bind(namedValues: NamedSQLiteValues) throws {
        var parameterNameToIndexMapping: [String: Int32] = [:]
        
        for (name, _) in namedValues {
            let index = sqlite3_bind_parameter_index(handle, ":\(name)")
            parameterNameToIndexMapping[name] = index
        }
        
        let values: SQLiteValues = namedValues.keys.sort {
            parameterNameToIndexMapping[$0]! < parameterNameToIndexMapping[$1]!
            }.map {namedValues[$0]!}
        
        try bind(values)
    }
    
    internal func bind(values: SQLiteValues) throws {
        try reset()
        try clearBindings()
        
        let totalBindCount = sqlite3_bind_parameter_count(handle)
        
        var bindCount: Int32 = 0
        for (index, value) in values.enumerate() {
            try bindValue(value, forIndex: Int32(index+1))
            ++bindCount
        }
        
        if bindCount != totalBindCount {
            throw Error.NumberOfBindings
        }
    }
    
// MARK: - Private methods
    
    private func bindValue(value: SQLiteValue?, forIndex index: Int32) throws {
        if value == nil {
            try SQLiteResultHandler.verifyResultCode(sqlite3_bind_null(handle, index), forHandle: handle)
            return
        }
        
        let result: Int32
        
        switch value {
            
        /* Bind special values */
        case let dateValue as NSDate:
            result = sqlite3_bind_double(handle, index, dateValue.timeIntervalSince1970)
            
        case let dataValue as NSData:
            if dataValue.length == 0 {
                print("[ WARNING: Data values with zero bytes are treated as NULL by SQLite ]")
            }
            result = sqlite3_bind_blob(handle, index, dataValue.bytes, Int32(dataValue.length), SQLITE_TRANSIENT)
            
        case let numberValue as NSNumber:
            result = try bindNumber(numberValue, forIndex: index)
            
        /* Bind integer values */
        case let integerValue as Int:
            result = sqlite3_bind_int64(handle, index, Int64(integerValue))
        case let integerValue as UInt:
            result = sqlite3_bind_int64(handle, index, Int64(integerValue))
        case let integerValue as Int8:
            result = sqlite3_bind_int64(handle, index, Int64(integerValue))
        case let integerValue as Int16:
            result = sqlite3_bind_int64(handle, index, Int64(integerValue))
        case let integerValue as Int32:
            result = sqlite3_bind_int64(handle, index, Int64(integerValue))
        case let integerValue as Int64:
            result = sqlite3_bind_int64(handle, index, Int64(integerValue))
        case let integerValue as UInt8:
            result = sqlite3_bind_int64(handle, index, Int64(integerValue))
        case let integerValue as UInt16:
            result = sqlite3_bind_int64(handle, index, Int64(integerValue))
        case let integerValue as UInt32:
            result = sqlite3_bind_int64(handle, index, Int64(integerValue))
        case let integerValue as UInt64:
            result = sqlite3_bind_int64(handle, index, Int64(integerValue))
        
        /* Bind boolean values */
        case let boolValue as Bool:
            result = sqlite3_bind_int64(handle, index, boolValue ? 1 : 0)
            
        /* Bind real values */
        case let floatValue as Float:
            result = sqlite3_bind_double(handle, index, Double(floatValue))
        case let doubleValue as Double:
            result = sqlite3_bind_double(handle, index, doubleValue)
            
        /* Bind text values */
        case let stringValue as String:
            result = sqlite3_bind_text(handle, index, stringValue, -1, SQLITE_TRANSIENT)
        case let stringValue as NSString:
            result = sqlite3_bind_text(handle, index, stringValue.UTF8String, -1, SQLITE_TRANSIENT)
        case let characterValue as Character:
            result = sqlite3_bind_text(handle, index, String(characterValue), -1, SQLITE_TRANSIENT)
            
        default:
            result = sqlite3_bind_text(handle, index, value as! String, -1, SQLITE_TRANSIENT)
        }
        
        try SQLiteResultHandler.verifyResultCode(result, forHandle: handle)
    }
    
    /** Bind the value wrapped in an NSNumber object based on the values type */
    private func bindNumber(numberValue: NSNumber, forIndex index: Int32) throws -> Int32 {
        
        let typeString = String.fromCString(numberValue.objCType)
        if typeString == nil || typeString!.isEmpty {
            throw Error.BindingType
        }
        
        let result: Int32
        
        switch typeString! {
        case "c":
            result = sqlite3_bind_int64(handle, index, Int64(numberValue.charValue))
        case "i":
            result = sqlite3_bind_int64(handle, index, Int64(numberValue.intValue))
        case "s":
            result = sqlite3_bind_int64(handle, index, Int64(numberValue.shortValue))
        case "l":
            result = sqlite3_bind_int64(handle, index, Int64(numberValue.longValue))
        case "q":
            result = sqlite3_bind_int64(handle, index, numberValue.longLongValue)
        case "C":
            result = sqlite3_bind_int64(handle, index, Int64(numberValue.charValue))
        case "I":
            result = sqlite3_bind_int64(handle, index, Int64(numberValue.unsignedIntValue))
        case "S":
            result = sqlite3_bind_int64(handle, index, Int64(numberValue.unsignedShortValue))
        case "L":
            result = sqlite3_bind_int64(handle, index, Int64(numberValue.unsignedLongValue))
        case "Q":
            result = sqlite3_bind_int64(handle, index, Int64(numberValue.unsignedLongLongValue))
        case "B":
            result = sqlite3_bind_int64(handle, index, Int64(numberValue.boolValue ? 1 : 0))
        case "f", "d":
            result = sqlite3_bind_double(handle, index, numberValue.doubleValue)
        default:
            result = sqlite3_bind_text(handle, index, numberValue.description, -1, SQLITE_TRANSIENT)
        }
        
        return result
    }
}





//MARK: - Values for indexed columns
extension Statement {
    
    /** Returns the datatype for the column given by an index */
    public func typeForColumn(index: Int32) -> SQLiteDatatype? {
        switch sqlite3_column_type(handle, index) {
        case SQLITE_INTEGER:
            return .Integer
        case SQLITE_FLOAT:
            return .Real
        case SQLITE_TEXT, SQLITE3_TEXT:
            return .Text
        case SQLITE_BLOB:
            return .Blob
        case SQLITE_NULL:
            return .Null
        default:
            return nil
        }
    }
    
    /** Returns a value for the column given by the index based on the columns datatype */
    public func valueForColumn(index: Int32) -> SQLiteValue? {
        let columnType = sqlite3_column_type(handle, index)
        
        switch columnType {
        case SQLITE_INTEGER:
            return integerForColumn(index)
        case SQLITE_FLOAT:
            return doubleForColumn(index)
        case SQLITE_TEXT:
            return stringForColumn(index)
        case SQLITE_BLOB:
            return dataForColumn(index)
        case SQLITE_NULL:
            fallthrough
        default:
            return nil
        }
    }
    
    /** Returns an integer for the column given by the index */
    public func integerForColumn(index: Int32) -> Int? {
        if let value = integer64ForColumn(index) {
            return Int(value)
        }
        return nil
    }
    
    /** Returns a 64-bit integer for the column given by the index */
    public func integer64ForColumn(index: Int32) -> Int64? {
        if typeForColumn(index) == .Null {
            return nil
        }
        return sqlite3_column_int64(handle, index)
    }
    
    /** Returns a 32-bit integer for the column given by the index */
    public func integer32ForColumn(index: Int32) -> Int32? {
        if let value = integer64ForColumn(index) {
            return Int32(value)
        }
        return nil
    }
    
    /** Returns a 16-bit integer for the column given by the index */
    public func integer16ForColumn(index: Int32) -> Int16? {
        if let value = integer64ForColumn(index) {
            return Int16(value)
        }
        return nil
    }
    
    /** Returns a 8-bit integer for the column given by the index */
    public func integer8ForColumn(index: Int32) -> Int8? {
        if let value = integer64ForColumn(index) {
            return Int8(value)
        }
        return nil
    }
    
    /** Returns an unsigned 64-bit integer for the column given by the index */
    public func unsignedInteger64ForColumn(index: Int32) -> UInt64? {
        if let value = integer64ForColumn(index) {
            return UInt64(value)
        }
        return nil
    }
    
    /** Returns an unsigned 32-bit integer for the column given by the index */
    public func unsignedInteger32ForColumn(index: Int32) -> UInt32? {
        if let value = integer64ForColumn(index) {
            return UInt32(value)
        }
        return nil
    }
    
    /** Returns an unsigned 16-bit integer for the column given by the index */
    public func unsignedInteger16ForColumn(index: Int32) -> UInt16? {
        if let value = integer64ForColumn(index) {
            return UInt16(value)
        }
        return nil
    }
    
    /** Returns an unsigned 8-bit integer for the column given by the index */
    public func unsignedInteger8ForColumn(index: Int32) -> UInt8? {
        if let value = integer64ForColumn(index) {
            return UInt8(value)
        }
        return nil
    }
    
    /** Returns an unsigned integer for the column given by the index */
    public func unsignedIntegerForColumn(index: Int32) -> UInt? {
        if let value = integer64ForColumn(index) {
            return UInt(value)
        }
        return nil
    }
    
    /** Returns a double for the column given by the index */
    public func doubleForColumn(index: Int32) -> Double? {
        if typeForColumn(index) == .Null {
            return nil
        }
        return sqlite3_column_double(handle, index)
    }
    
    /** Returns a float for the column given by the index */
    public func floatForColumn(index: Int32) -> Float? {
        if let value = doubleForColumn(index) {
            return Float(value)
        }
        return nil
    }
    
    /** Returns a boolean for the column given by the index */
    public func boolForColumn(index: Int32) -> Bool? {
        if let value = integerForColumn(index) {
            return Bool(value)
        }
        return nil
    }
    
    /** Returns a data for the column given by the index */
    public func dataForColumn(index: Int32) -> NSData? {
        if typeForColumn(index) == .Null {
            return nil
        }
        return NSData(bytes: sqlite3_column_blob(handle, index), length: Int(sqlite3_column_bytes(handle, index)))
    }
    
    /** Returns an date for the column given by the index */
    public func dateForColumn(index: Int32) -> NSDate? {
        if typeForColumn(index) == .Null {
            return nil
        }
        return doubleForColumn(index) != nil ? NSDate(timeIntervalSince1970: doubleForColumn(index)!) : nil
    }
    
    /** Returns a string for the column given by the index */
    public func stringForColumn(index: Int32) -> String? {
        return nsstringForColumn(index) as? String
    }
    
    /** Returns a character for the column given by the index */
    public func characterForColumn(index: Int32) -> Character? {
        return stringForColumn(index)?.characters.first
    }
    
    /** Returns a string for the column given by the index */
    public func nsstringForColumn(index: Int32) -> NSString? {
        return NSString(bytes: sqlite3_column_text(handle, index), length: Int(sqlite3_column_bytes(handle, index)), encoding: NSUTF8StringEncoding)
    }
    
    /** Returns a number for the column given by the index */
    public func numberForColumn(index: Int32) -> NSNumber? {
        switch sqlite3_column_type(handle, index) {
        case SQLITE_INTEGER:
            return integerForColumn(index) as NSNumber?
        case SQLITE_FLOAT:
            return doubleForColumn(index) as NSNumber?
        case SQLITE_TEXT:
            if let stringValue = stringForColumn(index) {
                return Int(stringValue)
            }
            return nil
        default:
            return nil
        }
    }
}





//MARK: - Dictionary representation of row
extension Statement {
    
    /** A dictionary representation of the data contained in the row */
    public var dictionary: NamedSQLiteValues {
        var dictionary: NamedSQLiteValues = [:]
        
        for i in 0..<sqlite3_column_count(handle) {
            dictionary[indexToNameMapping[i]!] = valueForColumn(i)
        }
        
        return dictionary
    }
}





//MARK: - Values for named columns
extension Statement {
    
    /** Returns the datatype for the column given by a column name */
    public func typeForColumn(name: String) -> SQLiteDatatype? {
        return typeForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns a value for the column given by the column name, based on the SQLite datatype of the column */
    public func valueForColumn(name: String) -> SQLiteValue? {
        return valueForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns an integer for the column given by the column name */
    public func integerForColumn(name: String) -> Int? {
        return integerForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns a 64-bit integer for the column given by the column name  */
    public func integer64ForColumn(name: String) -> Int64? {
        return  integer64ForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns a 32-bit integer for the column given by the column name  */
    public func integer32ForColumn(name: String) -> Int32? {
        return integer32ForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns a 16-bit integer for the column given by the column name  */
    public func integer16ForColumn(name: String) -> Int16? {
        return integer16ForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns a 8-bit integer for the column given by the column name  */
    public func integer8ForColumn(name: String) -> Int8? {
        return integer8ForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns an unsigned 64-bit integer for the column given by the column name  */
    public func unsignedInteger64ForColumn(name: String) -> UInt64? {
        return unsignedInteger64ForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns an unsigned 32-bit integer for the column given by the column name  */
    public func unsignedInteger32ForColumn(name: String) -> UInt32? {
        return unsignedInteger32ForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns an unsigned 16-bit integer for the column given by the column name  */
    public func unsignedInteger16ForColumn(name: String) -> UInt16? {
        return unsignedInteger16ForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns an unsigned 8-bit integer for the column given by the index */
    public func unsignedInteger8ForColumn(name: String) -> UInt8? {
        return unsignedInteger8ForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns an unsigned integer for the column given by the column name  */
    public func unsignedIntegerForColumn(name: String) -> UInt? {
        return unsignedIntegerForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns a double for the column given by the column name */
    public func doubleForColumn(name: String) -> Double? {
        return doubleForColumn(nameToIndexMapping[name]!)
    }

    /** Returns a float for the column given by the column name */
    public func floatForColumn(name: String) -> Float? {
        return floatForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns a boolean for the column given by the column name */
    public func boolForColumn(name: String) -> Bool? {
        return boolForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns data for the column given by the column name */
    public func dataForColumn(name: String) -> NSData? {
        return dataForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns a date for the column given by the column name */
    public func dateForColumn(name: String) -> NSDate? {
        return dateForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns a string for the column given by the column name */
    public func stringForColumn(name: String) -> String? {
        return stringForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns a character for the column given by the column name */
    public func characterForColumn(name: String) -> Character? {
        return characterForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns a string for the column given by the column name */
    public func nsstringForColumn(name: String) -> NSString? {
        return nsstringForColumn(nameToIndexMapping[name]!)
    }
    
    /** Returns a number for the column given by the column name */
    public func numberForColumn(name: String) -> NSNumber? {
        return numberForColumn(nameToIndexMapping[name]!)
    }
}

// MARK: - Generator and sequence type
extension Statement: GeneratorType, SequenceType {
    
    /** Easily iterate through the rows. Performs a sqlite_step() and returns itself */
    public func next() -> Statement? {
        do {
            let moreRows = try step()
            return moreRows ? self : nil
        } catch {
            return nil
        }
    }
    
    public func generate() -> Statement {
        let _ = try? self.reset()
        return self
    }
}