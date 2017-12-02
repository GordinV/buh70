'use strict';

const relatedDocuments = (self) => {
    // формируем зависимости

    let relatedDocuments = self.state.relations;
    if (relatedDocuments.length > 0) {
        relatedDocuments.forEach((doc) => {
            if (doc.id) {
                // проверим на уникальность списка документов
                let isExists = self.pages.find((page) => {
                    if (!page.docId) {
                        return false;
                    } else {
                        return page.docId == doc.id && page.docTypeId == doc.doc_type;
                    }
                });

                if (!isExists) {
                    // в массиве нет, добавим ссылку на документ
                    self.pages.push({docTypeId: doc.doc_type, docId: doc.id, pageName: doc.name + ' id:' + doc.id})
                }
            }
        });
    }
}

module.exports = relatedDocuments;