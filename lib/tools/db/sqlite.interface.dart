part of 'sqlite.dart';

class SQLDatabaseInterface extends SInterface<SQLDatabase> {
  @override
  get className => "SQLDatabase";

  @override
  get classDescription => """
A database connection to a SQLite database.

This class is used to connect to a SQLite database and execute queries on it.""";

  static final openedDBs = <String, SQLDatabase>{};

  @override
  get statics => {
        LEntry(
            name: "open",
            args: const {
              LArg<String>(
                  name: "path", descr: "The path to the database file."),
            },
            returnType: SQLDatabase, (String path) {
          if (openedDBs.containsKey(path)) {
            return openedDBs[path]!;
          }
          final db = SQLDatabase(path);
          openedDBs[path] = db;
          return db;
        })
      };

  @override
  get exports => {
        LEntry(
            name: "select",
            args: const {
              LArg<String>(name: "query", descr: "The query to execute."),
              LArg<List>(
                  name: "params", descr: "The parameters to pass to the query.")
            },
            returnType: List,
            isAsync: true,
            (String query, List params) => object!.select(query, params)),
        LEntry(name: "close", descr: "Closes the database connection.", () {
          openedDBs.remove(object!.path);
          object!._db.dispose();
        }),
      };
}
