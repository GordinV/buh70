'use strict';
require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ

import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');
const StartMenu = require('./start-menu.jsx');
const startMenuData = [
    {id: 1, parentId: 0, name: 'ParentId', is_node: true},
    {id: 2, parentId: 1, name: 'Child', is_node: false}];

describe('components test, StartMenu', () => {
    const component = ReactTestUtils.renderIntoDocument(<StartMenu data={startMenuData}/>);

    it('should be defined', () => {
        expect(component).toBeDefined();
        expect(component.refs['treeList']).toBeDefined();
    });

    it ('test of fetchData method', async()=> {
        expect(component.fetchData).toBeDefined();
        let result = await component.fetchData();
//        expect(result).toBeDefined();
    })

});