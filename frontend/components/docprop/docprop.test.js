require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');

describe('components test, DocProp', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const DokProp = require('./docprop.jsx');
//    const style = require('./input-text-styles');

    let data = require('./../../../test/fixture/doc-common-fixture');
    let onChangeHandler = jest.fn();

    let component = ReactTestUtils.renderIntoDocument(<DokProp
        title="Konteerimine: "
        name='doklausid'
        libs="dokProps"
        value={data.doklausid}
        defaultValue={data.dokprop}
        placeholder='Konteerimine'
        readOnly={true}/>);

    it('should be defined', () => {
        expect(component).toBeDefined();
    });

    it ('should contain Select and Text ', ()=> {
        expect(component.refs['select']).toBeDefined();
        expect(component.refs['text']).toBeDefined();
    })

});