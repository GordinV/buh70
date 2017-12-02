module.exports = {
    id: 1,
    type: 'DOK1',
    created: '2017-01-01',
    lastupdate: '2017-01-01',
    status: 'ok',
    kpv: '2017-07-01',
    number:'001',
    doklausid: 1,
    dokprop: 'Deebet / Kreedit',
    selg: 'SMK test dok',
    viitenr: '000000',
    maksepaev: '2017-06-25',
    relations: [],
    bpm:[
        {
            step: 0,
            name: 'Регистация документа',
            action: 'start',
            nextStep: 1,
            task: 'human',
            data: [],
            actors: [],
            status: null,
            actualStep: false
        },
        {
            step: 1,
            name: 'Контировка',
            action: 'generateJournal',
            nextStep: 2,
            task: 'human',
            data: [],
            status: null,
            actualStep: false
        },
//        {step:2, name:'Оплата', action: 'tasumine', nextStep:3, task:'human', data:[], status:null, actualStep:false},
        {
            step: 2,
            name: 'Конец',
            action: 'endProcess',
            nextStep: null,
            task: 'automat',
            data: [],
            actors: [],
            status: null,
            actualStep: false
        }
    ],
    details: [{
        id: 1,
        nomid: 5,
        asutusid: 1,
        konto:'113',
        summa: 44,
        tunnus:'tunnus',
        proj: 'proj'
    },
        {
            id: 2,
            nomid: 5,
            asutusid: 2,
            konto:'221',
            summa: 55,
            tunnus:'tunnus',
            proj: 'proj'

        }],
    doc_status: 0
};
