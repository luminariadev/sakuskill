const db = require('../../config/database');

class HealthRepository {
  async checkDatabaseAndPostgis() {
    const sql = [
      'SELECT',
      '  NOW() AS server_time,',
      '  current_database() AS database_name,',
      '  PostGIS_Full_Version() AS postgis_version;'
    ].join('\n');
    const { rows } = await db.query(sql);
    return rows[0];
  }
}

module.exports = new HealthRepository();
