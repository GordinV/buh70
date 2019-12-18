module.exports = async (file, mimeType, user) => {
    const Doc = require('./../../classes/DocumentTemplate');
    const Document = new Doc('LAPS', null, user.userId, user.asutusId, 'lapsed');

    let rows = [];

    try {
        if (mimeType === 'application/octet-stream') {
            rows = await readCSV(file);
        } else {
            return {error_message: 'Vale formaat', result: 0}
        }

    } catch (e) {
        console.error(e);
        return {error_message: e, result: 0}
    }
    let saved = 0;
    if (rows.length) {
        // сохраняем

        // делаем массив промисов
        const dataPromises = rows.map(row => {
            return new Promise(resolve => {
                const params = {
                    is_import: true,
                    data: JSON.stringify({data: row}),
                    userId: user.id,
                    asutusId: user.asutusId
                };

                resolve(Document.save(params, true));
            })
        });

        // решаем их
        await Promise.all(dataPromises).then((result) => {
            saved = result.length;
        }).catch((err) => {
            console.error('catched error->', err);
            return res.send({status: 500, result: null, error_message: err});
        });

    }
    return `Kokku leidsin ${rows.length} lapsed, salvestatud kokku: ${saved}`;

};

const readCSV = async (csvContent) => {
    const parse = require('csv-parse');
    const rows = [];
    // Create the parser
    const fileContent = await parse(csvContent, {headers: false, delimiter: ';', columns: false}, (err, output) => {
        result = output;
        if (err) {
            console.error(err);
            return null;
        }

        output.forEach(row => {
            // проверим на заголовок
            if (isNumber(row[0])) {
                rows.push({
                    isikukood: row[0],
                    nimi: row[1],
                    import: true
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

