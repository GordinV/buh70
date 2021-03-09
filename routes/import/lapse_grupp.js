module.exports = async (file, mimeType, user) => {
    console.log('user', user);
    const Doc = require('./../../classes/DocumentTemplate');
    const Document = new Doc('LAPSE_GRUPP', null, user.userId, user.asutusId, 'lapsed');

    let rows = [];

    try {
        rows = await readCSV(file);
    } catch (e) {
        console.error('Viga:', e);
        return `Tekkis viga, võib olla vale formaat`;
    }

    let saved = 0;
    if (rows.length) {
        // сохраняем

        const params = [JSON.stringify(rows), user.id, user.asutusId];
        console.log(params);
        const result = await Document.executeTask('importGroups', params).then((result) => {
                saved = result.result ? result.result : 0;
            }
        );

        return `Kokku leidsin ${rows.length} gruppid, salvestatud kokku: ${saved}`;

    } else {
        return `Kokku leidsin 0 gruppid, salvestatud kokku: 0`;

    }
};

const readCSV = async (csvContent) => {
    const parse = require('csv-parse');
    const rows = [];
    // Create the parser
    await parse(csvContent, {headers: false, delimiter: ';', columns: false}, (err, output) => {
        result = output;
        if (err) {
            console.error(err);
            return null;
        }

        output.forEach(row => {
            // проверим на заголовок
            if (row[0] !== 'Asutus') {

                rows.push({
                    asutus: row[0],
                    kood: row[1],
                    nimetus: row[2],
                    grupi_liik: row[3],
                    koolituse_tyyp: row[4],
                    tyyp: row[4],
                    all_yksused_1: row[5],
                    all_yksused_2: row[6],
                    all_yksused_3: row[7],
                    all_yksused_4: row[8],
                    all_yksused_5: row[9],
                    teenus: row[10],
                    kogus: row[11],
                    hind: row[12]
                });
            }
        });
    });
    return rows;
};


