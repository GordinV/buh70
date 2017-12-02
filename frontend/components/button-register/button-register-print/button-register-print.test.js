require('./../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react'),
    fs = require('fs'),
    path = require('path');

let  btnClickResult = null;

const btnClick = ()=> {
    btnClickResult = 'Ok';
}

describe.only('component test, buttonPrint', () => {

    const Button = require('./button-register-print.jsx'),
        style = require('../button-register-styles');

    let component = ReactTestUtils.renderIntoDocument(<Button
        value="Print"
        onClick={btnClick}>
    </Button>);

    let buttonPrint = component.refs['btnPrint'];
    let button = buttonPrint.refs['button'];

    it ('should be define', () => {
        expect(component).toBeDefined();
    });

    it('should have property show, disabled (default', () => {
        expect(buttonPrint.props.show).toBe(true);
        expect(buttonPrint.props.disabled).toBe(false);
    });

    it('should exist children image', () => {
        let image = component.refs['image'];
        expect(image).toBeDefined();
    });

    it('should exist image file', () => {
        let image = component.refs['image'],
            publicPath = path.join(__dirname, '../../../../public/'),
            src = path.join(publicPath, style.icons.print);

        let imageFile = fs.statSync(src);
        expect(imageFile.isFile()).toBe(true);

    });

});
