let teenus_ilma = 'TEENUS';
let teenus_drk = 'TEENUS ()';
let teenus_all = 'TEENUS ("ALL_YKSUS")';

console.log('teenus_ilma',get_teenus(teenus_ilma));
console.log('teenus_drk',get_teenus(teenus_drk));
console.log('teenus_all',get_teenus(teenus_all));

function get_teenus(yksus) {
    const tulemus = {
        yksus: '',
        all_yksus: ''
    };

    let found_brk = yksus.match(/[(]/);
    if (found_brk) {
        // найдена скоба с подучрежденим
        tulemus.yksus = yksus.slice(0, found_brk.index);
        tulemus.all_yksus = yksus.slice(found_brk.index).replace(/[^a-z,A-Z, 0-9,-,=]+/g,'');
    } else {
        //подучреждений нет
        tulemus.yksus = yksus;
    }
    console.log('tulemus', tulemus);
    return tulemus;
}