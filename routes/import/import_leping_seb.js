module.exports = async (file, mimeType, user) => {
    const Doc = require('./../../classes/DocumentTemplate');
    const Document = new Doc('VANEM', null, user.userId, user.asutusId, 'lapsed');

    let rows = [];

    try {
        rows = await readCSV(file);
    } catch
        (e) {
        console.error('Viga:', e);
        return `Tekkis viga, vale formaat`;
    }
    let saved = 0;
    if (rows.length) {
        // сохраняем

        const params = [JSON.stringify(rows), user.id, user.asutusId];

        const result = await Document.executeTask('importPankLeping', params).then((result) => {
                console.log('result', result);

                saved = result.result ? result.result : 0;
                return saved;
            }
        );


        return `Kokku leidsin ${rows.length} lepingud, salvestatud kokku: ${saved}`;

    } else {
        return `Kokku leidsin 0 lepingud, salvestatud kokku: 0`;

    }
}
;

const readCSV = async (csvContent) => {
    const parse = require('csv-parse');
    const rows = [];
    // Create the parser
    const fileContent = await parse(csvContent, {
        escape: '"',
        relax: true,
        headers: true,
        delimiter: ';',
        columns: false
    }, (err, output) => {
        console.log('outpur', output);
        result = output;
        if (err) {
            console.error(err);
            return null;
        }

        output.forEach(row => {
            // проверим на заголовок
            console.log('row', row[9], row);
            if (!row[0].match(/[A-Z]/g)) {
                rows.push({
                    kpv: row[8],
                    viitenr: row[0],
                    aa: row[3].replace(/EUR/g,''),
                    toiming: row[10] === 'A' ? 'Lisa': 'Kustuta',
                    nimi: row[2],
                    isikukood: row[1],
                    kanal: 'EYP',
                    kehtiv: row[9]
                });
            }
        });
    });
    return rows;
};

function isNumber(val) {
    // negative or positive
    return /^[-]?\d+$/.test(val);
}

