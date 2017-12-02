'use strict';
const flux = require('fluxify');

let validateForm = ((self, reqFields, data) => {
    // валидация формы
    let warning = null,
        requiredFields = reqFields || [],
        notRequiredFields = [],
        notMinMaxRule = [];

        if (!data) {
            data = flux.stores.docStore.data;
        }


    requiredFields.forEach((field) => {
        if (field.name in data) {

            let value = data[field.name];

            if (!value) {
                notRequiredFields.push(field.name);
            }
            // проверка на мин . макс значения

            // || value && value > props.max
            let checkValue = false;

            switch (field.type) {
                case 'D':
                    let controlledValueD = Date.parse(value);
                    if ((field.min && controlledValueD < field.min) && (field.max && controlledValueD > field.max)) {
                        checkValue = true;
                    }
                    break;
                case 'N':
                    let controlledValueN = Number(value);

                    if (field.min && controlledValueN === 0 ||
                        ((field.min && controlledValueN < field.min) && (field.max && controlledValueN > field.max))) {
                        checkValue = true;
                    }
                    break;
            }
            if (checkValue) {
                notMinMaxRule.push(field.name);
            }
        }
    });

    if (notRequiredFields.length > 0) {
        warning = 'puudub vajalikud andmed (' + notRequiredFields.join(', ') + ') ';
    }

    if (notMinMaxRule.length > 0) {
        warning = warning ? warning: '' + ' min/max on vale(' + notMinMaxRule.join(', ') + ') ';
    }

    return warning; // вернем извещение об итогах валидации
});

module.exports = validateForm;
