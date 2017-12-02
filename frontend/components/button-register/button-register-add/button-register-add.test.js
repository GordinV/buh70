require('./../../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react'),
    fs = require('fs'),
    path=require('path');

let  btnClickResult = null;

const btnClick = ()=> {
    btnClickResult = 'Ok';
}


/*
 let shallowRenderer = ReactTestUtils.createRenderer();

 shallowRenderer.render(
 <Button value="Test" onClick={btnClick}>
 </Button>);

 let shallowComponent = shallowRenderer.getRenderOutput();
 */


//const button = component.refs['button'];

describe.only('component test, button', () => {

    const Button = require('./button-register-add.jsx'),
        style = require('../button-register-styles');

    let component = ReactTestUtils.renderIntoDocument(<Button
        value="Add"
        show={false}
        disabled={true}
        onClick={btnClick}>
    </Button>);

    let buttonAdd = component.refs['btnAdd'];
    let button = buttonAdd.refs['button'];

    it ('should be define', () => {
        expect(component).toBeDefined();
    });

    it('should have property show, disabled (default', () => {
        expect(buttonAdd.props.show).toBe(false);
        expect(buttonAdd.props.disabled).toBe(true);
    });

    it ('should exist children image', () => {
        let image = component.refs['image'];
        expect(image).toBeDefined();
    });

    it ('should exist image file', () => {
        let image = component.refs['image'],
            publicPath = path.join(__dirname, '../../../../public/'),
            src = path.join(publicPath, style.icons.add);


        let imageFile = fs.statSync(src);
        expect(imageFile.isFile()).toBe(true);

    });
});
