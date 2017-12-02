require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');
const flux = require('fluxify');
const docStore = require('../../stores/doc_store.js'),
    data = require('./../../../test/fixture/doc-common-fixture');

const DocCommon = require('./doc-common.jsx');
//    const style = require('./datalist-styles');
const handlePageClick = jest.fn();

describe('components test, form', () => {
    flux.doAction('dataChange', data);
    let component = ReactTestUtils.renderIntoDocument(<DocCommon data={data}/>);

    it('should be defined', () => {
        expect(component).toBeDefined();
    });

    it ('should contain components', () => {
        expect(component.refs['id']).toBeDefined();
        expect(component.refs['created']).toBeDefined();
        expect(component.refs['lastupdate']).toBeDefined();
        expect(component.refs['status']).toBeDefined();
    });

    it ('should change data, received from changed input', ()=> {
        let idInput = component.refs['id'];
        expect(idInput).toBeDefined();
        expect(idInput.refs['input']).toBeDefined();
        ReactTestUtils.Simulate.change(idInput.refs['input'], {"target": {"value": 2}});
        setTimeout(()=>{
            expect(flux.stores.docStore.data['id']).toBe(2);
        }, 1000);

    });

});