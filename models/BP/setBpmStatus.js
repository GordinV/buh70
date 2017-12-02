'use strict';

const setBpmStatuses = (actualStepIndex, userId, doc)=>  {
// собираем данные на на статус документа, правим данные БП документа
    // 1. установить на actualStep = false
    // 2. задать статус документу
    // 3. выставить стутус задаче (пока только finished)
    // 4. если есть следующий шаг, то выставить там actualStep = true, статус задачи opened
    try {
        var bpm =  doc.bpm, // нельзя использовать let из - за использования try {}
            nextStep = bpm[actualStepIndex].nextStep,
            executors = bpm[actualStepIndex].actors || [];

        if (!executors || executors.length == 0) {
            // если исполнители не заданы, то добавляем автора
            executors.push({
                id: userId,
                name: 'AUTHOR',
                role: 'AUTHOR'
            })
        }

        bpm[actualStepIndex].data = [{execution: Date.now(), executor: userId, vars: null}];
        bpm[actualStepIndex].status = 'finished';  // 3. выставить стутус задаче (пока только finished)
        bpm[actualStepIndex].actualStatus = false;  // 1. установить на actualStep = false
        bpm[actualStepIndex].actors = executors;  // установить список акторов

        // выставим флаг на следующий щаг
        bpm = bpm.map(stepData => {
            if (stepData.step === nextStep) {
                // 4. если есть следующий шаг, то выставить там actualStep = true, статус задачи opened
                stepData.actualStep = true;
                stepData.status = 'opened';
            }
            return stepData;
        });

    } catch (e) {
        console.error('try error', e);
    }

    return bpm;

};

module.exports = setBpmStatuses;