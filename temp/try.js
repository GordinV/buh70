const {Client} = require('pg');
const path = require('path');
const fs = require('fs');

let data = test_db();

// SSL соединение, если прописано в конфигурации
async function test_db() {
    console.log('start');
    let client;

    const pathToSSLCa = 'c:/development/buh70/config/client.crt';
    const pathToSSLKey = 'c:/development/buh70/config/server.key';
    const pathToSSLcert = 'c:/development/buh70/config/client.crt';

    const pgConfig = {
        user: 'vlad',
        password: 'Vlad490710',
        database: 'narvalv',
        port: 5432,
        host: 'localhost',
        ssl: {
            rejectUnauthorized: false,
            require: true,
            ca: fs.readFileSync(pathToSSLCa).toString(),
            key: fs.readFileSync(pathToSSLKey).toString(),
            cert: fs.readFileSync(pathToSSLcert).toString(),
        }
    };
    let res;
    console.log('pgConfig', pgConfig);
    try {
       let client = new Client(pgConfig);
//console.log('client',client);
        await client.connect();
        res = await client.query('SELECT * FROM pg_stat_activity');
        console.log('data', res);
        await client.end();

    } catch (e) {
        console.error(err)
    }
console.log('lopp', res);
    return res;
}


