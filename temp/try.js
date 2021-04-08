const crypto = require('crypto');
const algorithm = 'aes-192-cbc';

let parametrid = {
    rekv_id: 63,
    isik_id: 30752,
    kuu: 3,
    aasta: 2021
};
const password = '2001MyForever';

let encrypted = '';
const iv = Buffer.from('1234567890123456', 'utf8');


const encrypt = (text) => {
    return new Promise((resolve, reject) => {

// We will first generate the key, as it is dependent on the algorithm.
// In this case for aes192, the key is 24 bytes (192 bits).
            crypto.scrypt(password, 'salt', 24, (err, key) => {
                if (err) throw err;
                // After that, we will generate a random iv (initialization vector)

                // Create Cipher with key and iv
                const cipher = crypto.createCipheriv(algorithm, key, iv);


                cipher.setEncoding('hex');

                cipher.on('data', (chunk) => encrypted += chunk);
                cipher.on('end', () => {
                        console.log(encrypted);
                        resolve(encrypted);
                    }
                );// Prints encrypted data with key

                cipher.write(text);
                cipher.end();
            });
        }
    )
};

const decrypt = (encrypted, callback) => {


// We will first generate the key, as it is dependent on the algorithm.
// In this case for aes192, the key is 24 bytes (192 bits).
// We will use the async `crypto.scrypt()` instead for deciphering.
    const key = crypto.scryptSync(password, 'salt', 24);
// The IV is usually passed along with the ciphertext.

// Create decipher with key and iv
    const decipher = crypto.createDecipheriv(algorithm, key, iv);

    let decrypted = '';
    decipher.on('readable', () => {
        while (null !== (chunk = decipher.read())) {
            decrypted += chunk.toString('utf8');
        }
    });
    decipher.on('end', () => {
        console.log(decrypted);
        // Prints: some clear text data
        callback(decrypted);
    });

// Encrypted with same algorithm, key and iv.
//const encrypted ='e5f79c5915c02171eec6b212d5520d44480993d7d622a7c4c2da32f6efda0ffa';

    decipher.write(encrypted, 'hex');
    decipher.end();
};

async function playWithPass(textToHash) {

    encrypted = await encrypt(textToHash);
    console.log('encrypted promise', encrypted);

    let descrypted = decrypt(encrypted, (pass) => {
            let obj = JSON.parse(pass);
            console.log('back pass', pass, obj)

        }
    )
}

playWithPass(JSON.stringify(parametrid));

console.log('final', encrypted);



