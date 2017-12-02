
import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');

describe('component test, toolbarContainer', () => {
    const ToolbarContainer = require('./toolbar-container.jsx');
    const style = require('./toolbar-container-styles');

    let component = ReactTestUtils.renderIntoDocument(<ToolbarContainer style = {style.toolBarContainerStyle}> <span></span></ToolbarContainer>);

    it('should be defined', () => {
        expect(component).toBeDefined();
    });

    it('should exists all components', ()=> {
        expect(component.refs['toolBarContainer']).toBeDefined();
    });

});
