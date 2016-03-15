# A Quick Demo of SwiftyDB

Choosing a way for storing data permanently is something that is always needed when developing applications. There are various options we can pick from: To create single files, to use CoreData or create a SQLite database. The last option includes some extra hassle as the database must be created first, and all tables and fields to be already defined before an app uses them. Furthermore, and from the programming point of view, it’s not that easy to manage a SQLite database when data needs to be stored, updated or retrieved.

Those problems seem to disappear when using a relatively new library that was popped on the GitHub called SwiftyDB. It’s a third-party library, which, as the creator says, is a plug-and-play component indeed. SwiftyDB reliefs developers from the hassle of creating a SQLite database manually, and from defining all required tables and fields. That happens automatically by the library using the properties of the class (or classes) used as data models. Besides that, all database operations are performed under the hood, so developers can focus on the implementation of the app logic only. A simple yet powerful API makes it really a piece of cake when dealing with the database.

For the full tutorial, please refer to the link below:

http://www.appcoda.com/swiftydb
