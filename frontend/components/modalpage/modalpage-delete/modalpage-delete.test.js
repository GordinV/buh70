require('./../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';
const React = require('react');

let result;

const handleClick = (e) => {
    result = e;
}

describe('component test, modalPage-delete', () => {

    const ModalPageDelete = require('./modalPage-delete.jsx'),
        style = require('../modalpage-delete/modalpage-delete-styles');

    const component = ReactTestUtils.renderIntoDocument(<ModalPageDelete
        modalObjects={['btnOk', 'btnCancel']}
        modalPageBtnClick={handleClick}
        show={true}>
    </ModalPageDelete>)

    it('should be define', () => {
        expect(component).toBeDefined();
    });

    it('children components', () => {
        let page = component.refs['modalPage'],
            container = page.refs['container'],
            image = page.refs['image'];

        //           message = page.refs['message'];

        expect(page).toBeDefined();
        expect(image).toBeDefined();
//        expect(message).toBeDefined();
    });

});