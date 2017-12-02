require('./../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react'),
    fs = require('fs'),
    path=require('path');

let  btnClickResult = null;

const btnClick = ()=> {
    btnClickResult = 'Ok';
}


describe.only('component test, button start', () => {

    const Button = require('./button-register-start.jsx'),
        style = require('../button-register-styles');

    let component = ReactTestUtils.renderIntoDocument(<Button
        value=""
        show={false}
        disabled={true}
        onClick={btnClick}>
    </Button>);

    let buttonStart = component.refs['btnStart'];
    let button = buttonStart.refs['button'];

    it ('should be define', () => {
        expect(component).toBeDefined();
    });

    it('should have property show, disabled (default', () => {
        expect(buttonStart.props.show).toBe(false);
        expect(buttonStart.props.disabled).toBe(true);
    });

    it ('should exist children image', () => {
        let image = component.refs['image'];
        expect(image).toBeDefined();
    });

    it ('should exist image file', () => {
        let image = component.refs['image'],
            publicPath = path.join(__dirname, '../../../../public/'),
            src = path.join(publicPath, style.icons.start);


        let imageFile = fs.statSync(src);
        expect(imageFile.isFile()).toBe(true);

    });
});
