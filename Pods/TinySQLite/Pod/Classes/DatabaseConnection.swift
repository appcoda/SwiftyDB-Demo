//
//  DatabaseConnection.swift
//  TinySQLite
//
//  Created by Øyvind Grimnes on 25/12/15.
//

import sqlite3

// MARK: - Setup SQLiteValue protocol for all supported  datatypes

/** Valid SQLite types are marked using the 'SQLiteValue' protocol */
public protocol SQLiteValue {}

extension String: SQLiteValue {}
extension NSString: SQLiteValue {}
extension Character: SQLiteValue {}

extension Bool: SQLiteValue {}

extension Int: SQLiteValue {}
extension Int8: SQLiteValue {}
extension Int16: SQLiteValue {}
extension Int32: SQLiteValue {}
extension Int64: SQLiteValue {}
extension UInt: SQLiteValue {}
extension UInt8: SQLiteValue {}
extension UInt16: SQLiteValue {}
extension UInt32: SQLiteValue {}
extension UInt64: SQLiteValue {}

extension Float: SQLiteValue {}
extension Double: SQLiteValue {}

extension NSData: SQLiteValue {}
extension NSDate: SQLiteValue {}
extension NSNumber: SQLiteValue {}

public typealias SQLiteValues = Array<SQLiteValue?>
public typealias NamedSQLiteValues = Dictionary<String, SQLiteValue?>

// MARK: -

public enum Error: Int32, ErrorType, CustomStringConvertible {
    case OK                 = 0
    case Error
    case InternalError
    case PermissionDenied
    case Abort
    case Busy
    case TableLocked
    case NoMemory
    case ReadOnly
    case Interrupted
    case IOError
    case Corrupted
    case NotFound
    case Full
    case CannotOpen
    case LockProtocol
    case Empty
    case Schema
    case TooBig
    case ConstraintViolation
    case DatatypeMismatch
    case LibraryMisuse
    case NoLSF
    case Authorization
    case InvalidFormat
    case OutOfRange
    case NotADatabase
    case Notification
    case Warning
    case Row                = 100
    case Done               = 101
    case BindingType
    case NumberOfBindings

    public var description: String {
        return "TinySQLite.Error: \(self.message) (\(rawValue))"
    }
    
    public var message: String {
        switch self {
        case .OK:
            return "Successful result"
        case .Error:
            return "SQL error or missing database"
        case .InternalError:
            return "Internal logic error in SQLite"
        case .PermissionDenied:
            return "Access permission denied"
        case .Abort:
            return "Callback routine requested an abort"
        case .Busy:
            return "The database file is locked"
        case .TableLocked:
            return "A table in the database is locked"
        case .NoMemory:
            return "A malloc() failed"
        case .ReadOnly:
            return "Attempt to write a readonly database"
        case .Interrupted:
            return "Operation terminated by sqlite3_interrupt()"
        case .IOError:
            return "Some kind of disk I/O error occurred"
        case .Corrupted:
            return "The database disk image is malformed"
        case .NotFound:
            return "Unknown opcode in sqlite3_file_control()"
        case .Full:
            return "Insertion failed because database is full"
        case .CannotOpen:
            return "Unable to open the database file"
        case .LockProtocol:
            return "Database lock protocol error"
        case .Empty:
            return "Database is empty"
        case .Schema:
            return "The database schema changed"
        case .TooBig:
            return "String or BLOB exceeds size limit"
        case .ConstraintViolation:
            return "Abort due to constraint violation"
        case .DatatypeMismatch:
            return "Data type mismatch"
        case .LibraryMisuse:
            return "Library used incorrectly"
        case .NoLSF:
            return "Uses OS features not supported on host"
        case .Authorization:
            return "Authorization denied"
        case .InvalidFormat:
            return "Auxiliary database format error"
        case .OutOfRange:
            return "2nd parameter to sqlite3_bind out of range"
        case .NotADatabase:
            return "File opened that is not a database file"
        case .Notification:
            return "Notifications from sqlite3_log()"
        case .Warning:
            return "Warnings from sqlite3_log()"
        case .Row:
            return "sqlite3_step() has another row ready"
        case .Done:
            return "sqlite3_step() has finished executing"
        case .BindingType:
            return "Tried to bind an unrecognized data type, or an NSNumber wrapping an unrecognied type"
        case .NumberOfBindings:
            return "Incorrect number of bindings"
            
        }
    }
}

internal struct SQLiteResultHandler {
    static let successCodes: Set<Int32> = [SQLITE_OK, SQLITE_DONE, SQLITE_ROW]
    
    static func isSuccess(resultCode: Int32) -> Bool {
        return SQLiteResultHandler.successCodes.contains(resultCode)
    }
    
    static func verifyResultCode(resultCode: Int32, forHandle handle: COpaquePointer) throws {
        guard isSuccess(resultCode) else {
            throw Error(rawValue: resultCode)!
        }
    }
}

// MARK: -

internal let SQLITE_STATIC = unsafeBitCast(0, sqlite3_destructor_type.self)
internal let SQLITE_TRANSIENT = unsafeBitCast(-1, sqlite3_destructor_type.self)


/** Responsible for opening and closing database connections, executing queries, and managing transactions */
public class DatabaseConnection {
    
    private var handle: COpaquePointer = nil
    private let path: String
    
    public var isOpen: Bool = false
    
    public init(path: String) {
        self.path = path
    }
    
    /** Open the database connection */
    public func open() throws {
        try SQLiteResultHandler.verifyResultCode(sqlite3_open(path, &handle), forHandle: handle)
        isOpen = true
    }
    
    /** Close the database connection */
    public func close() throws {
        try SQLiteResultHandler.verifyResultCode(sqlite3_close(handle), forHandle: handle)
        handle = nil
        isOpen = false
    }
    
    /** 
    Prepare a statement for the provided query
     
    - parameter query:  an SQLite query
    
    - returns:          a prepared statement
    */
    public func prepare(query: String) throws -> Statement {
        let statement: Statement = Statement(query)
        try statement.prepareForDatabase(handle)
        return statement
    }
}

// MARK: - Transactions
extension DatabaseConnection {
    
    /** Begin a transaction */
    func beginTransaction() throws {
        try self.prepare("BEGIN TRANSACTION")
                .executeUpdate()
                .finalize()
    }
    
    /** End an ongoing transaction */
    func endTransaction() throws {
        try self.prepare("END TRANSACTION")
                .executeUpdate()
                .finalize()
    }
    
    /** Rollback a transaction */
    func rollback() throws {
        try self.prepare("ROLLBACK TRANSACTION")
                .executeUpdate()
                .finalize()
    }
}

// MARK: - General
extension DatabaseConnection {
    
    /** Number of rows affected by INSERT, UPDATE, or DELETE since the database was opened */
    public func changes() -> Int {
        return Int(sqlite3_changes(handle))
    }
    
    /** Total number of rows affected by INSERT, UPDATE, or DELETE since the database was opened */
    public func totalChanges() -> Int {
        return Int(sqlite3_total_changes(handle))
    }
    
    /** Interrupts any pending database operations */
    public func interrupt() {
        sqlite3_interrupt(handle)
    }
}

// MARK: - Convenience
extension DatabaseConnection {
    
    /** 
    Check if a table exists 
    
    - parameter tableName:  name of the table
    
    - returns:              boolean indicating whether the table exists, or not
    */
    public func containsTable(tableName: String) throws -> Bool {
        let query = "SELECT name FROM sqlite_master WHERE type='table' AND name=?"
        
        let statement = try prepare(query)
                                .execute([tableName])
        
        /* Finalize the statement if necessary */
        defer {
            try! statement.finalize()
        }
        
        return statement.next() != nil
    }
}