require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');
const flux = require('fluxify');
const docStore = require('../../stores/doc_store.js');
const ToolBar = require('./doc-toolbar.jsx');
let tasks = [{step: 0, name: 'Start', action: 'start', status: 'opened'}];

describe('components test, DocToolbar', () => {
    const validator = jest.fn();


    let component = ReactTestUtils.renderIntoDocument(<ToolBar bpm = {tasks}
                                                               validator ={validator}
                                                               docStatus = {0}/>);

    it('should be defined', () => {
        expect(component).toBeDefined();
    });

    it('should exists all components', ()=> {
        expect(component.refs['btnAdd']).toBeDefined();
        expect(component.refs['btnEdit']).toBeDefined();
        expect(component.refs['btnSave']).toBeDefined();
        expect(component.refs['btnPrint']).toBeDefined();
        expect(component.refs['taskWidget']).toBeDefined();
    });

    it('btnAddClick function test', ()=> {
        component.btnAddClick();
        setTimeout(()=>{
            expect(flux.stores.docStore.docId).toBe(0);
            expect(flux.stores.docStore.edited).toBeTruthy();
            expect(flux.stores.docStore.saved).toBeFalsy();
        }, 1000);
    })

    it('btnEditClick function test', ()=> {
        component.btnEditClick();
        setTimeout(()=>{
            expect(flux.stores.docStore.edited).toBeTruthy();
            expect(flux.stores.docStore.saved).toBeFalsy();
        }, 1000);
    })

    it('btnSaveClick function test', ()=> {
        component.btnSaveClick();
        expect(validator).toBeCalled();

        setTimeout(()=>{
            expect(flux.stores.docStore.edited).toBeFalsy();
            expect(flux.stores.docStore.saved).toBeTruthy();
        }, 1000);
    });

    it('taskWidget should be shown', ()=> {
        let taskWidget = component.refs['taskWidget'];
        expect(taskWidget).toBeDefined();
        let taskButton = taskWidget.refs['buttonTask'];
        expect(taskButton).toBeDefined();
    })

});
