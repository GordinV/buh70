function base64urlEncode(str) {
    return Buffer.from(str, 'binary')
        .toString('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=/g, '')

}

function base64urlDecode(str) {
    str = str.replace(/-/g, '+').replace(/_/g, '/')
    while (str.length % 4) str += '='
    return Buffer.from(str, 'base64').toString('binary')
}

let JWT = base64urlEncode('{"alg":"HS256","typ":"JWT", "rekv_id": 63, "user_id": 2477}, "valid": "2025-02-23"')

console.log(JWT);

let our_str = base64urlDecode(JWT)

console.log(our_str);

console.log('decode', our_str)