require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');
const PageLabel = require('./page-label.jsx');
//    const style = require('./datalist-styles');
const handlePageClick = jest.fn();

describe('components test, PageLabel', () => {
    let page = {pageName: 'Arve', docId: 1};
    let component = ReactTestUtils.renderIntoDocument(<PageLabel page = {page} handlePageClick={handlePageClick}/>);

    it('should be defined', () => {
        expect(component).toBeDefined();
    });

    it('should call handlePageClick',()=> {
        let Page = component.refs['pageLabel'];
        expect(Page).toBeDefined();
        ReactTestUtils.Simulate.click(Page);
        expect(handlePageClick).toBeCalled();
        expect(handlePageClick.mock.calls).toEqual([[page]]);
    });

    it ('should not call handleClick if it disabled', () => {
        handlePageClick.mockClear(); // clear all previous states

        let component = ReactTestUtils.renderIntoDocument(<PageLabel page = {page}
                                                                     handlePageClick={handlePageClick}
                                                                     disabled={true}/>);
        expect(component.state.disabled).toBeTruthy();

        let Page = component.refs['pageLabel'];
        expect(Page).toBeDefined();
        ReactTestUtils.Simulate.click(Page);
        expect(handlePageClick).not.toBeCalled();

    })

});