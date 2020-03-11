module.exports = async (file, mimeType, user) => {
    const Doc = require('./../../classes/DocumentTemplate');
    const Document = new Doc('PANK_VV', null, user.userId, user.asutusId, 'lapsed');

    let rows = [];
    try {
        if (mimeType === 'text/xml') {
            rows = await readXML(file);
        } else {
            rows = await readCSV(file);
        }

    } catch (e) {
        console.error(e);
    }

    let saved = 0;
    if (rows.length) {
        // сохраняем

        const params = {
            data: JSON.stringify({data: rows}),
            userId: user.id,
            asutusId: user.asutusId
        };
        const response = await Document.save(params, true);
        saved = response.data && response.data.length > 0 ? response.data[0].result : 0;
        timestamp = response.data && response.data.length > 0 ? response.data[0].stamp : null;

        if (saved && timestamp) {
            let mk_params = [timestamp, user.id];
            const mkCount = await Document.executeTask('koostaMK', mk_params);
        }
    }
    return `Kokku leidsin ${rows.length} maksed, salvestatud kokku: ${saved}`;

};

const readXML = async (xmlContent) => {
    const xml2js = require('xml2js');
    const parser = new xml2js.Parser({ignoreAttrs: true});
    const fileContent = [];
    const rows = [];

    const result = await parser.parseString(xmlContent, (err, result) => {
        if (err) {
            throw err;
        }

        let stmtes = result.Document.BkToCstmrStmt[0].Stmt;

        let aa = stmtes[0].Acct[0].Id[0].IBAN[0];
        let Acct = stmtes[0].Acct[0].Svcr[0].FinInstnId[0].BIC[0]; //banc code
        let Ntres = stmtes[0].Ntry;

        Ntres.forEach(ntry => {
            if (ntry.CdtDbtInd[0] == 'CRDT') {
                let summa = Number(ntry.Amt[0]);
                let kpv = ntry.ValDt[0].Dt[0];
                let pankId = ntry.AcctSvcrRef[0];
                let NtryDtls = ntry.NtryDtls[0].TxDtls[0];
                let number = NtryDtls.Refs[0].InstrId ? NtryDtls.Refs[0].InstrId[0] : null;
                let RmtInf = NtryDtls.RmtInf[0];
                let viitenr = RmtInf.Strd ? RmtInf.Strd[0].CdtrRefInf[0].Ref[0] : null;
                let selg = RmtInf.Ustrd ? RmtInf.Ustrd[0] : null;
                let maksja = NtryDtls.RltdPties[0].Dbtr ? NtryDtls.RltdPties[0].Dbtr[0].Nm[0] : null;
                let isikukood = NtryDtls.RltdPties[0].Dbtr ? NtryDtls.RltdPties[0].Dbtr[0].Id[0].PrvtId[0].Othr[0].Id[0] : null;
                let eban = NtryDtls.RltdPties[0].DbtrAcct ? NtryDtls.RltdPties[0].DbtrAcct[0].Id[0].IBAN[0] : null;

                rows.push({
                    pank_id: pankId,
                    summa: summa,
                    kpv: kpv,
                    selg: selg,
                    viitenr: viitenr,
                    maksja: maksja,
                    iban: eban,
                    pank: Acct,
                    number: number,
                    isikukood: isikukood,
                    aa: aa
                });

            }

        });
        return `Ok ${rows.length}, xml`;
    });

    return rows;

};

const readCSV = async (csvContent) => {
    const parse = require('csv-parse');
    const rows = [];
    // Create the parser
    const fileContent = await parse(csvContent, {headers: false, delimiter: ';', columns: false}, (err, output) => {
        result = output;
        if (err) {

        }

        output.forEach(row => {
            if (row[7] == 'C') {
                // кредит
                rows.push({
                    pank_id: row[10],
                    summa: Number(row[8]),
                    kpv: parce_kpv(row[2]),
                    selg: row[11],
                    viitenr: row[9],
                    maksja: row[4],
                    iban: row[3],
                    pank: row[5]
                });
            }

        });
    });
    return rows;
};

const parce_kpv = (l_date) => {
    let kpv = l_date.split('.');
    return new Date(kpv[2], kpv[1], kpv[0]).toLocaleDateString();
};