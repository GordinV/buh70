describe('Document tests', () => {
    const Library = require('./LibraryTemplate');
    const tunnus = new Library('TUNNUS');
    let returnedData = {};

    it('should exist and have props', () => {
        expect(tunnus).toBeDefined();
        expect(tunnus.docTypeId).toBeDefined();
        expect(tunnus.config).toBeDefined();
    });

    it('should have methods',() => {
        expect(tunnus.selectLib).toBeDefined();
    });

    it ('should have setted docTypeId and docId', () => {
        expect(tunnus.docTypeId).not.toBeNull();
        expect(tunnus.docTypeId).toBe('TUNNUS');
    });

    it ('selectLib method', async(done) => {
        expect.assertions(4);

        returnedData = await tunnus.selectLib();
        expect(returnedData).toBeDefined();
        expect(returnedData).toHaveProperty('result');
        expect(returnedData).toHaveProperty('data');
        expect(returnedData.data.length).toBeGreaterThan(0);
        done();
    });



});