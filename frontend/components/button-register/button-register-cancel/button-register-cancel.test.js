require('./../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react'),
    fs = require('fs'),
    path = require('path');

let  btnClickResult = null;

const btnClick = jest.fn();

describe.only('component test, buttonCancel', () => {

    const Button = require('./button-register-cancel.jsx'),
        style = require('../button-register-styles');

    let component = ReactTestUtils.renderIntoDocument(<Button
        value="Cancel"
        onClick={btnClick}>
    </Button>);

    let buttonPrint = component.refs['btnCancel'];
    let button = buttonPrint.refs['button'];

    it ('should be define', () => {
        expect(component).toBeDefined();
    });

    it('should have property show, disabled (default', () => {
        expect(buttonPrint.props.show).toBeTruthy();
        expect(buttonPrint.props.disabled).toBeFalsy();
    });

    it('should exist children image', () => {
        let image = component.refs['image'];
        expect(image).toBeDefined();
    });

    it('should exist image file', () => {
        let image = component.refs['image'],
            publicPath = path.join(__dirname, '../../../../public/'),
            src = path.join(publicPath, style.icons.cancel);

        let imageFile = fs.statSync(src);
        expect(imageFile.isFile()).toBe(true);

    });

    it('should called onClick function', ()=> {
        ReactTestUtils.Simulate.click(button);
        expect(btnClick).toBeCalled();
    });

});
