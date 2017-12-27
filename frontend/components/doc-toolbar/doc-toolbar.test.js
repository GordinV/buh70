require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');
const ToolBar = require('./doc-toolbar.jsx');
let tasks = [{step: 0, name: 'Start', action: 'start', status: 'opened'}];

describe('components test, DocToolbar', () => {
    const validator = jest.fn();

    const methodClick = jest.fn();


    let component = ReactTestUtils.renderIntoDocument(<ToolBar bpm = {tasks}
                                                               btnEditClick = {methodClick}
                                                               btnAddClick = {methodClick}
                                                               btnSaveClick = {methodClick}
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
        expect(component.btnAddClick).toBeDefined();
        let button = component.refs['btnAdd'];
        component.btnAddClick();
//        ReactTestUtils.Simulate.click(button);
        expect(methodClick).toBeCalled();
    });

    it.skip('btnEditClick function test', ()=> {
        expect(component.btnEditClick).toBeDefined();
        let button = component.refs['btnEdit'];
        ReactTestUtils.Simulate.click(button);
        expect(methodClick).toBeCalled();
    });

    it('btnSaveClick function test', ()=> {
        expect(component.btnSaveClick).toBeDefined();
        component.btnSaveClick();
        expect(methodClick).toBeCalled();
    });

    it('btnCancelClick function test', ()=> {
        expect(component.btnCancelClick).toBeDefined();
        component.btnCancelClick();
        expect(methodClick).toBeCalled();
    });

    it('taskWidget should be shown', ()=> {
        let taskWidget = component.refs['taskWidget'];
        expect(taskWidget).toBeDefined();
        let taskButton = taskWidget.refs['buttonTask'];
        expect(taskButton).toBeDefined();
    })

});
