require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');


describe('doc test, DocumentTemplate', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Document = require('./index.jsx');
    const style = require('./document-styles');
    const data = {id: 187, kood: 'kod'},
        requiredFields = [
            {
                name: 'kood',
                type: 'C'
            }];

    const userData = {};


    let Handler = jest.fn();

    const render = () => {
        return (<div ref='customObject'>Test</div>)
    };

    let doc = ReactTestUtils.renderIntoDocument(<Document initData={data}
                                                          docId = {0}
                                                          docTypeId='JOURNAL'
                                                          userData={userData}
                                                          renderer={render}
                                                          libs={['tunnus']}
                                                          requiredFields={requiredFields}/>);

    it('should be defined', () => {
        expect(doc).toBeDefined();
        expect(doc.fetchData).toBeDefined();
        expect(doc.btnAddClick).toBeDefined();
        expect(doc.btnEditClick).toBeDefined();
        expect(doc.btnDeleteClick).toBeDefined();
        expect(doc.btnPrintClick).toBeDefined();
        expect(doc.btnSaveClick).toBeDefined();
        expect(doc.btnCancelClick).toBeDefined();
        expect(doc.handleButtonTask).toBeDefined();
        expect(doc.makeBackup).toBeDefined();
        expect(doc.restoreFromBackup).toBeDefined();
        expect(doc.handleInputChange).toBeDefined();
        expect(doc.validation).toBeDefined();
        expect(doc.renderDocToolBar).toBeDefined();
        expect(doc.prepareParamsForToolbar).toBeDefined();
//        expect(doc.renderStartMenu).toBeDefined();
//        expect(doc.startMenuClickHandler).toBeDefined();
        expect(doc.addRow).toBeDefined();

    });


    it('test of btnAddClick', () => {

        doc.btnAddClick();
        setTimeout(()=> {
            //переводит в режим редактирования
            expect(doc.state.edited).toBeTruthy();
            //делает копию
            expect(doc.backup).toEqual(data);

        },1000)
//        done();
    });

    it('test of btnEditClick', (done) => {
        // не должно позволить редактировать данные
        let result = doc.handleInputChange('kood', '0000');
        expect(result).toBeFalsy();
        expect(doc.docData).toEqual(data);

        doc.btnEditClick();
        //переводит в режим редактирования
        expect(doc.state.edited).toBeTruthy();
        //делает копию
        expect(doc.backup).toEqual(data);
        done();
    });

    it('test of createLibs and loadLibs method',() => {
        expect(doc.createLibs).toBeDefined();
        expect(doc.props.libs.length).toBeGreaterThan(0);
        setTimeout(()=> {
            expect(doc.state.loadedLibs).toBeFalsy();
            expect(doc.libs['tunnus'].length).toBeGreaterThan(0);
        },1000);
    });



    it('test of handleInputChange', () => {
        let inputName = 'kood',
            value = 'changedKood';

        doc.handleInputChange(inputName, value);
        expect(doc.docData[inputName]).toBe(value);
    });

    it('test of btnCancelClick', (done) => {
        doc.btnCancelClick();
        //переводит в режим редактирования
        expect(doc.state.edited).toBeFalsy();

        //востановим прежнее состояние
        expect(doc.docData).toEqual(doc.backup);

        done();
    });

    it('test of validation', () => {
        expect(doc.validation()).toBe(''); //проверка на валидацию в режиме просмотра. должно вернкть ''
        doc.btnEditClick();
        expect(doc.validation()).toBe(''); //проверка на достоверность. должно вернкть ''
        doc.handleInputChange('kood', '');
        expect(doc.validation()).toMatch('puudub'); //должно вернуть ошибку
        doc.btnCancelClick(); //в прежнее состояние
    });

    it('test of renderDocToolBar', () => {
        expect(doc.refs['doc-toolbar']).toBeDefined();
//        expect(doc.refs['menu-toolbar']).toBeDefined();
    });

    it('test of prepareParamsForToolbar', () => {
        const params = {
            btnAdd: {
                show: true,
                disabled: false
            },
            btnEdit: {
                show: true,
                disabled: false
            },
            btnSave: {
                show: false,
                disabled: false
            },
            btnDelete: {
                show: true,
                disabled: false
            },
            btnPrint: {
                show: true,
                disabled: false
            },
            btnStart: {
                show: true
            },
            btnLogin: {
                show: true,
                disabled: false
            },
            btnAccount: {
                show: true,
                disabled: false
            },
            btnRekv: {
                show: true,
                disabled: false
            }
        };

        expect(doc.prepareParamsForToolbar()).toMatchObject({btnAdd:{}, btnEdit:{},
            btnSave:{},btnDelete:{}, btnPrint:{}, btnStart:{}, btnLogin:{}, btnAccount:{},btnRekv:{} })
    });

    it.skip('test of renderStartMenu', ()=> {
        //пока кнопка старт меню не отжать компонент должен отсутствоать
        expect(doc.state.hasStartMenuVisible).toBeFalsy();
        expect(doc.refs['start-menu']).not.toBeDefined();
        //кнопка отжата
        doc.startMenuClickHandler ();
        expect(doc.state.hasStartMenuVisible).toBeTruthy();
        expect(doc.refs['start-menu']).toBeDefined();
        doc.startMenuClickHandler ('forTest'); //прячем меню
        expect(doc.state.hasStartMenuVisible).toBeFalsy();

    });

    it('test of custom rendered object', ()=> {
        expect(doc.refs['customObject']).toBeDefined();
    });

    it('test of fetch data', ()=> {
        doc.fetchData();
        setTimeout(()=> {
            expect(doc.state.reloadData).toBeFalsy();
        },1000);
    });

    it('test of handlePageClick',() => {
        expect(doc.handlePageClick).toBeDefined();
    });

    it('test of handleGridRowInput',() => {
        expect(doc.handleGridRowInput).toBeDefined();
    });

    it ('test of handleGridRow',() => {
        expect(doc.handleGridRow).toBeDefined();

    })

});