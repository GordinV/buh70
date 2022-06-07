// period_start
let gridConfig = {
    gridConfiguration: [
        {id: "id", name: "id", width: "10%", show: false},
        {id: "row_id", name: "Jrk", width: "3%", show: true, hideFilter: true},
        {id: "isikukood", name: "Isikukood", width: "15%"},
        {id: "nimi", name: "Nimi", width: "25%"},
        {id: "viitenumber", name: "Viitenumber", width: "25%"},
        {id: "vana_vn", name: "Vana vn", width: "25%"},
        {id: "yksused", name: "Üksused", width: "30%"},
        {id: "lopp_kpv", name: "Lõpp kpv", width: "20%", type: 'date', interval: true},
        {
            id: "period",
            name: "Kehtivuse periood",
            width: "20%",
            type: 'date',
            interval: true,
            show: false,
            default: 'AASTA',
            filterValidation: () => {
                console.log('validation');
                this.validation()
            }
        },
        {id: "kehtivus", name: "Kehtivus", width: "10%", type: 'select', data: ['', 'Jah', 'Ei']},
        {id: "rekv_names", name: "Asutused", width: "30%", default: `DocContext.userData.asutus`},
        {id: "select", name: "Valitud", width: "10%", show: false, type: 'boolean', hideFilter: true}
    ],
    validation: (data, name) => {
        console.log('validated', data, name);
        return true;
    }
};
var  fieldName = 'period_start';
fieldName = fieldName.replace(/_start/g, '').replace(/_end/g, '');

console.log('fieldName', fieldName);

let fieldParams = gridConfig.gridConfiguration.filter((row)=>{
    return row.id == fieldName
});

console.log('fieldParams', fieldParams);

if (fieldParams[0].filterValidation) {
    console.log('test val');
    fieldParams[0].filterValidation()
}