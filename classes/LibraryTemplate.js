const db = require('./../libs/db');
const Document = require('./DocumentTemplate');

class LibraryTemplate extends Document{

    selectLib () {
        if (!this.config) {
            return null;
        }
        return db.queryDb(this.config.selectAsLibs, []);
   }
}

module.exports = LibraryTemplate;