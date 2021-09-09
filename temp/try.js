const util = require('util');
const fs = require('fs');
const conversionFactory = require('html-to-xlsx');
const puppeteer = require('puppeteer');
const chromeEval = require('chrome-page-eval')({ puppeteer });
const writeFileAsync = util.promisify(fs.writeFile);

const conversion = conversionFactory({
    extract: async ({ html, ...restOptions }) => {
        const tmpHtmlPath = 'c:/temp/temp.html';

        await writeFileAsync(tmpHtmlPath, html);

        const result = await chromeEval({
            ...restOptions,
            html: tmpHtmlPath,
            scriptFn: conversionFactory.getScriptFn()
        });

        const tables = Array.isArray(result) ? result : [result];

        return tables.map((table) => ({
            name: table.name,
            getRows: async (rowCb) => {
                table.rows.forEach((row) => {
                    rowCb(row)
                })
            },
            rowsCount: table.rows.length
        }))
    }
});

async function run () {
    let html = fs.readFileSync('c:/temp/test.html', 'utf8');
    const stream = await conversion(`html`);

    stream.pipe(fs.createWriteStream('output.xlsx'))
}

run();