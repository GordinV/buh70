'use strict';

const relatedDocuments = (self) => {
    // формируем зависимости
    let pages = self.pages;
    let relatedDocuments = self.docData.relations ? self.docData.relations: [];
    if (self.pages && self.pages.length && (!self.docData.id || self.docData.id ===0)) {
        // создаем новый док
        pages= [self.pages[0]];
        relatedDocuments = [];
    }

    if (relatedDocuments.length > 0) {
        relatedDocuments.forEach((doc) => {
            if (doc.id) {
                // проверим на уникальность списка документов
                let isExists = pages.find((page) => {
                    if (!page.docId) {
                        return false;
                    } else {
                        return page.docId == doc.id && page.docTypeId == doc.doc_type;
                    }
                });

                if (!isExists) {
                    // в массиве нет, добавим ссылку на документ
                    pages.push({docTypeId: doc.doc_type, docId: doc.id,
                        pageName: doc.name + (doc.number ? ' nr:' + doc.number: ' id:' + doc.id)})
                }
            }
        });
    }
    self.pages = pages;
};

module.exports = relatedDocuments;