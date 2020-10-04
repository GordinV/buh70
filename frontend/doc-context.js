const createEmptyFilterData = require('./../libs/createEmptyFilterData');

const DocContext = {
    filter: {},
    libs: {},
    docTypeId: 'LAPS',
    initFilter: (docTypeId) => {
        /**
         * метод создаст пустой фильтр по переданной конфигурации
         */
        if (!docTypeId) {
            docTypeId = this.docTypeId;
            // проверим наличие конфигураций. если нет, то вернем пустой массив
            if (!DocContext.gridConfig || !DocContext.gridConfig[docTypeId].length) {
                DocContext.filter[docTypeId] = [];
            } else {
                DocContext.filter[docTypeId] = createEmptyFilterData(DocContext.gridConfig[docTypeId], [], docTypeId)
            }
        }

    }

};


module.export = (DocContext);