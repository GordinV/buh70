require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');


describe('doc test, Tunnused', () => {
    // проверяем на наличие компонента и его пропсы и стейты
    // проверяем изменение стейтов после клика
    const Tunnused = require('./index.jsx');

    let dataRow = require('./../../../test/fixture/project-fixture'),
        model = require('./../../../models/libs/libraries/tunnus');

    const initData = {result: {data: [{id: 1}]}, gridConfig: [{id: "id", name: "id", width: "10%", show: false}]};

    const user = require('./../../../test/fixture/userData');


    let onChangeHandler = jest.fn();

    let doc = ReactTestUtils.renderIntoDocument(<Tunnused userData={user}
                                                          initData={initData}/>);

    it('should be defined', () => {
        expect(doc).toBeDefined();
        expect(doc.refs['tunnused']).toBeDefined();
    });

});
