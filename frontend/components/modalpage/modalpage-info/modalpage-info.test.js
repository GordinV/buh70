require('./../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';
const React = require('react');

let result;

const handleClick = (e) => {
    result = e;
}

describe('component test, modalPage-info', () => {

    const ModalPageInfo = require('./modalPage-info.jsx'),
        style = require('../modalpage-info/modalpage-info-styles');

    const component = ReactTestUtils.renderIntoDocument(<ModalPageInfo
        modalObjects={['btnOk']}
        modalPageBtnClick={handleClick}
        show={true}>
    </ModalPageInfo>)

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