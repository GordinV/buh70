describe('prepaireData tests', () => {
    const PrepaireData = require('./prepaireData');
    const prepaireData = new PrepaireData('ARV', 'select');

    it('should exist module', () => {
        expect(prepaireData).toBeDefined();
/*
        expect(prepaireData).toHaveProperty('docTypeId');
        expect(prepaireData).toHaveProperty('selectAsLibs');
        expect(prepaireData).toHaveProperty('save');
        expect(prepaireData).toHaveProperty('execute');
        expect(prepaireData).toHaveProperty('delete');
        expect(prepaireData).toHaveProperty('select');
*/
    });


    it('тест на сеттер', ()=> {
        expect(prepaireData.docTypeId).toBe('ARV');
        expect(prepaireData.config).not.toBeNull();
    });

    it('тест для select', ()=> {
        const data = prepaireData.select();
        console.log('data', data);
//        expect(data).not.toBeNull();
    });

});