require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';
const React = require('react');

let result;

const handleClick = (e) => {
    result = e;
}

describe('component test, modalPage', () => {

    const ModalPage = require('./modalPage.jsx'),
        style = require('./modalpage-styles');

    const component = ReactTestUtils.renderIntoDocument(<ModalPage
        modalObjects = {['btnOk', 'btnCancel']}
        modalPageBtnClick={handleClick}
        show={true}
        modalPageName='Filter'>

        <span>filter test</span>
    </ModalPage>)

    it('should be define', () => {
        expect(component).toBeDefined();
    });

    it ('should contain header, btnOk, btnCancel', () => {
        expect(component.refs['modalPageHeader']).toBeDefined();
        expect(component.refs['btnOk']).toBeDefined();
        expect(component.refs['btnCancel']).toBeDefined();
        expect(component.refs['btnClose']).toBeDefined();
    });

    it ('should return Ok or Cancel as result of click events', ()=> {
        if (!component.state.show) {
            component.changeVisibilityModalPage()
        }

        let btnOk = component.refs['btnOk'];
            ReactTestUtils.Simulate.click(btnOk.refs['button']);

        expect(result).toBe('Ok');
        // модальное окно должно закрыться
        expect(component.state.show).toBeFalsy();

        // will open modalPage
        component.changeVisibilityModalPage()

        let btnCancel = component.refs['btnCancel'];
        ReactTestUtils.Simulate.click(btnCancel.refs['button']);

        // модальное окно должно закрыться
        expect(component.state.show).toBeFalsy();
        // результат
        expect(result).toBe('Cancel');

    });

    it ('test of the changeVisibilityModalPage',()=> {
       let container = component.refs['container'];
       expect(container).toBeDefined();

       if (!component.state.show) {
           component.changeVisibilityModalPage();
       }
       expect(container.style.display).not.toBe('none');
        component.changeVisibilityModalPage();
        expect(container.style.display).toBe('none');
    });

    it('should close modalpage by clicking closeButton',() => {
        let button = component.refs['btnClose'],
            container = component.refs['container'];

        if (!component.state.show) {
            // окно закрыто, меняет состояние
            component.changeVisibilityModalPage();
        }

         ReactTestUtils.Simulate.click(button.refs['button']);
        expect(button).toBeDefined();
        expect(component.state.show).toBe(false);
        expect(container.style.display).toBe('none');

    })
})
