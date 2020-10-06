'use strict';

let validateForm = ((self, reqFields, data) => {
    // валидация формы
    let warning = null,
        requiredFields = reqFields || [],
        notRequiredFields = [],
        expressionFields = [],
        notMinMaxRule = [];

        if (!data) {
            return 'no data supplied';
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

            // проверка на выражение
            if (field.expression) {
                let expression = field.expression;
                let result = eval(field.expression);
                if (!result) {
                    expressionFields.push(field.name);
                }

            }
        }
    });

    if (notRequiredFields.length > 0) {
        warning = 'puudub vajalikud andmed (' + notRequiredFields.join(', ') + ') ';
    }

    if (notMinMaxRule.length > 0) {
        warning = warning ? warning: '' + ' min/max on vale(' + notMinMaxRule.join(', ') + ') ';
    }

    if (expressionFields.length > 0) {
        warning = warning ? warning: '' + ' vale andmed (' + expressionFields.join(', ') + ') ';
    }

    return warning; // вернем извещение об итогах валидации
});

module.exports = validateForm;
