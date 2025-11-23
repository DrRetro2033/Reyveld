import 'package:pool/pool.dart';
import 'package:reyveld/reyveld.dart';
import 'package:reyveld/scripting/sinterface.dart';
import 'package:sqlite3/sqlite3.dart';

part 'sqlite.interface.dart';

class SQLDatabase {
  final Database _db;
  final String path;

  SQLDatabase(this.path) : _db = sqlite3.open(path);

  Pool? _pool;

  Future<Pool> get pool async => _pool ??=
      Pool(int.tryParse(await Reyveld.getPerformanceOption("SQLPOOL")) ?? 5);

  Future<List> select(String query, List params) async {
    return await pool.then((e) => e.withResource<List>(
        () async => _db.select(query, params).map((x) => x).toList()));
  }
}
