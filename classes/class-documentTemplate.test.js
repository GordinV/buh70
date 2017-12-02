describe('Document tests', () => {
    const Document = require('./DocumentTemplate');
    const doc = new Document('ARV', 383, 1);
    let returnedData = {};

    it('should exist and have props', () => {
        expect(doc).toBeDefined();
        expect(doc.docTypeId).toBeDefined();
        expect(doc.config).toBeDefined();
        expect(doc.documentId).toBeDefined();
    });

    it('should have methods',() => {
        expect(doc.createNew).toBeDefined();
        expect(doc.select).toBeDefined();
        expect(doc.save).toBeDefined();
        expect(doc.executeTask).toBeDefined();
    });

    it ('should have setted docTypeId and docId', () => {
        expect(doc.docTypeId).not.toBeNull();
        expect(doc.docId).not.toBeNull();
        expect(doc.userId).not.toBeNull();
    });

    it ('select new document method', async(done) => {
        expect.assertions(3);

        returnedData = await doc.createNew();
//        console.log('returnedData', returnedData);
        expect(returnedData).toBeDefined();
        expect(returnedData).toHaveProperty('row');
        expect(returnedData.row.length).toBeGreaterThan(0);
        done();
    });


    it ('select method', async(done) => {
        expect.assertions(3);

        returnedData = await doc.select();
        expect(returnedData).toBeDefined();
        expect(returnedData).toHaveProperty('row');
        expect(returnedData.row.length).toBeGreaterThan(0);
//        console.log('returnedData:', returnedData);
        done();
    });

    it ('tried to call save method with wrong parameters', () => {
        expect.assertions(1);

        const params = {};
        expect(() => {doc.save(params)}).toThrow('Wrong params structure');
    });

    it ('save new document ', async(done) => {
        expect.assertions(3);

        let docData = await doc.select();

        const params = {
            data: {
                doc_id: docData.row[0].id,
                data: docData.row[0],
                details: docData.details
            },
            userId: 1,
            asutusId: 1
        };

        let savedData = await doc.save(params);
        expect(savedData).toBeDefined();
        expect(savedData.result).toBe(1);
        expect(savedData.data.length).toBeGreaterThan(0);
        done();
    });


});